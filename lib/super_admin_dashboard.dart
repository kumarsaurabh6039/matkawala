import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

// --- THEME: MNC/Corporate Style (Deep Blue & White) ---
const Color kPrimary = Color(0xFF1A237E); // Corporate Blue
const Color kBgColor = Color(0xFFF5F7FA);
const Color kTextDark = Color(0xFF2D3436);
const Color kCardColor = Colors.white;

// Chat Colors
const Color kChatBubbleAdmin = Color(0xFF1A237E); 
const Color kChatBubbleUser = Color(0xFFECEFF1);

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const OverviewPage(),
    const ManageMarketsPage(), 
    const LiveBetsPage(),      
    const AdminChatListPage(), 
    const PeopleManagementPage(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text(
          'SUPER ADMIN', 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: kTextDark)
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextDark),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Logout",
          )
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: kPrimary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_input_component), label: 'Markets'),
          BottomNavigationBarItem(icon: Icon(Icons.visibility), label: 'Bets'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'People'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. OVERVIEW PAGE
// -----------------------------------------------------------------------------
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bets').snapshots(),
          builder: (context, betSnap) {
            if (!userSnap.hasData || !betSnap.hasData) return const Center(child: CircularProgressIndicator());

            var users = userSnap.data!.docs;
            var bets = betSnap.data!.docs;
            int totalUsers = users.where((d) => (d.data() as Map)['role'] == 'user').length;
            int totalAdmins = users.where((d) => (d.data() as Map)['role'] == 'admin').length;
            int totalBets = bets.length;
            double totalVolume = 0;
            for (var bet in bets) {
              totalVolume += (bet['amount'] as num? ?? 0).toDouble();
            }

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text("System Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _statCard("Total Users", totalUsers.toString(), Icons.group, Colors.blue),
                    const SizedBox(width: 16),
                    _statCard("Total Admins", totalAdmins.toString(), Icons.security, Colors.purple),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statCard("Total Bets", totalBets.toString(), Icons.receipt_long, Colors.orange),
                    const SizedBox(width: 16),
                    _statCard("Volume", "₹ ${totalVolume.toStringAsFixed(0)}", Icons.currency_rupee, Colors.green),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 20),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextDark)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. MANAGE MARKETS
// -----------------------------------------------------------------------------
class ManageMarketsPage extends StatefulWidget {
  const ManageMarketsPage({super.key});

  @override
  State<ManageMarketsPage> createState() => _ManageMarketsPageState();
}

class _ManageMarketsPageState extends State<ManageMarketsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimary,
        label: const Text("Create Market", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddGameDialog(context),
      ),
      body: Column(
        children: [
           Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: Colors.white,
               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
             ),
             child: Row(
               children: [
                 Container(
                   padding: const EdgeInsets.all(10),
                   decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                   child: const Icon(Icons.settings_input_component, color: kPrimary, size: 24),
                 ),
                 const SizedBox(width: 15),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text("Market Configuration", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark)),
                     Text("Tap on a card to edit settings", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                   ],
                 ),
               ],
             ),
           ),
           Expanded(
             child: StreamBuilder<QuerySnapshot>(
               stream: FirebaseFirestore.instance.collection('games').orderBy('order').snapshots(),
               builder: (context, snapshot) {
                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                 if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No markets added yet."));

                 return GridView.builder(
                   padding: const EdgeInsets.all(16),
                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                     crossAxisCount: 2, // 2 columns
                     crossAxisSpacing: 16,
                     mainAxisSpacing: 16,
                     childAspectRatio: 0.85, 
                   ),
                   itemCount: snapshot.data!.docs.length,
                   itemBuilder: (context, index) {
                     var doc = snapshot.data!.docs[index];
                     var data = doc.data() as Map<String, dynamic>;
                     return _buildMarketCard(context, doc, data);
                   },
                 );
               },
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildMarketCard(BuildContext context, DocumentSnapshot doc, Map<String, dynamic> data) {
    bool isClosed = data['isClosed'] ?? false;
    return GestureDetector(
      onTap: () => _showEditMarketSheet(context, doc.id, data),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: kPrimary.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
          ],
          border: Border.all(color: isClosed ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isClosed ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 3, backgroundColor: isClosed ? Colors.red : Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        isClosed ? "CLOSED" : "ACTIVE",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isClosed ? Colors.red : Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.05), shape: BoxShape.circle),
              child: Text(
                data['name'].isNotEmpty ? data['name'][0] : '?',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimary),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                data['name'],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Text(
                data['result'] ?? '***-**-***',
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
              ),
              child: const Center(
                child: Text("Tap to Configure", style: TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showEditMarketSheet(BuildContext context, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditMarketSheet(docId: docId, data: data),
    );
  }

  void _showAddGameDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final openCtrl = TextEditingController(text: "12:00 PM");
    final closeCtrl = TextEditingController(text: "02:00 PM");
    final openBetStartCtrl = TextEditingController(text: "10:00 AM");
    final openBetEndCtrl = TextEditingController(text: "11:00 AM");
    final closeBetStartCtrl = TextEditingController(text: "12:00 PM");
    final closeBetEndCtrl = TextEditingController(text: "01:00 PM");

    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("New Market"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name (e.g. KALYAN)")),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            if (nameCtrl.text.isNotEmpty) {
              FirebaseFirestore.instance.collection('games').add({
                'name': nameCtrl.text.toUpperCase(),
                'openBetStart': openBetStartCtrl.text, 'openBetEnd': openBetEndCtrl.text,
                'closeBetStart': closeBetStartCtrl.text, 'closeBetEnd': closeBetEndCtrl.text,
                'openTime': openCtrl.text, 'closeTime': closeCtrl.text,
                'result': '***-**-***', 'isClosed': false,
                'order': DateTime.now().millisecondsSinceEpoch,
              });
              Navigator.pop(context);
            }
          },
          child: const Text("Create"),
        )
      ],
    ));
  }
}

