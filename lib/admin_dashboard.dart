import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// --- THEME COLORS (MNC Level - High Contrast & Clean) ---
const Color kAdminBg = Color(0xFFF4F6F8); 
const Color kCardBg = Colors.white; 
const Color kPrimary = Color(0xFF2E3192); 
const Color kAccent = Color(0xFFD32F2F); 
const Color kTextMain = Color(0xFF1A1A1A); 
const Color kTextGrey = Color(0xFF5A5A5A); 
const Color kSuccess = Color(0xFF00897B); 
const Color kPurpleLedger = Color(0xFF7B1FA2);

const Map<String, int> GAME_RATES = {
  'Single Digit': 10,    
  'Jodi Digit': 100,      
  'Single Panna': 160,   
  'Double Panna': 320,   
  'Triple Panna': 1000,   
};

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  void _switchTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      AdminHomePage(onTabSelected: _switchTab), 
      const GameManagementPage(), 
      const ManageUsersPage(),    
      const AdminSlipPage(),         
      const ManualPanelPage(),    
    ];

    return Scaffold(
      backgroundColor: kAdminBg,
      appBar: AppBar(
        title: const Text(
          'मॅनेजमेंट पॅनेल (Management Panel)', 
          style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary, fontSize: 18)
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextMain),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout, color: kAccent),
            tooltip: "लॉगआउट करा",
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _switchTab,
        selectedItemColor: kPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'डॅशबोर्ड'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_input_component), label: 'मार्केट'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'एजंट'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'हिशोब'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'मॅन्युअल'),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. HOME DASHBOARD
