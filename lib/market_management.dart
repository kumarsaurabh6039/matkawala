import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// --- THEME COLORS ---
const Color _kPrimary  = Color(0xFF1A237E);
const Color _kSuccess  = Color(0xFF00897B);
const Color _kAccent   = Color(0xFFD32F2F);
const Color _kBg       = Color(0xFFF0F2F5);
const Color _kTextMain = Color(0xFF1A1A1A);
const Color _kTextGrey = Color(0xFF6B7280);
const Color _kCardBg   = Colors.white;

// =============================================================================
// FIRESTORE STRUCTURE:
//
//   games/{gameId}              → name, order   (SuperAdmin manage karta hai)
//
//   game_settings/{adminId}_{gameId}
//     → adminId, gameId, gameName
//     → openBetStart, openBetEnd, closeBetStart, closeBetEnd
//     → openTime, closeTime
//     → result, isClosed, openLocked, closeLocked
//                               (Har Admin apna alag settings document)
//
// User ke paas: createdBy = adminId
// User dashboard: game_settings where adminId == user.createdBy
// =============================================================================

String _settingsId(String adminId, String gameId) => '${adminId}_$gameId';

// =============================================================================
// MARKET MANAGE PAGE
//   isSuperAdmin = true  → FAB dikhega (market create), Delete button dikhega
//   isSuperAdmin = false → Admin: sirf apni settings manage kare
// =============================================================================
class MarketManagePage extends StatelessWidget {
  final bool isSuperAdmin;
  const MarketManagePage({super.key, this.isSuperAdmin = false});

