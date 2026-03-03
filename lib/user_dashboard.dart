import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:typed_data';

// --- NEW PACKAGES IMPORT FOR PRINTING ---
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- THEME COLORS (MNC Corporate Dark & Gold) ---
const Color kBgColor = Colors.white; 
const Color kCardColor = Color(0xFF1E1E1E);
const Color kPrimary = Color(0xFFFFD700); // Gold
const Color kAccent = Color(0xFFE53935); // Red
const Color kTextWhite = Colors.white;
const Color kTextGrey = Colors.white70;
const Color kSuccess = Color(0xFF00C853);
const Color kPurpleLedger = Color(0xFF7B1FA2); // For 'Baki' strip

// --- WHATSAPP THEME COLORS ---
const Color kWABg = Color(0xFF0B141A);       // Dark Background
const Color kWABubbleSelf = Color(0xFF005D4B); // Green Bubble
const Color kWAInputBg = Color(0xFF1F2C34);  // Input Bar
const Color kWAFab = Color(0xFF00A884);      // Send Button

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;
  String _selectedLang = 'mr'; // Default Marathi

  // --- TRANSLATIONS MAP ---
  final Map<String, Map<String, String>> _trans = {
    'en': {
      'title': 'MATKAWALA',
      'wallet': 'WALLET',
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
      'insufficient': 'तुमच्या खात्यात पुरेशी रक्कम नाही! (Insufficient Balance)',
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
      'wallet': 'शिल्लक',
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
      'insufficient': 'तुमच्या खात्यात पुरेशी रक्कम नाही! (Insufficient Balance)',
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
        backgroundColor: const Color(0xFF1F2C34),
        title: Text(t('title'), style: const TextStyle(color: kTextWhite, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: kPrimary),
            onSelected: _changeLanguage,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'en', child: Text('English')),
              const PopupMenuItem<String>(value: 'mr', child: Text('मराठी')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: kAccent),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1F2C34),
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: kPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: t('play')),
          BottomNavigationBarItem(icon: const Icon(Icons.grid_view), label: t('ledger')), 
          BottomNavigationBarItem(icon: const Icon(Icons.support_agent), label: t('chat')),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: t('settings')),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. HOME GAMES TAB 
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
    bool isForceClosed = data['isClosed'] ?? false;
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
        return {'status': 'UPCOMING', 'color': kSuccess, 'isOpen': true, 'msg': "${widget.t('betting_open')} @ $openStartStr"};
      }
      else if (now.isAfter(openStart) && now.isBefore(openEnd)) {
        return {'status': 'OPEN_RUNNING', 'color': Colors.green, 'isOpen': true, 'msg': widget.t('open_running')};
      }
      else if (now.isAfter(openEnd) && now.isBefore(closeStart)) {
        return {'status': 'WAITING', 'color': Colors.orange, 'isOpen': false, 'msg': widget.t('betting_closed')};
      }
      else if (now.isAfter(closeStart) && now.isBefore(closeEnd)) {
        return {'status': 'CLOSE_RUNNING', 'color': Colors.green, 'isOpen': true, 'msg': widget.t('close_running')};
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
          builder: (context, snapshot) {
            var balance = 0;
            if (snapshot.hasData && snapshot.data!.exists) {
              balance = (snapshot.data!.data() as Map<String, dynamic>)['balance'] ?? 0;
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1F2C34), Colors.black]),
                border: Border(bottom: BorderSide(color: kPrimary.withOpacity(0.3))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.t('wallet').toUpperCase(), style: const TextStyle(color: kTextGrey, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text("₹ $balance", style: const TextStyle(color: kPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('games').orderBy('order').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
              
              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: snapshot.data?.docs.length ?? 0,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  
                  var status = _getMarketStatus(data);
                  
                  return GestureDetector(
                    onTap: () {
                      if (!status['isOpen']) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status['msg'])));
                         return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChartBettingScreen(
                            uid: widget.uid,
                            gameId: doc.id,
                            gameName: data['name'],
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
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: status['color'].withOpacity(0.1), border: Border.all(color: status['color'])),
                              child: Center(child: Text(data['name'][0], style: TextStyle(color: status['color'], fontWeight: FontWeight.bold, fontSize: 22))),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['name'], style: const TextStyle(color: kTextWhite, fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 4),
                                  Text("${widget.t('open')}: ${data['openTime']}  •  ${widget.t('close')}: ${data['closeTime']}", style: const TextStyle(color: kTextGrey, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text(status['msg'], style: TextStyle(color: status['color'], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                ],
                              ),
                            ),
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
// 2. CHART BETTING SCREEN
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
  DateTime? _selectedDate;
  Timer? _realTimeSyncTimer;

  BlueThermalPrinter get bluetooth => BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
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

  Future<void> _sendMessageAndPlaceBet(String currentSession, bool isMarketOpen) async {
    if (!isMarketOpen) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Betting is currently CLOSED for this market."), backgroundColor: Colors.red));
      return;
    }

    String text = _inputCtrl.text;
    if (text.trim().isEmpty) return;

    setState(() => _sendButtonScale = 1.3);
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() => _sendButtonScale = 1.0);

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    Map<String, dynamic> userRatesData = {};
    if(userDoc.exists) {
      userRatesData = userDoc.data() as Map<String, dynamic>;
    }

    List<Map<String, dynamic>> parsedBets = _parseBets(text, currentSession, userRatesData);
    if (parsedBets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.t('no_valid_bets'))));
      return;
    }

    int msgTotal = parsedBets.fold(0, (sum, item) => sum + (item['amount'] as int));

    setState(() => _isLoading = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.uid);
      final chatRef = userRef.collection('game_chats').doc();
      String newChatId = chatRef.id;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot gameSnap = await transaction.get(FirebaseFirestore.instance.collection('games').doc(widget.gameId));
        if (gameSnap.exists) {
          var gData = gameSnap.data() as Map<String, dynamic>;
          if (gData['isClosed'] == true) throw Exception("मार्केट सध्या बंद आहे! (Market Closed by Admin)");
          
          DateTime now = DateTime.now();
          DateTime oStart = _parseTime(gData['openBetStart'] ?? '09:00 AM', now);
          DateTime oEnd = _parseTime(gData['openBetEnd'] ?? '10:00 AM', now);
          DateTime cStart = _parseTime(gData['closeBetStart'] ?? '12:00 PM', now);
          DateTime cEnd = _parseTime(gData['closeBetEnd'] ?? '02:00 PM', now);

          bool stillOpen = false;
          if (now.isAfter(oStart) && now.isBefore(oEnd)) stillOpen = true;
          else if (now.isAfter(cStart) && now.isBefore(cEnd)) stillOpen = true;

          if (!stillOpen) throw Exception("मार्केटची वेळ संपली आहे! (Time Over)");
        }

        DocumentSnapshot userSnap = await transaction.get(userRef);
        if (!userSnap.exists) throw Exception("User not found!");

        var uData = userSnap.data() as Map<String, dynamic>;
        int currentBalance = (uData['balance'] as num?)?.toInt() ?? 0;
        int limit = (uData['creditLimit'] as num?)?.toInt() ?? 0;

        if (currentBalance - msgTotal < -limit) {
          throw Exception("तुमची लिमिट संपली आहे! (Credit Limit Exceeded)");
        }

        transaction.update(userRef, {'balance': currentBalance - msgTotal});

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- PRINTING & ACTION LOGIC ---
  void _showOptions(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.white),
                title: const Text('Copy (कॉपी)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: data['text'] ?? ''));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                }
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit (बदल करा)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _editBet(data);
                }
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete (हटवा)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteBet(data);
                }
              ),
              ListTile(
                leading: const Icon(Icons.print, color: Colors.green),
                title: const Text('Print (प्रिंट करा)', style: TextStyle(color: Colors.white)),
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
        backgroundColor: kCardColor,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
      batch.update(userRef, {'balance': FieldValue.increment(refundAmount)}); 

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

  Future<BluetoothDevice?> _showPrinterSelectionDialog(List<BluetoothDevice> devices) async {
    return showDialog<BluetoothDevice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: const Text("Select Printer", style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(devices[index].name ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(devices[index].address ?? '', style: const TextStyle(color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(context, devices[index]);
                  }
                );
              }
            )
          )
        );
      }
    );
  }

  Future<void> _printBet(Map<String, dynamic> data) async {
    try {
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothScan.request();
      await Permission.locationWhenInUse.request(); 

      bool? isConnected = await bluetooth.isConnected;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedAddress = prefs.getString('printer_address');

      if (isConnected != true) {
        List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
        if (devices.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No paired bluetooth printers found!")));
          return;
        }

        BluetoothDevice? targetDevice;
        if (savedAddress != null) {
          targetDevice = devices.firstWhere(
            (d) => d.address == savedAddress, 
            orElse: () => devices.first
          );
        } else {
          targetDevice = await _showPrinterSelectionDialog(devices);
          if (targetDevice != null) {
            await prefs.setString('printer_address', targetDevice.address!);
          }
        }

        if (targetDevice == null) return;

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connecting to ${targetDevice.name}...")));
        await bluetooth.connect(targetDevice);
      }
      
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

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Printing Failed: $e"), backgroundColor: Colors.red));
    }
  }


  // --- UPDATED PARSING BETS LOGIC (ADDED 'fm' FAMILY LOGIC) ---
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
      else if (line.contains('fm')) mode = 'fm'; // NEW: Matka Family detection

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
      // If fm (Family) is used, we expect exactly a 3-digit Panna as input (e.g. 123=fm=10)
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
        
        // 3-digit panna hamesha ascending (badhte kram) me hona chahiye
        if (processedNumStr.length == 3) {
          List<String> chars = processedNumStr.split('');
          chars.sort(); 
          processedNumStr = chars.join('');
        }

        String type = _detectBetType(processedNumStr);

        // Close session mein Jodi (Double Digit) allow nahi karni hai
        if (type == 'Jodi Digit' && session == 'Close') {
          return; 
        }

        if (type != 'Unknown') {
          int applyRate = type == 'Jodi Digit' ? jRate : (type.contains('Panna') ? pRate : singleRate);
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

  // --- NEW: FAMILY CUT COMBINATION LOGIC ---
  List<Map<String, dynamic>> _generateFamilyBets(String panna, int amount, int pRate) {
    Set<String> familyPannas = {};
    List<int> digits = panna.split('').map((e) => int.parse(e)).toList();
    List<int> cuts = digits.map((d) => (d + 5) % 10).toList();

    // 8 Possible Combinations generated using bitwise logic (000 to 111)
    for (int i = 0; i < 8; i++) {
      int d1 = (i & 1) == 0 ? digits[0] : cuts[0];
      int d2 = (i & 2) == 0 ? digits[1] : cuts[1];
      int d3 = (i & 4) == 0 ? digits[2] : cuts[2];

      List<int> currentPanna = [d1, d2, d3];
      currentPanna.sort(); // Sort inside family ensures standard valid panna
      familyPannas.add(currentPanna.join('')); // Set automatically removes duplicates (e.g. for TP/DP)
    }

    return familyPannas.map((fp) {
      return {
        'number': fp,
        'amount': amount,
        'betType': _detectBetType(fp), // SP, DP or TP properly detected
        'rate': pRate // In normal matka, all panels win at panel rate
      };
    }).toList();
  }

  List<Map<String, dynamic>> _generatePannaBets(int digit, String mode, int amount, int customPannaRate) {
    List<String> pannas = [];
    String type = '';

    if (mode == 'sp') {
      type = 'Single Panna';
      pannas = _getSinglePannas(digit);
    } else if (mode == 'dp') {
      type = 'Double Panna';
      pannas = _getDoublePannas(digit);
    } else if (mode == 'tp') {
      type = 'Triple Panna';
      pannas = ["$digit$digit$digit"]; 
    }

    return pannas.map((p) => {
      'number': p,
      'amount': amount,
      'betType': type,
      'rate': customPannaRate
    }).toList();
  }

  List<String> _getSinglePannas(int digit) {
    List<String> sps = [];
    for (int i=0; i<=9; i++) {
      for (int j=i+1; j<=9; j++) {
        for (int k=j+1; k<=9; k++) {
          int sum = (i+j+k)%10;
          if (sum == (digit == 0 ? 0 : digit)) sps.add("$i$j$k");
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
        if (sum == (digit == 0 ? 0 : digit)) {
           List<int> sorted = [i, i, j]..sort();
           String p = sorted.join();
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

        return Scaffold(
          backgroundColor: kWABg,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1F2C34),
            leadingWidth: 70,
            leading: InkWell(
              onTap: () => Navigator.pop(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back, color: Colors.white),
                  const SizedBox(width: 5),
                  CircleAvatar(
                    backgroundColor: kPrimary,
                    radius: 18,
                    child: Text(titleName.isNotEmpty ? titleName[0] : 'G', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titleName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(
                      sessionDisplay == 'Closed' ? 'Closed' : (sessionDisplay == 'Open' ? widget.t('open') : widget.t('close')), 
                      style: TextStyle(color: isMarketOpen ? kPrimary : kAccent, fontSize: 13, fontWeight: FontWeight.bold)
                    ),
                    if (_selectedDate != null) ...[
                       const SizedBox(width: 8),
                       Text(
                         "(${DateFormat('dd MMM').format(_selectedDate!)})",
                         style: const TextStyle(color: Colors.grey, fontSize: 11)
                       )
                    ]
                  ],
                ),
              ],
            ),
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
                    
                    if (_selectedDate != null) {
                      docs = docs.where((doc) {
                        Timestamp? ts = (doc.data() as Map<String, dynamic>)['timestamp'];
                        if (ts == null) return false;
                        DateTime dt = ts.toDate();
                        return dt.year == _selectedDate!.year && 
                               dt.month == _selectedDate!.month && 
                               dt.day == _selectedDate!.day;
                      }).toList();
                    }

                    if (docs.isEmpty) {
                       return const Center(child: Text("कोणताही इतिहास सापडला नाही\n(No history found)", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)));
                    }

                    return ListView.builder(
                      reverse: true, 
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        var time = (data['timestamp'] as Timestamp?)?.toDate();
                        String timeStr = time != null ? DateFormat('hh:mm a').format(time) : '';
                        String dateStr = time != null ? DateFormat('dd MMM yyyy').format(time) : '';

                        return Align(
                          alignment: Alignment.centerRight,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            child: GestureDetector(
                              onLongPress: () => _showOptions(data),
                              child: Card(
                                color: kWABubbleSelf,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(data['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
                                      const SizedBox(height: 5),
                                      const Divider(color: Colors.white24, height: 10),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("Done | Game Amt- ${data['total']}.00", style: const TextStyle(color: Color(0xFFCE93D8), fontSize: 13)), 
                                          const SizedBox(width: 8),
                                          Text("$dateStr $timeStr", style: const TextStyle(color: Colors.white60, fontSize: 10)),
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
                        decoration: BoxDecoration(color: kWAInputBg, borderRadius: BorderRadius.circular(25)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(width: 15),
                            Expanded(
                              child: TextField(
                                controller: _inputCtrl,
                                enabled: isMarketOpen && !_isLoading,
                                minLines: 1,
                                maxLines: 5,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: isMarketOpen ? widget.t('type_hint') : "Betting Closed",
                                  hintStyle: const TextStyle(color: Colors.grey),
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
                      onTap: (isMarketOpen && !_isLoading) ? () => _sendMessageAndPlaceBet(sessionDisplay, isMarketOpen) : null,
                      child: AnimatedScale(
                        scale: _sendButtonScale,
                        duration: const Duration(milliseconds: 150),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: isMarketOpen ? kWAFab : Colors.grey,
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
            color: kCardColor,
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
                 return Center(child: Text(t('error'), style: const TextStyle(color: kTextGrey)));
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
                  String gameName = data['name'];
                  String hindiName = _getHindiName(gameName);
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GameLedgerScreen(uid: uid, gameId: doc.id, gameName: gameName, t: t)));
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
            color: kCardColor,
            border: Border(top: BorderSide(color: Colors.white12))
          ),
          child: ElevatedButton.icon(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => DaySlipScreen(uid: uid, t: t)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.black,
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
// 4. DAY SLIP SCREEN 
// -----------------------------------------------------------------------------
class DaySlipScreen extends StatelessWidget {
  final String uid;
  final Function(String) t;
  const DaySlipScreen({super.key, required this.uid, required this.t});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        double maagilJama = 0.0;
        if (userSnap.hasData && userSnap.data!.exists) {
          maagilJama = ((userSnap.data!.data() as Map<String, dynamic>)['balance'] ?? 0).toDouble();
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(t('official_receipt'), style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bets').where('userId', isEqualTo: uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
              
              var docs = snapshot.data!.docs;

              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);
              final todayDocs = docs.where((doc) {
                 Timestamp ts = doc['timestamp'];
                 return ts.toDate().isAfter(todayStart);
              }).toList();

              if (todayDocs.isEmpty) {
                return const Center(child: Text("No bets found for today", style: TextStyle(color: Colors.black54, fontSize: 16)));
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
              double baki = netDhanda - totalPayment;

              double ekunBaki = maagilJama + baki;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text(t('title'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black))),
                    Center(child: Text(t('official_receipt'), style: const TextStyle(color: Colors.grey))),
                    const Divider(color: Colors.black),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${t('date')}: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}", style: const TextStyle(color: Colors.black)),
                        Text("${t('id')}: ...${uid.substring(0,5)}", style: const TextStyle(color: Colors.black)),
                      ],
                    ),
                    const Divider(color: Colors.black),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(flex: 2, child: Text(t('game'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15))),
                        Expanded(flex: 1, child: Text(t('dhanda'), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15))),
                        Expanded(flex: 1, child: Text(t('payment'), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15))),
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

                    _buildCalcRow(t('total'), totalDhanda, totalPayment, isBold: true),
                    _buildCalcRow('कमिशन (10%)', commission, null),
                    _buildCalcRow(t('total'), netDhanda, totalPayment, isBold: true),

                    const SizedBox(height: 10),

                    Container(
                      color: const Color(0xFF7B1FA2),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t('baki'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(baki.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    _buildFinalRow(t('prev_baki'), maagilJama, Colors.black87),
                    _buildFinalRow(t('today_baki'), baki, Colors.black87),
                    _buildFinalRow(t('total_baki'), ekunBaki, Colors.black87),
                    _buildFinalRow(t('outstanding'), 0.00, Colors.black87),

                    const SizedBox(height: 30),
                    Center(child: Text(t('thank_you'), style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        icon: const Icon(Icons.download),
                        label: Text(t('download_pdf')),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Downloading PDF..."), backgroundColor: Colors.green)
                          );
                        },
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      }
    );
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
              primary: Colors.black, 
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

  Widget _buildLedgerRow(String title, double amount, {double? betAmount, bool isBold = false, Color bgColor = Colors.transparent}) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          if (betAmount != null)
            Row(
              children: [
                Text(amount.toStringAsFixed(2), style: const TextStyle(fontSize: 16, color: Colors.black87)),
                const SizedBox(width: 8),
                Text("= Rs.${betAmount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16, color: Colors.black54)),
              ],
            )
          else
            Text(amount.toStringAsFixed(2), style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
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
        String headerSub = "Loading...";
        double maagilJama = 0.0;
        double customComm = 0.10; 

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var uData = userSnapshot.data!.data() as Map<String, dynamic>;
          headerName = uData['name'] ?? (uData['email'] as String?)?.split('@')[0] ?? "User";
          headerSub = uData['phone'] ?? widget.uid.substring(0, 6);
          maagilJama = (uData['balance'] ?? 0).toDouble(); 
          if(uData.containsKey('commission')) customComm = (uData['commission'] as num).toDouble() / 100;
        }

        return Scaffold(
          backgroundColor: Colors.white, 
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(headerName, style: const TextStyle(color: Colors.teal, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  _selectedDate != null ? DateFormat('dd MMM yyyy').format(_selectedDate!) : headerSub,
                  style: const TextStyle(color: Colors.teal, fontSize: 14)
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
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: kPrimary));
              
              var docs = snapshot.data?.docs ?? [];
              
              if (_selectedDate != null) {
                docs = docs.where((doc) {
                  Timestamp? ts = doc['timestamp'];
                  if (ts == null) return false;
                  DateTime dt = ts.toDate();
                  return dt.year == _selectedDate!.year && dt.month == _selectedDate!.month && dt.day == _selectedDate!.day;
                }).toList();
              } else {
                final now = DateTime.now();
                docs = docs.where((doc) {
                  Timestamp? ts = doc['timestamp'];
                  if (ts == null) return false;
                  DateTime dt = ts.toDate();
                  return dt.year == now.year && dt.month == now.month && dt.day == now.day;
                }).toList();
              }

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

                if (winAmt > 0) {
                  if (type.contains('Single Digit')) {
                    if (session == 'Open') { openSinglePay += winAmt; openSingleBet += amount; }
                    else { closeSinglePay += winAmt; closeSingleBet += amount; }
                  } else if (type.contains('Panna')) {
                    if (session == 'Open') { openPannaPay += winAmt; openPannaBet += amount; }
                    else { closePannaPay += winAmt; closePannaBet += amount; }
                  } else if (type.contains('Jodi')) {
                    jodiPay += winAmt; jodiBet += amount;
                  }
                }
              }

              double totalDhanda = openDhanda + closeDhanda;
              double commission = totalDhanda * customComm; 
              double totalPayment = openSinglePay + openPannaPay + closeSinglePay + closePannaPay + jodiPay;
              double totalJama = totalPayment + commission;
              double baki = totalDhanda - totalJama;
              
              double ekunJama = maagilJama + baki;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 20, bottom: 10),
                      child: Text("धंदा", style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    _buildLedgerRow("ओपन धंदा", openDhanda),
                    _buildLedgerRow("क्लोज धंदा", closeDhanda),
                    _buildLedgerRow("फेर अमाउंट", 0.00),
                    _buildLedgerRow("टोटल नावे", totalDhanda, bgColor: Colors.grey.shade200),

                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 20, bottom: 10),
                      child: Text("पेमेंट", style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    _buildLedgerRow("ओपन सिंगल", openSinglePay, betAmount: openSingleBet),
                    _buildLedgerRow("ओपन पाना", openPannaPay, betAmount: openPannaBet),
                    _buildLedgerRow("जोड", jodiPay, betAmount: jodiBet),
                    _buildLedgerRow("क्लोज सिंगल", closeSinglePay, betAmount: closeSingleBet),
                    _buildLedgerRow("क्लोज पाना", closePannaPay, betAmount: closePannaBet),
                    _buildLedgerRow("कमिशन", commission),
                    _buildLedgerRow("फेर अमाउंट", 0.00),
                    _buildLedgerRow("टोटल जमा", totalJama, bgColor: Colors.grey.shade200),

                    const SizedBox(height: 10),
                    
                    _buildLedgerRow("टोटल धंदा", totalDhanda, isBold: true),
                    _buildLedgerRow("टोटल पेमेंट", totalJama, isBold: true),
                    _buildLedgerRow("बाकी", baki, isBold: true),
                    const Divider(),
                    _buildLedgerRow("मागील जमा", maagilJama),
                    _buildLedgerRow("बाकी", baki),
                    _buildLedgerRow("एकूण जमा", ekunJama, isBold: true),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
        );
      }
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
            return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isMe ? const Color(0xFF005D4B) : const Color(0xFF2A3942), borderRadius: BorderRadius.circular(10)), child: Text(data['text'] ?? '', style: const TextStyle(color: Colors.white))));
          });
        },
      )),
      Padding(padding: const EdgeInsets.all(8), child: Row(children: [Expanded(child: TextField(controller: _msgController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: const Color(0xFF2A3942), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), hintText: widget.t('type_msg'), hintStyle: const TextStyle(color: Colors.grey)))), const SizedBox(width: 8), CircleAvatar(backgroundColor: kPrimary, child: IconButton(icon: const Icon(Icons.send, color: Colors.black), onPressed: _sendMessage))]))
    ]);
  }
}