// -----------------------------------------------------------------------------
class AdminHomePage extends StatelessWidget {
  final Function(int) onTabSelected;
  const AdminHomePage({super.key, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    String currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ॲप्लिकेशन स्नॅपशॉट (Application Snapshot)", style: TextStyle(color: kTextMain, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('createdBy', isEqualTo: currentAdminId).snapshots(),
            builder: (context, userSnap) {
              int totalAgents = userSnap.hasData ? userSnap.data!.docs.length : 0;
              
              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: [
                  _buildShortcutCard("मॅन्युअल पॅनेल\n(Manual Panel)", Icons.edit, kSuccess, () => onTabSelected(4)),
                  _buildShortcutCard("निकाल अपडेट करा\n(Update Result)", Icons.receipt, kSuccess, () => onTabSelected(1)),
                  _buildShortcutCard("एकूण एजंट\n($totalAgents)", Icons.people, Colors.blue.shade700, () => onTabSelected(2)),
                  _buildShortcutCard("गेम लोड रिपोर्ट\n(Game Report)", Icons.insert_drive_file, kSuccess, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GameLoadReportPage()));
                  }),
                  _buildShortcutCard("पावती / जमा नावे\n(Receipt PDF)", Icons.file_download, kPurpleLedger, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const JamaNaaveReceiptPage()));
                  }),
                  _buildShortcutCard("पेमेंट (Payment)\nAdd/Deduct", Icons.request_quote, Colors.orange.shade800, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentPaymentPage()));
                  }),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            const Divider(indent: 20, endIndent: 20),
            Text("येथे क्लिक करा", style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. ADMIN SLIP PAGE (PROFIT & LOSS)
// -----------------------------------------------------------------------------
class AdminSlipPage extends StatefulWidget {
  const AdminSlipPage({super.key});

  @override
  State<AdminSlipPage> createState() => _AdminSlipPageState();
}

class _AdminSlipPageState extends State<AdminSlipPage> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedGameId;
  String? _selectedGameName;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text("ॲडमिन स्लिप (Admin Slip)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextMain))),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text("तारीख (Date) : ", style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain)),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                          child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(color: kTextMain)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text("गेमचे नाव : ", style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain)),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('games').orderBy('order').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          List<DropdownMenuItem<String>> items = [
                            const DropdownMenuItem(value: null, child: Text("--मार्केट निवडा--", style: TextStyle(color: kTextMain)))
                          ];
                          for(var doc in snapshot.data!.docs) {
                            var d = doc.data() as Map<String, dynamic>;
                            items.add(DropdownMenuItem(value: doc.id, child: Text(d['name'] ?? '', style: const TextStyle(color: kTextMain))));
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedGameId,
                                items: items,
                                dropdownColor: Colors.white,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedGameId = val;
                                    if(val != null) {
                                      var selectedDoc = snapshot.data!.docs.firstWhere((element) => element.id == val).data() as Map<String, dynamic>;
                                      _selectedGameName = selectedDoc['name'];
                                    } else {
                                      _selectedGameName = null;
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_selectedGameId != null)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bets').where('gameId', isEqualTo: _selectedGameId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData) return const Center(child: Text("No Data", style: TextStyle(color: kTextGrey)));
                  
                  var docs = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    Timestamp? ts = data['timestamp'];
                    if (ts == null) return false;
                    DateTime dt = ts.toDate();
                    return dt.year == _selectedDate.year && dt.month == _selectedDate.month && dt.day == _selectedDate.day;
                  }).toList();

                  double openDhanda = 0, closeDhanda = 0;
                  double openSinglePay = 0, openPannaPay = 0;
                  double closeSinglePay = 0, closePannaPay = 0;
                  double jodiPay = 0;

                  for (var doc in docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    double amt = (data['amount'] ?? 0).toDouble();
                    double winAmt = data['status'] == 'won' ? (data['potentialWin'] ?? 0).toDouble() : 0.0;
                    String type = data['betType'] ?? '';
                    String session = data['session'] ?? 'Open';

                    if (session == 'Open') openDhanda += amt;
                    else closeDhanda += amt;

                    if (winAmt > 0) {
                      if (type.contains('Single Digit')) {
                        if (session == 'Open') openSinglePay += winAmt;
                        else closeSinglePay += winAmt;
                      } else if (type.contains('Panna')) {
                        if (session == 'Open') openPannaPay += winAmt;
                        else closePannaPay += winAmt;
                      } else if (type.contains('Jodi')) {
                        jodiPay += winAmt;
                      }
                    }
                  }

                  double totalDhanda = openDhanda + closeDhanda;
                  double commission = totalDhanda * 0.10; 
                  double totalPayment = openSinglePay + openPannaPay + closeSinglePay + closePannaPay + jodiPay;
                  double totalJama = totalPayment + commission;
                  double profit = totalDhanda - totalJama;

                  return SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text("खेळ अमाऊंट (Dhanda)", style: TextStyle(fontWeight: FontWeight.bold, color: kTextGrey, fontSize: 12)),
                                    const Divider(),
                                    _slipRow("ओपन धंदा", openDhanda),
                                    _slipRow("क्लोज धंदा", closeDhanda),
                                    _slipRow("फेर अमाऊंट", 0.00),
                                    const Divider(),
                                    _slipRow("टोटल", totalDhanda, isBold: true),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 250, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 10)),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text("पेमेंट अमाऊंट (Payout)", style: TextStyle(fontWeight: FontWeight.bold, color: kTextGrey, fontSize: 12)),
                                    const Divider(),
                                    _slipRow("ओपन सिंगल", openSinglePay),
                                    _slipRow("ओपन पाना", openPannaPay),
                                    _slipRow("क्लोज सिंगल", closeSinglePay),
                                    _slipRow("क्लोज पाना", closePannaPay),
                                    _slipRow("जोड", jodiPay),
                                    _slipRow("कमिशन (10%)", commission),
                                    _slipRow("फेर अमाऊंट", 0.00),
                                    _slipRow("खर्च अमाऊंट", 0.00),
                                    const Divider(),
                                    _slipRow("टोटल", totalJama, isBold: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.black, thickness: 1.5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("धंदा : $totalDhanda", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kTextMain)),
                              const Text(" - ", style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain)),
                              Text("पेमेंट : $totalJama", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kTextMain)),
                              const Text(" = ", style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain)),
                              Text("नफा (Profit) : ${profit.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: profit >= 0 ? Colors.green : Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Printing Slip...")));
                              },
                              icon: const Icon(Icons.print, size: 18),
                              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                              label: const Text("प्रिन्ट करा (Print)"),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          else
             const Expanded(child: Center(child: Text("माहिती पाहण्यासाठी गेम निवडा (Select Game)", style: TextStyle(color: kTextGrey)))),
        ],
      ),
    );
  }

  Widget _slipRow(String label, double val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: kTextMain, fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(": ${val.toStringAsFixed(2)}", style: TextStyle(color: kTextMain, fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// GAME LOAD REPORT
// -----------------------------------------------------------------------------
class GameLoadReportPage extends StatefulWidget {
  const GameLoadReportPage({super.key});

  @override
  State<GameLoadReportPage> createState() => _GameLoadReportPageState();
}

class _GameLoadReportPageState extends State<GameLoadReportPage> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedGameId;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _selectedDate, firstDate: DateTime(2024), lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)), child: child!);
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    String currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: kAdminBg,
      appBar: AppBar(
        title: const Text("Game Load Report", style: TextStyle(color: kTextMain)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: kTextMain),
        elevation: 1,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: kCardBg,
            child: Column(
              children: [
                Row(
                  children: [
                    const Text("तारीख (Date): ", style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain)),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                          child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(color: kTextMain)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text("गेम (Market): ", style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain)),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('games').orderBy('order').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          List<DropdownMenuItem<String>> items = [const DropdownMenuItem(value: null, child: Text("--मार्केट निवडा--", style: TextStyle(color: kTextMain)))];
                          for(var doc in snapshot.data!.docs) {
                            var data = doc.data() as Map<String, dynamic>;
                            items.add(DropdownMenuItem(value: doc.id, child: Text(data['name'] ?? '', style: const TextStyle(color: kTextMain))));
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true, value: _selectedGameId, items: items,
                                dropdownColor: Colors.white, 
                                onChanged: (val) => setState(() => _selectedGameId = val),
                                style: const TextStyle(color: kTextMain, fontSize: 16),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (_selectedGameId != null)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bets').where('gameId', isEqualTo: _selectedGameId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  
                  var docs = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    Timestamp? ts = data['timestamp'];
                    if (ts == null) return false;
                    DateTime dt = ts.toDate();
                    return dt.year == _selectedDate.year && dt.month == _selectedDate.month && dt.day == _selectedDate.day;
                  }).toList();

                  Map<String, int> userTotals = {};
                  int grandTotal = 0;

                  for (var doc in docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String uId = data['userId'] ?? 'Unknown';
                    int amt = (data['amount'] as num? ?? 0).toInt();
                    
                    if (!userTotals.containsKey(uId)) userTotals[uId] = 0;
                    userTotals[uId] = userTotals[uId]! + amt;
                    grandTotal += amt;
                  }

                  if (userTotals.isEmpty) return const Center(child: Text("या मार्केटवर कोणतेही बेट लागले नाही.", style: TextStyle(color: kTextGrey)));

                  return Column(
                    children: [
                      Container(
                        color: kPrimary.withOpacity(0.1),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text("User Name", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
                            Text("Total Play Amount", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: userTotals.keys.length,
                          itemBuilder: (context, index) {
                            String uId = userTotals.keys.elementAt(index);
                            int total = userTotals[uId]!;

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(uId).get(),
                              builder: (context, userSnap) {
                                String name = "Loading...";
                                if (userSnap.hasData && userSnap.data!.exists) {
                                  var uData = userSnap.data!.data() as Map<String, dynamic>;
                                  if (uData['createdBy'] != currentAdminId) return const SizedBox(); 
                                  name = uData['name'] ?? (uData['email'] as String?)?.split('@')[0] ?? "Unknown";
                                }
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(name, style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold)),
                                      Text("₹$total", style: const TextStyle(color: kSuccess, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: kCardBg,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Grand Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kTextMain)),
                            Text("₹$grandTotal", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kSuccess)),
                          ],
                        ),
                      )
                    ],
                  );
                },
              ),
            )
          else
            const Expanded(child: Center(child: Text("गेम निवडा (Select a Game)", style: TextStyle(color: kTextGrey)))),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// JAMA NAAVE / AGENT BALANCE RECEIPT