  void _showAddMarketDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.storefront_rounded, color: _kPrimary, size: 22),
          SizedBox(width: 10),
          Text('नवीन मार्केट जोडा',
              style: TextStyle(color: _kTextMain, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: _kTextMain, fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'मार्केटचे नाव (Market Name)',
            labelStyle: const TextStyle(color: _kTextGrey),
            hintText: 'उदा: KALYAN',
            filled: true, fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kPrimary, width: 2)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('रद्द करा', style: TextStyle(color: _kTextGrey))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('तयार करा', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                // SuperAdmin sirf naam + order save karta hai — koi adminId nahi
                FirebaseFirestore.instance.collection('games').add({
                  'name':  nameCtrl.text.trim().toUpperCase(),
                  'order': DateTime.now().millisecondsSinceEpoch,
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${nameCtrl.text.trim().toUpperCase()} मार्केट जोडले!'),
                  backgroundColor: _kSuccess, behavior: SnackBarBehavior.floating,
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMarketDialog(context),
              backgroundColor: _kPrimary, foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('नवीन मार्केट', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('games').orderBy('order').snapshots(),
        builder: (context, gamesSnap) {
          if (gamesSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kPrimary));
          }
          if (!gamesSnap.hasData || gamesSnap.data!.docs.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('कोणतेही मार्केट नाही', style: TextStyle(color: _kTextGrey, fontSize: 16)),
                if (isSuperAdmin) ...[
                  const SizedBox(height: 8),
                  const Text('वरील + बटणाने मार्केट जोडा', style: TextStyle(color: _kTextGrey, fontSize: 13)),
                ],
              ]),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: gamesSnap.data!.docs.length,
            itemBuilder: (context, index) {
              final gameDoc  = gamesSnap.data!.docs[index];
              final gameData = gameDoc.data() as Map<String, dynamic>;
              final gameId   = gameDoc.id;
              final gameName = gameData['name']?.toString() ?? 'Market';

              // Current admin ki settings stream
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('game_settings')
                    .doc(_settingsId(currentAdminId, gameId))
                    .snapshots(),
                builder: (context, settingsSnap) {
                  Map<String, dynamic> settings = {};
                  if (settingsSnap.hasData && settingsSnap.data!.exists) {
                    settings = settingsSnap.data!.data() as Map<String, dynamic>;
                  }
                  return _MarketCard(
                    gameId: gameId, gameName: gameName,
                    adminId: currentAdminId, settings: settings,
                    isSuperAdmin: isSuperAdmin,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// =============================================================================
// MARKET CARD
// =============================================================================
class _MarketCard extends StatelessWidget {
  final String gameId, gameName, adminId;
  final Map<String, dynamic> settings;
  final bool isSuperAdmin;

  const _MarketCard({
    required this.gameId, required this.gameName, required this.adminId,
    required this.settings, required this.isSuperAdmin,
  });

  bool   get _isClosed    => settings['isClosed']    == true;
  bool   get _openLocked  => settings['openLocked']  == true;
  bool   get _closeLocked => settings['closeLocked'] == true;
  String get _result      => settings['result']?.toString()    ?? '***-**-***';
  String get _openTime    => settings['openTime']?.toString()  ?? '--:-- --';
  String get _closeTime   => settings['closeTime']?.toString() ?? '--:-- --';
  bool   get _hasSettings => settings.isNotEmpty;
  bool   get _hasFullResult => !_result.contains('*');

  Color get _statusColor {
    if (!_hasSettings)                return Colors.grey;
    if (_isClosed)                    return _kAccent;
    if (_openLocked && !_closeLocked) return Colors.orange.shade700;
    if (_closeLocked)                 return Colors.indigo.shade600;
    return _kSuccess;
  }

  String get _statusLabel {
    if (!_hasSettings)                return 'सेटिंग नाही — टायमिंग सेट करा';
    if (_isClosed)                    return 'बंद (Closed)';
    if (_openLocked && !_closeLocked) return 'ओपन बंद';
    if (_closeLocked)                 return 'क्लोज बंद';
    return 'चालू (Open)';
  }

  DocumentReference get _settingsRef =>
      FirebaseFirestore.instance.collection('game_settings').doc(_settingsId(adminId, gameId));

  Future<void> _ensureSettings() async {
    final doc = await _settingsRef.get();
    if (!doc.exists) {
      await _settingsRef.set({
        'adminId': adminId, 'gameId': gameId, 'gameName': gameName,
        'openBetStart': '09:00 AM', 'openBetEnd': '11:00 AM',
        'closeBetStart': '12:00 PM', 'closeBetEnd': '02:00 PM',
        'openTime': '11:30 AM', 'closeTime': '02:30 PM',
        'result': '***-**-***',
        'isClosed': false, 'openLocked': false, 'closeLocked': false,
      });
    }
  }

  void _toggleMarket(bool enable) async {
    await _ensureSettings();
    _settingsRef.update({'isClosed': !enable});
  }

  void _toggleOpenSession(BuildContext ctx) async {
    await _ensureSettings();
    final lock = !_openLocked;
    _settingsRef.update({'openLocked': lock});
    _snack(ctx, lock ? 'ओपन सेशन बंद केले' : 'ओपन सेशन चालू केले', lock ? _kAccent : _kSuccess);
  }

  void _toggleCloseSession(BuildContext ctx) async {
    await _ensureSettings();
    final lock = !_closeLocked;
    _settingsRef.update({'closeLocked': lock});
    _snack(ctx, lock ? 'क्लोज सेशन बंद केले' : 'क्लोज सेशन चालू केले', lock ? _kAccent : _kSuccess);
  }

  void _snack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  void _showEditTimingsSheet(BuildContext context) async {
    await _ensureSettings();
    final doc = await _settingsRef.get();
    final fresh = doc.exists ? doc.data() as Map<String, dynamic> : settings;
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _EditTimingsSheet(settingsRef: _settingsRef, data: fresh, gameName: gameName),
    );
  }

  void _showResultDialog(BuildContext context) async {
    await _ensureSettings();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => _ResultDialog(
        settingsRef: _settingsRef, gameId: gameId,
        gameName: gameName, current: _result, adminId: adminId,
      ),
    );
  }

  void _showResetConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('निकाल रिसेट करायचा?',
            style: TextStyle(color: _kAccent, fontWeight: FontWeight.bold)),
        content: Text('$gameName चा निकाल पुन्हा ***-**-*** होईल.',
            style: const TextStyle(color: _kTextMain)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('रद्द करा', style: TextStyle(color: _kTextGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: Colors.white),
            onPressed: () async {
              await _ensureSettings();
              _settingsRef.update({'result': '***-**-***'});
              Navigator.pop(ctx);
            },
            child: const Text('रिसेट करा'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: _kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_forever_rounded, color: _kAccent, size: 20)),
          const SizedBox(width: 10),
          const Text('मार्केट डिलीट करायचं?',
              style: TextStyle(color: _kAccent, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(style: const TextStyle(color: _kTextMain, fontSize: 14), children: [
            const TextSpan(text: '⚠️  '),
            TextSpan(text: gameName, style: const TextStyle(fontWeight: FontWeight.bold, color: _kAccent)),
            const TextSpan(text: ' हे मार्केट कायमचे डिलीट होईल.'),
          ])),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200)),
            child: const Text('सर्व admins च्या settings पण डिलीट होतील.\nही क्रिया परत करता येणार नाही.',
                style: TextStyle(color: _kAccent, fontSize: 12)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('रद्द करा', style: TextStyle(color: _kTextGrey, fontWeight: FontWeight.w600))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('डिलीट करा', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('games').doc(gameId).delete();
                final settingsSnap = await FirebaseFirestore.instance
                    .collection('game_settings').where('gameId', isEqualTo: gameId).get();
                for (final s in settingsSnap.docs) { await s.reference.delete(); }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$gameName डिलीट झाले!'),
                    backgroundColor: _kAccent, behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'), backgroundColor: _kAccent, behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: [
        _buildHeader(context),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        _buildResultRow(),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        _buildSessionCards(context),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        _buildBottomActions(context),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.storefront_rounded, color: _kPrimary, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(gameName, style: const TextStyle(color: _kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Row(children: [
            Container(width: 7, height: 7,
                decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Flexible(child: Text(_statusLabel,
                style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
        ])),
        Column(children: [
          Transform.scale(scale: 0.85,
              child: Switch(value: !_isClosed, activeColor: _kSuccess,
                  inactiveThumbColor: _kAccent, onChanged: _toggleMarket)),
          Text(_isClosed ? 'OFF' : 'ON',
              style: TextStyle(color: _isClosed ? _kAccent : _kSuccess,
                  fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _buildResultRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        const Icon(Icons.bar_chart_rounded, color: _kTextGrey, size: 18),
        const SizedBox(width: 8),
        const Text('निकाल: ', style: TextStyle(color: _kTextGrey, fontSize: 13)),
        Expanded(child: Text(_result,
            style: TextStyle(color: _hasFullResult ? _kSuccess : _kTextMain,
                fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 2))),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _timeChip(Icons.wb_sunny_outlined, _openTime, Colors.orange.shade700),
          const SizedBox(height: 4),
          _timeChip(Icons.nights_stay_outlined, _closeTime, _kPrimary),
        ]),
      ]),
    );
  }

  Widget _timeChip(IconData icon, String time, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(time, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildSessionCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Expanded(child: _SessionCard(
          label: 'ओपन सेशन', subLabel: 'Open Session', time: _openTime,
          isLocked: _openLocked, icon: Icons.wb_sunny_rounded,
          color: Colors.orange.shade700, onToggle: () => _toggleOpenSession(context),
        )),
        const SizedBox(width: 10),
        Expanded(child: _SessionCard(
          label: 'क्लोज सेशन', subLabel: 'Close Session', time: _closeTime,
          isLocked: _closeLocked, icon: Icons.nights_stay_rounded,
          color: _kPrimary, onToggle: () => _toggleCloseSession(context),
        )),
      ]),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Expanded(child: _ActionBtn(icon: Icons.access_time_filled_rounded, label: 'टायमिंग',
            color: Colors.orange.shade700, onTap: () => _showEditTimingsSheet(context))),
        const SizedBox(width: 8),
        Expanded(child: _ActionBtn(icon: Icons.check_circle_rounded, label: 'निकाल',
            color: _kSuccess, onTap: () => _showResultDialog(context))),
        const SizedBox(width: 8),
        Expanded(child: _ActionBtn(icon: Icons.refresh_rounded, label: 'रिसेट',
            color: Colors.indigo.shade600, onTap: () => _showResetConfirm(context))),
        if (isSuperAdmin) ...[
          const SizedBox(width: 8),
          Expanded(child: _ActionBtn(icon: Icons.delete_forever_rounded, label: 'डिलीट',
              color: _kAccent, onTap: () => _showDeleteConfirm(context))),
        ],
      ]),
    );
  }
}

// =============================================================================
// SESSION CARD
// =============================================================================
class _SessionCard extends StatelessWidget {
  final String label, subLabel, time;
  final bool isLocked;
  final IconData icon;
  final Color color;
  final VoidCallback onToggle;

  const _SessionCard({required this.label, required this.subLabel, required this.time,
      required this.isLocked, required this.icon, required this.color, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLocked ? _kAccent.withOpacity(0.05) : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isLocked ? _kAccent.withOpacity(0.3) : color.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(isLocked ? Icons.lock_rounded : icon, color: isLocked ? _kAccent : color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isLocked ? _kAccent : color,
                fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(color: isLocked ? _kAccent : color,
              fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: isLocked ? _kAccent : color,
                borderRadius: BorderRadius.circular(6)),
            child: Text(isLocked ? 'बंद' : 'चालू',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }
}

// =============================================================================
// ACTION BUTTON
// =============================================================================
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(color: color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

// =============================================================================
// EDIT TIMINGS SHEET
// =============================================================================
class _EditTimingsSheet extends StatefulWidget {
  final DocumentReference settingsRef;
  final Map<String, dynamic> data;
  final String gameName;
  const _EditTimingsSheet({required this.settingsRef, required this.data, required this.gameName});

  @override
  State<_EditTimingsSheet> createState() => _EditTimingsSheetState();
}

class _EditTimingsSheetState extends State<_EditTimingsSheet> {
  bool _saving = false;

  // ── Stored as "hh:mm AM/PM" strings — always valid format ──────────────────
  late String openStart, openEnd, closeStart, closeEnd, openTime, closeTime;

  @override
  void initState() {
    super.initState();
    openStart  = widget.data['openBetStart']  ?? '09:00 AM';
    openEnd    = widget.data['openBetEnd']    ?? '11:00 AM';
    closeStart = widget.data['closeBetStart'] ?? '12:00 PM';
    closeEnd   = widget.data['closeBetEnd']   ?? '02:00 PM';
    openTime   = widget.data['openTime']      ?? '11:30 AM';
    closeTime  = widget.data['closeTime']     ?? '02:30 PM';
  }

  // ── Parse "hh:mm AM/PM" → TimeOfDay ─────────────────────────────────────────
  TimeOfDay _toTimeOfDay(String s) {
    try {
      final clean = s.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
      final m = RegExp(r'(\d{1,2}):(\d{2})(AM|PM)?').firstMatch(clean);
      if (m == null) return const TimeOfDay(hour: 9, minute: 0);
      int h = int.parse(m.group(1)!);
      int min = int.parse(m.group(2)!);
      final p = m.group(3);
      if (p == 'PM' && h != 12) h += 12;
      if (p == 'AM' && h == 12) h = 0;
      return TimeOfDay(hour: h, minute: min);
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  // ── TimeOfDay → "hh:mm AM/PM" string ────────────────────────────────────────
  String _fromTimeOfDay(TimeOfDay t) {
    final h12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '${h12.toString().padLeft(2, '0')}:$min $period';
  }

  // ── Show time picker and update field ────────────────────────────────────────
  Future<void> _pick(String current, void Function(String) onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _toTimeOfDay(current),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => onPicked(_fromTimeOfDay(picked)));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.settingsRef.update({
      'openBetStart': openStart,   'openBetEnd': openEnd,
      'closeBetStart': closeStart,  'closeBetEnd': closeEnd,
      'openTime': openTime,         'closeTime': closeTime,
    });
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('टायमिंग सेव्ह झाले!'), backgroundColor: _kSuccess, behavior: SnackBarBehavior.floating));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 8),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.access_time_filled_rounded, color: _kPrimary, size: 22),
            const SizedBox(width: 8),
            Text(widget.gameName, style: const TextStyle(color: _kTextMain, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          const Text('⚠️ सर्व वेळा Clock से सेट होंगी — टाइप नहीं होगा',
              style: TextStyle(color: Colors.orange, fontSize: 11)),
          const SizedBox(height: 20),

          // ── OPEN SESSION ───────────────────────────────────────────────────
          Text('🌅  ओपन सेशन (Open Session)',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _timePickerTile('बेट सुरू (Start)', openStart,  () => _pick(openStart,  (v) => openStart  = v))),
            const SizedBox(width: 10),
            Expanded(child: _timePickerTile('बेट बंद (End)',   openEnd,    () => _pick(openEnd,    (v) => openEnd    = v))),
          ]),
          const SizedBox(height: 10),
          _timePickerTile('ओपन रिझल्ट वेळ', openTime, () => _pick(openTime, (v) => openTime = v)),
          const SizedBox(height: 20),

          // ── CLOSE SESSION ──────────────────────────────────────────────────
          const Text('🌙  क्लोज सेशन (Close Session)',
              style: TextStyle(color: _kPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _timePickerTile('बेट सुरू (Start)', closeStart, () => _pick(closeStart, (v) => closeStart = v))),
            const SizedBox(width: 10),
            Expanded(child: _timePickerTile('बेट बंद (End)',   closeEnd,   () => _pick(closeEnd,   (v) => closeEnd   = v))),
          ]),
          const SizedBox(height: 10),
          _timePickerTile('क्लोज रिझल्ट वेळ', closeTime, () => _pick(closeTime, (v) => closeTime = v)),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'सेव्ह होत आहे...' : 'सेव्ह करा',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Time Picker tile (tap karo → clock popup) ────────────────────────────────
  Widget _timePickerTile(String label, String currentVal, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _kTextGrey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(currentVal,
                    style: const TextStyle(color: _kTextMain, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const Icon(Icons.access_time, color: _kPrimary, size: 20),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// RESULT DIALOG — Real Maharashtra Matka Style
// Open aur Close alag-alag declare karo. Single digit auto-calculate hota hai.
// Format: OpenPanna - OpenSingle CloseSingle - ClosePanna  (e.g. 128-15-369)
// =============================================================================
class _ResultDialog extends StatefulWidget {
  final DocumentReference settingsRef;
  final String gameId, gameName, current, adminId;
  const _ResultDialog({
    required this.settingsRef, required this.gameId,
    required this.gameName,   required this.current, required this.adminId,
  });

  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog> {
  final _openCtrl  = TextEditingController();
  final _closeCtrl = TextEditingController();
  bool _procOpen  = false, _procClose  = false;
  bool _editOpen  = false, _editClose  = false;
  String? _openErr, _closeErr;

  // Parsed live state from Firestore result string
  String _op = '***'; // open panna
  String _os = '*';   // open single
  String _cs = '*';   // close single
  String _cp = '***'; // close panna

  @override
  void initState() {
    super.initState();
    _parseResult(widget.current);
    // Pre-fill controllers if already declared
    if (_op != '***') _openCtrl.text  = _op;
    if (_cp != '***') _closeCtrl.text = _cp;
    // Start in edit mode only if not yet declared
    _editOpen  = (_op == '***');
    _editClose = (_cp == '***');
  }

  @override
  void dispose() {
    _openCtrl.dispose();
    _closeCtrl.dispose();
    super.dispose();
  }

  // ── Parse "OpenPanna-SingleSingle-ClosePanna" ────────────────────────────────
  void _parseResult(String r) {
    _op = '***'; _os = '*'; _cs = '*'; _cp = '***';
    final parts = r.split('-');
    if (parts.isNotEmpty) _op = parts[0];
    if (parts.length >= 2) {
      final mid = parts[1].replaceAll('*', '');
      if (mid.length == 1) _os = mid;
      if (mid.length == 2) { _os = mid[0]; _cs = mid[1]; }
    }
    if (parts.length >= 3) _cp = parts[2];
  }

  // ── Panna (3 digits) → Single digit: sum % 10 ───────────────────────────────
  String _single(String panna) {
    if (!RegExp(r'^\d{3}$').hasMatch(panna)) return '*';
    final s = panna.split('').fold(0, (a, c) => a + (int.tryParse(c) ?? 0));
    return '${s % 10}';
  }

  String get _liveOS => _single(_openCtrl.text.trim());
  String get _liveCS => _single(_closeCtrl.text.trim());

  // ── Build the result string for live display ─────────────────────────────────
  String get _displayResult {
    if (_op == '***' && _cp == '***') return '***-**-***';
    if (_cp == '***') return '$_op-${_os == '*' ? '*' : _os}-***';
    return '$_op-$_os$_cs-$_cp';
  }

  bool get _openDeclared  => _op != '***';
  bool get _closeDeclared => _cp != '***';

  // ── Confirm re-declaration ───────────────────────────────────────────────────
  Future<bool?> _confirmRedeclare(String oldR, String newR) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
          SizedBox(width: 8),
          Text('निकाल बदलायचा?',
              style: TextStyle(color: _kTextMain, fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('जुना: ', style: TextStyle(color: _kTextGrey, fontSize: 13)),
                Text(oldR, style: const TextStyle(
                    color: _kAccent, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Text('नवीन: ', style: TextStyle(color: _kTextGrey, fontSize: 13)),
                Text(newR, style: const TextStyle(
                    color: _kSuccess, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
              ]),
            ]),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200)),
            child: const Text(
              '⚠️  जुन्या जिंकलेल्या बेट्स reverse होतील आणि नव्या निकालाप्रमाणे पुन्हा गणना होईल.',
              style: TextStyle(color: _kAccent, fontSize: 12),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false),
              child: const Text('रद्द करा', style: TextStyle(color: _kTextGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('हो, बदला', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Declare Open ─────────────────────────────────────────────────────────────
  Future<void> _declareOpen() async {
    final panna = _openCtrl.text.trim();
    if (!RegExp(r'^\d{3}$').hasMatch(panna)) {
      setState(() => _openErr = '3 अंकांचा पाना टाका (उदा: 128)');
      return;
    }
    setState(() => _openErr = null);

    final single = _single(panna);

    // Build result — preserve close if already declared
    final String result = _closeDeclared
        ? '$panna-$single$_cs-$_cp'
        : '$panna-$single-***';

    // Ask confirmation if re-declaring
    if (_openDeclared && _op != panna) {
      final ok = await _confirmRedeclare(_displayResult, result);
      if (ok != true) return;
    }

    setState(() => _procOpen = true);
    try {
      await _updateResultAndProcessWins(
          context, widget.settingsRef, widget.gameId, widget.gameName, result, widget.adminId);
      if (mounted) setState(() { _op = panna; _os = single; _editOpen = false; _openErr = null; });
    } catch (e) {
      if (mounted) setState(() => _openErr = 'Error: $e');
    }
    if (mounted) setState(() => _procOpen = false);
  }

  // ── Declare Close ────────────────────────────────────────────────────────────
  Future<void> _declareClose() async {
    if (!_openDeclared) {
      setState(() => _closeErr = 'आधी ओपन जाहीर करा!');
      return;
    }
    final panna = _closeCtrl.text.trim();
    if (!RegExp(r'^\d{3}$').hasMatch(panna)) {
      setState(() => _closeErr = '3 अंकांचा पाना टाका (उदा: 369)');
      return;
    }
    setState(() => _closeErr = null);

    final single = _single(panna);
    final String result = '$_op-$_os$single-$panna';

    // Ask confirmation if re-declaring
    if (_closeDeclared && _cp != panna) {
      final ok = await _confirmRedeclare(_displayResult, result);
      if (ok != true) return;
    }

    setState(() => _procClose = true);
    try {
      await _updateResultAndProcessWins(
          context, widget.settingsRef, widget.gameId, widget.gameName, result, widget.adminId);
      if (mounted) setState(() { _cp = panna; _cs = single; _editClose = false; _closeErr = null; });
    } catch (e) {
      if (mounted) setState(() => _closeErr = 'Error: $e');
    }
    if (mounted) setState(() => _procClose = false);
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: _kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.bar_chart_rounded, color: _kSuccess, size: 20)),
          const SizedBox(width: 10),
          const Text('निकाल जाहीर करा',
              style: TextStyle(color: _kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 3),
        Text(widget.gameName,
            style: const TextStyle(color: _kPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // ── Current Result Display ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kPrimary.withOpacity(0.2)),
            ),
            child: Column(children: [
              const Text('सद्याचा निकाल',
                  style: TextStyle(color: _kTextGrey, fontSize: 11, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Text(
                _displayResult,
                style: TextStyle(
                  color: (!_openDeclared && !_closeDeclared) ? _kTextGrey : _kPrimary,
                  fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _statusDot(_openDeclared ? Colors.orange.shade700 : Colors.grey, 'ओपन'),
                const SizedBox(width: 16),
                _statusDot(_closeDeclared ? _kPrimary : Colors.grey, 'क्लोज'),
              ]),
            ]),
          ),

          const SizedBox(height: 14),

          // ── OPEN DECLARE SECTION ────────────────────────────────────────────
          _DeclareSection(
            label: 'ओपन',
            icon: Icons.wb_sunny_rounded,
            color: Colors.orange.shade700,
            isDeclared: _openDeclared,
            isEditing: _editOpen,
            declaredPanna: _op,
            declaredSingle: _os,
            ctrl: _openCtrl,
            liveSingle: _liveOS,
            error: _openErr,
            hintPanna: '128',
            previewLabel: _editOpen && _openCtrl.text.length == 3 && _liveOS != '*'
                ? '${_openCtrl.text.trim()}-$_liveOS-***'
                : null,
            isProcessing: _procOpen,
            onChanged: () => setState(() {}),
            onDeclare: _declareOpen,
            onEdit: () => setState(() { _editOpen = true; _openErr = null; }),
            onCancelEdit: () => setState(() {
              _editOpen = false;
              _openCtrl.text = _op != '***' ? _op : '';
              _openErr = null;
            }),
            blockedMsg: null,
          ),

          const SizedBox(height: 12),

          // ── CLOSE DECLARE SECTION ───────────────────────────────────────────
          _DeclareSection(
            label: 'क्लोज',
            icon: Icons.nights_stay_rounded,
            color: _kPrimary,
            isDeclared: _closeDeclared,
            isEditing: _editClose,
            declaredPanna: _cp,
            declaredSingle: _cs,
            ctrl: _closeCtrl,
            liveSingle: _liveCS,
            error: _closeErr,
            hintPanna: '369',
            previewLabel: _editClose && _openDeclared && _closeCtrl.text.length == 3 && _liveCS != '*'
                ? '$_op-$_os$_liveCS-${_closeCtrl.text.trim()}'
                : null,
            isProcessing: _procClose,
            onChanged: () => setState(() {}),
            onDeclare: _declareClose,
            onEdit: () => setState(() { _editClose = true; _closeErr = null; }),
            onCancelEdit: () => setState(() {
              _editClose = false;
              _closeCtrl.text = _cp != '***' ? _cp : '';
              _closeErr = null;
            }),
            blockedMsg: !_openDeclared ? 'आधी ओपन जाहीर करा!' : null,
          ),

        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('बंद करा', style: TextStyle(color: _kTextGrey)),
        ),
      ],
    );
  }

  Widget _statusDot(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
  ]);
}

// =============================================================================
// DECLARE SECTION WIDGET — 3 States: Not Declared / Editing / Declared+Locked
// =============================================================================
class _DeclareSection extends StatelessWidget {
  final String label, hintPanna, liveSingle;
  final String declaredPanna, declaredSingle; // current declared values
  final IconData icon;
  final Color color;
  final bool isDeclared, isEditing, isProcessing;
  final String? error, previewLabel, blockedMsg;
  final TextEditingController ctrl;
  final VoidCallback onChanged, onDeclare, onEdit, onCancelEdit;

  const _DeclareSection({
    required this.label,       required this.icon,          required this.color,
    required this.isDeclared,  required this.isEditing,     required this.isProcessing,
    required this.ctrl,        required this.hintPanna,     required this.liveSingle,
    required this.declaredPanna, required this.declaredSingle,
    required this.onChanged,   required this.onDeclare,
    required this.onEdit,      required this.onCancelEdit,
    this.error, this.previewLabel, this.blockedMsg,
  });

  @override
  Widget build(BuildContext context) {
    // ── Blocked (e.g. close before open) ────────────────────────────────────
    if (blockedMsg != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.grey.shade400, size: 17),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline, color: Colors.orange, size: 13),
              const SizedBox(width: 5),
              Text(blockedMsg!, style: const TextStyle(
                  color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      );
    }

    // ── STATE 1: Declared & NOT editing → Show result card + Edit button ────
    if (isDeclared && !isEditing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 7),
            Text('$label जाहीर झाले ✓',
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),

          // Declared result display
          Row(children: [
            // Panna box
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Text('पाना', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(declaredPanna,
                      style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 5)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            // Arrow
            Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 14),
            const SizedBox(width: 10),
            // Single digit box
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(declaredSingle,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const Text('अंक', style: TextStyle(color: Colors.white70, fontSize: 9)),
              ]),
            ),
          ]),

          const SizedBox(height: 12),

          // Edit button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: Text('$label बदला (Edit)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ]),
      );
    }

    // ── STATE 2 / 3: Not declared OR editing → Show input form ──────────────
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35), width: isEditing ? 2 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Text(
            isEditing && isDeclared ? '$label बदला' : '$label जाहीर करा',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          if (isEditing && isDeclared) ...[
            const Spacer(),
            // Cancel edit button
            GestureDetector(
              onTap: onCancelEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.close_rounded, color: _kTextGrey, size: 13),
                  SizedBox(width: 3),
                  Text('रद्द करा', style: TextStyle(color: _kTextGrey, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ]),

        // Show current declared value as reference when editing
        if (isEditing && isDeclared) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.info_outline, color: Colors.amber, size: 13),
              const SizedBox(width: 5),
              Text('जुना: $declaredPanna – $declaredSingle',
                  style: const TextStyle(
                      color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ]),
          ),
        ],

        const SizedBox(height: 12),

        // Panna input + auto single box
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              maxLength: 3,
              autofocus: isEditing,
              onChanged: (_) => onChanged(),
              style: const TextStyle(
                  color: _kTextMain, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 5),
              decoration: InputDecoration(
                counterText: '',
                labelText: 'पाना (3 अंक)',
                labelStyle: TextStyle(color: color, fontSize: 12),
                hintText: hintPanna,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 18),
                filled: true, fillColor: Colors.white,
                errorText: error,
                errorMaxLines: 2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color.withOpacity(0.4))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Auto-calculated single digit box
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: liveSingle != '*' ? color : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(liveSingle,
                  style: TextStyle(
                    color: liveSingle != '*' ? Colors.white : Colors.grey.shade400,
                    fontSize: 26, fontWeight: FontWeight.bold,
                  )),
              Text('अंक', style: TextStyle(
                  color: liveSingle != '*' ? Colors.white70 : Colors.grey.shade400, fontSize: 9)),
            ]),
          ),
        ]),

        // Live preview of full result
        if (previewLabel != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.preview_rounded, color: color, size: 14),
              const SizedBox(width: 6),
              Text(previewLabel!,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5)),
            ]),
          ),
        ],

        const SizedBox(height: 12),

        // Declare / Update button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: color, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: isProcessing ? null : onDeclare,
            icon: isProcessing
                ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(isEditing && isDeclared ? Icons.save_rounded : icon, size: 17),
            label: Text(
              isProcessing
                  ? 'जाहीर होत आहे...'
                  : (isEditing && isDeclared ? '$label अपडेट करा' : '$label जाहीर करा'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ]),
    );
  }
}
// =============================================================================
// WIN PROCESSING — Reversal + Fresh Calculation
// Jab result edit hota hai: purani wins reverse, loss reset, naya result apply
// =============================================================================
Future<void> _updateResultAndProcessWins(
    BuildContext context, DocumentReference settingsRef,
    String gameId, String gameName, String resultText, String adminId) async {
  try {
    // ── Aaj ka din ka range (midnight se ab tak) ─────────────────────────────
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayStartTs = Timestamp.fromDate(todayStart);

    // ── Step 1: Sirf is admin ke users ───────────────────────────────────────
    final usersSnap = await FirebaseFirestore.instance
        .collection('users').where('createdBy', isEqualTo: adminId).get();
    final adminUserIds = usersSnap.docs.map((d) => d.id).toSet();

    // ── Step 2: Purani WON bets reverse karo (aaj ki) ────────────────────────
    final wonBetsSnap = await FirebaseFirestore.instance
        .collection('bets')
        .where('gameId', isEqualTo: gameId)
        .where('status', isEqualTo: 'won')
        .where('timestamp', isGreaterThanOrEqualTo: todayStartTs)
        .get();

    int reversedCount = 0;
    for (final betDoc in wonBetsSnap.docs) {
      final bet    = betDoc.data();
      final userId = bet['userId']?.toString() ?? '';
      if (!adminUserIds.contains(userId)) continue;

      final winAmount  = int.tryParse(bet['potentialWin']?.toString() ?? '') ?? 0;
      // limitAdded = exactly kitna limit add hua tha jab win declare hua
      // Agar field nahi hai (purana bet) toh 0 => limit touch nahi karni
      final limitAdded = int.tryParse(bet['limitAdded']?.toString() ?? '0') ?? 0;
      reversedCount++;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final userRef  = FirebaseFirestore.instance.collection('users').doc(userId);
        final userSnap = await tx.get(userRef);
        if (userSnap.exists) {
          final uMap           = userSnap.data() as Map<String, dynamic>;
          final currentLimit   = int.tryParse(uMap['limit']?.toString()   ?? '') ?? 0;
          final currentBalance = int.tryParse(uMap['balance']?.toString() ?? '') ?? 0;
          // Exact reverse — clamp nahi, exact amount jo add hua tha
          final newBalance = currentBalance - limitAdded; // same netJama jo add hua tha
          final newLimit   = currentLimit   - limitAdded;
          tx.update(userRef, {'limit': newLimit, 'balance': newBalance});
          tx.set(FirebaseFirestore.instance.collection('transactions').doc(), {
            'userId'         : userId,
            'amount'         : -winAmount,
            'limitReversed'  : -limitAdded,
            'type'           : 'win_reversal',
            'previousBalance': currentBalance,
            'newBalance'     : newBalance,
            'previousLimit'  : currentLimit,
            'newLimit'       : newLimit,
            'timestamp'      : FieldValue.serverTimestamp(),
            'adminId'        : adminId,
            'note'           : 'Result Edit — Win Reversed: $gameName (${bet['number']})',
          });
        }
        // Bet ko wapas pending pe lao aur limitAdded reset
        tx.update(betDoc.reference, {'status': 'pending', 'limitAdded': 0});
      });
    }

    // ── Step 3: LOSS bets bhi pending pe reset karo (aaj ki) ─────────────────
    final lossBetsSnap = await FirebaseFirestore.instance
        .collection('bets')
        .where('gameId', isEqualTo: gameId)
        .where('status', isEqualTo: 'loss')
        .where('timestamp', isGreaterThanOrEqualTo: todayStartTs)
        .get();

    for (final betDoc in lossBetsSnap.docs) {
      final bet    = betDoc.data();
      final userId = bet['userId']?.toString() ?? '';
      if (!adminUserIds.contains(userId)) continue;
      await betDoc.reference.update({'status': 'pending'});
    }

    // ── Step 4: Naya result save karo ────────────────────────────────────────
    await settingsRef.update({'result': resultText});

    // ── Step 5: Result parse karo ─────────────────────────────────────────────
    String openPanna = '', openSingle = '', closeSingle = '', closePanna = '', jodi = '';
    final parts = resultText.trim().split('-');
    if (parts.isNotEmpty) openPanna = parts[0].replaceAll('*', '').trim();
    if (parts.length >= 2) {
      final mid = parts[1].replaceAll('*', '').trim();
      if (mid.length == 1) { openSingle = mid; }
      else if (mid.length == 2) { openSingle = mid[0]; closeSingle = mid[1]; jodi = mid; }
    }
    if (parts.length >= 3) closePanna = parts[2].replaceAll('*', '').trim();

    // ── Step 6: Fresh pending bets process karo (naye result se) ─────────────
    final betsQuery = await FirebaseFirestore.instance
        .collection('bets')
        .where('gameId', isEqualTo: gameId)
        .where('status', isEqualTo: 'pending')
        .where('timestamp', isGreaterThanOrEqualTo: todayStartTs)
        .get();

    int processedCount = 0;

    for (final betDoc in betsQuery.docs) {
      final bet    = betDoc.data();
      final userId = bet['userId']?.toString() ?? '';
      if (!adminUserIds.contains(userId)) continue;

      final type      = bet['betType']?.toString() ?? '';
      final session   = bet['session']?.toString() ?? 'Open';
      final num       = bet['number']?.toString() ?? '';
      final winAmount = int.tryParse(bet['potentialWin']?.toString() ?? '') ?? 0;

      bool isDecided = false, isWon = false;

      if (session == 'Open') {
        if (type.contains('Panna') && openPanna.isNotEmpty) { isDecided = true; isWon = (num == openPanna); }
        else if (type == 'Single Digit' && openSingle.isNotEmpty) { isDecided = true; isWon = (num == openSingle); }
      } else if (session == 'Close') {
        if (type.contains('Panna') && closePanna.isNotEmpty) { isDecided = true; isWon = (num == closePanna); }
        else if (type == 'Single Digit' && closeSingle.isNotEmpty) { isDecided = true; isWon = (num == closeSingle); }
      }
      if (type == 'Jodi Digit' && jodi.isNotEmpty && jodi.length == 2) { isDecided = true; isWon = (num == jodi); }

      if (isDecided) {
        processedCount++;
        final int betAmount = int.tryParse(bet['amount']?.toString() ?? '') ?? 0;
        await FirebaseFirestore.instance.runTransaction((tx) async {
          if (isWon) {
            final userRef  = FirebaseFirestore.instance.collection('users').doc(userId);
            final userSnap = await tx.get(userRef);
            if (userSnap.exists) {
              final uMap           = userSnap.data() as Map<String, dynamic>;
              final currentBalance = int.tryParse(uMap['balance']?.toString() ?? '') ?? 0;

              // ── LIMIT LOGIC ──────────────────────────────────────────────────
              // WIN declare pe: limit += netJama + betAmount
              // betAmount wapas isliye ki bet lagane par limit se deduct hua tha
              // netJama = winAmount - netBetAmount (commission cut ke baad)
              // Example: limit=5000, bet=20, comm=10%, win=3200
              //   netBet = 20*(1-0.1) = 18
              //   netJama = 3200 - 18 = 3182
              //   limitToAdd = 3182 + 20 = 3202  ← betAmount bhi wapas
              //   finalLimit = 4980 + 3202 = 8182
              // ────────────────────────────────────────────────────────────────
              final currentLimit    = int.tryParse(uMap['limit']?.toString() ?? '') ?? 0;
              final commissionPct   = double.tryParse(uMap['commission']?.toString() ?? '0') ?? 0.0;
              final commissionRate  = commissionPct / 100.0;
              // netBetAmount = commission ke baad jo admin ka dhanda bacha
              final double netBetAmt = betAmount * (1.0 - commissionRate);
              // netJama = jeeti raqam - net dhanda
              final int netJama = (winAmount - netBetAmt).round();
              // betAmount bhi wapas add karo (jo bet lagane par deduct hua tha)
              final int limitToAdd  = (netJama > 0 ? netJama : winAmount) + betAmount;
              tx.update(userRef, {
                'balance': currentBalance + limitToAdd, // Net jama (win - netDhanda)
                'limit':   currentLimit   + limitToAdd, // Net jama limit mein add
              });
              // limitAdded bet document mein store karo — reversal ke liye exact amount
              tx.update(betDoc.reference, {'limitAdded': limitToAdd});
              tx.set(FirebaseFirestore.instance.collection('transactions').doc(), {
                'userId'         : userId,
                'amount'         : winAmount,
                'betAmount'      : betAmount,
                'limitAdded'     : limitToAdd,
                'type'           : 'win',
                'previousBalance': currentBalance,
                'newBalance'     : currentBalance + limitToAdd,
                'previousLimit'  : currentLimit,
                'newLimit'       : currentLimit + limitToAdd,
                'timestamp'      : FieldValue.serverTimestamp(),
                'adminId'        : adminId,
                'note'           : 'Win: $gameName ($num)',
              });
            }
          }
          tx.update(betDoc.reference, {'status': isWon ? 'won' : 'loss'});
        });
      }
    }

    if (context.mounted) {
      final msg = reversedCount > 0
          ? '✅ निकाल बदलला! $reversedCount जुन्या wins reverse झाल्या. $processedCount बेट्स नव्याने रिझॉल्व्ह.'
          : '✅ निकाल अपडेट! $processedCount बेट्स रिझॉल्व्ह झाल्या.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: _kSuccess, behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: _kAccent, behavior: SnackBarBehavior.floating,
      ));
    }
  }
}