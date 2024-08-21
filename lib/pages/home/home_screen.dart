// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crud_supabase/pages/auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home-screen';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> contactStream;

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      contactStream = Supabase.instance.client
          .from('contacts')
          .stream(primaryKey: ['id']).eq('user_id', userId);
    } else {
      contactStream = Stream.value([]);
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  Future<void> createContact(String name, String phone) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client.from('contacts').insert({
      'name': name,
      'phone': phone,
      'user_id': userId,
    });
  }

  Future<void> updateContact(
      String contactId, String name, String phone) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('contacts')
        .update({
          'name': name,
          'phone': phone,
        })
        .eq('id', contactId)
        .eq('user_id', userId);
  }

  Future<void> deleteContact(String contactId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('contacts')
        .delete()
        .eq('id', contactId)
        .eq('user_id', userId);
  }

  void _showAddContactDialog() {
    _nameController.clear();
    _phoneController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Kontak'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text;
                final phone = _phoneController.text;

                if (name.isNotEmpty && phone.isNotEmpty) {
                  await createContact(name, phone);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua Kolom Harus Diisi!'),
                    ),
                  );
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateContactDialog(
      String contactId, String currentName, String currentPhone) {
    _nameController.text = currentName;
    _phoneController.text = currentPhone;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Kontak'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text;
                final phone = _phoneController.text;

                if (name.isNotEmpty && phone.isNotEmpty) {
                  await updateContact(contactId, name, phone);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua Kolom Harus Diisi!'),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Kontak'),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: contactStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final contacts = snapshot.data!;
          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contact_phone,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Belum ada kontak',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final contactId = contact['id'].toString();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    contact['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(contact['phone']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          _showUpdateContactDialog(
                              contactId, contact['name'], contact['phone']);
                        },
                        icon: const Icon(Icons.edit),
                        color: Colors.blue,
                      ),
                      IconButton(
                        onPressed: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Hapus Kontak'),
                                content: const Text(
                                    'Apakah Anda yakin ingin menghapus kontak ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (shouldDelete == true) {
                            await deleteContact(contactId);
                          }
                        },
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