// -----------------------------------------------------------------------------
class JamaNaaveReceiptPage extends StatelessWidget {
  const JamaNaaveReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: kAdminBg,
      appBar: AppBar(
        title: const Text("AGENT BALANCE", style: TextStyle(color: kTextMain, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: kTextMain),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').where('createdBy', isEqualTo: currentAdminId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Data Found", style: TextStyle(color: kTextGrey)));
          }

          double yeneBalance = 0; 
          double deneBalance = 0; 

          List<Map<String, dynamic>> userList = [];
          
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            double bal = (data['balance'] ?? 0).toDouble();
            bool isAppr = data['approved'] == true;
            userList.add({
              'name': data['name'] ?? (data['email'] as String?)?.split('@')[0] ?? 'Unknown',
              'balance': bal,
              'status': isAppr ? 'Active' : 'Deactive',
            });

            if (bal > 0) yeneBalance += bal;
            if (bal < 0) deneBalance += bal;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: kCardBg,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Dene Balance", style: TextStyle(color: kTextGrey, fontWeight: FontWeight.bold)),
                            Text(deneBalance.toStringAsFixed(2), style: const TextStyle(color: kAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Yene Balance", style: TextStyle(color: kTextGrey, fontWeight: FontWeight.bold)),
                            Text(yeneBalance.toStringAsFixed(2), style: const TextStyle(color: kSuccess, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
                        icon: const Icon(Icons.print),
                        label: const Text("Print / Download Excel"),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloading File...")));
                        },
                      ),
                    )
                  ],
                ),
              ),
              
              Container(
                color: kPrimary.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: const [
                     SizedBox(width: 40, child: Text("Sr No", style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain))),
                     Expanded(flex: 2, child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain))),
                     Expanded(flex: 1, child: Text("Balance", style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain))),
                     Expanded(flex: 1, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain))),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  color: Colors.white,
                  child: ListView.separated(
                    itemCount: userList.length,
                    separatorBuilder: (_,__) => const Divider(height: 1, color: Colors.black12),
                    itemBuilder: (context, index) {
                      var u = userList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                             SizedBox(width: 40, child: Text("${index + 1}", style: const TextStyle(color: kTextGrey))),
                             Expanded(flex: 2, child: Text(u['name'], style: const TextStyle(color: kTextMain))),
                             Expanded(flex: 1, child: Text(u['balance'].toStringAsFixed(2), style: TextStyle(color: (u['balance'] as num) >= 0 ? kSuccess : kAccent, fontWeight: FontWeight.bold))),
                             Expanded(flex: 1, child: Text(u['status'], style: TextStyle(color: u['status'] == 'Active' ? kSuccess : kAccent))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DEDICATED PAYMENT PAGE 
// -----------------------------------------------------------------------------
class AgentPaymentPage extends StatefulWidget {
  const AgentPaymentPage({super.key});

  @override
  State<AgentPaymentPage> createState() => _AgentPaymentPageState();
}

class _AgentPaymentPageState extends State<AgentPaymentPage> {
  String _searchQuery = "";

  void _showAddFundsDialog(BuildContext context, String docId, int currentBalance, String userName) {
    final balCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Payment: $userName", style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("सध्याचा बॅलन्स (Current Balance): ₹$currentBalance", style: const TextStyle(color: kSuccess, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 15),
            TextField(
              controller: balCtrl, 
              keyboardType: const TextInputType.numberWithOptions(signed: true), 
              style: const TextStyle(color: kTextMain),
              decoration: const InputDecoration(
                labelText: "Amount (+ for add, - for deduct)", 
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: kTextGrey)
              )
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("रद्द करा (Cancel)", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
            onPressed: () {
              int val = int.tryParse(balCtrl.text) ?? 0;
              if (val != 0) {
                FirebaseFirestore.instance.collection('users').doc(docId).update({
                  'balance': FieldValue.increment(val)
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Updated Successfully!"), backgroundColor: Colors.green));
              }
              Navigator.pop(ctx);
            },
            child: const Text("अपडेट करा (Submit)")
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: kAdminBg,
      appBar: AppBar(
        title: const Text("Payment Management", style: TextStyle(color: kTextMain)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: kTextMain),
        elevation: 1,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: kTextMain),
              decoration: InputDecoration(
                hintText: "एजंट शोधा...",
                hintStyle: const TextStyle(color: kTextGrey),
                prefixIcon: const Icon(Icons.search, color: kTextGrey),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users')
                  .where('role', isEqualTo: 'user')
                  .where('createdBy', isEqualTo: currentAdminId) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No agents found", style: TextStyle(color: kTextGrey)));

                var docs = snapshot.data!.docs.where((doc) {
                   var data = doc.data() as Map<String, dynamic>;
                   String name = (data['name']?.toString() ?? '').toLowerCase();
                   return name.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String displayName = data['name']?.toString() ?? (data['email']?.toString().split('@')[0]) ?? 'Agent';
                    int balance = (data['balance'] as num?)?.toInt() ?? 0;

                    return Card(
                      color: kCardBg,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(displayName, style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text("Balance: ₹$balance", style: TextStyle(color: balance >= 0 ? kSuccess : kAccent, fontWeight: FontWeight.bold)),
                        trailing: ElevatedButton.icon(
                           style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                           icon: const Icon(Icons.payment, size: 16), 
                           label: const Text("Payment"), 
                           onPressed: () => _showAddFundsDialog(context, doc.id, balance, displayName)
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. AGENT LIST (Manage Users)
// -----------------------------------------------------------------------------
class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  String _searchQuery = "";

  void _showDeleteUserDialog(BuildContext context, String docId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Delete User?", style: TextStyle(color: kAccent, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to completely delete '$userName'? This cannot be undone.", style: const TextStyle(color: kTextMain)),
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

  @override
  Widget build(BuildContext context) {
    String currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("एजंट यादी (Agent List)", style: TextStyle(color: kTextMain, fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: kSuccess, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text("नवीन जोडा"),
                    onPressed: () => _showAgentDialog(context, currentAdminId, isEdit: false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                style: const TextStyle(color: kTextMain),
                decoration: InputDecoration(
                  hintText: "नाव किंवा मोबाईल नंबरने शोधा...",
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
                 String phone = (data['phone']?.toString() ?? '').toLowerCase();
                 return name.contains(_searchQuery) || email.contains(_searchQuery) || phone.contains(_searchQuery);
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var doc = docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  bool isActive = data['approved'] == true;
                  String displayName = data['name']?.toString() ?? (data['email']?.toString().split('@')[0]) ?? 'Agent';
                  String displayPhone = data['phone']?.toString() ?? '-';
                  int balance = (data['balance'] as num?)?.toInt() ?? 0;

                  return Card(
                    color: kCardBg,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayName, style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(displayPhone, style: const TextStyle(color: kTextGrey, fontSize: 13)),
                                ]
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("₹$balance", style: TextStyle(color: balance >= 0 ? kSuccess : kAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text(isActive ? "चालू (Active)" : "बंद (Deactive)", style: TextStyle(color: isActive ? kSuccess : kAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ]
                              )
                            ]
                          ),
                          const Divider(height: 24, color: Colors.black12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                               TextButton.icon(
                                 style: TextButton.styleFrom(foregroundColor: Colors.orange.shade700),
                                 icon: const Icon(Icons.edit, size: 18), 
                                 label: const Text("Edit"), 
                                 onPressed: () => _showAgentDialog(context, currentAdminId, isEdit: true, docId: doc.id, data: data)
                               ),
                               TextButton.icon(
                                 style: TextButton.styleFrom(foregroundColor: kAccent),
                                 icon: const Icon(Icons.delete, size: 18), 
                                 label: const Text("Delete"), 
                                 onPressed: () => _showDeleteUserDialog(context, doc.id, displayName)
                               ),
                               IconButton(
                                 icon: const Icon(Icons.receipt_long, color: kPrimary), 
                                 tooltip: "Ledger / Hishob",
                                 onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserLedgerScreen(userId: doc.id, userName: displayName)))
                               ),
                            ]
                          )
                        ],
                      ),
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

  void _showAgentDialog(BuildContext context, String currentAdminId, {required bool isEdit, String? docId, Map<String, dynamic>? data}) {
    Map<String, dynamic> safeData = data ?? {};
    
    final nameCtrl = TextEditingController(text: isEdit ? (safeData['name']?.toString() ?? "") : "");
    final phoneCtrl = TextEditingController(text: isEdit ? (safeData['phone']?.toString() ?? "") : "");
    final emailCtrl = TextEditingController(text: isEdit ? (safeData['email']?.toString() ?? "") : "");
    final passCtrl = TextEditingController(text: isEdit ? (safeData['password']?.toString() ?? "") : "");
    
    final limitCtrl = TextEditingController(text: isEdit ? (safeData['creditLimit']?.toString() ?? "100000") : "100000"); 
    final pRateCtrl = TextEditingController(text: isEdit ? (safeData['panelRate']?.toString() ?? "160") : "160"); 
    final jRateCtrl = TextEditingController(text: isEdit ? (safeData['jodiRate']?.toString() ?? "100") : "100"); 
    final commCtrl = TextEditingController(text: isEdit ? (safeData['commission']?.toString() ?? "10") : "10"); 

    bool isActive = isEdit ? (safeData['approved'] == true) : true;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setStateBuilder) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(isEdit ? "एजंट माहिती बदला (Edit Agent)" : "नवीन एजंट जोडा (New Agent)", style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, style: const TextStyle(color: kTextMain), decoration: const InputDecoration(labelText: "नाव (Name)", labelStyle: TextStyle(color: kTextGrey))),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: kTextMain), decoration: const InputDecoration(labelText: "मोबाईल नंबर", labelStyle: TextStyle(color: kTextGrey))),
                  
                  if(!isEdit)
                    TextField(controller: emailCtrl, style: const TextStyle(color: kTextMain), decoration: const InputDecoration(labelText: "ईमेल (Email) - Login ID", labelStyle: TextStyle(color: kTextGrey))),
                  
                  TextField(controller: passCtrl, style: const TextStyle(color: kTextMain), decoration: const InputDecoration(labelText: "पासवर्ड (Password)", labelStyle: TextStyle(color: kTextGrey))),
                  
                  const SizedBox(height: 20),
                  const Text("सेटिंग्ज आणि रेट्स (Settings & Rates)", style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(child: TextField(controller: limitCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: kTextMain), decoration: const InputDecoration(labelText: "लिमिट (Limit)", labelStyle: TextStyle(color: kTextGrey)))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: commCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: kTextMain), decoration: const InputDecoration(labelText: "कमिशन (%)", labelStyle: TextStyle(color: kTextGrey)))),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: pRateCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: kTextMain), decoration: const InputDecoration(labelText: "पॅनेल रेट (Panel)", labelStyle: TextStyle(color: kTextGrey)))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: jRateCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: kTextMain), decoration: const InputDecoration(labelText: "जोडी रेट (Jodi)", labelStyle: TextStyle(color: kTextGrey)))),
                    ],
                  ),
                  
                  if(isEdit) ...[
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: Text(isActive ? "चालू (Active)" : "बंद (Deactive)", style: TextStyle(color: isActive ? kSuccess : kAccent, fontWeight: FontWeight.bold)),
                      value: isActive,
                      activeColor: kSuccess,
                      onChanged: (val) => setStateBuilder(() => isActive = val),
                    )
                  ]
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("रद्द करा", style: TextStyle(color: kTextGrey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kSuccess, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);

                Map<String, dynamic> updateData = {
                  'name': nameCtrl.text,
                  'phone': phoneCtrl.text,
                  'password': passCtrl.text,
                  'creditLimit': int.tryParse(limitCtrl.text) ?? 100000,
                  'panelRate': int.tryParse(pRateCtrl.text) ?? 160,
                  'jodiRate': int.tryParse(jRateCtrl.text) ?? 100,
                  'commission': int.tryParse(commCtrl.text) ?? 10,
                  'approved': isActive,
                };

                if (isEdit) {
                   await FirebaseFirestore.instance.collection('users').doc(docId).update(updateData);
                   if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("अपडेट केले! (Updated)"), backgroundColor: Colors.green));
                } else {
                   await _registerUser(context, updateData, emailCtrl.text, passCtrl.text, currentAdminId);
                }
              }, 
              child: Text(isEdit ? "अपडेट करा" : "सेव्ह करा")
            )
          ],
        );
      }
    ));
  }

  Future<void> _registerUser(BuildContext context, Map<String, dynamic> dbData, String email, String password, String adminId) async {
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(name: 'tempUserCreate_${DateTime.now().millisecondsSinceEpoch}', options: Firebase.app().options);
      UserCredential cred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(email: email, password: password);
      
      dbData['email'] = email;
      dbData['role'] = 'user';
      dbData['balance'] = 0; 
      dbData['createdBy'] = adminId; 
      dbData['createdAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set(dbData);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("एजंट यशस्वीरित्या जोडला! (Created Successfully)"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("त्रुटी: $e"), backgroundColor: Colors.red));
    } finally {
      await tempApp?.delete();
    }
  }
}

