import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// --- THEME COLORS ---
const Color kPrimary = Color(0xFF1A237E);
const Color kAccent = Color(0xFFD32F2F);
const Color kTextMain = Color(0xFF1A1A1A);
const Color kTextGrey = Color(0xFF5A5A5A);
const Color kSuccess = Color(0xFF00897B);

class ManageAdminScreen extends StatefulWidget {
  final String searchQuery;
  const ManageAdminScreen({super.key, required this.searchQuery});

  @override
  State<ManageAdminScreen> createState() => _ManageAdminScreenState();
}

class _ManageAdminScreenState extends State<ManageAdminScreen> {

  // --- ADMIN CREATION / EDIT DIALOG (WITH PERMISSIONS) ---
  void _showAdminDialog(BuildContext context, {required bool isEdit, String? docId, Map<String, dynamic>? data}) {
    Map<String, dynamic> safeData = data ?? {};
    String originalEmail = safeData['email']?.toString() ?? "";
    if (originalEmail.endsWith('@matkawala.com')) {
      originalEmail = originalEmail.replaceAll('@matkawala.com', '');
    }

    final nameCtrl = TextEditingController(text: isEdit ? (safeData['name'] ?? "") : "");
    final phoneCtrl = TextEditingController(text: isEdit ? (safeData['phone'] ?? "") : "");
    final emailCtrl = TextEditingController(text: isEdit ? originalEmail : "");
    final passCtrl = TextEditingController(text: isEdit ? (safeData['password'] ?? "") : "");

    // Permissions State
    bool pUsers = true;
    bool pPayments = true;
    bool pGames = true;
    bool pLedger = true;
    bool pManual = true;

    if (isEdit && safeData['permissions'] != null) {
      Map<String, dynamic> perms = safeData['permissions'];
      pUsers = perms['manage_users'] ?? true;
      pPayments = perms['manage_payments'] ?? true;
      pGames = perms['edit_games'] ?? true;
      pLedger = perms['view_ledger'] ?? true;
      pManual = perms['manual_panel'] ?? true;
    }

    showDialog(
      context: context, 
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(isEdit ? "ॲडमिन माहिती बदला (Edit Admin)" : "नवीन ॲडमिन जोडा (New Admin)", style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameCtrl, style: const TextStyle(color: kTextMain), decoration: const InputDecoration(labelText: "नाव (Name)", labelStyle: TextStyle(color: kTextGrey))),
                  TextField(controller: phoneCtrl, style: const TextStyle(color: kTextMain), decoration: const InputDecoration(labelText: "मोबाईल (Phone)", labelStyle: TextStyle(color: kTextGrey))),
                  if (!isEdit) TextField(controller: emailCtrl, style: const TextStyle(color: kTextMain), decoration: const InputDecoration(labelText: "लॉगिन आयडी (Username)", labelStyle: TextStyle(color: kTextGrey))),
                  TextField(controller: passCtrl, style: const TextStyle(color: kTextMain), decoration: const InputDecoration(labelText: "पासवर्ड (Password)", labelStyle: TextStyle(color: kTextGrey))),
                  
                  const SizedBox(height: 24),
                  const Text("अधिकार नियंत्रण (Permissions):", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary, fontSize: 15)),
                  const SizedBox(height: 10),
                  
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text("युजर्स व्यवस्थापन (Manage Users)", style: TextStyle(fontSize: 13, color: kTextMain)), 
                          value: pUsers, 
                          onChanged: (v) => setStateBuilder(() => pUsers = v), 
                          activeColor: kSuccess
                        ),
                        const Divider(height: 1, color: Colors.black12),
                        SwitchListTile(
                          title: const Text("पेमेंट व्यवस्थापन (Manage Payments)", style: TextStyle(fontSize: 13, color: kTextMain)), 
                          value: pPayments, 
                          onChanged: (v) => setStateBuilder(() => pPayments = v), 
                          activeColor: kSuccess
                        ),
                        const Divider(height: 1, color: Colors.black12),
                        SwitchListTile(
                          title: const Text("गेम वेळ/निकाल अपडेट (Edit Games)", style: TextStyle(fontSize: 13, color: kTextMain)), 
                          value: pGames, 
                          onChanged: (v) => setStateBuilder(() => pGames = v), 
                          activeColor: kSuccess
                        ),
                        const Divider(height: 1, color: Colors.black12),
                        SwitchListTile(
                          title: const Text("हिशोब पाहणे (View Ledger)", style: TextStyle(fontSize: 13, color: kTextMain)), 
                          value: pLedger, 
                          onChanged: (v) => setStateBuilder(() => pLedger = v), 
                          activeColor: kSuccess
                        ),
                        const Divider(height: 1, color: Colors.black12),
                        SwitchListTile(
                          title: const Text("मॅन्युअल पॅनेल (Manual Panel)", style: TextStyle(fontSize: 13, color: kTextMain)), 
                          value: pManual, 
                          onChanged: (v) => setStateBuilder(() => pManual = v), 
                          activeColor: kSuccess
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("रद्द करा", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.pop(ctx);
                  String finalEmail = emailCtrl.text.trim();
                  if(!finalEmail.contains('@')) finalEmail = '$finalEmail@matkawala.com';

                  Map<String, dynamic> updateData = {
                    'name': nameCtrl.text,
                    'phone': phoneCtrl.text,
                    'password': passCtrl.text,
                    'permissions': {
                      'manage_users': pUsers,
                      'manage_payments': pPayments,
                      'edit_games': pGames,
                      'view_ledger': pLedger,
                      'manual_panel': pManual,
                    }
                  };

                  if (isEdit) {
                     await FirebaseFirestore.instance.collection('users').doc(docId).update(updateData);
                     if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("माहिती आणि अधिकार अपडेट केले!"), backgroundColor: Colors.green));
                  } else {
                     updateData['role'] = 'admin';
                     updateData['approved'] = true;
                     await _registerAuthUser(context, updateData, finalEmail, passCtrl.text);
                  }
                }, 
                child: const Text("सेव्ह करा")
              )
            ],
          );
        }
      )
    );
  }

  // --- FIREBASE USER CREATION ---
  Future<void> _registerAuthUser(BuildContext context, Map<String, dynamic> dbData, String email, String password) async {
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(name: 'tempAdminCreate_${DateTime.now().millisecondsSinceEpoch}', options: Firebase.app().options);
      UserCredential cred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(email: email, password: password);
      
      dbData['email'] = email;
      dbData['createdAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set(dbData);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ॲडमिन यशस्वीरित्या जोडला! (Admin Created)"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("त्रुटी: $e"), backgroundColor: Colors.red));
    } finally {
      await tempApp?.delete();
    }
  }

  void _deleteUser(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Delete Admin?", style: TextStyle(color: kAccent, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure? This cannot be undone.", style: TextStyle(color: kTextMain)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAccent, foregroundColor: Colors.white),
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(docId).delete();
              Navigator.pop(ctx);
            },
            child: const Text("Delete")
          )
        ],
      )
    );
  }

  String _getPermName(String key) {
    switch(key) {
      case 'manage_users': return 'Users';
      case 'manage_payments': return 'Payments';
      case 'edit_games': return 'Games';
      case 'view_ledger': return 'Ledger';
      case 'manual_panel': return 'Manual Panel';
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdminDialog(context, isEdit: false),
        icon: const Icon(Icons.add), 
        label: const Text("नवीन ॲडमिन"),
        backgroundColor: Colors.purple, 
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'admin').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs.where((doc) {
             var data = doc.data() as Map<String, dynamic>;
             String name = (data['name']?.toString() ?? '').toLowerCase();
             String email = (data['email']?.toString() ?? '').toLowerCase();
             return name.contains(widget.searchQuery) || email.contains(widget.searchQuery);
          }).toList();

          if (docs.isEmpty) return const Center(child: Text("Admins not found.", style: TextStyle(color: kTextGrey)));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String email = data['email']?.toString() ?? '';
              if (email.endsWith('@matkawala.com')) email = email.replaceAll('@matkawala.com', '');
              
              Map<String, dynamic> perms = data['permissions'] ?? {};

              return Card(
                color: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.admin_panel_settings, color: Colors.white)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['name'] ?? email, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextMain, fontSize: 16)),
                                  Text("ID: $email | Ph: ${data['phone'] ?? '-'}", style: const TextStyle(color: kTextGrey, fontSize: 12)),
                                ],
                              )
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showAdminDialog(context, isEdit: true, docId: doc.id, data: data)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteUser(doc.id)),
                            ],
                          )
                        ],
                      ),
                      if (perms.isNotEmpty) ...[
                        const Divider(color: Colors.black12, height: 20),
                        const Text("अधिकार (Active Permissions):", style: TextStyle(fontSize: 11, color: kTextGrey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: perms.entries.where((e) => e.value == true).map((e) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green.shade200)),
                            child: Text(_getPermName(e.key), style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                          )).toList(),
                        )
                      ]
                    ],
                  ),
                ),
              );
            }
          );
        }
      ),
    );
  }
}