class ProfileTab extends StatelessWidget {
  final String uid;
  final Function(String) t;
  const ProfileTab({super.key, required this.uid, required this.t});

  void _showChangePasswordDialog(BuildContext context) {
    final passCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: kCardColor, title: Text(t('change_pass'), style: const TextStyle(color: Colors.white)), content: TextField(controller: passCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: t('new_pass'), labelStyle: const TextStyle(color: Colors.grey))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))), ElevatedButton(onPressed: () async { if (passCtrl.text.length < 6) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('pass_short')))); return; } try { await FirebaseAuth.instance.currentUser?.updatePassword(passCtrl.text); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('pass_updated')), backgroundColor: kSuccess)); await FirebaseAuth.instance.signOut(); } catch (e) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${t('error')}: $e"), backgroundColor: Colors.red)); } }, style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.black), child: Text(t('update')))]));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kPrimary));
        var data = snapshot.data!.data() as Map<String, dynamic>;
        return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [const CircleAvatar(radius: 50, backgroundColor: kCardColor, child: Icon(Icons.person, size: 60, color: kPrimary)), const SizedBox(height: 20), Text(data['email'] ?? "User", style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: kPrimary)), child: Text("${t('wallet')}: ₹ ${data['balance']}", style: const TextStyle(color: kPrimary, fontSize: 20, fontWeight: FontWeight.bold))), const SizedBox(height: 30), ListTile(tileColor: kCardColor, leading: const Icon(Icons.lock, color: Colors.white), title: Text(t('change_pass'), style: const TextStyle(color: Colors.white)), trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), onTap: () => _showChangePasswordDialog(context)), const SizedBox(height: 10), ListTile(tileColor: kCardColor, leading: const Icon(Icons.logout, color: Colors.redAccent), title: Text(t('logout'), style: const TextStyle(color: Colors.redAccent)), onTap: () => FirebaseAuth.instance.signOut())]));
      },
    );
  }
}