class EditMarketSheet extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const EditMarketSheet({super.key, required this.docId, required this.data});

  @override
  State<EditMarketSheet> createState() => _EditMarketSheetState();
}

class _EditMarketSheetState extends State<EditMarketSheet> {
  late bool isClosed;
  late TextEditingController resultCtrl;

  @override
  void initState() {
    super.initState();
    isClosed = widget.data['isClosed'] ?? false;
    resultCtrl = TextEditingController(text: widget.data['result'] == '***-**-***' ? '' : widget.data['result']);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.data['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSectionHeader("MARKET STATUS"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isClosed ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isClosed ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2)),
                  ),
                  child: SwitchListTile(
                    title: Text(isClosed ? "Market is CLOSED" : "Market is ACTIVE", style: TextStyle(fontWeight: FontWeight.bold, color: isClosed ? Colors.red : Colors.green)),
                    subtitle: const Text("Manually stop betting"),
                    value: !isClosed, 
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                    onChanged: (val) {
                      setState(() => isClosed = !val);
                      FirebaseFirestore.instance.collection('games').doc(widget.docId).update({'isClosed': !val});
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader("DECLARE RESULT"),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: resultCtrl,
                        decoration: InputDecoration(
                          hintText: "123-68-456",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        FirebaseFirestore.instance.collection('games').doc(widget.docId).update({'result': resultCtrl.text});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Result Updated!"), backgroundColor: Colors.green));
                      },
                      child: const Text("UPDATE"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader("BETTING SCHEDULE"),
                _buildTimeRow("Open Session", "Bet Start", "openBetStart", "Bet End", "openBetEnd"),
                const SizedBox(height: 12),
                _buildTimeRow("Close Session", "Bet Start", "closeBetStart", "Bet End", "closeBetEnd"),
                const SizedBox(height: 24),
                _buildSectionHeader("RESULT DISPLAY TIME"),
                _buildSingleTimeRow("Open Result Time", "openTime"),
                _buildSingleTimeRow("Close Result Time", "closeTime"),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red.withOpacity(0.05),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("DELETE MARKET"),
                    onPressed: () => _confirmDelete(context),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildTimeRow(String label, String t1Label, String t1Key, String t2Label, String t2Key) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTimePicker(t1Label, widget.data[t1Key], t1Key)),
              const SizedBox(width: 12), 
              const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
              const SizedBox(width: 12), 
              Expanded(child: _buildTimePicker(t2Label, widget.data[t2Key], t2Key)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleTimeRow(String label, String key) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kTextDark)),
          _buildTimePicker("Select", widget.data[key], key),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label, String? currentVal, String dbKey) {
    return InkWell(
      onTap: () => _pickTime(dbKey, currentVal ?? "12:00 PM"),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: kBgColor, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(currentVal ?? "--:--", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // --- FORCE ENGLISH LOCALE WHEN SAVING TIME (FIXED UI REFRESH & PARSING) ---
  Future<void> _pickTime(String key, String current) async {
    TimeOfDay initial = TimeOfDay.now();
    try {
      String clean = current.trim().toUpperCase().replaceAll('.', ':');
      // Clean weird spaces flutter might throw
      clean = clean.replaceAll('\u202F', ' ').replaceAll('\u00A0', ' ');
      
      if (!clean.contains(" ") && (clean.endsWith("AM") || clean.endsWith("PM"))) {
        clean = clean.replaceFirst("AM", " AM").replaceFirst("PM", " PM");
      }
      
      // Explicit formatting
      final format = DateFormat("hh:mm a", 'en_US'); 
      DateTime dt = format.parseLoose(clean); 
      initial = TimeOfDay.fromDateTime(dt);
    } catch (e) {
      debugPrint("Parsing Error in time: $e");
    }

    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: initial);
    
    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      
      // Explicitly format to avoid hidden \u202F character space
      String formatted = DateFormat("hh:mm a", 'en_US').format(dt);
      formatted = formatted.replaceAll('\u202F', ' ').replaceAll('\u00A0', ' ');
      
      // 1. Update Database
      await FirebaseFirestore.instance.collection('games').doc(widget.docId).update({key: formatted});
      
      // 2. Update Local UI immediately
      if (mounted) {
        setState(() {
          widget.data[key] = formatted;
        });
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Time Updated Successfully"), backgroundColor: Colors.green, duration: Duration(seconds: 1))
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Delete Market?"),
      content: const Text("This action cannot be undone."),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text("Cancel")),
        TextButton(onPressed: () { 
          FirebaseFirestore.instance.collection('games').doc(widget.docId).delete(); 
          Navigator.pop(ctx); 
          Navigator.pop(context); 
        }, child: const Text("Delete", style: TextStyle(color: Colors.red)))
      ],
    ));
  }
}

