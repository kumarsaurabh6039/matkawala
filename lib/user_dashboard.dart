import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:typed_data';

// --- NEW PACKAGES IMPORT FOR PRINTING & PDF ---
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// --- THEME COLORS (MNC Corporate Light Theme) ---
const Color kBgColor = Color(0xFFF0F2F5); // Light greyish background for contrast
const Color kCardColor = Colors.white; // Solid white for cards
const Color kPrimary = Color(0xFF1A73E8); // Professional Google Blue
const Color kAccent = Color(0xFFE53935); // Red
const Color kTextMain = Color(0xFF202124); // Dark text for white backgrounds
const Color kTextSub = Color(0xFF5F6368); // Grey subtext
const Color kSuccess = Color(0xFF0F9D58); // Green
const Color kPurpleLedger = Color(0xFF7B1FA2); // For 'Baki' strip

// --- WHATSAPP THEME COLORS (Light Mode) ---
const Color kWABg = Color(0xFFEFE7DD);       // Light chat background
const Color kWABubbleSelf = Color(0xFFDCF8C6); // Light green bubble
const Color kWAInputBg = Colors.white;       // Input Bar
const Color kWAFab = Color(0xFF1A73E8);      // Send Button

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;
  String _selectedLang = 'mr'; // Default Marathi
  DateTime _lastReadTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _loadLastReadTime();
  }

  Future<void> _loadLastReadTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int ms = prefs.getInt('last_notification_read') ?? 0;
    if(mounted) {
      setState(() {
        _lastReadTime = DateTime.fromMillisecondsSinceEpoch(ms);
      });
    }
  }

  Future<void> _markNotificationsAsRead() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_notification_read', DateTime.now().millisecondsSinceEpoch);
    if(mounted) {
      setState(() {
        _lastReadTime = DateTime.now();
      });
    }
  }

  // --- TRANSLATIONS MAP ---
  final Map<String, Map<String, String>> _trans = {
    'en': {
      'title': 'MATKAWALA',
      'wallet': 'LIMIT',
      'play': 'Live Market',
      'ledger': 'Select Market', 
      'chat': 'Support',
      'settings': 'Profile',
      'open': 'Open',
      'close': 'Close',
      'betting_open': 'Betting Open',
      'open_running': 'Open Running',
      'close_running': 'Close Running',
      'betting_closed': 'Betting Closed',
      'market_closed': 'Market Closed',
      'error': 'Error',
      'type_hint': 'Type 145*10, dp*4*10, 4=dp=10...',
      'total_amount': 'Total Amount',
      'place_order': 'PLACE ORDER',
      'game': 'Game',
      'dhanda': 'Dhanda',
      'payment': 'Payment',
      'all_games': 'ALL GAMES',
      'total': 'Total',
      'baki': 'Baki',
      'prev_baki': 'Magil Jama',
      'today_baki': 'Aajche Jama',
      'total_baki': 'Ekun Baki',
      'outstanding': 'Thakbaki',
      'final_baki': 'Final Baki',
      'vasuli': 'Vasuli (Collected)',
      'vatap': 'Vatap (Paid Out)',
      'view_slip': 'VIEW DAY SLIP (PDF)',
      'change_pass': 'Change Password',
      'logout': 'Logout',
      'update': 'Update',
      'cancel': 'Cancel',
      'new_pass': 'New Password',
      'pass_short': 'Password too short!',
      'pass_updated': 'Password Updated! Please Login Again.',
      'no_valid_bets': 'No valid bets found! Check format.',
      'success_bets': 'Bets Placed Successfully!',
      'insufficient': 'तुमची लिमिट संपली आहे! (Insufficient Limit)',
      'official_receipt': 'Official Receipt',
      'date': 'Date',
      'id': 'ID',
      'no': 'NO',
      'amt': 'AMT',
      'thank_you': '* Thank you for playing *',
      'type_msg': 'Type a message...',
      'lang_sel': 'Language',
      'analysis': 'Analysis',
      'select_market_ledger': 'Select Market for History',
      'download_pdf': 'Download Slip (PDF)',
    },
    'mr': {
      'title': 'मटकावाला',
      'wallet': 'लिमिट',
      'play': 'लाइव्ह मार्केट',
      'ledger': 'मार्केट निवडा', 
      'chat': 'मदत',
      'settings': 'प्रोफाइल',
      'open': 'ओपन',
      'close': 'क्लोज',
      'betting_open': 'बेटिंग चालू',
      'open_running': 'ओपन चालू',
      'close_running': 'क्लोज चालू',
      'betting_closed': 'बेटिंग बंद',
      'market_closed': 'बाजार बंद',
      'error': 'त्रुटी',
      'type_hint': 'टाइप करा 145*10, dp*4*10, 123=fm=10...',
      'total_amount': 'एकूण रक्कम',
      'place_order': 'ऑर्डर द्या',
      'game': 'गेम',
      'dhanda': 'धंदा',
      'payment': 'पेमेंट',
      'all_games': 'सर्व गेम्स',
      'total': 'एकूण',
      'baki': 'बाकी',
      'prev_baki': 'मागील जमा',
      'today_baki': 'आजचे जमा',
      'total_baki': 'एकूण बाकी',
      'outstanding': 'थकबाकी',
      'final_baki': 'अंतिम बाकी',
      'vasuli': 'वसुली',
      'vatap': 'वाटप',
      'view_slip': 'दिवसाची स्लिप पहा (PDF)',
      'change_pass': 'पासवर्ड बदला',
      'logout': 'लॉगआउट',
      'update': 'अपडेट करा',
      'cancel': 'रद्द करा',
      'new_pass': 'नवीन पासवर्ड',
      'pass_short': 'पासवर्ड खूप लहान आहे!',
      'pass_updated': 'पासवर्ड अपडेट झाला! कृपया पुन्हा लॉगिन करा.',
      'no_valid_bets': 'वैध बेट्स सापडले नाहीत!',
      'success_bets': 'बेट्स यशस्वीरित्या लावले!',
      'insufficient': 'तुमची लिमिट संपली आहे! (Insufficient Limit)',
      'official_receipt': 'अधिकृत पावती',
      'date': 'तारीख',
      'id': 'आयडी',
      'no': 'क्र.',
      'amt': 'रक्कम',
      'thank_you': '* खेळल्याबद्दल धन्यवाद *',
      'type_msg': 'संदेश टाइप करा...',
      'lang_sel': 'भाषा',
      'analysis': 'विश्लेषण',
      'select_market_ledger': 'हिशोब पाहण्यासाठी मार्केट निवडा',
      'download_pdf': 'स्लिप डाउनलोड करा (PDF)',
    }
  };

  String t(String key) => _trans[_selectedLang]?[key] ?? key;

  void _changeLanguage(String lang) {
    setState(() {
      _selectedLang = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final List<Widget> pages = [
      HomeGamesTab(uid: uid, t: t, lang: _selectedLang),
      LedgerTab(uid: uid, t: t), 
      ChatTab(uid: uid, t: t), 
      ProfileTab(uid: uid, t: t),
    ];

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(t('title'), style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextMain),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: kPrimary),
            color: Colors.white,
            onSelected: _changeLanguage,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'en', child: Text('English', style: TextStyle(color: kTextMain))),
              const PopupMenuItem<String>(value: 'mr', child: Text('मराठी', style: TextStyle(color: kTextMain))),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: kAccent),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
        builder: (context, snapshot) {
          bool hasUnread = false;
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              Timestamp? exp = data['expiresAt'];
              
              if (exp != null && exp.toDate().isBefore(DateTime.now())) {
                FirebaseFirestore.instance.collection('notifications').doc(doc.id).delete();
                continue;
              }

              Timestamp? ts = data['timestamp'];
              if (ts != null && ts.toDate().isAfter(_lastReadTime)) {
                hasUnread = true;
              }
            }
          }

          return BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() => _selectedIndex = index);
              if (index == 3) {
                _markNotificationsAsRead();
              }
            },
            selectedItemColor: kPrimary,
            unselectedItemColor: kTextSub,
            type: BottomNavigationBarType.fixed,
            elevation: 10,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: t('play')),
              BottomNavigationBarItem(icon: const Icon(Icons.grid_view), label: t('ledger')), 
              BottomNavigationBarItem(icon: const Icon(Icons.support_agent), label: t('chat')),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.person),
                    if (hasUnread && _selectedIndex != 3) 
                      Positioned(
                        right: -2, top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                        ),
                      )
                  ]
                ),
                label: t('settings')
              ),
            ],
          );
        }
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. HOME GAMES TAB (UPGRADED LIGHT UI)
// -----------------------------------------------------------------------------
class HomeGamesTab extends StatefulWidget {
  final String uid;
  final Function(String) t;
  final String lang;

  const HomeGamesTab({super.key, required this.uid, required this.t, required this.lang});

  @override
  State<HomeGamesTab> createState() => _HomeGamesTabState();
}

class _HomeGamesTabState extends State<HomeGamesTab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  Map<String, dynamic> _getMarketStatus(Map<String, dynamic> data) {
    bool isForceClosed = data['isClosed'] == true;
    if (isForceClosed) {
      return {'status': 'CLOSED', 'color': kAccent, 'isOpen': false, 'msg': widget.t('market_closed')};
    }

