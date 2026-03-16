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
// MARKET MANAGE PAGE — Main Entry Point
// Usage in both admin & super-admin: const MarketManagePage()
// =============================================================================
class MarketManagePage extends StatelessWidget {
  const MarketManagePage({super.key});

  void _showAddMarketDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded, color: _kPrimary, size: 22),
            SizedBox(width: 10),
            Text('नवीन मार्केट जोडा',
                style: TextStyle(color: _kTextMain, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: _kTextMain, fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'मार्केटचे नाव (Market Name)',
            labelStyle: const TextStyle(color: _kTextGrey),
            hintText: 'उदा: KALYAN',
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kPrimary, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करा', style: TextStyle(color: _kTextGrey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('तयार करा', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                FirebaseFirestore.instance.collection('games').add({
                  'name':          nameCtrl.text.trim().toUpperCase(),
                  'openBetStart':  '09:00 AM',
                  'openBetEnd':    '11:00 AM',
                  'closeBetStart': '12:00 PM',
                  'closeBetEnd':   '02:00 PM',
                  'openTime':      '11:30 AM',
                  'closeTime':     '02:30 PM',
                  'result':        '***-**-***',
                  'isClosed':      false,
                  'openLocked':    false,
                  'closeLocked':   false,
                  'order':         DateTime.now().millisecondsSinceEpoch,
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${nameCtrl.text.trim().toUpperCase()} मार्केट जोडले!'),
                  backgroundColor: _kSuccess,
                  behavior: SnackBarBehavior.floating,
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
    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMarketDialog(context),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('नवीन मार्केट', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('games').orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kPrimary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('कोणतेही मार्केट उपलब्ध नाही',
                  style: TextStyle(color: _kTextGrey, fontSize: 16)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc  = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _MarketCard(docId: doc.id, data: data);
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
  final String               docId;
  final Map<String, dynamic> data;

  const _MarketCard({required this.docId, required this.data});

  // ── getters ──────────────────────────────────────────────────────────────
  bool   get _isClosed    => data['isClosed']    == true;
  bool   get _openLocked  => data['openLocked']  == true;
  bool   get _closeLocked => data['closeLocked'] == true;
  String get _result      => data['result']?.toString()    ?? '***-**-***';
  String get _openTime    => data['openTime']?.toString()  ?? '--:-- --';
  String get _closeTime   => data['closeTime']?.toString() ?? '--:-- --';
  String get _gameName    => data['name']?.toString()      ?? 'Market';

  bool get _hasFullResult => !_result.contains('*');

  Color get _statusColor {
    if (_isClosed)                         return _kAccent;
    if (_openLocked && !_closeLocked)      return Colors.orange.shade700;
    if (_closeLocked)                      return Colors.indigo.shade600;
    return _kSuccess;
  }

  String get _statusLabel {
    if (_isClosed)                         return 'बंद (Closed)';
    if (_openLocked && !_closeLocked)      return 'ओपन बंद';
    if (_closeLocked)                      return 'क्लोज बंद';
    return 'चालू (Open)';
  }

  // ── Firestore helpers ─────────────────────────────────────────────────────
  void _toggleMarket(bool enable) {
    FirebaseFirestore.instance.collection('games').doc(docId).update({'isClosed': !enable});
  }

  void _toggleOpenSession(BuildContext ctx) {
    final lock = !_openLocked;
    FirebaseFirestore.instance.collection('games').doc(docId).update({'openLocked': lock});
    _snack(ctx, lock ? 'ओपन सेशन बंद केले' : 'ओपन सेशन चालू केले',
        lock ? _kAccent : _kSuccess);
  }

  void _toggleCloseSession(BuildContext ctx) {
    final lock = !_closeLocked;
    FirebaseFirestore.instance.collection('games').doc(docId).update({'closeLocked': lock});
    _snack(ctx, lock ? 'क्लोज सेशन बंद केले' : 'क्लोज सेशन चालू केले',
        lock ? _kAccent : _kSuccess);
  }

  void _snack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showEditTimingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTimingsSheet(docId: docId, data: data),
    );
  }

  void _showResultDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ResultDialog(docId: docId, gameName: _gameName, current: _result),
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
        content: Text('$_gameName चा निकाल पुन्हा ***-**-*** होईल.',
            style: const TextStyle(color: _kTextMain)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करा', style: TextStyle(color: _kTextGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: Colors.white),
            onPressed: () {
              FirebaseFirestore.instance.collection('games').doc(docId).update({'result': '***-**-***'});
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_forever_rounded, color: _kAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('मार्केट डिलीट करायचं?',
                style: TextStyle(color: _kAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: _kTextMain, fontSize: 14),
                children: [
                  const TextSpan(text: '⚠️  '),
                  TextSpan(
                    text: _gameName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _kAccent),
                  ),
                  const TextSpan(text: ' हे मार्केट कायमचे डिलीट होईल.'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                'हे मार्केट आणि त्याचा सर्व डेटा कायमचा जाईल.\nही क्रिया परत करता येणार नाही.',
                style: TextStyle(color: _kAccent, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करा',
                style: TextStyle(color: _kTextGrey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('डिलीट करा', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('games').doc(docId).delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$_gameName डिलीट झाले!'),
                    backgroundColor: _kAccent,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: _kAccent,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildResultRow(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildSessionCards(context),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildBottomActions(context),
        ],
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.storefront_rounded, color: _kPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_gameName,
                    style: const TextStyle(
                        color: _kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(_statusLabel,
                        style: TextStyle(
                            color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          // Master ON/OFF
          Column(
            children: [
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: !_isClosed,
                  activeColor: _kSuccess,
                  inactiveThumbColor: _kAccent,
                  onChanged: _toggleMarket,
                ),
              ),
              Text(_isClosed ? 'OFF' : 'ON',
                  style: TextStyle(
                      color: _isClosed ? _kAccent : _kSuccess,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // ── result row ────────────────────────────────────────────────────────────
  Widget _buildResultRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, color: _kTextGrey, size: 18),
          const SizedBox(width: 8),
          const Text('निकाल: ', style: TextStyle(color: _kTextGrey, fontSize: 13)),
          Expanded(
            child: Text(
              _result,
              style: TextStyle(
                color: _hasFullResult ? _kSuccess : _kTextMain,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _timeChip(Icons.wb_sunny_outlined, _openTime, Colors.orange.shade700),
              const SizedBox(height: 4),
              _timeChip(Icons.nights_stay_outlined, _closeTime, _kPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeChip(IconData icon, String time, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(time,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── session cards ─────────────────────────────────────────────────────────
  Widget _buildSessionCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _SessionCard(
              label:    'ओपन सेशन',
              subLabel: 'Open Session',
              time:     _openTime,
              isLocked: _openLocked,
              icon:     Icons.wb_sunny_rounded,
              color:    Colors.orange.shade700,
              onToggle: () => _toggleOpenSession(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SessionCard(
              label:    'क्लोज सेशन',
              subLabel: 'Close Session',
              time:     _closeTime,
              isLocked: _closeLocked,
              icon:     Icons.nights_stay_rounded,
              color:    _kPrimary,
              onToggle: () => _toggleCloseSession(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── bottom actions ────────────────────────────────────────────────────────
  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(child: _ActionBtn(
            icon: Icons.access_time_filled_rounded, label: 'टायमिंग',
            color: Colors.orange.shade700, onTap: () => _showEditTimingsSheet(context),
          )),
          const SizedBox(width: 8),
          Expanded(child: _ActionBtn(
            icon: Icons.check_circle_rounded, label: 'निकाल',
            color: _kSuccess, onTap: () => _showResultDialog(context),
          )),
          const SizedBox(width: 8),
          Expanded(child: _ActionBtn(
            icon: Icons.refresh_rounded, label: 'रिसेट',
            color: Colors.indigo.shade600, onTap: () => _showResetConfirm(context),
          )),
          const SizedBox(width: 8),
          Expanded(child: _ActionBtn(
            icon: Icons.delete_forever_rounded, label: 'डिलीट',
            color: _kAccent, onTap: () => _showDeleteConfirm(context),
          )),
        ],
      ),
    );
  }
}

// =============================================================================
// SESSION CARD WIDGET
// =============================================================================
class _SessionCard extends StatelessWidget {
  final String       label;
  final String       subLabel;
  final String       time;
  final bool         isLocked;
  final IconData     icon;
  final Color        color;
  final VoidCallback onToggle;

  const _SessionCard({
    required this.label,
    required this.subLabel,
    required this.time,
    required this.isLocked,
    required this.icon,
    required this.color,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bg    = isLocked ? _kAccent.withOpacity(0.07)  : color.withOpacity(0.08);
    final badge = isLocked ? _kAccent : color;
    final border = isLocked ? _kAccent.withOpacity(0.4) : color.withOpacity(0.3);

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: badge, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      style: TextStyle(color: badge, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(subLabel, style: const TextStyle(color: _kTextGrey, fontSize: 10)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time,
                    style: const TextStyle(
                        color: _kTextMain, fontSize: 12, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: badge, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    isLocked ? 'बंद' : 'चालू',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ACTION BUTTON WIDGET
// =============================================================================
class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// RESULT DIALOG
// =============================================================================
class _ResultDialog extends StatefulWidget {
  final String docId;
  final String gameName;
  final String current;

  const _ResultDialog({required this.docId, required this.gameName, required this.current});

  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog> {
  late final TextEditingController _ctrl;
  bool    _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.current.contains('*') ? '' : widget.current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String? _validate(String v) {
    if (v.isEmpty) return 'निकाल टाका';
    if (!RegExp(r'^\d{3}-\d{1,2}-\d{3}$').hasMatch(v)) {
      return 'फॉर्मेट चुकीचा. उदा: 123-45-678';
    }
    return null;
  }

  Future<void> _submit() async {
    final val = _ctrl.text.trim();
    final err = _validate(val);
    if (err != null) { setState(() => _error = err); return; }
    setState(() { _processing = true; _error = null; });
    try {
      await _updateResultAndProcessWins(context, widget.docId, widget.gameName, val);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _processing = false; _error = 'Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: _kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.check_circle_rounded, color: _kSuccess, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('निकाल जाहीर करा',
                  style: TextStyle(color: _kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(widget.gameName,
              style: const TextStyle(color: _kPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Format guide
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('फॉर्मेट:', style: TextStyle(color: _kPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _fmtRow('ओपन पाना',          'पहिले 3 अंक',  '123'),
                _fmtRow('ओपन+क्लोज सिंगल',  'मधले अंक',     '45'),
                _fmtRow('क्लोज पाना',         'शेवटचे 3 अंक', '678'),
                const Divider(height: 12),
                const Center(
                  child: Text('123-45-678',
                      style: TextStyle(
                          color: _kPrimary, fontWeight: FontWeight.bold,
                          fontSize: 16, letterSpacing: 2)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _kTextMain, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
            decoration: InputDecoration(
              hintText: '123-45-678',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              errorText: _error,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kSuccess, width: 2)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _processing ? null : () => Navigator.pop(context),
          child: const Text('रद्द करा', style: TextStyle(color: _kTextGrey)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: _kSuccess,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
          onPressed: _processing ? null : _submit,
          icon: _processing
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check, size: 18),
          label: Text(_processing ? 'प्रोसेस होत आहे...' : 'अपडेट करा'),
        ),
      ],
    );
  }

  Widget _fmtRow(String label, String desc, String eg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(children: [
        Text('• $label: ', style: const TextStyle(color: _kTextMain, fontSize: 10)),
        Text(eg, style: const TextStyle(color: _kPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
        Text('  ($desc)', style: const TextStyle(color: _kTextGrey, fontSize: 10)),
      ]),
    );
  }
}

// =============================================================================
// EDIT TIMINGS SHEET
// =============================================================================
class _EditTimingsSheet extends StatefulWidget {
  final String               docId;
  final Map<String, dynamic> data;

  const _EditTimingsSheet({required this.docId, required this.data});

  @override
  State<_EditTimingsSheet> createState() => _EditTimingsSheetState();
}

class _EditTimingsSheetState extends State<_EditTimingsSheet> {
  late final TextEditingController openStartCtrl;
  late final TextEditingController openEndCtrl;
  late final TextEditingController closeStartCtrl;
  late final TextEditingController closeEndCtrl;
  late final TextEditingController openTimeCtrl;
  late final TextEditingController closeTimeCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    openStartCtrl  = TextEditingController(text: widget.data['openBetStart']  ?? '09:00 AM');
    openEndCtrl    = TextEditingController(text: widget.data['openBetEnd']    ?? '11:00 AM');
    closeStartCtrl = TextEditingController(text: widget.data['closeBetStart'] ?? '12:00 PM');
    closeEndCtrl   = TextEditingController(text: widget.data['closeBetEnd']   ?? '02:00 PM');
    openTimeCtrl   = TextEditingController(text: widget.data['openTime']      ?? '11:30 AM');
    closeTimeCtrl  = TextEditingController(text: widget.data['closeTime']     ?? '02:30 PM');
  }

  @override
  void dispose() {
    for (final c in [openStartCtrl, openEndCtrl, closeStartCtrl, closeEndCtrl, openTimeCtrl, closeTimeCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance.collection('games').doc(widget.docId).update({
      'openBetStart':  openStartCtrl.text.trim(),
      'openBetEnd':    openEndCtrl.text.trim(),
      'closeBetStart': closeStartCtrl.text.trim(),
      'closeBetEnd':   closeEndCtrl.text.trim(),
      'openTime':      openTimeCtrl.text.trim(),
      'closeTime':     closeTimeCtrl.text.trim(),
    });
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('टायमिंग सेव्ह झाले!'),
        backgroundColor: _kSuccess,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time_filled_rounded, color: _kPrimary, size: 22),
                const SizedBox(width: 8),
                Text(widget.data['name']?.toString() ?? 'Market',
                    style: const TextStyle(
                        color: _kTextMain, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),

            // Open Session
            Text('🌅  ओपन सेशन (Open Session)',
                style: TextStyle(color: Colors.orange.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _timingField(openStartCtrl, 'बेट सुरू (Start)')),
              const SizedBox(width: 10),
              Expanded(child: _timingField(openEndCtrl, 'बेट बंद (End)')),
            ]),
            const SizedBox(height: 10),
            _timingField(openTimeCtrl, 'ओपन रिझल्ट वेळ'),

            const SizedBox(height: 20),

            // Close Session
            const Text('🌙  क्लोज सेशन (Close Session)',
                style: TextStyle(color: _kPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _timingField(closeStartCtrl, 'बेट सुरू (Start)')),
              const SizedBox(width: 10),
              Expanded(child: _timingField(closeEndCtrl, 'बेट बंद (End)')),
            ]),
            const SizedBox(height: 10),
            _timingField(closeTimeCtrl, 'क्लोज रिझल्ट वेळ'),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'सेव्ह होत आहे...' : 'सेव्ह करा',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timingField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: _kTextMain, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kTextGrey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// =============================================================================
// WIN PROCESSING LOGIC — centralized
// =============================================================================
Future<void> _updateResultAndProcessWins(
    BuildContext context, String docId, String gameName, String resultText) async {
  try {
    await FirebaseFirestore.instance.collection('games').doc(docId).update({'result': resultText});

    String openPanna = '', openSingle = '', closeSingle = '', closePanna = '', jodi = '';
    final parts = resultText.trim().split('-');
    if (parts.isNotEmpty) openPanna = parts[0].replaceAll('*', '').trim();
    if (parts.length >= 2) {
      final mid = parts[1].replaceAll('*', '').trim();
      if (mid.length == 1) {
        openSingle = mid;
      } else if (mid.length == 2) {
        openSingle = mid[0]; closeSingle = mid[1]; jodi = mid;
      }
    }
    if (parts.length >= 3) closePanna = parts[2].replaceAll('*', '').trim();

    final betsQuery = await FirebaseFirestore.instance
        .collection('bets')
        .where('gameId', isEqualTo: docId)
        .where('status', isEqualTo: 'pending')
        .get();

    int processedCount = 0;

    for (final betDoc in betsQuery.docs) {
      final bet      = betDoc.data();
      final type     = bet['betType']?.toString() ?? '';
      final session  = bet['session']?.toString() ?? 'Open';
      final num      = bet['number']?.toString() ?? '';
      final userId   = bet['userId']?.toString() ?? '';
      final winAmount = int.tryParse(bet['potentialWin']?.toString() ?? '') ?? 0;

      bool isDecided = false, isWon = false;

      if (session == 'Open') {
        if (type.contains('Panna') && openPanna.isNotEmpty) {
          isDecided = true; isWon = (num == openPanna);
        } else if (type == 'Single Digit' && openSingle.isNotEmpty) {
          isDecided = true; isWon = (num == openSingle);
        }
      } else if (session == 'Close') {
        if (type.contains('Panna') && closePanna.isNotEmpty) {
          isDecided = true; isWon = (num == closePanna);
        } else if (type == 'Single Digit' && closeSingle.isNotEmpty) {
          isDecided = true; isWon = (num == closeSingle);
        }
      }
      if (type == 'Jodi Digit' && jodi.isNotEmpty && jodi.length == 2) {
        isDecided = true; isWon = (num == jodi);
      }

      if (isDecided) {
        processedCount++;
        await FirebaseFirestore.instance.runTransaction((tx) async {
          if (isWon) {
            final userRef  = FirebaseFirestore.instance.collection('users').doc(userId);
            final userSnap = await tx.get(userRef);
            if (userSnap.exists) {
              final uMap         = userSnap.data() as Map<String, dynamic>;
              final currentLimit   = int.tryParse(uMap['limit']?.toString()   ?? '') ?? 0;
              final currentBalance = int.tryParse(uMap['balance']?.toString() ?? '') ?? 0;
              tx.update(userRef, {
                'limit':   currentLimit   + winAmount,
                'balance': currentBalance + winAmount,
              });
              tx.set(FirebaseFirestore.instance.collection('transactions').doc(), {
                'userId':          userId,
                'amount':          winAmount,
                'type':            'win',
                'previousBalance': currentBalance,
                'newBalance':      currentBalance + winAmount,
                'timestamp':       FieldValue.serverTimestamp(),
                'adminId':         FirebaseAuth.instance.currentUser?.uid ?? 'System',
                'note':            'Win: $gameName ($num)',
              });
            }
          }
          tx.update(betDoc.reference, {'status': isWon ? 'won' : 'loss'});
        });
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ निकाल अपडेट! $processedCount बेट्स रिझॉल्व्ह झाल्या.'),
        backgroundColor: _kSuccess,
        behavior: SnackBarBehavior.floating,
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: _kAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