// -----------------------------------------------------------------------------
// 3. LIVE BETS PAGE 
// -----------------------------------------------------------------------------
class LiveBetsPage extends StatelessWidget {
  const LiveBetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.centerLeft,
          child: const Text("Live Betting Feed", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark)),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bets').orderBy('timestamp', descending: true).limit(100).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No bets found"));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  String status = data['status'] ?? 'pending';
                  
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text(data['number'].toString(), style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                      ),
                      title: Text("${data['gameName']} (${data['session']})"),
                      subtitle: Text("${data['betType']} • ₹${data['amount']}"),
                      trailing: status == 'pending'
                        ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text("PENDING", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)))
                        : Text(status.toUpperCase(), style: TextStyle(color: status == 'win' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
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
// 4. CHAT LIST PAGE
// -----------------------------------------------------------------------------
class AdminChatListPage extends StatelessWidget {
  const AdminChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.centerLeft,
          child: const Text("Support & Chats", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark)),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('chats').orderBy('lastUpdated', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No chats yet"));

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String userId = data['userId'] ?? doc.id;
                  
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                    builder: (context, userSnap) {
                      String displayName = "User $userId";
                      if(userSnap.hasData && userSnap.data!.exists) {
                        var userData = userSnap.data!.data() as Map<String, dynamic>;
                        displayName = userData['email'] ?? "Unknown";
                      }

                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: kPrimary, child: Icon(Icons.person, color: Colors.white)),
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(data['lastMessage'] ?? '...', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(userId: userId, userName: displayName)));
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}

class AdminChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const AdminChatScreen({super.key, required this.userId, required this.userName});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _msgCtrl = TextEditingController();

  void _sendReply() {
    if (_msgCtrl.text.trim().isEmpty) return;
    String msg = _msgCtrl.text.trim();
    _msgCtrl.clear();

    FirebaseFirestore.instance.collection('chats').doc(widget.userId).collection('messages').add({
      'text': msg, 'sender': 'admin', 'type': 'text', 'timestamp': FieldValue.serverTimestamp(),
    });
    FirebaseFirestore.instance.collection('chats').doc(widget.userId).set({
      'lastMessage': "SuperAdmin: $msg", 'lastUpdated': FieldValue.serverTimestamp(), 'userId': widget.userId,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(title: Text(widget.userName, style: const TextStyle(color: kTextDark)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: kTextDark)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(widget.userId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    bool isAdmin = data['sender'] == 'admin';
                    bool isBet = data['type'] == 'bet';
                    return Align(
                      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: isAdmin ? kChatBubbleAdmin : kChatBubbleUser, borderRadius: BorderRadius.circular(12)),
                        child: isBet 
                          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text("BID SLIP", style: TextStyle(color: isAdmin ? Colors.white : kPrimary, fontWeight: FontWeight.bold, fontSize: 10)),
                              Text(data['gameName'], style: TextStyle(color: isAdmin ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                              Text("${data['betType']} (${data['session']}) - No: ${data['number']} | ₹${data['amount']}", style: TextStyle(color: isAdmin ? Colors.white70 : Colors.black54, fontSize: 12)),
                            ])
                          : Text(data['text'] ?? '', style: TextStyle(color: isAdmin ? Colors.white : Colors.black87)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(children: [
              Expanded(child: TextField(controller: _msgCtrl, decoration: const InputDecoration(hintText: "Reply...", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30)))))),
              IconButton(icon: const Icon(Icons.send, color: kPrimary), onPressed: _sendReply)
            ]),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5. PEOPLE MANAGEMENT 
// -----------------------------------------------------------------------------
class PeopleManagementPage extends StatefulWidget {
  const PeopleManagementPage({super.key});

  @override
  State<PeopleManagementPage> createState() => _PeopleManagementPageState();
}

class _PeopleManagementPageState extends State<PeopleManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: kPrimary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Manage Users"),
              Tab(text: "Manage Admins"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              ManageUsersView(),
              ManageAdminsView(),
            ],
          ),
        ),
      ],
    );
  }
}