    try {
      final now = DateTime.now();
      
      String openStartStr = data['openBetStart'] ?? data['openTime'] ?? '09:00 AM';
      String openEndStr = data['openBetEnd'] ?? '10:00 AM';
      String closeStartStr = data['closeBetStart'] ?? '12:00 PM';
      String closeEndStr = data['closeBetEnd'] ?? data['closeTime'] ?? '02:00 PM';
      
      DateTime openStart = _parseTime(openStartStr, now);
      DateTime openEnd = _parseTime(openEndStr, now);
      DateTime closeStart = _parseTime(closeStartStr, now);
      DateTime closeEnd = _parseTime(closeEndStr, now);

      if (now.isBefore(openStart)) {
        return {'status': 'UPCOMING', 'color': Colors.blueAccent, 'isOpen': true, 'msg': "${widget.t('betting_open')} @ $openStartStr"};
      }
      else if (now.isAfter(openStart) && now.isBefore(openEnd)) {
        return {'status': 'OPEN_RUNNING', 'color': kSuccess, 'isOpen': true, 'msg': widget.t('open_running')};
      }
      else if (now.isAfter(openEnd) && now.isBefore(closeStart)) {
        return {'status': 'WAITING', 'color': Colors.orange, 'isOpen': false, 'msg': widget.t('betting_closed')};
      }
      else if (now.isAfter(closeStart) && now.isBefore(closeEnd)) {
        return {'status': 'CLOSE_RUNNING', 'color': kSuccess, 'isOpen': true, 'msg': widget.t('close_running')};
      }
      else {
        return {'status': 'CLOSED', 'color': kAccent, 'isOpen': false, 'msg': widget.t('market_closed')};
      }
    } catch (e) {
      return {'status': 'ERROR', 'color': Colors.grey, 'isOpen': false, 'msg': 'Time Error'};
    }
  }

  DateTime _parseTime(String timeStr, DateTime now) {
    try {
      String clean = timeStr.trim().toUpperCase()
          .replaceAll('.', ':') 
          .replaceAll(RegExp(r'\s+'), ''); 

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
      return DateTime(now.year, now.month, now.day, format.parseLoose(timeStr).hour, format.parseLoose(timeStr).minute);
      
    } catch (e) {
      return DateTime(now.year, now.month, now.day, 23, 59);
    }
  }


  // Parses result string like "123-45-678" and displays declared vs undeclared parts
  Widget _buildResultDisplay(String result) {
    List<String> parts = result.split("-");
    String open = parts.isNotEmpty ? parts[0] : "***";
    String jodi = parts.length > 1 ? parts[1] : "**";
    String close = parts.length > 2 ? parts[2] : "***";
    bool openDeclared = !open.contains("*");
    bool jodiDeclared = !jodi.contains("*");
    bool closeDeclared = !close.contains("*");
    Widget segment(String val, bool declared) {
      return Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: declared ? const Color(0xFF1A237E) : Colors.grey.shade400, letterSpacing: 1.5));
    }
    return Row(children: [
      segment(open, openDeclared),
      Text(" - ", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
      segment(jodi, jodiDeclared),
      Text(" - ", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
      segment(close, closeDeclared),
    ]);
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
          builder: (context, snapshot) {
            var limit = 0;
            bool showLimit = true;
            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              limit = data['limit'] ?? data['creditLimit'] ?? 0;
              showLimit = data['showLimitToUser'] ?? true;
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("AVAILABLE LIMIT", style: TextStyle(color: kTextSub, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 5),
                      Text(showLimit ? "₹ $limit" : "---", style: const TextStyle(color: kPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.account_balance_wallet, color: kPrimary, size: 35),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('games').orderBy('order').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: snapshot.data?.docs.length ?? 0,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  
                  var status = _getMarketStatus(data);
                  
                  return GestureDetector(
                    onTap: () {
                      // ALLOW OPENING CHART EVEN IF CLOSED
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChartBettingScreen(
                            uid: widget.uid,
                            gameId: doc.id,
                            gameName: data['name'] ?? '',
                            openBetStart: data['openBetStart'] ?? '09:00 AM',
                            openBetEnd: data['openBetEnd'] ?? '10:00 AM',
                            closeBetStart: data['closeBetStart'] ?? '10:00 AM',
                            closeBetEnd: data['closeBetEnd'] ?? '12:00 PM',
                            t: widget.t,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 55, height: 55,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle, 
                                color: status['color'].withOpacity(0.1),
                                border: Border.all(color: status['color'].withOpacity(0.5), width: 1.5)
                              ),
                              child: Center(child: Icon(Icons.play_arrow_rounded, color: status['color'], size: 30)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['name'] ?? '', style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.1)),
                                  const SizedBox(height: 4),
                                  // RESULT ROW — shows declared result like "258-50-235"
                                  _buildResultDisplay(data['result'] ?? '***-**-***'),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, color: kTextSub, size: 14),
                                      const SizedBox(width: 4),
                                      Text("${data['openTime']} - ${data['closeTime']}", style: const TextStyle(color: kTextSub, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: status['color'].withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8)
                                    ),
                                    child: Text(status['msg'], style: TextStyle(color: status['color'], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 18),
                          ],
                        ),
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
}

// -----------------------------------------------------------------------------
// 2. CHART BETTING SCREEN (UPDATED VALIDATION & DATE LOGIC)
// -----------------------------------------------------------------------------
class ChartBettingScreen extends StatefulWidget {
  final String uid;
  final String gameId;
  final String gameName;
  final String openBetStart;
  final String openBetEnd;
  final String closeBetStart;
  final String closeBetEnd;
  final Function(String) t;

  const ChartBettingScreen({
    super.key, 
    required this.uid, 
    required this.gameId, 
    required this.gameName, 
    required this.openBetStart,
    required this.openBetEnd,
    required this.closeBetStart,
    required this.closeBetEnd,
    required this.t
  });

  @override
  State<ChartBettingScreen> createState() => _ChartBettingScreenState();
}

class _ChartBettingScreenState extends State<ChartBettingScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  
  double _sendButtonScale = 1.0;
  bool _isLoading = false;
  late DateTime _selectedDate;
  Timer? _realTimeSyncTimer;

  BlueThermalPrinter get bluetooth => BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); // Default is ALWAYS today
    _realTimeSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _realTimeSyncTimer?.cancel();
    super.dispose();
  }

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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(), // Disable future dates
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: kPrimary, onPrimary: Colors.white, surface: Colors.white),
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

  Future<void> _sendMessageAndPlaceBet(String currentSession, bool isMarketOpen) async {
    bool isToday = _selectedDate.year == DateTime.now().year && _selectedDate.month == DateTime.now().month && _selectedDate.day == DateTime.now().day;
    if (!isMarketOpen || !isToday) {
      return; // Disabled from UI, extra check here
    }

    String text = _inputCtrl.text;
    if (text.trim().isEmpty) return;

    setState(() => _sendButtonScale = 1.3);
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() => _sendButtonScale = 1.0);

    setState(() => _isLoading = true);

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      Map<String, dynamic> userRatesData = {};
      if(userDoc.exists) {
        userRatesData = userDoc.data() as Map<String, dynamic>;
      }

      // STRICT VALIDATION
      List<Map<String, dynamic>> parsedBets = _parseBets(text, currentSession, userRatesData);
      
      if (parsedBets.isEmpty) {
        throw Exception("कृपया सही फॉर्मेट में बिड टाइप करें! (e.g. 145*10)");
      }

      int msgTotal = parsedBets.fold(0, (sum, item) => sum + (item['amount'] as int));

      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.uid);
      final chatRef = userRef.collection('game_chats').doc();
      String newChatId = chatRef.id;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot gameSnap = await transaction.get(FirebaseFirestore.instance.collection('games').doc(widget.gameId));
        if (gameSnap.exists) {
          var gData = gameSnap.data() as Map<String, dynamic>;
          if (gData['isClosed'] == true) throw Exception("मार्केट फिलहाल बंद है! (Market Closed by Admin)");
          
          DateTime now = DateTime.now();
          DateTime oStart = _parseTime(gData['openBetStart'] ?? '09:00 AM', now);
          DateTime oEnd = _parseTime(gData['openBetEnd'] ?? '10:00 AM', now);
          DateTime cStart = _parseTime(gData['closeBetStart'] ?? '12:00 PM', now);
          DateTime cEnd = _parseTime(gData['closeBetEnd'] ?? '02:00 PM', now);

          bool stillOpen = false;
          if (now.isAfter(oStart) && now.isBefore(oEnd)) stillOpen = true;
          else if (now.isAfter(cStart) && now.isBefore(cEnd)) stillOpen = true;

          if (!stillOpen) throw Exception("मार्केट का समय समाप्त हो गया है! (Time Over)");
        }

        DocumentSnapshot userSnap = await transaction.get(userRef);
        if (!userSnap.exists) throw Exception("User not found!");

        var uData = userSnap.data() as Map<String, dynamic>;
        
        int currentLimit = (uData['limit'] ?? uData['creditLimit'] ?? 0).toInt();

        if (currentLimit < msgTotal) {
          throw Exception("तुम्हारी लिमिट ख़तम हो गयी है! (Insufficient Limit)");
        }

        transaction.update(userRef, {
           'limit': currentLimit - msgTotal
        });

        for (var bet in parsedBets) {
          DocumentReference betRef = FirebaseFirestore.instance.collection('bets').doc();
          transaction.set(betRef, {
            'chatId': newChatId, 
            'userId': widget.uid,
            'gameId': widget.gameId,
            'gameName': widget.gameName,
            'betType': bet['betType'],
            'session': currentSession,
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
          'gameId': widget.gameId,
          'text': text.trim(),
          'total': msgTotal,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        _inputCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.t('success_bets')), backgroundColor: kSuccess));
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString().replaceAll("Exception:", "").trim();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOptions(Map<String, dynamic> data, bool canBet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (!canBet)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.orange.shade50,
                  child: Row(
                    children: const [
                      Icon(Icons.lock_outline, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'या सेशनचा वेळ संपला आहे. Edit/Delete बंद.\n(Session over — Edit/Delete locked)',
                        style: TextStyle(color: Colors.orange, fontSize: 12)
                      )),
                    ],
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.copy, color: kTextMain),
                title: const Text('Copy (कॉपी)', style: TextStyle(color: kTextMain)),
                onTap: () {
                  // Copies ONLY the raw bid text placed by the user, without Name or Date
                  Clipboard.setData(ClipboardData(text: (data['text'] ?? '').toString().trim()));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('बिड कॉपी हो गई (Bid Copied)')));
                }
              ),
              ListTile(
                leading: Icon(Icons.edit, color: canBet ? Colors.blue : Colors.grey),
                title: Text('Edit (बदल करा)', style: TextStyle(color: canBet ? kTextMain : Colors.grey)),
                onTap: canBet ? () {
                  Navigator.pop(context);
                  _editBet(data);
                } : null,
              ),
              ListTile(
                leading: Icon(Icons.delete, color: canBet ? Colors.red : Colors.grey),
                title: Text('Delete (हटवा)', style: TextStyle(color: canBet ? kTextMain : Colors.grey)),
                onTap: canBet ? () {
                  Navigator.pop(context);
                  _deleteBet(data);
                } : null,
              ),
              ListTile(
                leading: const Icon(Icons.print, color: Colors.green),
                title: const Text('Print (प्रिंट करा)', style: TextStyle(color: kTextMain)),
                onTap: () {
                  Navigator.pop(context);
                  _printBet(data);
                }
              ),
            ],
          ),
        );
      }
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: kTextSub)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: kTextSub))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes', style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;
  }

  Future<void> _cancelBetProcess(Map<String, dynamic> data) async {
    String? chatId = data['chatId'];
    if(chatId == null) throw Exception("Cannot modify older bets as they lack an ID.");

    setState(() => _isLoading = true);
    try {
      int refundAmount = data['total'] ?? 0;
      var betsQuery = await FirebaseFirestore.instance.collection('bets').where('chatId', isEqualTo: chatId).get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      var userRef = FirebaseFirestore.instance.collection('users').doc(widget.uid);
      batch.update(userRef, {
         'limit': FieldValue.increment(refundAmount)
      }); 

      for(var doc in betsQuery.docs) {
        batch.delete(doc.reference);
      }

      var chatRef = FirebaseFirestore.instance.collection('users').doc(widget.uid).collection('game_chats').doc(chatId);
      batch.delete(chatRef);

      await batch.commit();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editBet(Map<String, dynamic> data) async {
    bool confirm = await _showConfirmDialog("Edit Bet", "This will cancel the current bet, refund amount, and place text in input. Continue?");
    if (!confirm) return;

    try {
      await _cancelBetProcess(data);
      setState(() {
        _inputCtrl.text = data['text'] ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  void _deleteBet(Map<String, dynamic> data) async {
    bool confirm = await _showConfirmDialog("Delete Bet", "This will cancel the bet and refund your wallet. Are you sure?");
    if (!confirm) return;

    try {
      await _cancelBetProcess(data);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bet Deleted and Amount Refunded Successfully", style: TextStyle(color: Colors.white)), backgroundColor: kSuccess));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _printBet(Map<String, dynamic> data) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedAddress = prefs.getString('printer_address');

      if (savedAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("प्रिंटर सेटअप नहीं है! कृपया Profile -> Printer Settings में जाकर प्रिंटर कनेक्ट करें।", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red, duration: Duration(seconds: 4)));
        return;
      }

      bool? isConnected = await bluetooth.isConnected;
      
      if (isConnected != true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("प्रिंटर कनेक्ट हो रहा है...")));
        List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
        BluetoothDevice? targetDevice;
        try {
           targetDevice = devices.firstWhere((d) => d.address == savedAddress);
           await bluetooth.connect(targetDevice);
           isConnected = true;
        } catch(e) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("प्रिंटर कनेक्ट नहीं हो पाया! कृपया सेटिंग्स चेक करें।", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
           return;
        }
      }
      
      if (isConnected == true) {
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
        String agentName = "Unknown";
        if(userDoc.exists) {
          var uData = userDoc.data() as Map<String, dynamic>;
          agentName = uData['name'] ?? uData['email']?.split('@')[0] ?? widget.uid.substring(0, 5);
        }

        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);
        List<int> bytes = [];

        bytes += generator.text('Acknowledgement Slip', styles: const PosStyles(align: PosAlign.center));
        
        String sessionName = data['session'] ?? 'Open';
        bytes += generator.text('${widget.gameName} $sessionName', styles: const PosStyles(align: PosAlign.center));

        var time = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        String dateStr = DateFormat('d/M/yyyy - h:mm a').format(time);
        bytes += generator.text('Date: $dateStr', styles: const PosStyles(align: PosAlign.center));
        bytes += generator.emptyLines(1);

        bytes += generator.text('Message', styles: const PosStyles(align: PosAlign.center));
        bytes += generator.emptyLines(1);
        bytes += generator.text(widget.gameName, styles: const PosStyles(align: PosAlign.left, height: PosTextSize.size2)); 

        for(String line in (data['text'] ?? '').toString().split('\n')) {
          if (line.trim().isNotEmpty) {
            bytes += generator.text(line.trim(), styles: const PosStyles(align: PosAlign.left, height: PosTextSize.size2));
          }
        }

        bytes += generator.emptyLines(1);
        bytes += generator.text('Total Points: ${data['total']}.00', styles: const PosStyles(align: PosAlign.center, bold: true));
        bytes += generator.emptyLines(1);
        
        bytes += generator.text('Agent : $agentName', styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text('Second Print', styles: const PosStyles(align: PosAlign.center));

        bytes += generator.feed(2);
        bytes += generator.cut();

        bluetooth.writeBytes(Uint8List.fromList(bytes));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Printed successfully!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Printing Failed: $e"), backgroundColor: Colors.red));
    }
  }

  // --- STRICT VALIDATION FOR PANNA ---
  bool _isValidPanna(String panna) {
    if (panna.length != 3) return false;
    
    int val(String char) {
      int v = int.tryParse(char) ?? 0;
      return v == 0 ? 10 : v; 
    }
    
    int d1 = val(panna[0]);
    int d2 = val(panna[1]);
    int d3 = val(panna[2]);
    
    return (d1 <= d2) && (d2 <= d3);
  }

  // Returns a specific error string if numStr is a zero-start invalid number, else null
  String? _zeroBidError(String numStr) {
    if (!RegExp(r'^\d+$').hasMatch(numStr)) return null;
    String type = _detectBetType(numStr);
    if (type == 'Single Digit' && numStr == '0') {
      return "❌ '0' सिंगल डिजिट invalid है";
    }
    // Jodi 00-99 tak valid hai, 0 se shuru ho sakti hai (04, 09, 00 sab valid)
    if ((type == 'Single Panna' || type == 'Double Panna' || type == 'Triple Panna') && numStr.startsWith('0')) {
      return "❌ Panna '0' से शुरू नहीं हो सकता: $numStr";
    }
    return null;
  }

  // --- STRICT PARSING WITH ERROR THROWING ---
  // Bid text display ke liye mobile numbers, dates, aur game name headers filter karo
  String _filterDisplayText(String text) {
    List<String> lines = text.split('\n');
    List<String> filtered = [];
    for (String line in lines) {
      String trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // WhatsApp full header: "[3/11, 7:52 PM] Name: bids" or "[3/9, 23:45] +91 70666: bids"
      // Bracket can contain digits, slash, comma, space, colon, letters (AM/PM)
      if (RegExp(r'^\[.+?\]\s*[^:]+:').hasMatch(trimmed)) continue;
      // Standalone mobile number lines (e.g. +91 70666 68122)
      if (RegExp(r'^\+?\d[\d\s\-]{8,}$').hasMatch(trimmed)) continue;
      // Lines that are purely letters (game name headers like "Kalyan Night Close") skip
      if (!trimmed.contains(RegExp(r'\d'))) continue;
      filtered.add(trimmed);
    }
    return filtered.join('\n');
  }

  List<Map<String, dynamic>> _parseBets(String text, String session, Map<String, dynamic> userRates) {
    List<Map<String, dynamic>> finalBets = [];
    List<String> errors = [];
    List<String> lines = text.split('\n');
    int currentAmount = 0; 
    String? currentMode;

    for (String originalLine in lines) {
      // STEP 0: WhatsApp header lines jaise "[3/11, 7:52 PM] Bhausaheb: 33x100"
      // WhatsApp format: "[3/11, 7:52 PM] +91 70666 68122: bids" OR "[3/9, 23:45] Name: bids"
      String processLine = originalLine;
      final waHeaderMatch = RegExp(r'^\[.+?\]\s*[^:]+:(.*)').firstMatch(originalLine);
      if (waHeaderMatch != null) {
        // Header ke baad ka part nikalo e.g. " 33x100" or " 3*50"
        String afterColon = waHeaderMatch.group(1)?.trim() ?? '';
        if (afterColon.isEmpty) continue; // sirf header tha, koi bid nahi
        processLine = afterColon; // bid part ko process karo
      } else if (RegExp(r'^\+\d{1,3}[\s\-]?\d{4,6}[\s\-]?\d{4,6}').hasMatch(originalLine.trim())) {
        continue; // plain phone number line - skip
      }

      // FIX: Treat ALL special characters as separators (same as space)
      String lineNormalized = processLine
          .replaceAll(RegExp(r'[!@#\$%\^&\*,;:|\/\\~`\(\)\[\]\{\}\+\-xX]+'), ' ')
          .trim();

      String line = lineNormalized.toLowerCase();
      if (line.isEmpty) continue;

      // WhatsApp copy-paste — if line has NO digits at all, it's a name/label/header line → silently skip
      if (!line.contains(RegExp(r'\d'))) {
        bool lineHasModeKeyword = line.contains('sp') || line.contains('dp') || line.contains('tp') || line.contains('fm');
        if (lineHasModeKeyword) {
          if (line.contains('sp')) currentMode = 'sp';
          else if (line.contains('dp')) currentMode = 'dp';
          else if (line.contains('tp')) currentMode = 'tp';
          else if (line.contains('fm')) currentMode = 'fm';
        }
        // Pure text (names like "Rahul", "Total:", date headers) → silently skip
        continue;
      }

      bool lineHasModeStr = line.contains('sp') || line.contains('dp') || line.contains('tp') || line.contains('fm');

      // Remove known valid non-digit chars for mode detection, then check for unexpected letters
      String textOnly = line.replaceAll(RegExp(r'[0-9\*\-\=\.\s\+xX]'), '');
      textOnly = textOnly.replaceAll(RegExp(r'(sp|dp|tp|fm)'), '');
      if (textOnly.trim().isNotEmpty) {
        // Line has letters — could be "Kalyan Night Close 399-200 800-200" style
        // Extract only the numeric bid portion (numbers with separators) and try to parse it
        // Strip leading alphabetic header words, keep only numeric token groups
        String numericPart = line.replaceAll(RegExp(r'[a-zA-Z\u0900-\u097F]+'), ' ').trim();
        // If there are still usable digits after stripping, process that part
        if (numericPart.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty) {
          // Reuse same logic: treat as if this numericPart is the line
          String cleanNumeric = numericPart.replaceAll(RegExp(r'[^0-9]'), ' ').trim();
          List<String> numParts = cleanNumeric.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
          if (numParts.length >= 2) {
            int amount = int.tryParse(numParts.last) ?? 0;
            if (amount > 0) {
              currentAmount = amount;
              if (!lineHasModeStr) currentMode = null;
              for (int i = 0; i < numParts.length - 1; i++) {
                int preCount = finalBets.length;
                _addParsedBet(finalBets, numParts[i], currentAmount, currentMode, session, userRates);
                if (finalBets.length == preCount) {
                  errors.add(_zeroBidError(numParts[i]) ?? "ग़लत बिड: ${numParts[i]}");
                }
              }
            }
          }
        }
        // Either way, skip rest of loop for this line (already processed or pure text header)
        continue;
      }

      if (lineHasModeStr) {
         if (line.contains('sp')) currentMode = 'sp';
         else if (line.contains('dp')) currentMode = 'dp';
         else if (line.contains('tp')) currentMode = 'tp';
         else if (line.contains('fm')) currentMode = 'fm';
      }

      String clean = line.replaceAll(RegExp(r'[^0-9]'), ' ').trim();
      List<String> parts = clean.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

      if (parts.isEmpty) {
        errors.add("ग़लत फॉर्मेट: $originalLine");
        continue;
      }

      if (parts.length == 1) {
        int number = int.tryParse(parts[0]) ?? -1;
        if (number >= 0 && currentAmount > 0) {
          int preCount = finalBets.length;
          _addParsedBet(finalBets, parts[0], currentAmount, currentMode, session, userRates);
          if (finalBets.length == preCount) {
             errors.add(_zeroBidError(parts[0]) ?? "ग़लत बिड/पाना: $originalLine");
          }
        } else {
          errors.add("अमाउंट नहीं डाला गया: $originalLine");
        }
      } else if (parts.length >= 2) {
        int amount = int.tryParse(parts.last) ?? 0;
        if (amount > 0) {
          currentAmount = amount; 
          if (!lineHasModeStr) {
             currentMode = null; 
          }
          for (int i = 0; i < parts.length - 1; i++) {
            int preCount = finalBets.length;
            _addParsedBet(finalBets, parts[i], currentAmount, currentMode, session, userRates);
            if (finalBets.length == preCount) {
               errors.add(_zeroBidError(parts[i]) ?? "ग़लत बिड/पाना: ${parts[i]}");
            }
          }
        } else {
           errors.add("अमाउंट ग़लत है: $originalLine");
        }
      }
    }
    
    if (errors.isNotEmpty) {
       throw Exception("नीचे दी गई बिड ग़लत हैं, ठीक करें:\n${errors.join('\n')}");
    }

    return finalBets;
  }

  void _addParsedBet(List<Map<String, dynamic>> bets, String numStr, int amount, String? mode, String session, Map<String, dynamic> userRates) {
    if (numStr.length == 3 && RegExp(r'^\d+$').hasMatch(numStr)) {
       if (!_isValidPanna(numStr)) {
         return; 
       }
    }

    int spRate = (userRates['spRate'] as num?)?.toInt() ?? (userRates['panelRate'] as num?)?.toInt() ?? 160;
    int dpRate = (userRates['dpRate'] as num?)?.toInt() ?? 320;
    int tpRate = (userRates['tpRate'] as num?)?.toInt() ?? 1000;
    int jRate = (userRates['jodiRate'] as num?)?.toInt() ?? 100;
    int singleRate = (userRates['singleRate'] as num?)?.toInt() ?? 10;

    bool generatedFromMode = false;

    if (mode == 'fm' && numStr.length == 3) {
      bets.addAll(_generateFamilyBets(numStr, amount, spRate, dpRate, tpRate));
      generatedFromMode = true;
    } else if (mode == 'sp' || mode == 'dp' || mode == 'tp') {
      int digit = int.tryParse(numStr) ?? -1;
      if (digit >= 0 && digit <= 9) {
        bets.addAll(_generatePannaBets(digit, mode!, amount, spRate, dpRate, tpRate));
        generatedFromMode = true;
      }
    } 
    
    if (!generatedFromMode) {
      if (RegExp(r'^\d+$').hasMatch(numStr)) {
        String processedNumStr = numStr;
        String type = _detectBetType(processedNumStr);

        // 0 से शुरू या सिर्फ 0 — ERROR दो, skip नहीं
        // Single digit "0" → invalid
        if (type == 'Single Digit' && processedNumStr == '0') {
          return; // caller in _parseBets will add error because preCount == finalBets.length
        }
        // Panna 0 से शुरू (012, 045 etc.) → INVALID (matka mein 0-start panna nahi hota)
        if ((type == 'Single Panna' || type == 'Double Panna' || type == 'Triple Panna') && processedNumStr.startsWith('0')) {
          return;
        }

        if (type == 'Jodi Digit' && session == 'Close') {
          return; 
        }

        if (type != 'Unknown') {
          int applyRate = singleRate;
          if (type == 'Jodi Digit') applyRate = jRate;
          else if (type == 'Single Panna') applyRate = spRate;
          else if (type == 'Double Panna') applyRate = dpRate;
          else if (type == 'Triple Panna') applyRate = tpRate;

          bets.add({
            'number': processedNumStr, 
            'amount': amount,
            'betType': type,
            'rate': applyRate
          });
        }
      }
    }
  }

  List<Map<String, dynamic>> _generateFamilyBets(String panna, int amount, int spRate, int dpRate, int tpRate) {
    Set<String> familyPannas = {};
    List<int> digits = panna.split('').map((e) => int.parse(e)).toList();
    List<int> cuts = digits.map((d) => (d + 5) % 10).toList();

    for (int i = 0; i < 8; i++) {
      int d1 = (i & 1) == 0 ? digits[0] : cuts[0];
      int d2 = (i & 2) == 0 ? digits[1] : cuts[1];
      int d3 = (i & 4) == 0 ? digits[2] : cuts[2];

      familyPannas.add(_matkaSortPanna([d1, d2, d3]));
    }

    return familyPannas.map((fp) {
      String type = _detectBetType(fp);
      int r = type == 'Single Panna' ? spRate : (type == 'Double Panna' ? dpRate : tpRate);
      return {
        'number': fp,
        'amount': amount,
        'betType': type, 
        'rate': r 
      };
    }).toList();
  }

  List<Map<String, dynamic>> _generatePannaBets(int digit, String mode, int amount, int spRate, int dpRate, int tpRate) {
    List<String> pannas = [];
    String type = '';
    int rate = spRate;

    if (mode == 'sp') {
      type = 'Single Panna';
      rate = spRate;
      pannas = _getSinglePannas(digit);
    } else if (mode == 'dp') {
      type = 'Double Panna';
      rate = dpRate;
      pannas = _getDoublePannas(digit);
    } else if (mode == 'tp') {
      type = 'Triple Panna';
      rate = tpRate;
      // FIX BUG 2: digit=1 -> 777 (7+7+7=21->1), NOT 111 (sum=3)
      int tDigit = -1;
      for (int t = 0; t <= 9; t++) {
        if ((t * 3) % 10 == digit) { tDigit = t; break; }
      }
      pannas = tDigit >= 0 ? ["$tDigit$tDigit$tDigit"] : [];
    }

    return pannas.map((p) => {
      'number': p,
      'amount': amount,
      'betType': type,
      'rate': rate
    }).toList();
  }

  // FIX BUG 3: Matka standard - zeros at end (290 not 029, 100 not 001)
  String _matkaSortPanna(List<int> digits) {
    List<int> nonZero = digits.where((d) => d != 0).toList()..sort();
    List<int> zeros = List.filled(digits.where((d) => d == 0).length, 0);
    return (nonZero + zeros).join();
  }

  List<String> _getSinglePannas(int digit) {
    List<String> sps = [];
    for (int i=0; i<=9; i++) {
      for (int j=i+1; j<=9; j++) {
        for (int k=j+1; k<=9; k++) {
          int sum = (i+j+k)%10;
          if (sum == digit) sps.add(_matkaSortPanna([i, j, k]));
        }
      }
    }
    return sps;
  }

  List<String> _getDoublePannas(int digit) {
    List<String> dps = [];
    for (int i=0; i<=9; i++) {
      for (int j=0; j<=9; j++) {
        if (i == j) continue;
        int sum = (i+i+j)%10;
        if (sum == digit) {
           String p = _matkaSortPanna([i, i, j]);
           if (!dps.contains(p)) dps.add(p);
        }
      }
    }
    return dps;
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

  @override
  Widget build(BuildContext context) {
    bool isToday = _selectedDate.year == DateTime.now().year && _selectedDate.month == DateTime.now().month && _selectedDate.day == DateTime.now().day;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('games').doc(widget.gameId).snapshots(),
      builder: (context, gameSnapshot) {
        
        String sessionDisplay = 'Closed';
        bool isMarketOpen = false;
        String titleName = widget.gameName;

        if (gameSnapshot.hasData && gameSnapshot.data!.exists) {
           var gData = gameSnapshot.data!.data() as Map<String, dynamic>;
           titleName = gData['name'] ?? widget.gameName;

           if (gData['isClosed'] != true) {
              DateTime now = DateTime.now();
              DateTime oStart = _parseTime(gData['openBetStart'] ?? '09:00 AM', now);
              DateTime oEnd = _parseTime(gData['openBetEnd'] ?? '10:00 AM', now);
              DateTime cStart = _parseTime(gData['closeBetStart'] ?? '12:00 PM', now);
              DateTime cEnd = _parseTime(gData['closeBetEnd'] ?? '02:00 PM', now);

              if (now.isAfter(oStart) && now.isBefore(oEnd)) {
                sessionDisplay = 'Open';
                isMarketOpen = true;
              } else if (now.isAfter(cStart) && now.isBefore(cEnd)) {
                sessionDisplay = 'Close';
                isMarketOpen = true;
              }
           }
        }

        bool canBet = isMarketOpen && isToday;
        // Session-specific edit/delete control:
        // openSessionActive = true means Open bets can be edited/deleted
        // closeSessionActive = true means Close bets can be edited/deleted
        bool openSessionActive = false;
        bool closeSessionActive = false;
        if (gameSnapshot.hasData && gameSnapshot.data!.exists) {
          var gData2 = gameSnapshot.data!.data() as Map<String, dynamic>;
          if (gData2['isClosed'] != true) {
            DateTime now2 = DateTime.now();
            DateTime oStart2 = _parseTime(gData2['openBetStart'] ?? '09:00 AM', now2);
            DateTime oEnd2 = _parseTime(gData2['openBetEnd'] ?? '10:00 AM', now2);
            DateTime cStart2 = _parseTime(gData2['closeBetStart'] ?? '12:00 PM', now2);
            DateTime cEnd2 = _parseTime(gData2['closeBetEnd'] ?? '02:00 PM', now2);
            openSessionActive = now2.isAfter(oStart2) && now2.isBefore(oEnd2);
            closeSessionActive = now2.isAfter(cStart2) && now2.isBefore(cEnd2);
          }
        }

        return Scaffold(
          backgroundColor: kWABg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            leadingWidth: 70,
            leading: InkWell(
              onTap: () => Navigator.pop(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back, color: kTextMain),
                  const SizedBox(width: 5),
                  CircleAvatar(
                    backgroundColor: kPrimary.withOpacity(0.1),
                    radius: 18,
                    child: Text(titleName.isNotEmpty ? titleName[0] : 'G', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titleName, style: const TextStyle(color: kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(
                      sessionDisplay == 'Closed' ? 'Closed' : (sessionDisplay == 'Open' ? widget.t('open') : widget.t('close')), 
                      style: TextStyle(color: isMarketOpen ? kPrimary : kAccent, fontSize: 13, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "(${DateFormat('dd MMM').format(_selectedDate)})",
                      style: const TextStyle(color: kTextSub, fontSize: 11)
                    )
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month, color: kPrimary),
                onPressed: _pickDate,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users')
                      .doc(widget.uid)
                      .collection('game_chats')
                      .where('gameId', isEqualTo: widget.gameId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimary));
                    
                    var docs = snapshot.data!.docs.toList();
                    docs.sort((a, b) {
                       Timestamp? t1 = (a.data() as Map<String, dynamic>)['timestamp'];
                       Timestamp? t2 = (b.data() as Map<String, dynamic>)['timestamp'];
                       DateTime dt1 = t1?.toDate() ?? DateTime.now();
                       DateTime dt2 = t2?.toDate() ?? DateTime.now();
                       return dt2.compareTo(dt1); 
                    });
                    
                    // Always strictly filter to _selectedDate
                    docs = docs.where((doc) {
                      Timestamp? ts = (doc.data() as Map<String, dynamic>)['timestamp'];
                      if (ts == null) return false;
                      DateTime dt = ts.toDate();
                      return dt.year == _selectedDate.year && 
                             dt.month == _selectedDate.month && 
                             dt.day == _selectedDate.day;
                    }).toList();

                    if (docs.isEmpty) {
                       return Center(
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             const Icon(Icons.history_toggle_off, color: Colors.black26, size: 50),
                             const SizedBox(height: 10),
                             Text("इस दिन की कोई हिस्ट्री नहीं है\n(No history found for ${DateFormat('dd MMM').format(_selectedDate)})", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                           ],
                         )
                       );
                    }

                    return ListView.builder(
                      reverse: true, 
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        var time = (data['timestamp'] as Timestamp?)?.toDate();
                        String timeStr = time != null ? DateFormat('hh:mm a').format(time) : '';

                        return Align(
                          alignment: Alignment.centerRight,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            child: GestureDetector(
                              onLongPress: () {
                                // Determine if this specific bet can be edited based on its session
                                String betSession = (data['session'] ?? 'Open').toString();
                                bool canEditThisBet = isToday && (
                                  (betSession == 'Open' && openSessionActive) ||
                                  (betSession == 'Close' && closeSessionActive)
                                );
                                _showOptions(data, canEditThisBet);
                              },
                              child: Card(
                                color: kWABubbleSelf,
                                elevation: 1,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(_filterDisplayText(data['text'] ?? ''), style: const TextStyle(color: kTextMain, fontSize: 16)),
                                      const SizedBox(height: 5),
                                      const Divider(color: Colors.black12, height: 10),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("Done | Game Amt- ${data['total']}.00", style: const TextStyle(color: kPurpleLedger, fontSize: 13, fontWeight: FontWeight.bold)), 
                                          const SizedBox(width: 8),
                                          Text(timeStr, style: const TextStyle(color: kTextSub, fontSize: 10)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: kWABg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(color: kWAInputBg, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(width: 15),
                            Expanded(
                              child: TextField(
                                controller: _inputCtrl,
                                enabled: canBet && !_isLoading,
                                minLines: 1,
                                maxLines: 5,
                                style: const TextStyle(color: kTextMain),
                                decoration: InputDecoration(
                                  hintText: !isToday ? "पुरानी तारीख में बिड संभव नहीं" : (isMarketOpen ? widget.t('type_hint') : "मार्केट बंद है (Market Closed)"),
                                  hintStyle: TextStyle(color: canBet ? kTextSub : kAccent),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: (canBet && !_isLoading) ? () => _sendMessageAndPlaceBet(sessionDisplay, isMarketOpen) : null,
                      child: AnimatedScale(
                        scale: _sendButtonScale,
                        duration: const Duration(milliseconds: 150),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: canBet ? kWAFab : Colors.grey.shade400,
                          child: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }
}

// -----------------------------------------------------------------------------
// 3. LEDGER TAB
// -----------------------------------------------------------------------------
class LedgerTab extends StatelessWidget {
  final String uid;
  final Function(String) t;

  const LedgerTab({super.key, required this.uid, required this.t});

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
          child: Text(
            t('select_market_ledger'), 
            textAlign: TextAlign.center,
            style: const TextStyle(color: kPrimary, fontSize: 18, fontWeight: FontWeight.bold)
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('games').orderBy('order').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                 return Center(child: Text(t('error'), style: const TextStyle(color: kTextSub)));
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
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GameLedgerScreen(uid: uid, gameId: doc.id, gameName: gameName, t: t)));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            gameName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF1976D2), fontSize: 16, fontWeight: FontWeight.bold), 
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
               Navigator.push(context, MaterialPageRoute(builder: (_) => DaySlipScreen(uid: uid, t: t)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            icon: const Icon(Icons.receipt_long),
            label: Text(t('view_slip'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 4. DAY SLIP SCREEN (REAL-TIME + DATE PICKER + WIN/LOSS LIVE)
// -----------------------------------------------------------------------------
class DaySlipScreen extends StatefulWidget {
  final String uid;
  final Function(String) t;
  const DaySlipScreen({super.key, required this.uid, required this.t});

  @override
  State<DaySlipScreen> createState() => _DaySlipScreenState();
}

class _DaySlipScreenState extends State<DaySlipScreen> {
  DateTime _selectedDate = DateTime.now();

  String get uid => widget.uid;
  Function(String) get t => widget.t;

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
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ---- PDF GENERATION ----
  Future<void> _generateAndPrintPDF({
    required BuildContext context,
    required Map<String, Map<String, double>> gameStats,
    required double totalDhanda,
    required double totalPayment,
    required double commission,
    required double baki,
    required double maagilJama,
    required double ekunBaki,
    required String userName,
    required double commissionPct,
    required double vasuli,
    required double vatap,
    required double antimbaki,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text("MATKAWALA - OFFICIAL RECEIPT", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 6),
              pw.Center(child: pw.Text(userName, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700))),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Date: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}"),
                  pw.Text("ID: ...${uid.substring(0, 5)}"),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text("Game", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text("Dhanda", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text("Payment", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.Divider(),
              ...gameStats.entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 3, child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 11))),
                    pw.Expanded(flex: 2, child: pw.Text(e.value['dhanda']!.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 11, color: PdfColors.green800))),
                    pw.Expanded(flex: 2, child: pw.Text(e.value['payment']!.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 11, color: PdfColors.red800))),
                  ],
                ),
              )).toList(),
              pw.Divider(),
              pw.Row(children: [
                pw.Expanded(flex: 3, child: pw.Text("एकूण Total", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Expanded(flex: 2, child: pw.Text(totalDhanda.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800))),
                pw.Expanded(flex: 2, child: pw.Text(totalPayment.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800))),
              ]),
              pw.SizedBox(height: 4),
              pw.Row(children: [
                pw.Expanded(flex: 3, child: pw.Text("कमिशन (${commissionPct.toStringAsFixed(0)}%)")),
                pw.Expanded(flex: 2, child: pw.Text(commission.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(color: PdfColors.green800))),
                pw.Expanded(flex: 2, child: pw.SizedBox()),
              ]),
              pw.SizedBox(height: 4),
              pw.Row(children: [
                pw.Expanded(flex: 3, child: pw.Text("Net Dhanda", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Expanded(flex: 2, child: pw.Text((totalDhanda - commission).toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800))),
                pw.Expanded(flex: 2, child: pw.Text(totalPayment.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800))),
              ]),
              pw.SizedBox(height: 12),
              pw.Container(
                color: PdfColors.purple,
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("बाकी BAKI", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text(baki.toStringAsFixed(2), style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("मागील जमा (Prev Balance)"), pw.Text(maagilJama.toStringAsFixed(2))]),
              pw.SizedBox(height: 4),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("आजचे जमा (Today Baki)"), pw.Text(baki.toStringAsFixed(2))]),
              pw.SizedBox(height: 4),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("एकूण बाकी (Total)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(ekunBaki.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ]),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("थकबाकी (Outstanding)"), pw.Text(maagilJama.toStringAsFixed(2))]),
              pw.SizedBox(height: 4),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("वसुली (Collected from Agent)"), pw.Text(vasuli.toStringAsFixed(0))]),
              pw.SizedBox(height: 4),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("वाटप (Paid to Agent)"), pw.Text(vatap.toStringAsFixed(0))]),
              pw.SizedBox(height: 6),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("अंतिम बाकी (Final Balance)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(antimbaki.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ]),
              pw.SizedBox(height: 30),
              pw.Center(child: pw.Text("* Thank you for playing *", style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'DaySlip_${DateFormat('dd-MM-yyyy').format(_selectedDate)}.pdf',
    );
  }

  // ---- HELPER WIDGETS ----
  Widget _buildCalcRow(String title, double? val1, double? val2, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(title, style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
          if (val1 != null) Expanded(flex: 1, child: Text(val1.toStringAsFixed(2), textAlign: TextAlign.right, style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
          if (val2 != null)
            Expanded(flex: 1, child: Text(val2.toStringAsFixed(2), textAlign: TextAlign.right, style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)))
          else
            const Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildFinalRow(String title, double value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.black, fontSize: 14)),
          Text(value.toStringAsFixed(2), style: TextStyle(color: valColor, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ---- MAIN BUILD ----
  @override
  Widget build(BuildContext context) {
    // TRIPLE StreamBuilder:
    // 1) User doc — name, commission%, balance (maagilJama / thakbaki)
    // 2) Bets — real-time, filtered by _selectedDate (dhanda + payment from won bets)
    // 3) Transactions — vasuli (collected from agent) & vatap (paid to agent) for selected date
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        // --- User data ---
        String userName = "User";
        double thakbaki = 0.0;    // Previous outstanding balance (manually set by admin)
        double commissionPct = 10.0;

        if (userSnap.hasData && userSnap.data!.exists) {
          final uData = userSnap.data!.data() as Map<String, dynamic>;
          userName = uData['name'] ?? (uData['email'] as String?)?.split('@')[0] ?? 'User';
          // 'balance' = admin ka manually maintained balance (outstanding dues)
          thakbaki = (uData['balance'] as num?)?.toDouble() ?? 0.0;
          if (uData.containsKey('commission')) {
            commissionPct = (uData['commission'] as num).toDouble();
          }
        }

        final double commissionRate = commissionPct / 100.0;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(t('official_receipt'), style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  DateFormat('dd MMM yyyy').format(_selectedDate),
                  style: const TextStyle(color: kPrimary, fontSize: 13),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              if (_selectedDate.year != DateTime.now().year ||
                  _selectedDate.month != DateTime.now().month ||
                  _selectedDate.day != DateTime.now().day)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  tooltip: "Today",
                  onPressed: () => setState(() => _selectedDate = DateTime.now()),
                ),
              IconButton(
                icon: const Icon(Icons.calendar_month, color: kPrimary),
                tooltip: "Change Date",
                onPressed: _pickDate,
              ),
            ],
          ),

          // ---- BETS REAL-TIME STREAM ----
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bets')
                .where('userId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: kPrimary));
              }

              // Filter bets for selected date only
              final selStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
              final selEnd = selStart.add(const Duration(days: 1));

              final filteredDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final Timestamp? ts = data['timestamp'];
                if (ts == null) return false;
                final dt = ts.toDate();
                return dt.isAfter(selStart) && dt.isBefore(selEnd);
              }).toList();

              // --- Aggregate per game ---
              final Map<String, Map<String, double>> gameStats = {};

              for (final doc in filteredDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final String game = data['gameName'] ?? 'Unknown';
                final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                // Payment only from WON bets — updates live when admin declares result
                final double payment = data['status'] == 'won'
                    ? (data['potentialWin'] as num?)?.toDouble() ?? 0.0
                    : 0.0;

                gameStats.putIfAbsent(game, () => {'dhanda': 0.0, 'payment': 0.0});
                gameStats[game]!['dhanda'] = gameStats[game]!['dhanda']! + amount;
                gameStats[game]!['payment'] = gameStats[game]!['payment']! + payment;
              }

              // --- Totals ---
              double totalDhanda = 0;
              double totalPayment = 0;
              gameStats.forEach((_, v) {
                totalDhanda += v['dhanda']!;
                totalPayment += v['payment']!;
              });

              final double commission = totalDhanda * commissionRate;
              final double netDhanda = totalDhanda - commission;
              // आजची बाकी = net dhanda - win payments
              final double aajchiBaki = netDhanda - totalPayment;

              // ---- TRANSACTIONS STREAM (vasuli + vatap) ----
              // Nested StreamBuilder for same-date admin transactions
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('userId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, txSnap) {
                  double vasuli = 0.0; // Agent ne admin ko cash diya (type: 'deduct')
                  double vatap = 0.0;  // Admin ne agent ko cash diya (type: 'add') — sirf manual payment

                  if (txSnap.hasData) {
                    for (final doc in txSnap.data!.docs) {
                      final d = doc.data() as Map<String, dynamic>;
                      final Timestamp? ts = d['timestamp'];
                      if (ts == null) continue;
                      final dt = ts.toDate();
                      if (!dt.isAfter(selStart) || !dt.isBefore(selEnd)) continue;

                      final double amt = (d['amount'] as num?)?.toDouble() ?? 0.0;
                      final String type = d['type'] ?? '';

                      if (type == 'deduct') {
                        // Agent ne admin ko cash diya — vasuli
                        vasuli += amt.abs();
                      } else if (type == 'add') {
                        // Admin ne agent ko cash diya — vatap (sirf manual payment)
                        vatap += amt.abs();
                      }
                      // 'win' type nahi hai — win sirf limit badhata hai, vasuli/vatap nahi
                    }
                  }

                  // अंतिम बाकी = थकबाकी + आजची बाकी - वसुली + वाटप
                  // Logic: previous dues + today's net baki - what agent paid + what admin paid
                  final double ekunBaki = thakbaki + aajchiBaki;
                  final double antimbaki = ekunBaki - vasuli + vatap;

                  // ---- EMPTY STATE ----
                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            "${DateFormat('dd MMM yyyy').format(_selectedDate)} रोजी कोणतीही बेट नाही",
                            style: const TextStyle(color: Colors.grey, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month, color: kPrimary),
                            label: const Text("दुसरी तारीख निवडा", style: TextStyle(color: kPrimary)),
                          ),
                        ],
                      ),
                    );
                  }

                  // ---- SLIP UI ----
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Header
                        Center(child: Text(t('title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black))),
                        Center(child: Text(userName, style: const TextStyle(color: kPrimary, fontSize: 15, fontWeight: FontWeight.w600))),
                        Center(child: Text(t('official_receipt'), style: const TextStyle(color: Colors.grey, fontSize: 13))),
                        const Divider(color: Colors.black, thickness: 1.2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${t('date')}: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}", style: const TextStyle(color: Colors.black, fontSize: 13)),
                            Text("${t('id')}: ...${uid.substring(0, 5)}", style: const TextStyle(color: Colors.black, fontSize: 13)),
                          ],
                        ),
                        const Divider(color: Colors.black, thickness: 1.2),
                        const SizedBox(height: 8),

                        // Column Headers: Game | Dhanda | Payment
                        Row(
                          children: [
                            Expanded(flex: 3, child: Text(t('game'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14))),
                            Expanded(flex: 2, child: Text(t('dhanda'), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14))),
                            Expanded(flex: 2, child: Text(t('payment'), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14))),
                          ],
                        ),
                        const Divider(color: Colors.black),

                        // Game rows
                        ...gameStats.entries.map((e) {
                          final bool hasPendingBets = filteredDocs.any((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return d['gameName'] == e.key && d['status'] == 'pending';
                          });
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Flexible(child: Text(e.key, style: const TextStyle(color: Colors.black, fontSize: 13))),
                                      if (hasPendingBets) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                                          child: const Text("pending", style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Expanded(flex: 2, child: Text(e.value['dhanda']!.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text(e.value['payment']!.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          );
                        }).toList(),

                        const Divider(color: Colors.black),

                        // Calculation rows
                        _buildCalcRow(t('total'), totalDhanda, totalPayment, isBold: true),
                        _buildCalcRow('कमिशन (${commissionPct.toStringAsFixed(0)}%)', commission, null),
                        _buildCalcRow(t('total'), netDhanda, totalPayment, isBold: true),

                        const SizedBox(height: 12),

                        // ---- आजची बाकी (BAKI) — purple strip ----
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: kPurpleLedger,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t('baki'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(aajchiBaki.toStringAsFixed(2), style: TextStyle(
                                color: aajchiBaki >= 0 ? Colors.greenAccent.shade100 : Colors.red.shade200,
                                fontSize: 18, fontWeight: FontWeight.bold,
                              )),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // मागील जमा + आजचे जमा
                        _buildFinalRow(t('prev_baki'), thakbaki, Colors.black87),
                        _buildFinalRow(t('today_baki'), aajchiBaki, aajchiBaki >= 0 ? Colors.green.shade700 : Colors.red.shade700),

                        // एकूण बाकी box
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: ekunBaki >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                            border: Border.all(color: ekunBaki >= 0 ? Colors.green.shade300 : Colors.red.shade300, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t('total_baki'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                              Text(ekunBaki.toStringAsFixed(2), style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold,
                                color: ekunBaki >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                              )),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        const Divider(color: Colors.black12, thickness: 1),

                        // ---- थकबाकी (outstanding) ----
                        _buildFinalRow(t('outstanding'), thakbaki, Colors.black87),

                        // ---- वसुली / वाटप — GREEN background ----
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676), // Bright green like video
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Column(
                            children: [
                              // वसुली row
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(t('vasuli'), style: const TextStyle(
                                      color: Color(0xFF1A237E), fontSize: 17, fontWeight: FontWeight.bold,
                                    )),
                                    Text(vasuli.toStringAsFixed(0), style: const TextStyle(
                                      color: Color(0xFFB71C1C), fontSize: 17, fontWeight: FontWeight.bold,
                                    )),
                                  ],
                                ),
                              ),
                              const Divider(color: Colors.white38, height: 1),
                              // वाटप row
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(t('vatap'), style: const TextStyle(
                                      color: Color(0xFF1A237E), fontSize: 17, fontWeight: FontWeight.bold,
                                    )),
                                    Text(vatap.toStringAsFixed(0), style: const TextStyle(
                                      color: Color(0xFFB71C1C), fontSize: 17, fontWeight: FontWeight.bold,
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ---- अंतिम बाकी ----
                        _buildFinalRow(t('final_baki'), antimbaki, antimbaki >= 0 ? Colors.green.shade800 : Colors.red.shade800),

                        // Pending bets notice
                        if (filteredDocs.any((d) => (d.data() as Map<String, dynamic>)['status'] == 'pending')) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              border: Border.all(color: Colors.orange.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline, color: Colors.orange, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "काही बेट्स अजून Pending आहेत. Admin निकाल जाहीर केल्यावर Payment आपोआप अपडेट होईल.",
                                    style: TextStyle(color: Colors.orange, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        Center(child: Text(t('thank_you'), style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                        const SizedBox(height: 16),

                        // PDF Download button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: Text(t('download_pdf'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _generateAndPrintPDF(
                              context: context,
                              gameStats: gameStats,
                              totalDhanda: totalDhanda,
                              totalPayment: totalPayment,
                              commission: commission,
                              baki: aajchiBaki,
                              maagilJama: thakbaki,
                              ekunBaki: ekunBaki,
                              userName: userName,
                              commissionPct: commissionPct,
                              vasuli: vasuli,
                              vatap: vatap,
                              antimbaki: antimbaki,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 5. GAME SPECIFIC LEDGER SCREEN
// -----------------------------------------------------------------------------
class GameLedgerScreen extends StatefulWidget {
  final String uid;
  final String gameId;
  final String gameName;
  final Function(String) t;

  const GameLedgerScreen({super.key, required this.uid, required this.gameId, required this.gameName, required this.t});

  @override
  State<GameLedgerScreen> createState() => _GameLedgerScreenState();
}

class _GameLedgerScreenState extends State<GameLedgerScreen> {
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
            colorScheme: const ColorScheme.light(
              primary: kPrimary, 
              onPrimary: Colors.white, 
              surface: Colors.white, 
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

  Widget _buildLedgerRow(String title, double amount, {double? betAmount, bool isBold = false, Color bgColor = Colors.transparent}) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(
            fontSize: 16,
            color: isBold ? const Color(0xFF311B92) : const Color(0xFF311B92),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal
          )),
          if (betAmount != null)
            // Image format: "betAmount.00 = Rs.winAmount" - betAmount on left, winAmount on right
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  betAmount.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 16, color: Color(0xFFD32F2F), fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Text(
                  "= Rs.${amount.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ],
            )
          else
            Text(
              amount.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFFD32F2F),
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 20, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTotalRow(String title, double amount, {Color bgColor = Colors.transparent}) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, color: Color(0xFF311B92), fontWeight: FontWeight.bold)),
          Text(amount.toStringAsFixed(2), style: const TextStyle(fontSize: 18, color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, double amount, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 15, color: Colors.black87, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 15,
              color: valueColor ?? (amount >= 0 ? Colors.green.shade700 : Colors.red.shade700),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
      builder: (context, userSnapshot) {
        String headerName = "Loading...";
        String headerResult = "---";
        double maagilJama = 0.0;
        double customComm = 0.10;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var uData = userSnapshot.data!.data() as Map<String, dynamic>;
          headerName = uData['name'] ?? (uData['email'] as String?)?.split('@')[0] ?? "User";
          headerResult = uData['phone'] ?? widget.uid.substring(0, 6);
          maagilJama = (uData['balance'] ?? 0).toDouble();
          if (uData.containsKey('commission')) customComm = (uData['commission'] as num).toDouble() / 100;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(headerName, style: const TextStyle(color: kPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  _selectedDate != null ? DateFormat('dd MMM yyyy').format(_selectedDate!) : headerResult,
                  style: const TextStyle(color: kTextSub, fontSize: 14),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: Colors.black),
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
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bets')
                .where('userId', isEqualTo: widget.uid)
                .where('gameId', isEqualTo: widget.gameId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kPrimary));
              }

              var docs = snapshot.data?.docs ?? [];

              // Date filter
              if (_selectedDate != null) {
                docs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  Timestamp? ts = data['timestamp'];
                  if (ts == null) return false;
                  DateTime dt = ts.toDate();
                  return dt.year == _selectedDate!.year &&
                      dt.month == _selectedDate!.month &&
                      dt.day == _selectedDate!.day;
                }).toList();
              } else {
                final now = DateTime.now();
                docs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  Timestamp? ts = data['timestamp'];
                  if (ts == null) return false;
                  DateTime dt = ts.toDate();
                  return dt.year == now.year && dt.month == now.month && dt.day == now.day;
                }).toList();
              }

              // --- ALSO fetch game result for header display ---
              // Aggregate calculations
              double openDhanda = 0, closeDhanda = 0;
              double openSinglePay = 0, openSingleBet = 0;
              double closeSinglePay = 0, closeSingleBet = 0;
              double closeSPPay = 0, closeSPBet = 0;
              double closeDPPay = 0, closeDPBet = 0;
              double closeTPPay = 0, closeTPBet = 0;
              double jodiPay = 0, jodiBet = 0;

              // Open Panna broken into SP/DP/TP
              double openSPPay = 0, openSPBet = 0;
              double openDPPay = 0, openDPBet = 0;
              double openTPPay = 0, openTPBet = 0;

              for (var doc in docs) {
                var data = doc.data() as Map<String, dynamic>;
                double amount = (data['amount'] ?? 0).toDouble();
                // Only won bets contribute to payment
                double winAmt = data['status'] == 'won' ? (data['potentialWin'] ?? 0).toDouble() : 0.0;
                String type = data['betType'] ?? '';
                String session = data['session'] ?? 'Open';

                if (session == 'Open') openDhanda += amount;
                else closeDhanda += amount;

                if (type == 'Single Digit') {
                  if (session == 'Open') { openSingleBet += amount; openSinglePay += winAmt; }
                  else { closeSingleBet += amount; closeSinglePay += winAmt; }
                } else if (type == 'Single Panna') {
                  if (session == 'Open') { openSPBet += amount; openSPPay += winAmt; }
                  else { closeSPBet += amount; closeSPPay += winAmt; }
                } else if (type == 'Double Panna') {
                  if (session == 'Open') { openDPBet += amount; openDPPay += winAmt; }
                  else { closeDPBet += amount; closeDPPay += winAmt; }
                } else if (type == 'Triple Panna') {
                  if (session == 'Open') { openTPBet += amount; openTPPay += winAmt; }
                  else { closeTPBet += amount; closeTPPay += winAmt; }
                } else if (type == 'Jodi Digit') {
                  jodiBet += amount;
                  jodiPay += winAmt;
                }
              }

              // Combined Panna totals for display
              double openPannaBet = openSPBet + openDPBet + openTPBet;
              double openPannaPay = openSPPay + openDPPay + openTPPay;
              double closePannaBet = closeSPBet + closeDPBet + closeTPBet;
              double closePannaPay = closeSPPay + closeDPPay + closeTPPay;

              double totalDhanda = openDhanda + closeDhanda;
              double commission = totalDhanda * customComm;
              double totalWinPayment = openSinglePay + openPannaPay + closeSinglePay + closePannaPay + jodiPay;
              double totalJama = totalWinPayment + commission;
              double baki = totalDhanda - totalJama;
              double ekunJama = maagilJama + baki;

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        _selectedDate != null
                            ? "${DateFormat('dd MMM yyyy').format(_selectedDate!)} रोजी कोणतीही बेट नाही"
                            : "आज कोणतीही बेट नाही",
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ===================== DHANDA SECTION =====================
                    _buildSectionHeader("धंदा"),
                    const Divider(height: 1, color: Colors.black12, indent: 16, endIndent: 16),
                    _buildLedgerRow("Open Dhanda", openDhanda),
                    _buildLedgerRow("Close Dhanda", closeDhanda),
                    _buildLedgerRow("Fer Amount", 0.00),
                    _buildTotalRow("Total Naave", totalDhanda, bgColor: Colors.grey.shade100),

                    // ===================== PAYMENT SECTION =====================
                    _buildSectionHeader("पेमेंट"),
                    const Divider(height: 1, color: Colors.black12, indent: 16, endIndent: 16),
                    _buildLedgerRow("Open Single", openSinglePay, betAmount: openSingleBet),
                    if (openSPBet > 0 || openSPPay > 0)
                      _buildLedgerRow("Open SP (Single Panna)", openSPPay, betAmount: openSPBet),
                    if (openDPBet > 0 || openDPPay > 0)
                      _buildLedgerRow("Open DP (Double Panna)", openDPPay, betAmount: openDPBet),
                    if (openTPBet > 0 || openTPPay > 0)
                      _buildLedgerRow("Open TP (Triple Panna)", openTPPay, betAmount: openTPBet),
                    if (openSPBet == 0 && openDPBet == 0 && openTPBet == 0)
                      _buildLedgerRow("Open Pana", openPannaPay, betAmount: openPannaBet),
                    _buildLedgerRow("Jodi", jodiPay, betAmount: jodiBet),
                    _buildLedgerRow("Close Single", closeSinglePay, betAmount: closeSingleBet),
                    if (closeSPBet > 0 || closeSPPay > 0)
                      _buildLedgerRow("Close SP (Single Panna)", closeSPPay, betAmount: closeSPBet),
                    if (closeDPBet > 0 || closeDPPay > 0)
                      _buildLedgerRow("Close DP (Double Panna)", closeDPPay, betAmount: closeDPBet),
                    if (closeTPBet > 0 || closeTPPay > 0)
                      _buildLedgerRow("Close TP (Triple Panna)", closeTPPay, betAmount: closeTPBet),
                    if (closeSPBet == 0 && closeDPBet == 0 && closeTPBet == 0)
                      _buildLedgerRow("Close Pana", closePannaPay, betAmount: closePannaBet),
                    _buildLedgerRow("Commission (${(customComm * 100).toStringAsFixed(0)}%)", commission),
                    _buildLedgerRow("Fer Amount", 0.00),
                    _buildTotalRow("Total Jama", totalJama, bgColor: Colors.grey.shade100),

                    // ===================== BAKI SECTION =====================
                    const SizedBox(height: 8),
                    const Divider(thickness: 1.5, color: Colors.black26),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        color: baki >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                        border: Border.all(color: baki >= 0 ? Colors.green.shade300 : Colors.red.shade300, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("बाकी (Baki)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: baki >= 0 ? Colors.green.shade800 : Colors.red.shade800)),
                              Text(baki.toStringAsFixed(2), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: baki >= 0 ? Colors.green.shade800 : Colors.red.shade800)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            baki >= 0 ? "Admin को देना है: ₹${baki.toStringAsFixed(2)}" : "Admin से लेना है: ₹${baki.abs().toStringAsFixed(2)}",
                            style: TextStyle(fontSize: 12, color: baki >= 0 ? Colors.green.shade700 : Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),
                    _buildSummaryRow("मागील जमा (Prev Balance)", maagilJama, valueColor: Colors.black87),
                    _buildSummaryRow("आजची बाकी (Today Baki)", baki, valueColor: baki >= 0 ? Colors.green.shade700 : Colors.red.shade700),
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B1FA2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("एकूण जमा (Total)", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(ekunJama.toStringAsFixed(2), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ChatTab extends StatefulWidget {
  final String uid;
  final Function(String) t;
  const ChatTab({super.key, required this.uid, required this.t});
  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _msgController = TextEditingController();
  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    FirebaseFirestore.instance.collection('chats').doc(widget.uid).collection('messages').add({'text': _msgController.text.trim(), 'sender': 'user', 'type': 'text', 'timestamp': FieldValue.serverTimestamp()});
    FirebaseFirestore.instance.collection('chats').doc(widget.uid).set({'lastMessage': _msgController.text.trim(), 'lastUpdated': FieldValue.serverTimestamp(), 'userId': widget.uid}, SetOptions(merge: true));
    _msgController.clear();
  }
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').doc(widget.uid).collection('messages').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(reverse: true, itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map;
            bool isMe = data['sender'] == 'user';
            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, 
              child: Container(
                margin: const EdgeInsets.all(8), 
                padding: const EdgeInsets.all(12), 
                decoration: BoxDecoration(
                  color: isMe ? kWABubbleSelf : Colors.white, 
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]
                ), 
                child: Text(data['text'] ?? '', style: const TextStyle(color: kTextMain))
              )
            );
          });
        },
      )),
      Padding(
        padding: const EdgeInsets.all(8), 
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _msgController, 
              style: const TextStyle(color: kTextMain), 
              decoration: InputDecoration(
                filled: true, 
                fillColor: Colors.white, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), 
                hintText: widget.t('type_msg'), 
                hintStyle: const TextStyle(color: kTextSub)
              )
            )
          ), 
          const SizedBox(width: 8), 
          CircleAvatar(
            backgroundColor: kPrimary, 
            child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage)
          )
        ])
      )
    ]);
  }
}

// -----------------------------------------------------------------------------
// PROFILE TAB (WITH PRINTER SETTINGS ADDED)
// -----------------------------------------------------------------------------
class ProfileTab extends StatelessWidget {
  final String uid;
  final Function(String) t;
  const ProfileTab({super.key, required this.uid, required this.t});

  void _showChangePasswordDialog(BuildContext context) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, 
        title: Text(t('change_pass'), style: const TextStyle(color: kTextMain)), 
        content: TextField(
          controller: passCtrl, 
          style: const TextStyle(color: kTextMain), 
          decoration: InputDecoration(labelText: t('new_pass'), labelStyle: const TextStyle(color: kTextSub))
        ), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'), style: const TextStyle(color: kTextSub))), 
          ElevatedButton(
            onPressed: () async { 
              if (passCtrl.text.length < 6) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('pass_short')))); return; } 
              try { 
                await FirebaseAuth.instance.currentUser?.updatePassword(passCtrl.text); 
                Navigator.pop(ctx); 
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('pass_updated')), backgroundColor: kSuccess)); 
                await FirebaseAuth.instance.signOut(); 
              } catch (e) { 
                Navigator.pop(ctx); 
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${t('error')}: $e"), backgroundColor: Colors.red)); 
              } 
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white), 
            child: Text(t('update'))
          )
        ]
      )
    );
  }

  void _showPrinterSettingsDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const PrinterSettingsDialog());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimary));
        var data = snapshot.data!.data() as Map<String, dynamic>;
        
        int limit = data['limit'] ?? data['creditLimit'] ?? 0;
        bool showLimit = data['showLimitToUser'] ?? true;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20), 
          child: Column(
            children: [
              CircleAvatar(radius: 50, backgroundColor: kPrimary.withOpacity(0.1), child: const Icon(Icons.person, size: 60, color: kPrimary)), 
              const SizedBox(height: 20), 
              Text(data['email'] ?? "User", style: const TextStyle(color: kTextMain, fontSize: 22, fontWeight: FontWeight.bold)), 
              const SizedBox(height: 10), 
              Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)), child: Text(showLimit ? "Limit: ₹ $limit" : "Limit: ---", style: const TextStyle(color: kPrimary, fontSize: 20, fontWeight: FontWeight.bold))), 
              const SizedBox(height: 30), 

              // NOTIFICATIONS SECTION
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('notifications').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, notifSnap) {
                  if (!notifSnap.hasData || notifSnap.data!.docs.isEmpty) return const SizedBox();
                  
                  List<Widget> notifWidgets = [];
                  for (var doc in notifSnap.data!.docs) {
                    var nData = doc.data() as Map<String, dynamic>;
                    Timestamp? exp = nData['expiresAt'];
                    
                    if (exp != null && exp.toDate().isBefore(DateTime.now())) {
                       continue; 
                    }

                    String msg = nData['message'] ?? '';
                    Timestamp? ts = nData['timestamp'];
                    String dateStr = ts != null ? DateFormat('dd MMM, hh:mm a').format(ts.toDate()) : '';

                    notifWidgets.add(
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.notifications_active, color: kPrimary, size: 20),
                                const SizedBox(width: 8),
                                const Text("नवीन सूचना (Notification)", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
                                const Spacer(),
                                Text(dateStr, style: const TextStyle(fontSize: 10, color: kTextSub)),
                              ],
                            ),
                            const Divider(color: Colors.black12),
                            Text(msg, style: const TextStyle(color: kTextMain, fontSize: 14)),
                          ]
                        )
                      )
                    );
                  }

                  if (notifWidgets.isEmpty) return const SizedBox();

                  return Column(
                    children: [
                      ...notifWidgets,
                      const SizedBox(height: 10),
                      const Divider(color: Colors.black12),
                      const SizedBox(height: 10),
                    ]
                  );
                }
              ),

              ListTile(tileColor: Colors.white, leading: const Icon(Icons.print, color: kPrimary), title: const Text('Printer Settings (प्रिंटर सेटिंग)', style: TextStyle(color: kTextMain)), trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: kTextSub), onTap: () => _showPrinterSettingsDialog(context)),
              const SizedBox(height: 10),
              ListTile(tileColor: Colors.white, leading: const Icon(Icons.lock, color: kPrimary), title: Text(t('change_pass'), style: const TextStyle(color: kTextMain)), trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: kTextSub), onTap: () => _showChangePasswordDialog(context)), 
              const SizedBox(height: 10), 
              ListTile(tileColor: Colors.white, leading: const Icon(Icons.logout, color: kAccent), title: Text(t('logout'), style: const TextStyle(color: kAccent)), trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: kTextSub), onTap: () => FirebaseAuth.instance.signOut())
            ]
          )
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// PRINTER SETTINGS DIALOG (MANAGE & TEST PRINTER)
// -----------------------------------------------------------------------------
class PrinterSettingsDialog extends StatefulWidget {
  const PrinterSettingsDialog({super.key});
  @override
  State<PrinterSettingsDialog> createState() => _PrinterSettingsDialogState();
}

