import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// --- THEME COLORS ---
const Color kPrimary = Color(0xFF2E3192); 
const Color kAccent = Color(0xFFD32F2F); 
const Color kTextMain = Color(0xFF1A1A1A); 
const Color kTextGrey = Color(0xFF5A5A5A);
const Color kAdminBg = Color(0xFFF4F6F8); 
const Color kCardBg = Colors.white; 

// --- WHATSAPP THEME COLORS FOR CHAT ---
const Color kWABg = Color(0xFF0B141A);       
const Color kWABubbleAdmin = Color(0xFF005D4B); // Admin ka green bubble
const Color kWABubbleUser = Color(0xFF2A3942);  // User ka grey bubble
const Color kWAInputBg = Color(0xFF1F2C34);  
const Color kWAFab = Color(0xFF00A884);      

// -----------------------------------------------------------------------------
// ADMIN CHAT TAB - USERS LIST DIKHANE KE LIYE
// -----------------------------------------------------------------------------
class AdminChatTab extends StatefulWidget {
  const AdminChatTab({super.key});

  @override
  State<AdminChatTab> createState() => _AdminChatTabState();
}

class _AdminChatTabState extends State<AdminChatTab> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    String currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("सपोर्ट चॅट (Support Chat)", style: TextStyle(color: kTextMain, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                style: const TextStyle(color: kTextMain),
                decoration: InputDecoration(
                  hintText: "एजंट शोधा (Search Agent)...",
                  hintStyle: const TextStyle(color: kTextGrey),
                  prefixIcon: const Icon(Icons.search, color: kTextGrey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Sirf wahi users fetch karo jo is admin ne banaye hain
            stream: FirebaseFirestore.instance.collection('users')
                .where('role', isEqualTo: 'user')
                .where('createdBy', isEqualTo: currentAdminId) 
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("कोणतेही एजंट सापडले नाहीत. (No agents found)", style: TextStyle(color: kTextGrey)));
              }

              var docs = snapshot.data!.docs.where((doc) {
                 var data = doc.data() as Map<String, dynamic>;
                 String name = (data['name']?.toString() ?? '').toLowerCase();
                 String email = (data['email']?.toString() ?? '').toLowerCase();
                 return name.contains(_searchQuery) || email.contains(_searchQuery);
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var doc = docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  
                  String displayEmail = data['email']?.toString() ?? '';
                  if (displayEmail.endsWith('@matkawala.com')) {
                     displayEmail = displayEmail.replaceAll('@matkawala.com', '');
                  }

                  String displayName = data['name']?.toString() ?? displayEmail;
                  if(displayName.isEmpty) displayName = 'Agent';

                  return Card(
                    color: kCardBg,
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: kPrimary.withOpacity(0.1),
                        child: Text(displayName[0].toUpperCase(), style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(displayName, style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: StreamBuilder<DocumentSnapshot>(
                        // Latest message check karne ke liye chat doc ko stream karo
                        stream: FirebaseFirestore.instance.collection('chats').doc(doc.id).snapshots(),
                        builder: (context, chatSnap) {
                          if (chatSnap.hasData && chatSnap.data!.exists) {
                             var chatData = chatSnap.data!.data() as Map<String, dynamic>;
                             return Text(chatData['lastMessage'] ?? "Tap to chat...", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kTextGrey));
                          }
                          return const Text("Tap to chat...", style: TextStyle(color: kTextGrey, fontStyle: FontStyle.italic));
                        },
                      ),
                      trailing: const Icon(Icons.chat, color: kPrimary),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserChatScreen(userId: doc.id, userName: displayName)));
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ADMIN - USER CHAT SCREEN
// -----------------------------------------------------------------------------
class AdminUserChatScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminUserChatScreen({super.key, required this.userId, required this.userName});

  @override
  State<AdminUserChatScreen> createState() => _AdminUserChatScreenState();
}

class _AdminUserChatScreenState extends State<AdminUserChatScreen> {
  final TextEditingController _msgController = TextEditingController();

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    
    // Message bhejte time sender 'admin' mark karna zaroori hai
    FirebaseFirestore.instance.collection('chats').doc(widget.userId).collection('messages').add({
      'text': _msgController.text.trim(), 
      'sender': 'admin', // Sender admin hai 
      'type': 'text', 
      'timestamp': FieldValue.serverTimestamp()
    });
    
    // Main doc update for last message info
    FirebaseFirestore.instance.collection('chats').doc(widget.userId).set({
      'lastMessage': _msgController.text.trim(), 
      'lastUpdated': FieldValue.serverTimestamp(), 
      'userId': widget.userId
    }, SetOptions(merge: true));
    
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWABg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2C34),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats')
                  .doc(widget.userId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kWAFab));
                
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("येथे चॅट सुरू करा... (Start chat here)", style: TextStyle(color: Colors.white54)));
                }

                return ListView.builder(
                  reverse: true, 
                  itemCount: snapshot.data!.docs.length, 
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    
                    // Admin screen par, 'admin' ke messages right mein dikhenge
                    bool isMe = data['sender'] == 'admin';
                    
                    var time = (data['timestamp'] as Timestamp?)?.toDate();
                    String timeStr = time != null ? DateFormat('hh:mm a').format(time) : '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, 
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), 
                          decoration: BoxDecoration(
                            color: isMe ? kWABubbleAdmin : kWABubbleUser, 
                            borderRadius: BorderRadius.circular(12)
                          ), 
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(data['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(timeStr, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            ],
                          )
                        ),
                      )
                    );
                  }
                );
              },
            )
          ),
          
          // Input Box
          Padding(
            padding: const EdgeInsets.all(8), 
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController, 
                    style: const TextStyle(color: Colors.white), 
                    decoration: InputDecoration(
                      filled: true, 
                      fillColor: kWAInputBg, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), 
                      hintText: 'मेसेज लिहा (Type message)...', 
                      hintStyle: const TextStyle(color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                    )
                  )
                ), 
                const SizedBox(width: 8), 
                CircleAvatar(
                  backgroundColor: kWAFab, 
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white), 
                    onPressed: _sendMessage
                  )
                )
              ]
            )
          )
        ]
      )
    );
  }
}