// --- USERS LIST VIEW ---
class ManageUsersView extends StatelessWidget {
  const ManageUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        label: const Text("Create User"),
        icon: const Icon(Icons.person_add),
        onPressed: () => _showCreateDialog(context, 'user'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No users found"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: const Icon(Icons.person, color: Colors.green)),
                  title: Text(data['email'] ?? 'User'),
                  subtitle: Text("Balance: ₹${data['balance'] ?? 0}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye, color: kPrimary),
                        tooltip: "View User Ledger",
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (ctx) => SuperAdminUserLedgerScreen(userId: doc.id, userEmail: data['email'] ?? 'User')));
                        },
                      ),
                      IconButton(icon: const Icon(Icons.add_card, color: Colors.blue), onPressed: () => _recharge(context, doc.id, data['balance'] ?? 0)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => doc.reference.delete()),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _recharge(BuildContext context, String uid, int current) {
    final c = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Add Funds"),
      content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount")),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: () {
          int amt = int.tryParse(c.text) ?? 0;
          if(amt > 0) FirebaseFirestore.instance.collection('users').doc(uid).update({'balance': current + amt});
          Navigator.pop(ctx);
        }, child: const Text("Add"))
      ],
    ));
  }
}

// --- ADMINS LIST VIEW ---
class ManageAdminsView extends StatelessWidget {
  const ManageAdminsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimary,
        label: const Text("Create Admin", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.security, color: Colors.white),
        onPressed: () => _showCreateDialog(context, 'admin'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'admin').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No admins found"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: kPrimary.withOpacity(0.1), child: const Icon(Icons.security, color: kPrimary)),
                  title: Text(data['email'] ?? 'Admin'),
                  subtitle: const Text("Role: Admin"),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => doc.reference.delete()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- SHARED CREATE DIALOG ---
void _showCreateDialog(BuildContext context, String role) {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: Text("Create New $role"),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
        TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Password")),
      ],
    ),
    actions: [
      TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
      ElevatedButton(
        onPressed: () async {
          if(emailCtrl.text.isNotEmpty && passCtrl.text.isNotEmpty) {
             Navigator.pop(ctx);
             await _registerEntity(context, emailCtrl.text, passCtrl.text, role);
          }
        }, 
        child: const Text("Create")
      )
    ],
  ));
}

