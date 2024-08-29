// ignore_for_file: use_build_context_synchronously

import 'package:crud_supabase/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.imgUrl,
    required this.onUpload,
  });

  final String? imgUrl;
  final void Function(String) onUpload;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 125,
          height: 125,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              width: 2,
              color: Colors.white,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: Colors.lightBlue.withOpacity(0.2),
            child: imgUrl != null && imgUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      imgUrl!,
                      fit: BoxFit.cover,
                      width: 125,
                      height: 125,
                    ),
                  )
                : Text(
                    'No Pic',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () async {
            final ImagePicker picker = ImagePicker();
            final XFile? image =
                await picker.pickImage(source: ImageSource.gallery);
            if (image == null) return;

            String getMimeType(String extension) {
              switch (extension) {
                case 'jpg':
                case 'jpeg':
                  return 'image/jpeg';
                case 'png':
                  return 'image/png';
                case 'gif':
                  return 'image/gif';
                default:
                  return 'application/octet-stream';
              }
            }

            final imageExtension = image.path.split('.').last.toLowerCase();
            final imageBytes = await image.readAsBytes();
            final userId = supabase.auth.currentUser!.id;
            final imagePath = 'public/$userId/profile.$imageExtension';
            final mimeType = getMimeType(imageExtension);

            try {
              await supabase.storage.from('profiles').uploadBinary(
                    imagePath,
                    imageBytes,
                    fileOptions: FileOptions(
                      upsert: true,
                      contentType: mimeType,
                    ),
                  );
              String imageUrl =
                  supabase.storage.from('profiles').getPublicUrl(imagePath);
              imageUrl = Uri.parse(imageUrl).replace(queryParameters: {
                't': DateTime.now().millisecondsSinceEpoch.toString(),
              }).toString();
              onUpload(imageUrl);
            } catch (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Upload failed: $error')),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Unggah',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