// -----------------------------------------------------------------------------
// 4. ADMIN USER LEDGER 
// -----------------------------------------------------------------------------
class AdminUserLedgerScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminUserLedgerScreen({super.key, required this.userId, required this.userName});

  @override
  State<AdminUserLedgerScreen> createState() => _AdminUserLedgerScreenState();
}

class _AdminUserLedgerScreenState extends State<AdminUserLedgerScreen> {
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)), child: child!);
      },
    );
    if (picked != null && picked != _selectedDate) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAdminBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${widget.userName} चा हिशोब", style: const TextStyle(color: kTextMain, fontSize: 16)),
            if (_selectedDate != null)
              Text(DateFormat('dd MMM yyyy').format(_selectedDate!), style: const TextStyle(color: kPrimary, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: kTextMain),
        actions: [
          if (_selectedDate != null)
            IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() => _selectedDate = null)),
          IconButton(icon: const Icon(Icons.calendar_month, color: kPrimary), onPressed: _pickDate),
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
              if (!betSnap.hasData) return const Center(child: CircularProgressIndicator());
              var docs = betSnap.data!.docs;

              if (_selectedDate != null) {
                docs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  Timestamp? ts = data['timestamp'];
                  if (ts == null) return false;
                  DateTime dt = ts.toDate();
                  return dt.year == _selectedDate!.year && dt.month == _selectedDate!.month && dt.day == _selectedDate!.day;
                }).toList();
              }

              docs.sort((a,b) {
                var d1 = a.data() as Map<String, dynamic>;
                var d2 = b.data() as Map<String, dynamic>;
                Timestamp? t1 = d1['timestamp'];
                Timestamp? t2 = d2['timestamp'];
                return (t2 ?? Timestamp.now()).compareTo(t1 ?? Timestamp.now());
              });

              int totalDhanda = 0;
              int totalPayment = 0;
              for (var doc in docs) {
                var bet = doc.data() as Map<String, dynamic>;
                totalDhanda += (bet['amount'] as num? ?? 0).toInt();
                if (bet['status'] == 'won') totalPayment += (bet['potentialWin'] as num? ?? 0).toInt();
              }

              return Column(
                children: [
                  Container(
                    color: kCardBg,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: const [
                        Expanded(flex: 2, child: Padding(padding: EdgeInsets.only(left:16), child: Text("गेम (Game)", style: TextStyle(color: kTextGrey, fontWeight: FontWeight.bold)))),
                        Expanded(child: Center(child: Text("धंदा", style: TextStyle(color: kSuccess, fontWeight: FontWeight.bold)))),
                        Expanded(child: Center(child: Text("पेमेंट", style: TextStyle(color: kAccent, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      children: [
                        const Expanded(flex: 2, child: Padding(padding: EdgeInsets.only(left:16), child: Text("एकूण (TOTAL)", style: TextStyle(color: kTextMain, fontWeight: FontWeight.bold)))),
                        Expanded(child: Center(child: Text("$totalDhanda", style: const TextStyle(color: kSuccess, fontWeight: FontWeight.bold)))),
                        Expanded(child: Center(child: Text("$totalPayment", style: const TextStyle(color: kAccent, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.black12),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        var time = (data['timestamp'] as Timestamp?)?.toDate();
                        String timeStr = time != null ? DateFormat('dd MMM, hh:mm a').format(time) : '';

                        bool isWon = data['status'] == 'won';
                        bool isLoss = data['status'] == 'loss';

                        return Container(
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12)), color: Colors.white),
                          child: ListTile(
                            title: Text("${data['gameName']} (${data['session']}) - ${data['betType']}", style: const TextStyle(color: kTextMain, fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text("Time: $timeStr\nNo: ${data['number']}", style: const TextStyle(color: kTextGrey, fontSize: 12)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("₹${data['amount']}", style: const TextStyle(color: kSuccess, fontWeight: FontWeight.bold, fontSize: 14)),
                                Text((data['status'] ?? 'pending').toString().toUpperCase(), style: TextStyle(color: isWon ? kSuccess : (isLoss ? kAccent : Colors.orange), fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: kPurpleLedger,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("सध्याचा बॅलन्स (Current Balance)", style: TextStyle(color: Colors.white, fontSize: 14)),
                        Text("₹ $currentWallet", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5. MANUAL PANEL
// -----------------------------------------------------------------------------
class ManualPanelPage extends StatefulWidget {
  const ManualPanelPage({super.key});

  @override
  State<ManualPanelPage> createState() => _ManualPanelPageState();
}

class _ManualPanelPageState extends State<ManualPanelPage> {
  String? _selectedAgentId;
  String? _selectedGameId;
  String? _selectedGameName;
  final TextEditingController _reqCtrl = TextEditingController();
  bool _isLoading = false;

  DateTime _parseTime(String timeStr, DateTime now) {
    try {
      String clean = timeStr.trim().toUpperCase().replaceAll('.', ':').replaceAll(RegExp(r'\s+'), '');
      final RegExp regex = RegExp(r'(\d{1,2}):(\d{2})(AM|PM)?');
      final match = regex.firstMatch(clean);

      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String? period = match.group(3); 
        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
      final format = DateFormat.jm('en_US');
      DateTime dt = format.parseLoose(timeStr);
      return DateTime(now.year, now.month, now.day, dt.hour, dt.minute);
    } catch (e) {
      return now;
    }
  }

  List<Map<String, dynamic>> _parseBets(String text, String session, Map<String, dynamic> userRates) {
    List<Map<String, dynamic>> finalBets = [];
    List<String> lines = text.split('\n');
    int currentAmount = 0; 

    for (String line in lines) {
      line = line.trim().toLowerCase();
      if (line.isEmpty) continue;
      if (!line.contains(RegExp(r'\d'))) continue; 

      String? mode;
      if (line.contains('sp')) mode = 'sp';
      else if (line.contains('dp')) mode = 'dp';
      else if (line.contains('tp')) mode = 'tp';
      else if (line.contains('fm')) mode = 'fm'; 

      String clean = line.replaceAll(RegExp(r'[^0-9]'), ' ').trim();
      List<String> parts = clean.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

      if (parts.isEmpty) continue;

      if (parts.length == 1) {
        int number = int.tryParse(parts[0]) ?? -1;
        if (number >= 0 && currentAmount > 0) {
          _addParsedBet(finalBets, parts[0], currentAmount, mode, session, userRates);
        }
      } else if (parts.length >= 2) {
        int amount = int.tryParse(parts.last) ?? 0;
        if (amount > 0) {
          currentAmount = amount; 
          for (int i = 0; i < parts.length - 1; i++) {
            _addParsedBet(finalBets, parts[i], currentAmount, mode, session, userRates);
          }
        }
      }
    }
    return finalBets;
  }

  void _addParsedBet(List<Map<String, dynamic>> bets, String numStr, int amount, String? mode, String session, Map<String, dynamic> userRates) {
    int pRate = (userRates['panelRate'] as num?)?.toInt() ?? 160;
    int jRate = (userRates['jodiRate'] as num?)?.toInt() ?? 100;
    int singleRate = 10; 

    if (mode == 'fm') {
      if (numStr.length == 3 && int.tryParse(numStr) != null) {
        bets.addAll(_generateFamilyBets(numStr, amount, pRate));
      }
    } else if (mode != null) {
      int digit = int.tryParse(numStr) ?? -1;
      if (digit >= 0 && digit <= 9) {
        bets.addAll(_generatePannaBets(digit, mode, amount, pRate));
      }
    } else {
      if (RegExp(r'^\d+$').hasMatch(numStr)) {
        String processedNumStr = numStr;
        if (processedNumStr.length == 3) {
          List<String> chars = processedNumStr.split('');
          chars.sort(); 
          processedNumStr = chars.join('');
        }
        String type = _detectBetType(processedNumStr);
        
        if (type == 'Jodi Digit' && session == 'Close') return;

        if (type != 'Unknown') {
          int rateToUse = type == 'Jodi Digit' ? jRate : (type.contains('Panna') ? pRate : singleRate);
          bets.add({
            'number': processedNumStr, 
            'amount': amount,
            'betType': type,
            'rate': rateToUse
          });
        }
      }
    }
  }

  List<Map<String, dynamic>> _generateFamilyBets(String panna, int amount, int pRate) {
    Set<String> familyPannas = {};
    List<int> digits = panna.split('').map((e) => int.parse(e)).toList();
    List<int> cuts = digits.map((d) => (d + 5) % 10).toList();

    for (int i = 0; i < 8; i++) {
      int d1 = (i & 1) == 0 ? digits[0] : cuts[0];
      int d2 = (i & 2) == 0 ? digits[1] : cuts[1];
      int d3 = (i & 4) == 0 ? digits[2] : cuts[2];

      List<int> currentPanna = [d1, d2, d3];
      currentPanna.sort(); 
      familyPannas.add(currentPanna.join('')); 
    }

    return familyPannas.map((fp) {
      return {
        'number': fp,
        'amount': amount,
        'betType': _detectBetType(fp), 
        'rate': pRate 
      };
    }).toList();
  }

  List<Map<String, dynamic>> _generatePannaBets(int digit, String mode, int amount, int pRate) {
    List<String> pannas = [];
    String type = '';
    if (mode == 'sp') {
      type = 'Single Panna';
      for (int i=0; i<=9; i++) { for (int j=i+1; j<=9; j++) { for (int k=j+1; k<=9; k++) { if ((i+j+k)%10 == (digit==0?0:digit)) pannas.add("$i$j$k"); } } }
    } else if (mode == 'dp') {
      type = 'Double Panna';
      for (int i=0; i<=9; i++) { for (int j=0; j<=9; j++) { if (i == j) continue; if ((i+i+j)%10 == (digit==0?0:digit)) { List<int> sorted = [i, i, j]..sort(); String p = sorted.join(); if (!pannas.contains(p)) pannas.add(p); } } }
    } else if (mode == 'tp') {
      type = 'Triple Panna';
      pannas = ["$digit$digit$digit"]; 
    }
    return pannas.map((p) => {'number': p, 'amount': amount, 'betType': type, 'rate': pRate}).toList();
  }

  String _detectBetType(String number) {
    if (number.length == 1) return 'Single Digit';
    if (number.length == 2) return 'Jodi Digit';
    if (number.length == 3) {
      int uniqueDigits = number.split('').toSet().length;
      if (uniqueDigits == 3) return 'Single Panna'; 
      if (uniqueDigits == 2) return 'Double Panna'; 
      if (uniqueDigits == 1) return 'Triple Panna'; 
    }
    return 'Unknown';
  }

  Future<void> _submitManualRequest() async {
    if (_selectedAgentId == null || _selectedGameId == null || _reqCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("कृपया एजंट, गेम निवडा आणि रिक्वेस्ट टाका. (Select Agent & Game)"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      DocumentSnapshot gameSnap = await FirebaseFirestore.instance.collection('games').doc(_selectedGameId).get();
      if(!gameSnap.exists) throw Exception("Game not found!");
      var gameData = gameSnap.data() as Map<String, dynamic>;
      
      if (gameData['isClosed'] == true) {
         throw Exception("हा मार्केट सध्या बंद आहे! (Market is forcefully Closed)");
      }

      DateTime now = DateTime.now();
      DateTime openStart = _parseTime(gameData['openBetStart'] ?? '09:00 AM', now);
      DateTime openEnd = _parseTime(gameData['openBetEnd'] ?? '10:00 AM', now);
      DateTime closeStart = _parseTime(gameData['closeBetStart'] ?? '12:00 PM', now);
      DateTime closeEnd = _parseTime(gameData['closeBetEnd'] ?? '02:00 PM', now);

      String activeSession = 'Closed';
      if (now.isAfter(openStart) && now.isBefore(openEnd)) {
        activeSession = 'Open';
      } else if (now.isAfter(closeStart) && now.isBefore(closeEnd)) {
        activeSession = 'Close';
      }

      if (activeSession == 'Closed') {
         throw Exception("मार्केटची वेळ संपली आहे. बेट लावता येणार नाही! (Time is over for this market)");
      }

      DocumentSnapshot userSnapTemp = await FirebaseFirestore.instance.collection('users').doc(_selectedAgentId).get();
      if (!userSnapTemp.exists) throw Exception("Agent not found!");
      var userDataTemp = userSnapTemp.data() as Map<String, dynamic>;

      List<Map<String, dynamic>> parsedBets = _parseBets(_reqCtrl.text, activeSession, userDataTemp);
      if (parsedBets.isEmpty) {
        throw Exception("कोणतीही वैध बेट सापडली नाही. (No valid bets found)");
      }

      int totalAmount = parsedBets.fold(0, (sum, item) => sum + (item['amount'] as int));
      
      final userRef = FirebaseFirestore.instance.collection('users').doc(_selectedAgentId);
      final chatRef = userRef.collection('game_chats').doc();
      String newChatId = chatRef.id;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot userSnap = await transaction.get(userRef);
        var uData = userSnap.data() as Map<String, dynamic>;
        int currentBalance = (uData['balance'] as num?)?.toInt() ?? 0;
        int limit = (uData['creditLimit'] as num?)?.toInt() ?? 0;

        if (currentBalance - totalAmount < -limit) {
          throw Exception("एजंटची लिमिट संपली आहे! (Agent Credit Limit Exceeded)");
        }

        transaction.update(userRef, {'balance': currentBalance - totalAmount});

        for (var bet in parsedBets) {
          DocumentReference betRef = FirebaseFirestore.instance.collection('bets').doc();
          transaction.set(betRef, {
            'chatId': newChatId, 
            'userId': _selectedAgentId,
            'gameId': _selectedGameId,
            'gameName': _selectedGameName,
            'betType': bet['betType'],
            'session': activeSession, 
            'number': bet['number'],
            'amount': bet['amount'],
            'rate': bet['rate'],
            'potentialWin': (bet['amount'] as int) * (bet['rate'] as int),
            'status': 'pending',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        transaction.set(chatRef, {
          'chatId': newChatId,
          'gameId': _selectedGameId,
          'text': "Manual Entry by Admin:\n${_reqCtrl.text.trim()}",
          'total': totalAmount,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      _reqCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("रिक्वेस्ट यशस्वीरित्या सबमिट केली! (Submitted)"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: kAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("मॅन्युअल पॅनेल (Manual Panel)", style: TextStyle(color: kPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("येथून तुम्ही मॅन्युअल बेट लावू शकता.", style: TextStyle(color: kTextGrey, fontSize: 12)),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("एजंट निवडा (Agent Name)", style: TextStyle(color: kTextGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').where('createdBy', isEqualTo: currentAdminId).snapshots(),
                  builder: (context, snapshot) {
                    if(!snapshot.hasData) return const LinearProgressIndicator();
                    List<DropdownMenuItem<String>> items = [const DropdownMenuItem(value: null, child: Text("--एजंट निवडा--", style: TextStyle(color: kTextMain)))];
                    for(var doc in snapshot.data!.docs) {
                       var data = doc.data() as Map<String, dynamic>;
                       items.add(DropdownMenuItem(value: doc.id, child: Text(data['name']?.toString() ?? data['email']?.toString() ?? '', style: const TextStyle(color: kTextMain))));
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true, value: _selectedAgentId, items: items,
                          dropdownColor: Colors.white, // FIX: Light Dropdown
                          style: const TextStyle(color: kTextMain, fontSize: 16),
                          onChanged: (val) => setState(() => _selectedAgentId = val),
                        )
                      )
                    );
                  }
                ),
                
                const SizedBox(height: 16),
                
                const Text("गेम निवडा (Game Name)", style: TextStyle(color: kTextGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('games').orderBy('order').snapshots(),
                  builder: (context, snapshot) {
                    if(!snapshot.hasData) return const LinearProgressIndicator();
                    List<DropdownMenuItem<String>> items = [const DropdownMenuItem(value: null, child: Text("--गेम निवडा--", style: TextStyle(color: kTextMain)))];
                    for(var doc in snapshot.data!.docs) {
                       var data = doc.data() as Map<String, dynamic>;
                       items.add(DropdownMenuItem(value: doc.id, child: Text(data['name']?.toString() ?? '', style: const TextStyle(color: kTextMain))));
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true, value: _selectedGameId, items: items,
                          dropdownColor: Colors.white, // FIX: Light Dropdown
                          style: const TextStyle(color: kTextMain, fontSize: 16),
                          onChanged: (val) {
                            setState(() {
                              _selectedGameId = val;
                              if (val != null) {
                                var data = snapshot.data!.docs.firstWhere((d) => d.id == val).data() as Map<String, dynamic>;
                                _selectedGameName = data['name'];
                              }
                            });
                          },
                        )
                      )
                    );
                  }
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text("गेम रिक्वेस्ट (Game Request)", style: TextStyle(color: kTextGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    Icon(Icons.picture_as_pdf, size: 16, color: kAccent), 
                    Text(" PDF", style: TextStyle(fontSize: 12, color: kAccent, fontWeight: FontWeight.bold))
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reqCtrl,
                  maxLines: 10,
                  style: const TextStyle(color: kTextMain),
                  decoration: InputDecoration(
                    hintText: "येथे WhatsApp मेसेज पेस्ट करा...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: kSuccess, foregroundColor: Colors.white),
                      onPressed: _isLoading ? null : _submitManualRequest, 
                      child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text("सबमिट करा (Submit)")
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                      onPressed: () => _reqCtrl.clear(), 
                      child: const Text("पुसा (Clear)")
                    )
                  ],
                )
              ],
            ),
          ),

        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 6. GAME MANAGEMENT (Update Result & TIMINGS)
// -----------------------------------------------------------------------------
class GameManagementPage extends StatelessWidget {
  const GameManagementPage({super.key});

  void _showAddGameDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      title: const Text("नवीन मार्केट जोडा (New Market)", style: TextStyle(color: kTextMain)),
      content: TextField(
        controller: nameCtrl, 
        style: const TextStyle(color: kTextMain),
        decoration: const InputDecoration(labelText: "मार्केटचे नाव (उदा. KALYAN)", labelStyle: TextStyle(color: kTextGrey)),
      ),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(context), child: const Text("रद्द करा", style: TextStyle(color: kTextGrey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kSuccess, foregroundColor: Colors.white),
          onPressed: () {
            if (nameCtrl.text.isNotEmpty) {
              FirebaseFirestore.instance.collection('games').add({
                'name': nameCtrl.text.toUpperCase(),
                'openBetStart': "09:00 AM", 'openBetEnd': "11:00 AM",
                'closeBetStart': "12:00 PM", 'closeBetEnd': "02:00 PM",
                'openTime': "11:30 AM", 'closeTime': "02:30 PM",
                'result': '***-**-***', 'isClosed': false,
                'order': DateTime.now().millisecondsSinceEpoch,
              });
              Navigator.pop(context);
            }
          },
          child: const Text("तयार करा"),
        )
      ],
    ));
  }

  void _showUpdateResultDialog(BuildContext context, String docId, String gameName) {
    final resCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      title: Text("निकाल अपडेट करा: $gameName", style: const TextStyle(color: kTextMain)),
      content: TextField(controller: resCtrl, style: const TextStyle(color: kTextMain), decoration: const InputDecoration(hintText: "123-45-678", hintStyle: TextStyle(color: Colors.grey))),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("रद्द करा", style: TextStyle(color: kTextGrey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kSuccess, foregroundColor: Colors.white),
          onPressed: () {
             FirebaseFirestore.instance.collection('games').doc(docId).update({'result': resCtrl.text});
             Navigator.pop(ctx);
          }, 
          child: const Text("अपडेट करा")
        )
      ],
    ));
  }

  void _showEditTimingsSheet(BuildContext context, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditTimingsDialog(docId: docId, data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAdminBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGameDialog(context),
        label: const Text('नवीन मार्केट', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: kCardBg,
            child: const Text("गेम कॉन्फिगरेशन (Markets)", style: TextStyle(color: kTextMain, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('games').orderBy('order').snapshots(),
              builder: (context, snapshot) {
                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimary));
                 return ListView.separated(
                   itemCount: snapshot.data!.docs.length,
                   separatorBuilder: (_,__) => const Divider(height: 1, color: Colors.black12),
                   itemBuilder: (context, index) {
                     var doc = snapshot.data!.docs[index];
                     var data = doc.data() as Map<String, dynamic>;
                     bool isClosed = data['isClosed'] == true;

                     return ListTile(
                       tileColor: Colors.white,
                       title: Text(data['name'], style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold)),
                       subtitle: Text("निकाल: ${data['result'] ?? '***-**-***'}\nओपन: ${data['openTime']} | क्लोज: ${data['closeTime']}", style: const TextStyle(color: kTextGrey)),
                       trailing: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Switch(
                             value: !isClosed, 
                             activeColor: kSuccess,
                             onChanged: (val) {
                               FirebaseFirestore.instance.collection('games').doc(doc.id).update({'isClosed': !val});
                             }
                           ),
                           IconButton(
                             icon: const Icon(Icons.access_time, color: Colors.orange),
                             tooltip: 'वेळ सेट करा (Set Timings)',
                             onPressed: () => _showEditTimingsSheet(context, doc.id, data),
                           ),
                           IconButton(
                             icon: const Icon(Icons.edit_note, color: Colors.blue),
                             tooltip: 'निकाल अपडेट करा (Update Result)',
                             onPressed: () => _showUpdateResultDialog(context, doc.id, data['name']),
                           )
                         ],
                       ),
                     );
                   },
                 );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EDIT TIMINGS BOTTOM SHEET
// -----------------------------------------------------------------------------
class EditTimingsDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const EditTimingsDialog({super.key, required this.docId, required this.data});

  @override
  State<EditTimingsDialog> createState() => _EditTimingsDialogState();
}

class _EditTimingsDialogState extends State<EditTimingsDialog> {
  late Map<String, dynamic> localData;

  @override
  void initState() {
    super.initState();
    localData = Map.from(widget.data);
  }

  Future<void> _pickTime(String key, String current) async {
    TimeOfDay initial = TimeOfDay.now();
    try {
      String clean = current.trim().toUpperCase().replaceAll('.', ':');
      clean = clean.replaceAll('\u202F', ' ').replaceAll('\u00A0', ' ');
      if (!clean.contains(" ") && (clean.endsWith("AM") || clean.endsWith("PM"))) {
        clean = clean.replaceFirst("AM", " AM").replaceFirst("PM", " PM");
      }
      final format = DateFormat("hh:mm a", 'en_US'); 
      DateTime dt = format.parse(clean); 
      initial = TimeOfDay.fromDateTime(dt);
    } catch (e) {
      debugPrint("Parsing error for time: $e");
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: initial,
      builder: (context, child) {
        return Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)), child: child!);
      },
    );
    
    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      String formatted = DateFormat("hh:mm a", 'en_US').format(dt);
      formatted = formatted.replaceAll('\u202F', ' ').replaceAll('\u00A0', ' ');

      await FirebaseFirestore.instance.collection('games').doc(widget.docId).update({key: formatted});
      
      if (mounted) {
        setState(() {
          localData[key] = formatted;
        });
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("वेळ अपडेट केली! (Time Updated)"), backgroundColor: Colors.green, duration: Duration(seconds: 1))
        );
      }
    }
  }

  Widget _buildTimeRow(String label, String t1Label, String t1Key, String t2Label, String t2Key) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTimePicker(t1Label, localData[t1Key]?.toString(), t1Key)),
              const SizedBox(width: 12), 
              const Icon(Icons.arrow_forward, size: 16, color: kTextGrey),
              const SizedBox(width: 12), 
              Expanded(child: _buildTimePicker(t2Label, localData[t2Key]?.toString(), t2Key)),
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
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold)),
          _buildTimePicker("निवडा", localData[key]?.toString(), key),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label, String? currentVal, String dbKey) {
    return InkWell(
      onTap: () => _pickTime(dbKey, currentVal ?? "12:00 PM"),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade400)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 14, color: kTextGrey),
            const SizedBox(width: 6),
            Text(currentVal ?? "--:--", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextMain)),
          ],
        ),
      ),
    );
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
                Text("${localData['name']} - वेळ सेट करा", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextMain)),
                IconButton(icon: const Icon(Icons.close, color: kTextGrey), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text("बेट्टींग वेळ (BETTING SCHEDULE)", style: TextStyle(color: kTextGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildTimeRow("ओपन सेशन (Open Session)", "सुरुवात", "openBetStart", "शेवट", "openBetEnd"),
                _buildTimeRow("क्लोज सेशन (Close Session)", "सुरुवात", "closeBetStart", "शेवट", "closeBetEnd"),

                const SizedBox(height: 24),
                const Text("निकाल वेळ (RESULT DISPLAY TIME)", style: TextStyle(color: kTextGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildSingleTimeRow("ओपन निकाल वेळ", "openTime"),
                _buildSingleTimeRow("क्लोज निकाल वेळ", "closeTime"),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () => Navigator.pop(context), 
                    child: const Text("सेव्ह करा आणि बंद करा (Save & Close)"),
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
}