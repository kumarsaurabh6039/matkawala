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
            stream: FirebaseFirestore.instance.collection('game_settings')
                .where('adminId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                .snapshots(),
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
                  String gameName = data['gameName'] ?? data['name'] ?? '';
                  String hindiName = _getHindiName(gameName);
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminGameLedgerScreen(gameId: data['gameId'] ?? doc.id, gameName: gameName)));
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
                       commission = totalDhanda * 0.10; 
                    }

                    double totalPayment = openSinglePay + openPannaPay + closeSinglePay + closePannaPay + jodiPay;
                    double totalJama = totalPayment + commission;
                    double profit = totalDhanda - totalJama; 
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
  String? _selectedUserId;   // null = All Agents
  String? _selectedUserName; // display label

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: kPrimary,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildCalcRow(String title, double? val1, double? val2, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(title,
                style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          ),
          Expanded(
            flex: 1,
            child: Text(
              val1 != null ? val1.toStringAsFixed(2) : '',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              val2 != null ? val2.toStringAsFixed(2) : '',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  // ── PDF generate & print ──────────────────────────────────────────────────
  Future<void> _printPdf({
    required String filterLabel,
    required Map<String, Map<String, double>> gameStats,
    required double totalDhanda,
    required double totalPayment,
    required double totalCommission,
    required double netDhanda,
    required double profit,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          final rows = gameStats.entries
              .map((e) => [e.key, e.value['dhanda']!.toStringAsFixed(2), e.value['payment']!.toStringAsFixed(2)])
              .toList();

          pw.Widget pRow(String label, String v1, String v2, {bool bold = false}) {
            final s = pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(children: [
                pw.Expanded(flex: 3, child: pw.Text(label, style: s)),
                pw.Expanded(flex: 2, child: pw.Text(v1, textAlign: pw.TextAlign.right, style: s.copyWith(color: PdfColors.green800))),
                pw.Expanded(flex: 2, child: pw.Text(v2, textAlign: pw.TextAlign.right, style: s.copyWith(color: PdfColors.red800))),
              ]),
            );
          }

          return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Center(child: pw.Text('OFFICIAL SUMMARY', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
            pw.Divider(),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Agent: $filterLabel', style: const pw.TextStyle(fontSize: 11)),
            ]),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Game', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Dhanda', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Payment', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11))),
                  ],
                ),
                ...rows.asMap().entries.map((entry) => pw.TableRow(
                  decoration: pw.BoxDecoration(color: entry.key % 2 == 0 ? PdfColors.white : PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(entry.value[0], style: const pw.TextStyle(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(entry.value[1], textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10, color: PdfColors.green800))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(entry.value[2], textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10, color: PdfColors.red800))),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pRow('Total', totalDhanda.toStringAsFixed(2), totalPayment.toStringAsFixed(2), bold: true),
            pRow('Commission', totalCommission.toStringAsFixed(2), ''),
            pRow('Net Total', netDhanda.toStringAsFixed(2), totalPayment.toStringAsFixed(2), bold: true),
            pw.SizedBox(height: 10),
            pw.Container(
              color: profit >= 0 ? PdfColors.green700 : PdfColors.red700,
              padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Total Profit/Loss', style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text(profit.toStringAsFixed(2), style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold)),
              ]),
            ),
            pw.Spacer(),
            pw.Center(child: pw.Text('* Generated by MATKAWALA Admin Panel *', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
          ]);
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'DaySlip_${filterLabel.replaceAll(' ', '_')}_${DateFormat('dd-MM-yyyy').format(_selectedDate)}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final String adminId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('सर्व मार्केट हिशोब (All Markets Day Slip)',
                style: TextStyle(color: Colors.black, fontSize: 16)),
            Text(DateFormat('dd-MM-yyyy').format(_selectedDate),
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

      // ── Layer 1: Fetch admin's agents (for filter dropdown + commission map) ──
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('createdBy', isEqualTo: adminId)
            .snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator(color: kPrimary));
          }

          // Build name + commission maps for this admin's agents
          final Map<String, double> userCommMap = {}; // userId → rate (fraction)
          final Map<String, String> userNameMap = {}; // userId → display name

          for (var doc in userSnap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            userCommMap[doc.id] =
                (double.tryParse(d['commission']?.toString() ?? '') ?? 0.0) / 100.0;
            String nm = d['name']?.toString() ?? '';
            if (nm.isEmpty) {
              nm = (d['email']?.toString() ?? '').replaceAll('@matkawala.com', '');
            }
            userNameMap[doc.id] = nm.isEmpty ? 'Agent' : nm;
          }

          final agentEntries = userNameMap.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));

          // ── Agent Filter Bar ─────────────────────────────────────────────
          final filterBar = Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              border: Border(
                bottom: BorderSide(color: kPrimary.withOpacity(0.2), width: 1.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'एजंट निवडा (Select Agent)',
                  style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_pin, color: kPrimary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: _selectedUserId != null ? kPrimary : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: _selectedUserId,
                            style: const TextStyle(color: kTextMain, fontSize: 14, fontWeight: FontWeight.w600),
                            dropdownColor: Colors.white,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _selectedUserId != null ? kPrimary : Colors.grey,
                              size: 22,
                            ),
                            items: [
                              // All agents option
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('🧑‍💼  सर्व एजंट (All Agents)',
                                    style: TextStyle(color: kTextGrey, fontSize: 14)),
                              ),
                              // Individual agent options
                              ...agentEntries.map((e) => DropdownMenuItem<String?>(
                                    value: e.key,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: kPrimary,
                                          child: Text(
                                            e.value.isNotEmpty ? e.value[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(e.value,
                                              style: const TextStyle(
                                                  color: kTextMain,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                            onChanged: (val) => setState(() {
                              _selectedUserId = val;
                              _selectedUserName = val == null ? null : userNameMap[val];
                            }),
                          ),
                        ),
                      ),
                    ),
                    // Clear filter button
                    if (_selectedUserId != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() {
                          _selectedUserId = null;
                          _selectedUserName = null;
                        }),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kAccent.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: kAccent),
                        ),
                      ),
                    ],
                  ],
                ),
                // Active filter badge
                if (_selectedUserId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt, size: 14, color: kPrimary),
                        const SizedBox(width: 4),
                        Text(
                          'Filter Active: ${userNameMap[_selectedUserId] ?? "Agent"}',
                          style: const TextStyle(
                              color: kPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );

          // ── Layer 2: Fetch bets ─────────────────────────────────────────────
          return Column(
            children: [
              filterBar,
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bets').snapshots(),
                  builder: (context, betSnap) {
                    if (betSnap.hasError) {
                      return Center(
                          child: Text("Error: ${betSnap.error}",
                              style: const TextStyle(color: Colors.red)));
                    }
                    if (!betSnap.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.black));
                    }

                    // Filter: date + admin's agents only + optional agent filter
                    final todayDocs = betSnap.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final Timestamp? ts = data['timestamp'];
                      if (ts == null) return false;
                      final dt = ts.toDate();
                      // Date check
                      if (dt.year != _selectedDate.year ||
                          dt.month != _selectedDate.month ||
                          dt.day != _selectedDate.day) return false;
                      final String uid = data['userId']?.toString() ?? '';
                      // Only this admin's agents
                      if (!userCommMap.containsKey(uid)) return false;
                      // Agent-level filter
                      if (_selectedUserId != null && uid != _selectedUserId) return false;
                      return true;
                    }).toList();

                    if (todayDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              _selectedUserId != null
                                  ? '${userNameMap[_selectedUserId]} साठी ${DateFormat('dd MMM yyyy').format(_selectedDate)} रोजी कोणताही डेटा नाही'
                                  : '${DateFormat('dd MMM yyyy').format(_selectedDate)} रोजी कोणताही डेटा नाही',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    }

                    // Aggregate game stats + dynamic commission
                    final Map<String, Map<String, double>> gameStats = {};
                    double totalCommission = 0.0;

                    for (var doc in todayDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String game = data['gameName'] ?? 'Unknown';
                      final String uId = data['userId']?.toString() ?? '';
                      final double amount =
                          double.tryParse(data['amount']?.toString() ?? '') ?? 0.0;
                      double payment = 0.0;
                      if (data['status'] == 'won') {
                        payment =
                            double.tryParse(data['potentialWin']?.toString() ?? '') ?? 0.0;
                      }
                      gameStats.putIfAbsent(game, () => {'dhanda': 0.0, 'payment': 0.0});
                      gameStats[game]!['dhanda'] = gameStats[game]!['dhanda']! + amount;
                      gameStats[game]!['payment'] = gameStats[game]!['payment']! + payment;
                      // Dynamic per-agent commission
                      totalCommission += amount * (userCommMap[uId] ?? 0.0);
                    }

                    double totalDhanda = 0, totalPayment = 0;
                    gameStats.forEach((_, v) {
                      totalDhanda += v['dhanda']!;
                      totalPayment += v['payment']!;
                    });
                    final double netDhanda = totalDhanda - totalCommission;
                    final double profit = netDhanda - totalPayment;

                    // Commission label — per-agent % if filtered, else "Dynamic"
                    final String commLabel = _selectedUserId == null
                        ? 'कमिशन (Dynamic)'
                        : 'कमिशन (${((userCommMap[_selectedUserId] ?? 0) * 100).toStringAsFixed(0)}%)';

                    final String filterLabel = _selectedUserId == null
                        ? 'All Agents'
                        : (userNameMap[_selectedUserId] ?? 'Agent');

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text('OFFICIAL SUMMARY',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                          ),
                          const Divider(color: Colors.black),

                          // Date + agent name row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Date: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}',
                                  style: const TextStyle(color: Colors.black)),
                              if (_selectedUserId != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: kPrimary.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    '👤 $filterLabel',
                                    style: const TextStyle(
                                        color: kPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(color: Colors.black),
                          const SizedBox(height: 10),

                          // Column headers
                          const Row(children: [
                            Expanded(
                                flex: 2,
                                child: Text('Game',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 15))),
                            Expanded(
                                flex: 1,
                                child: Text('Dhanda',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 15))),
                            Expanded(
                                flex: 1,
                                child: Text('Payment',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                        fontSize: 15))),
                          ]),
                          const Divider(color: Colors.black),

                          // Game rows
                          ...gameStats.entries.map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text(e.key,
                                          style: const TextStyle(
                                              color: Colors.black, fontSize: 14))),
                                  Expanded(
                                      flex: 1,
                                      child: Text(
                                          e.value['dhanda']!.toStringAsFixed(2),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 1,
                                      child: Text(
                                          e.value['payment']!.toStringAsFixed(2),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold))),
                                ]),
                              )),

                          const Divider(color: Colors.black),
                          _buildCalcRow('Total', totalDhanda, totalPayment, isBold: true),
                          _buildCalcRow(commLabel, totalCommission, null),
                          _buildCalcRow('Net Total', netDhanda, totalPayment, isBold: true),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            color: profit >= 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Profit/Loss',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Text(profit.toStringAsFixed(2),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // PDF button
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _printPdf(
                                filterLabel: filterLabel,
                                gameStats: gameStats,
                                totalDhanda: totalDhanda,
                                totalPayment: totalPayment,
                                totalCommission: totalCommission,
                                netDhanda: netDhanda,
                                profit: profit,
                              ),
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                              label: const Text('PDF Print / Download',
                                  style: TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kAccent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
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
        },
      ),
    );
  }
}