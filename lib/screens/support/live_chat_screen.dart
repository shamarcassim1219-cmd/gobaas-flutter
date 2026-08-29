import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/support_service.dart';
import '../../services/api_client.dart';
import '../../services/api_exception.dart';
import '../../models/support_query.dart';
import '../../main.dart';

/// Live support chat - a customer sends a message, the backend
/// (admin side, elsewhere in this project) replies, and this screen
/// polls for updates every few seconds so replies show up without
/// needing a persistent connection. A query is only created the
/// moment a real (non-guest) account actually sends a first
/// message - a guest typing and hitting Send is redirected to login
/// instead, matching the app's usual "ask for login exactly when
/// something real is attempted" pattern.
class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  String? _queryId;
  List<ChatMessage> _messages = [];
  bool _queryOpen = true;
  bool _sending = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _isGuest() async {
    final user = await ApiClient.instance.getUser();
    final mobile = user?['mobile'] as String? ?? '';
    final email = user?['email'] as String? ?? '';
    return mobile.isEmpty && email.isEmpty;
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    if (await _isGuest()) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Please login or register to chat with support.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                showLoginRequired(context);
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      // First message in this screen's lifetime - start a new
      // query, then send within it.
      _queryId ??= (await SupportService.instance.createQuery()).id;

      await SupportService.instance.sendMessage(_queryId!, text);
      _messageController.clear();

      await _refresh();
      _startPolling();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unable to send your message. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _refresh() async {
    if (_queryId == null) return;
    try {
      final query = await SupportService.instance.getQuery(_queryId!);
      if (!mounted) return;
      setState(() {
        _messages = query.messages;
        _queryOpen = query.isOpen;
      });
      _scrollToBottom();
      if (!query.isOpen) _pollTimer?.cancel();
    } catch (_) {
      // Silent - next poll tick tries again.
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _refresh());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _startNewConversation() async {
    _pollTimer?.cancel();
    setState(() {
      _queryId = null;
      _messages = [];
      _queryOpen = true;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Support Chat')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                    ),
            ),
            if (!_queryOpen) _buildClosedBanner(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
              ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              "Send a message and we'll be right with you.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isCustomer = message.isFromCustomer;

    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isCustomer ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: isCustomer ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          message.message,
          style: TextStyle(
            color: isCustomer ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildClosedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: AppColors.warningSoft,
      child: Column(
        children: [
          const Text(
            'This conversation has closed due to inactivity.',
            style: TextStyle(fontSize: 12.5, color: AppColors.warning, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _startNewConversation,
            child: const Text('Start New Conversation'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final disabled = !_queryOpen;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !disabled,
              decoration: InputDecoration(
                hintText: disabled ? 'Conversation closed' : 'Type a message...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: disabled ? null : _send,
            icon: _sending
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
