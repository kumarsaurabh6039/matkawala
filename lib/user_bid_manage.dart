import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- THEME COLORS (Matched with Admin Dashboard) ---
const Color kAdminBg = Color(0xFFF4F6F8);
const Color kCardBg = Colors.white;
const Color kPrimary = Color(0xFF2E3192);
const Color kAccent = Color(0xFFD32F2F);
const Color kTextMain = Color(0xFF1A1A1A);
const Color kTextGrey = Color(0xFF5A5A5A);
const Color kSuccess = Color(0xFF00897B);

class UserBidManagePage extends StatefulWidget {
  final String currentAdminId; // Pass admin ID for filtering their network only. Pass empty string for SuperAdmin (Global)

  const UserBidManagePage({super.key, required this.currentAdminId});

  @override
  State<UserBidManagePage> createState() => _UserBidManagePageState();
}

class _UserBidManagePageState extends State<UserBidManagePage> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedGameId;
  String _statusFilter = 'All'; // All, pending, won, loss
  String _searchQuery = "";

  Map<String, String> _agentNamesCache = {};
  bool _isLoadingAgents = true;

  @override
  void initState() {
    super.initState();
    _fetchAgentNames();
  }

  Future<void> _fetchAgentNames() async {
    try {
      Query query = FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user');
      
      // If it's an admin (not superadmin), only fetch their agents
      if (widget.currentAdminId.isNotEmpty) {
        query = query.where('createdBy', isEqualTo: widget.currentAdminId);
      }

      var snap = await query.get();
      Map<String, String> cache = {};
      for (var doc in snap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        cache[doc.id] = data['name'] ?? (data['email'] as String?)?.split('@')[0] ?? 'Unknown Agent';
      }
      if (mounted) {
        setState(() {
          _agentNamesCache = cache;
          _isLoadingAgents = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching agents: $e");
      if (mounted) setState(() => _isLoadingAgents = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: kPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _deleteBid(String bidId, int amount, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("बिड रद्द करा (Delete Bid)?", style: TextStyle(color: kAccent, fontWeight: FontWeight.bold)),
        content: const Text("तुम्ही ही बिड डिलीट करू इच्छिता? युजरची लिमिट परत जोडली जाईल. (Amount will be refunded to user limit).", style: TextStyle(color: kTextMain)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("रद्द करा", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Run transaction to delete bet and refund limit
                await FirebaseFirestore.instance.runTransaction((transaction) async {
                  DocumentReference betRef = FirebaseFirestore.instance.collection('bets').doc(bidId);
                  DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);
                  
                  DocumentSnapshot userSnap = await transaction.get(userRef);
                  if (userSnap.exists) {
                    var uData = userSnap.data() as Map<String, dynamic>;
                    int currentLimit = int.tryParse(uData['limit']?.toString() ?? '') ?? int.tryParse(uData['balance']?.toString() ?? '') ?? 0;
                    transaction.update(userRef, {'limit': currentLimit + amount});
                  }
                  
                  transaction.delete(betRef);
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("बिड यशस्वीरित्या रद्द केली! (Bid Deleted)"), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("डिलीट करा")
          )
        ],
      )
    );
  }

  // --- FULL CHART DIALOG (WhatsApp Style) ---
  void _showFullChart(BuildContext context, String userId, String chatId) {
    // First fetch the chat to get gameId
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).collection('game_chats').doc(chatId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              backgroundColor: Color(0xFF0B141A),
              content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.amber))),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0B141A),
              title: const Text("Error", style: TextStyle(color: Colors.white)),
              content: const Text("चार्ट उपलब्ध नाही (Chart not found)", style: TextStyle(color: Colors.white70)),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Colors.amber)))],
            );
          }
          
          var chatData = snapshot.data!.data() as Map<String, dynamic>;
          String text = chatData['text'] ?? '';
          int total = int.tryParse(chatData['total']?.toString() ?? '') ?? 0;
          String gameId = chatData['gameId'] ?? '';
          var time = (chatData['timestamp'] as Timestamp?)?.toDate();
          String timeStr = time != null ? DateFormat('dd MMM yyyy, hh:mm a').format(time) : '';
          DateTime chatDate = time ?? DateTime.now();

          return Dialog(
            backgroundColor: const Color(0xFF0B141A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F2C34),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("मूळ चार्ट (Original Chart)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(timeStr, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  // Original bid text
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF005D4B), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📋 Original Bid Text:", style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 8),
                        const Divider(color: Colors.white24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total: ₹$total", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                            Text(timeStr, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // All bets for this game on this date
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart, color: Colors.amber, size: 14),
                        SizedBox(width: 6),
                        Text("सर्व बेट्स - या तारखेसाठी (All Bets This Date):", style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (gameId.isNotEmpty)
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('bets')
                          .where('chatId', isEqualTo: chatId)
                          .get(),
                      builder: (context, betSnap) {
                        if (betSnap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(color: Colors.amber),
                          );
                        }
                        if (!betSnap.hasData || betSnap.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text("No bet details found", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          );
                        }
                        var bets = betSnap.data!.docs;
                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: const Color(0xFF1F2C34), borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              children: [
                                // Header row
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: const BoxDecoration(color: Color(0xFF2A3942), borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
                                  child: const Row(
                                    children: [
                                      Expanded(flex: 2, child: Text("Number", style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold))),
                                      Expanded(flex: 2, child: Text("Type", style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold))),
                                      Expanded(child: Text("₹ Amt", style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold))),
                                      Expanded(child: Text("Status", style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: bets.length,
                                    itemBuilder: (ctx, i) {
                                      var bd = bets[i].data() as Map<String, dynamic>;
                                      String statusStr = bd['status'] ?? 'pending';
                                      Color statusColor = statusStr == 'won' ? Colors.green : (statusStr == 'loss' ? Colors.red : Colors.orange);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
                                        child: Row(
                                          children: [
                                            Expanded(flex: 2, child: Text(bd['number']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                                            Expanded(flex: 2, child: Text(bd['betType']?.toString() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 10))),
                                            Expanded(child: Text("₹${bd['amount']}", style: const TextStyle(color: Colors.greenAccent, fontSize: 12))),
                                            Expanded(child: Text(statusStr.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold))),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx), 
                    child: const Text("बंद करा (Close)", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'won':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = "WON";
        break;
      case 'loss':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = "LOSS";
        break;
      case 'pending':
      default:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        label = "PENDING";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAdminBg,
      appBar: AppBar(
        title: const Text("सर्व युजर बिड्स (User Bets)", style: TextStyle(color: kTextMain, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: kTextMain),
        elevation: 1,
      ),
      body: Column(
        children: [
          // --- FILTER SECTION ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Date Picker
                    Expanded(
                      flex: 4,
                      child: InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(color: kTextMain, fontSize: 13, fontWeight: FontWeight.bold)),
                              const Icon(Icons.calendar_month, color: kPrimary, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Status Filter
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _statusFilter,
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text("सर्व (All)", style: TextStyle(color: kTextMain, fontSize: 13))),
                              DropdownMenuItem(value: 'pending', child: Text("Pending", style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: 'won', child: Text("Won", style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: 'loss', child: Text("Loss", style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold))),
                            ],
                            onChanged: (val) => setState(() => _statusFilter = val!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    // Game Filter
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('games').orderBy('order').snapshots(),
                        builder: (context, snapshot) {
                          List<DropdownMenuItem<String>> items = [const DropdownMenuItem(value: null, child: Text("--सर्व गेम (All Games)--", style: TextStyle(color: kTextGrey, fontSize: 13)))];
                          if (snapshot.hasData) {
                            for(var doc in snapshot.data!.docs) {
                              var data = doc.data() as Map<String, dynamic>;
                              items.add(DropdownMenuItem(value: doc.id, child: Text(data['name'] ?? '', style: const TextStyle(color: kTextMain, fontSize: 13, fontWeight: FontWeight.bold))));
                            }
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true, 
                                value: _selectedGameId, 
                                items: items,
                                dropdownColor: Colors.white, 
                                onChanged: (val) => setState(() => _selectedGameId = val),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Search Bar
                SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    style: const TextStyle(fontSize: 13, color: kTextMain),
                    decoration: InputDecoration(
                      hintText: "एजंटचे नाव किंवा नंबर (उदा. 143) शोधा...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- BID LIST / CHART ---
          Expanded(
            child: _isLoadingAgents 
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bets').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("कोणतीही बिड सापडली नाही. (No Bids Found)", style: TextStyle(color: kTextGrey)));

                    var docs = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      
                      // 1. Filter by Admin's Network
                      String uId = data['userId'] ?? '';
                      if (widget.currentAdminId.isNotEmpty && !_agentNamesCache.containsKey(uId)) {
                        return false; 
                      }

                      // 2. Filter by Date
                      Timestamp? ts = data['timestamp'];
                      if (ts == null) return false;
                      DateTime dt = ts.toDate();
                      if (dt.year != _selectedDate.year || dt.month != _selectedDate.month || dt.day != _selectedDate.day) {
                        return false;
                      }

                      // 3. Filter by Game
                      if (_selectedGameId != null && data['gameId'] != _selectedGameId) return false;

                      // 4. Filter by Status
                      String status = data['status'] ?? 'pending';
                      if (_statusFilter != 'All' && status.toLowerCase() != _statusFilter.toLowerCase()) return false;

                      // 5. Search by Agent Name or Number
                      String agentName = (_agentNamesCache[uId] ?? '').toLowerCase();
                      String number = data['number']?.toString() ?? '';
                      if (_searchQuery.isNotEmpty) {
                        if (!agentName.contains(_searchQuery) && !number.contains(_searchQuery)) {
                          return false;
                        }
                      }

                      return true;
                    }).toList();

                    // Sort by newest first
                    docs.sort((a, b) {
                      Timestamp? t1 = (a.data() as Map)['timestamp'];
                      Timestamp? t2 = (b.data() as Map)['timestamp'];
                      return (t2 ?? Timestamp.now()).compareTo(t1 ?? Timestamp.now());
                    });

                    if (docs.isEmpty) {
                      return const Center(child: Text("या फिल्टरसाठी कोणतीही बिड नाही. (No Bids matching filters)", style: TextStyle(color: kTextGrey)));
                    }

                    // Group bets by userId
                    Map<String, List<QueryDocumentSnapshot>> groupedByUser = {};
                    int totalAmount = 0;
                    for (var doc in docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      String uId = data['userId'] ?? 'unknown';
                      groupedByUser.putIfAbsent(uId, () => []).add(doc);
                      totalAmount += int.tryParse(data['amount']?.toString() ?? '') ?? 0;
                    }
                    List<String> userIds = groupedByUser.keys.toList();

                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: kSuccess.withOpacity(0.1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total Bids: ${docs.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: kTextMain, fontSize: 13)),
                              Text("Total Amount: ₹$totalAmount", style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary, fontSize: 14)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: userIds.length,
                            itemBuilder: (context, index) {
                              String uId = userIds[index];
                              List<QueryDocumentSnapshot> userDocs = groupedByUser[uId]!;
                              String agentName = _agentNamesCache[uId] ?? 'Unknown Agent';
                              int userTotal = userDocs.fold(0, (sum, d) => sum + (int.tryParse((d.data() as Map)['amount']?.toString() ?? '') ?? 0));

                              return _UserBidCard(
                                agentName: agentName,
                                userId: uId,
                                userTotal: userTotal,
                                bets: userDocs,
                                agentCache: _agentNamesCache,
                                onDelete: _deleteBid,
                                onChartTap: (uid, chatId) => _showFullChart(context, uid, chatId),
                                buildStatusBadge: _buildStatusBadge,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }
                )
          )
        ],
      ),
    );
  }
}

// --- GROUPED USER BID CARD (1 card per user, expandable) ---
class _UserBidCard extends StatefulWidget {
  final String agentName;
  final String userId;
  final int userTotal;
  final List<QueryDocumentSnapshot> bets;
  final Map<String, String> agentCache;
  final Function(String, int, String) onDelete;
  final Function(String, String) onChartTap;
  final Widget Function(String) buildStatusBadge;

  const _UserBidCard({
    required this.agentName,
    required this.userId,
    required this.userTotal,
    required this.bets,
    required this.agentCache,
    required this.onDelete,
    required this.onChartTap,
    required this.buildStatusBadge,
  });

  @override
  State<_UserBidCard> createState() => _UserBidCardState();
}

class _UserBidCardState extends State<_UserBidCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    String initials = widget.agentName.isNotEmpty ? widget.agentName[0].toUpperCase() : '?';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _expanded ? kPrimary.withOpacity(0.4) : Colors.grey.shade200, width: 1.5),
      ),
      color: Colors.white,
      child: Column(
        children: [
          // Collapsed header
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: kPrimary.withOpacity(0.12)),
                    child: Center(child: Text(initials, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.agentName, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("${widget.bets.length} bid${widget.bets.length > 1 ? 's' : ''}", style: const TextStyle(color: kTextGrey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("₹${widget.userTotal}", style: const TextStyle(color: kSuccess, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("Total", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: kPrimary),
                ],
              ),
            ),
          ),

          // Expanded bets
          if (_expanded) ...[
            const Divider(height: 1, color: Colors.black12),
            ...widget.bets.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String gameName = data['gameName'] ?? '-';
              String session = data['session'] ?? 'Open';
              String betType = data['betType'] ?? '-';
              String number = data['number']?.toString() ?? '-';
              int amount = int.tryParse(data['amount']?.toString() ?? '') ?? 0;
              String status = data['status'] ?? 'pending';
              Timestamp? ts = data['timestamp'];
              String timeStr = ts != null ? DateFormat('hh:mm a').format(ts.toDate()) : '';
              String? chatId = data['chatId'];

              return InkWell(
                onTap: chatId != null ? () => widget.onChartTap(widget.userId, chatId) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("$gameName ($session)", style: const TextStyle(fontWeight: FontWeight.bold, color: kTextMain, fontSize: 13)),
                                Text(betType, style: const TextStyle(color: kTextGrey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              children: [
                                const Text("Number", style: TextStyle(fontSize: 9, color: Colors.blueGrey)),
                                Text(number, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                                Text("₹$amount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kSuccess)),
                                const SizedBox(height: 3),
                                widget.buildStatusBadge(status),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          if (status == 'pending')
                            InkWell(
                              onTap: () => widget.onDelete(doc.id, amount, widget.userId),
                              child: const Text("Delete Bid", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}