import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// --- NEW IMPORTS FOR PDF ---
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// --- THEME COLORS (Imported for independence) ---
const Color kPrimary = Color(0xFF2E3192); 
const Color kAccent = Color(0xFFD32F2F); 
const Color kTextMain = Color(0xFF1A1A1A); 
const Color kTextGrey = Color(0xFF5A5A5A); 

// -----------------------------------------------------------------------------
// NEW: ADMIN MARKET TAB (SABHI MARKETS KA SUMMARY)
// -----------------------------------------------------------------------------
class AdminMarketTab extends StatelessWidget {
  const AdminMarketTab({super.key});

  String _getHindiName(String englishName) {
    String upper = englishName.toUpperCase();
    if (upper.contains("KALYAN")) return "कल्याण";
    if (upper.contains("MAIN BAZAR")) return "मेन बाज़ार";
    if (upper.contains("TIME BAZAR")) return "टाइम बाज़ार";
    if (upper.contains("MILAN DAY")) return "मिलन डे";
    if (upper.contains("MILAN NIGHT")) return "मिलन नाइट";
    if (upper.contains("RAJDHANI DAY")) return "राजधानी डे";
    if (upper.contains("RAJDHANI NIGHT")) return "राजधानी नाइट";
    if (upper.contains("SRIDEVI")) return "श्रीदेवी";
    if (upper.contains("MADHUR")) return "मधुर";
    if (upper.contains("SUPREME")) return "सुप्रीम";
    if (upper.contains("MORNING")) return "मॉर्निंग";
    if (upper.contains("NIGHT")) return "नाइट";
    if (upper.contains("DAY")) return "डे";
    return ""; 
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          width: double.infinity,
          child: const Text(
            'हिशोब पाहण्यासाठी मार्केट निवडा', 
            textAlign: TextAlign.center,
            style: TextStyle(color: kPrimary, fontSize: 18, fontWeight: FontWeight.bold)
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('games').orderBy('order').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                 return const Center(child: Text('कोणतेही मार्केट उपलब्ध नाही', style: TextStyle(color: kTextGrey)));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String gameName = data['name'] ?? '';
                  String hindiName = _getHindiName(gameName);
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminGameLedgerScreen(gameId: doc.id, gameName: gameName)));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            gameName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF311B92), fontSize: 16, fontWeight: FontWeight.bold), 
                          ),
                          if (hindiName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              hindiName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 14, fontWeight: FontWeight.bold), 
                            ),
                          ]
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black12))
          ),
          child: ElevatedButton.icon(
            onPressed: () {
               // Navigate to a Day slip for all markets
               Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDaySlipScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            icon: const Icon(Icons.receipt_long),
            label: const Text('दिवसाची स्लिप पहा (Day Slip)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// NEW: ADMIN GAME LEDGER SCREEN (WITH USER FILTER & PDF)
// -----------------------------------------------------------------------------
class AdminGameLedgerScreen extends StatefulWidget {
  final String gameId;
  final String gameName;

  const AdminGameLedgerScreen({super.key, required this.gameId, required this.gameName});

  @override
  State<AdminGameLedgerScreen> createState() => _AdminGameLedgerScreenState();
}

class _AdminGameLedgerScreenState extends State<AdminGameLedgerScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedUserId;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimary, 
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
            ),
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

  // PDF Generation Function
  Future<void> _generateAndPrintPDF({
    required String agentName,
    required double openDhanda, required double closeDhanda, required double totalDhanda,
    required double openSinglePay, required double openPannaPay, required double jodiPay,
    required double closeSinglePay, required double closePannaPay, required double commission,
    required double totalPayment, required double totalJama, required double profit
  }) async {
    final pdf = pw.Document();

    pw.Widget buildPdfRow(String title, double value, {bool isBold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(title, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.Text(value.toStringAsFixed(2), style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ]
        )
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text("MARKET LEDGER", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text(widget.gameName, style: pw.TextStyle(fontSize: 20))),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Date: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}"),
                  pw.Text("Agent: $agentName"),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Collections (Dhanda)
              pw.Text("Total Collections (Dhanda)", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              buildPdfRow("Open Dhanda", openDhanda),
              buildPdfRow("Close Dhanda", closeDhanda),
              pw.SizedBox(height: 5),
              buildPdfRow("Total Dhanda", totalDhanda, isBold: true),
              pw.SizedBox(height: 20),

              // Payouts
              pw.Text("Total Payouts (Payment)", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              buildPdfRow("Open Single Pay", openSinglePay),
              buildPdfRow("Open Panna Pay", openPannaPay),
              buildPdfRow("Jodi Pay", jodiPay),
              buildPdfRow("Close Single Pay", closeSinglePay),
              buildPdfRow("Close Panna Pay", closePannaPay),
              buildPdfRow("Commission", commission),
              pw.SizedBox(height: 5),
              buildPdfRow("Total Jama", totalJama, isBold: true),
              pw.SizedBox(height: 20),
              pw.Divider(),

              // Profit/Loss
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                color: profit >= 0 ? PdfColors.green100 : PdfColors.red100,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Net Profit / Loss", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(profit.toStringAsFixed(2), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ]
                )
              )
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Market_Ledger_${widget.gameName}_${DateFormat('dd-MM-yyyy').format(_selectedDate)}.pdf',
    );
  }

  Widget _buildLedgerRow(String title, double amount, {double? betAmount, bool isBold = false, Color bgColor = Colors.transparent}) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: kTextMain, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          if (betAmount != null)
            Row(
              children: [
                Text(amount.toStringAsFixed(2), style: const TextStyle(fontSize: 14, color: kTextMain)),
                const SizedBox(width: 8),
                Text("= Rs.${betAmount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 14, color: kTextGrey)),
              ],
            )
          else
            Text(amount.toStringAsFixed(2), style: TextStyle(fontSize: 14, color: kTextMain, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(widget.gameName, style: const TextStyle(color: kPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              DateFormat('dd MMM yyyy').format(_selectedDate),
              style: const TextStyle(color: kPrimary, fontSize: 14)
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: kPrimary),
            onPressed: _pickDate,
          ),
        ],
      ),
      // User Fetch Stream
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users')
                  .where('role', isEqualTo: 'user')
                  .where('createdBy', isEqualTo: currentAdminId)
                  .snapshots(),
        builder: (context, userSnapshot) {
          Map<String, Map<String, dynamic>> agentDataMap = {};
          if (userSnapshot.hasData) {
            for (var doc in userSnapshot.data!.docs) {
              agentDataMap[doc.id] = doc.data() as Map<String, dynamic>;
            }
          }

          return Column(
            children: [
              // User Dropdown Filter
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedUserId,
                    hint: const Text("सर्व एजंट (All Agents)", style: TextStyle(color: kTextMain)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("सर्व एजंट (All Agents)", style: TextStyle(fontWeight: FontWeight.bold))),
                      ...agentDataMap.entries.map((e) {
                        String name = e.value['name'] ?? e.value['email']?.toString().split('@')[0] ?? 'Unknown';
                        return DropdownMenuItem(value: e.key, child: Text(name));
                      })
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedUserId = val;
                      });
                    },
                  ),
                ),
              ),

              // Bets Stream & Ledger Calculations
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bets')
                      .where('gameId', isEqualTo: widget.gameId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
                    
                    var docs = snapshot.data?.docs ?? [];
                    
                    // Filter by Date AND Selected User
                    docs = docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      Timestamp? ts = data['timestamp'];
                      if (ts == null) return false;
                      DateTime dt = ts.toDate();
                      bool dateMatch = dt.year == _selectedDate.year && dt.month == _selectedDate.month && dt.day == _selectedDate.day;
                      
                      bool userMatch = true;
                      if (_selectedUserId != null) {
                        userMatch = data['userId'] == _selectedUserId;
                      }

                      return dateMatch && userMatch;
                    }).toList();

                    double openDhanda = 0, closeDhanda = 0;
                    double openSinglePay = 0, openSingleBet = 0;
                    double openPannaPay = 0, openPannaBet = 0;
                    double closeSinglePay = 0, closeSingleBet = 0;
                    double closePannaPay = 0, closePannaBet = 0;
                    double jodiPay = 0, jodiBet = 0;

                    for (var doc in docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      double amount = (data['amount'] ?? 0).toDouble();
                      double winAmt = data['status'] == 'won' ? (data['potentialWin'] ?? 0).toDouble() : 0.0;
                      String type = data['betType'] ?? '';
                      String session = data['session'] ?? 'Open';

                      if (session == 'Open') {
                        openDhanda += amount;
                      } else {
                        closeDhanda += amount;
                      }

                      if (type.contains('Single Digit')) {
                        if (session == 'Open') { openSingleBet += amount; openSinglePay += winAmt; }
                        else { closeSingleBet += amount; closeSinglePay += winAmt; }
                      } else if (type.contains('Panna')) {
                        if (session == 'Open') { openPannaBet += amount; openPannaPay += winAmt; }
                        else { closePannaBet += amount; closePannaPay += winAmt; }
                      } else if (type.contains('Jodi')) {
                        jodiBet += amount; jodiPay += winAmt;
                      }
                    }

                    double totalDhanda = openDhanda + closeDhanda;
                    
                    // Commission Logic based on specific user vs all users
                    double commission = 0;
                    if (_selectedUserId != null && agentDataMap.containsKey(_selectedUserId)) {
                       double customComm = (agentDataMap[_selectedUserId]!['commission'] ?? 10).toDouble() / 100.0;
                       commission = totalDhanda * customComm;
                    } else {
                       commission = totalDhanda * 0.10; // Default 10% for All
                    }

                    double totalPayment = openSinglePay + openPannaPay + closeSinglePay + closePannaPay + jodiPay;
                    double totalJama = totalPayment + commission;
                    double profit = totalDhanda - totalJama; // Admin profit calculation

                    // Agent Name for PDF
                    String selectedAgentName = "All Agents";
                    if (_selectedUserId != null && agentDataMap.containsKey(_selectedUserId)) {
                        selectedAgentName = agentDataMap[_selectedUserId]!['name'] ?? 'Unknown';
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 16, top: 10, bottom: 10),
                            child: Text("धंदा (Total Collections)", style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          _buildLedgerRow("ओपन धंदा", openDhanda),
                          _buildLedgerRow("क्लोज धंदा", closeDhanda),
                          _buildLedgerRow("फेर अमाउंट", 0.00),
                          _buildLedgerRow("टोटल नावे", totalDhanda, bgColor: Colors.grey.shade200, isBold: true),

                          const Padding(
                            padding: EdgeInsets.only(left: 16, top: 20, bottom: 10),
                            child: Text("पेमेंट (Total Payouts)", style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          _buildLedgerRow("ओपन सिंगल", openSinglePay, betAmount: openSingleBet),
                          _buildLedgerRow("ओपन पाना", openPannaPay, betAmount: openPannaBet),
                          _buildLedgerRow("जोड", jodiPay, betAmount: jodiBet),
                          _buildLedgerRow("क्लोज सिंगल", closeSinglePay, betAmount: closeSingleBet),
                          _buildLedgerRow("क्लोज पाना", closePannaPay, betAmount: closePannaBet),
                          _buildLedgerRow("कमिशन (${_selectedUserId != null ? (agentDataMap[_selectedUserId]?['commission'] ?? 10) : 10}%)", commission),
                          _buildLedgerRow("फेर अमाउंट", 0.00),
                          _buildLedgerRow("टोटल जमा", totalJama, bgColor: Colors.grey.shade200, isBold: true),

                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: profit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("नफा / तोटा (Net Profit/Loss)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: profit >= 0 ? Colors.green : Colors.red)),
                                Text(profit.toStringAsFixed(2), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: profit >= 0 ? Colors.green : Colors.red)),
                              ],
                            ),
                          ),
                          
                          // NEW: PDF DOWNLOAD BUTTON
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                ),
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text("Download Ledger (PDF)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                onPressed: () {
                                  _generateAndPrintPDF(
                                    agentName: selectedAgentName,
                                    openDhanda: openDhanda, closeDhanda: closeDhanda, totalDhanda: totalDhanda,
                                    openSinglePay: openSinglePay, openPannaPay: openPannaPay, jodiPay: jodiPay,
                                    closeSinglePay: closeSinglePay, closePannaPay: closePannaPay, commission: commission,
                                    totalPayment: totalPayment, totalJama: totalJama, profit: profit
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
class AdminDaySlipScreen extends StatefulWidget {
  const AdminDaySlipScreen({super.key});

  @override
  State<AdminDaySlipScreen> createState() => _AdminDaySlipScreenState();
}

class _AdminDaySlipScreenState extends State<AdminDaySlipScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimary, 
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
            ),
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

  Widget _buildCalcRow(String title, double? val1, double? val2, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(title, style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
          if (val1 != null) Expanded(flex: 1, child: Text(val1.toStringAsFixed(2), textAlign: TextAlign.right, style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
          if (val2 != null) Expanded(flex: 1, child: Text(val2.toStringAsFixed(2), textAlign: TextAlign.right, style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)))
          else Expanded(flex: 1, child: const SizedBox()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('सर्व मार्केट हिशोब (All Markets Day Slip)', style: TextStyle(color: Colors.black, fontSize: 16)),
            Text(DateFormat('dd-MM-yyyy').format(_selectedDate), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: kPrimary),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bets').snapshots(), // Fetching all bets, but filtering below
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
          
          var docs = snapshot.data!.docs;

          final todayDocs = docs.where((doc) {
             var data = doc.data() as Map<String, dynamic>;
             Timestamp? ts = data['timestamp'];
             if (ts == null) return false;
             DateTime dt = ts.toDate();
             return dt.year == _selectedDate.year && dt.month == _selectedDate.month && dt.day == _selectedDate.day;
          }).toList();

          if (todayDocs.isEmpty) {
            return const Center(child: Text("कोणताही डेटा सापडला नाही (No data found)", style: TextStyle(color: Colors.black54, fontSize: 16)));
          }

          Map<String, Map<String, double>> gameStats = {};

          for (var doc in todayDocs) {
            var data = doc.data() as Map<String, dynamic>;
            String game = data['gameName'] ?? 'Unknown';
            double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            double payment = 0.0;

            if (data['status'] == 'won') {
              payment = (data['potentialWin'] as num?)?.toDouble() ?? 0.0;
            }

            if (!gameStats.containsKey(game)) {
              gameStats[game] = {'dhanda': 0.0, 'payment': 0.0};
            }
            gameStats[game]!['dhanda'] = gameStats[game]!['dhanda']! + amount;
            gameStats[game]!['payment'] = gameStats[game]!['payment']! + payment;
          }

          double totalDhanda = 0;
          double totalPayment = 0;

          gameStats.forEach((key, value) {
            totalDhanda += value['dhanda']!;
            totalPayment += value['payment']!;
          });

          double commission = totalDhanda * 0.10; 
          double netDhanda = totalDhanda - commission;
          double profit = netDhanda - totalPayment; 

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text('OFFICIAL SUMMARY', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black))),
                const Divider(color: Colors.black),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Date: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}", style: const TextStyle(color: Colors.black)),
                  ],
                ),
                const Divider(color: Colors.black),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(flex: 2, child: Text('Game', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15))),
                    Expanded(flex: 1, child: Text('Dhanda', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15))),
                    Expanded(flex: 1, child: Text('Payment', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15))),
                  ],
                ),
                const Divider(color: Colors.black),

                ...gameStats.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 2, child: Text(e.key, style: const TextStyle(color: Colors.black, fontSize: 14))),
                        Expanded(flex: 1, child: Text(e.value['dhanda']!.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text(e.value['payment']!.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  );
                }).toList(),

                const Divider(color: Colors.black),

                _buildCalcRow('Total', totalDhanda, totalPayment, isBold: true),
                _buildCalcRow('कमिशन (10%)', commission, null),
                _buildCalcRow('Net Total', netDhanda, totalPayment, isBold: true),

                const SizedBox(height: 10),

                Container(
                  color: profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Profit/Loss', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(profit.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}