class _PrinterSettingsDialogState extends State<PrinterSettingsDialog> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    
    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      // ignore
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedAddress = prefs.getString('printer_address');

    if (savedAddress != null && devices.isNotEmpty) {
      try {
        _selectedDevice = devices.firstWhere((d) => d.address == savedAddress);
      } catch (e) {
        _selectedDevice = null;
      }
    }

    setState(() {
      _devices = devices;
      _connected = isConnected ?? false;
      _isLoading = false;
    });
  }

  Future<void> _connect() async {
    if (_selectedDevice == null) return;
    setState(() => _isLoading = true);
    try {
      await bluetooth.connect(_selectedDevice!);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('printer_address', _selectedDevice!.address!);
      setState(() => _connected = true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connected & Saved successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnect() async {
    await bluetooth.disconnect();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('printer_address');
    setState(() => _connected = false);
  }

  Future<void> _testPrint() async {
    if (_connected) {
      bluetooth.printCustom("TEST PRINT SUCCESSFUL", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom("MATKAWALA SYSTEM", 0, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connect a printer first!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Printer Settings', style: TextStyle(color: kTextMain, fontWeight: FontWeight.bold)),
      content: _isLoading 
        ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: kPrimary)))
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<BluetoothDevice>(
                dropdownColor: Colors.white,
                hint: const Text('Select Printer', style: TextStyle(color: kTextSub)),
                value: _selectedDevice,
                isExpanded: true,
                items: _devices.map((device) {
                  return DropdownMenuItem(
                    value: device,
                    child: Text(device.name ?? 'Unknown', style: const TextStyle(color: kTextMain)),
                  );
                }).toList(),
                onChanged: (device) {
                  setState(() => _selectedDevice = device);
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _connected ? Colors.red : Colors.green),
                    onPressed: _connected ? _disconnect : _connect,
                    child: Text(_connected ? 'Disconnect' : 'Connect', style: const TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    onPressed: _testPrint,
                    child: const Text('Test Print', style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: kTextSub)))
      ],
    );
  }
}