Future<void> _registerEntity(BuildContext context, String email, String password, String role) async {
  FirebaseApp? tempApp;
  try {
    tempApp = await Firebase.initializeApp(name: 'tempCreate_${DateTime.now().millisecondsSinceEpoch}', options: Firebase.app().options);
    UserCredential cred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(email: email, password: password);
    
    await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'role': role,
      'approved': true,
      'balance': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': 'SuperAdmin',
    });
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$role Created Successfully!"), backgroundColor: Colors.green));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
  } finally {
    await tempApp?.delete();
  }
}

// -----------------------------------------------------------------------------
// SUPER ADMIN LEDGER VIEW
// -----------------------------------------------------------------------------
class SuperAdminUserLedgerScreen extends StatefulWidget {
  final String userId;
  final String userEmail;

  const SuperAdminUserLedgerScreen({super.key, required this.userId, required this.userEmail});

  @override
  State<SuperAdminUserLedgerScreen> createState() => _SuperAdminUserLedgerScreenState();
}

class _SuperAdminUserLedgerScreenState extends State<SuperAdminUserLedgerScreen> {
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.black, onPrimary: Colors.white, surface: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ledger: ${widget.userEmail}", style: const TextStyle(color: kTextDark, fontSize: 16)),
            if (_selectedDate != null)
              Text(DateFormat('dd MMM yyyy').format(_selectedDate!), style: const TextStyle(color: kPrimary, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: kTextDark),
        actions: [
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => setState(() => _selectedDate = null),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: kPrimary),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
          
          var userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
          int currentWallet = (userData['balance'] as num? ?? 0).toInt();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bets').where('userId', isEqualTo: widget.userId).snapshots(),
            builder: (context, betSnap) {
              if (betSnap.hasError) return Center(child: Text("Error: ${betSnap.error}", style: const TextStyle(color: Colors.red)));
              if (!betSnap.hasData) return const Center(child: CircularProgressIndicator());

              var docs = betSnap.data!.docs;

              // --- FILTER LOGIC ---
              if (_selectedDate != null) {
                docs = docs.where((doc) {
                  Timestamp? ts = (doc.data() as Map<String, dynamic>)['timestamp'];
                  if (ts == null) return false;
                  DateTime dt = ts.toDate();
                  return dt.year == _selectedDate!.year && dt.month == _selectedDate!.month && dt.day == _selectedDate!.day;
                }).toList();
              }

              // Client side sorting
              docs.sort((a, b) {
                Timestamp t1 = (a.data() as Map<String, dynamic>)['timestamp'] ?? Timestamp.now();
                Timestamp t2 = (b.data() as Map<String, dynamic>)['timestamp'] ?? Timestamp.now();
                return t2.compareTo(t1);
              });

              int totalDhanda = 0;
              int totalPayment = 0;
              
              for (var doc in docs) {
                var bet = doc.data() as Map<String, dynamic>;
                totalDhanda += (bet['amount'] as num? ?? 0).toInt();
                if (bet['status'] == 'win') {
                  totalPayment += (bet['potentialWin'] as num? ?? 0).toInt();
                }
              }

              return Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Current Wallet", style: TextStyle(fontSize: 18, color: Colors.grey)),
                        Text("₹ $currentWallet", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 16, right: 8),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(children: [
                             const Text("Total Dhanda", style: TextStyle(color: Colors.grey)),
                             const SizedBox(height: 8),
                             Text("₹ $totalDhanda", style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 8, right: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(children: [
                             const Text("Total Payment", style: TextStyle(color: Colors.grey)),
                             const SizedBox(height: 8),
                             Text("₹ $totalPayment", style: const TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(alignment: Alignment.centerLeft, child: Text("Detailed History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text("${data['gameName']} (${data['session']})"),
                            subtitle: Text("Bet: ₹${data['amount']} on ${data['number']}"),
                            trailing: Text(
                              (data['status'] ?? 'pending').toString().toUpperCase(), 
                              style: TextStyle(fontWeight: FontWeight.bold, color: data['status'] == 'win' ? Colors.green : (data['status']=='loss' ? Colors.red : Colors.orange))
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }
}