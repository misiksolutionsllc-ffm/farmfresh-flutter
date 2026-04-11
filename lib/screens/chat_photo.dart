import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'dart:io';

// ============================================
// ORDER CHAT SCREEN
// ============================================
class OrderChatScreen extends StatefulWidget {
  final String orderId, otherName, otherRole;
  const OrderChatScreen({super.key, required this.orderId, required this.otherName, required this.otherRole});
  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final _ctl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _msgs = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('chat_${widget.orderId}');
    if (saved != null) setState(() => _msgs = List<Map<String, dynamic>>.from(jsonDecode(saved)));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_${widget.orderId}', jsonEncode(_msgs));
  }

  void _send() {
    if (_ctl.text.trim().isEmpty) return;
    setState(() {
      _msgs.add({'id': 'msg_${DateTime.now().millisecondsSinceEpoch}', 'me': true, 'text': _ctl.text.trim(), 'time': DateTime.now().toIso8601String()});
    });
    _ctl.clear();
    _save();
    _scrollDown();
    // Auto reply
    Future.delayed(Duration(milliseconds: 2000 + (DateTime.now().millisecond % 3000)), () {
      if (!mounted) return;
      final replies = ['Got it, thanks!', 'On my way!', 'Almost there!', 'Order is being prepared', 'Thank you! 🙏', 'Leaving now 🚗'];
      setState(() {
        _msgs.add({'id': 'msg_r${DateTime.now().millisecondsSinceEpoch}', 'me': false, 'text': replies[DateTime.now().second % replies.length], 'time': DateTime.now().toIso8601String()});
      });
      _save();
      _scrollDown();
    });
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  String _fmtTime(String t) {
    try { final d = DateTime.parse(t); return '${d.hour % 12 == 0 ? 12 : d.hour % 12}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}'; }
    catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface950,
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: AppColors.blue.withOpacity(0.2), child: Text(widget.otherName[0], style: TextStyle(color: AppColors.blue, fontSize: 14, fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.otherName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text('${widget.otherRole} • #${widget.orderId.substring(widget.orderId.length - 6).toUpperCase()}', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ]),
        ]),
        actions: [Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 16), decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.emerald))],
      ),
      body: Column(children: [
        Expanded(child: _msgs.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('💬', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Send a message to ${widget.otherName}', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            ]))
          : ListView.builder(
              controller: _scroll, padding: const EdgeInsets.all(16), itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[i];
                final isMe = m['me'] == true;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.blue : AppColors.surface800,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (!isMe) Text(widget.otherName, style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      Text(m['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.white.withOpacity(0.9), fontSize: 14)),
                      const SizedBox(height: 2),
                      Align(alignment: Alignment.bottomRight, child: Text(_fmtTime(m['time'] ?? ''), style: TextStyle(fontSize: 9, color: isMe ? Colors.white54 : AppColors.textMuted))),
                    ]),
                  ),
                );
              },
            ),
        ),
        // Input
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctl, onSubmitted: (_) => _send(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type a message...', hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                filled: true, fillColor: AppColors.surface800,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
