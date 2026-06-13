import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/providers/supabase_provider.dart';

/// Live Room Chat screen — ephemeral real-time debate via Supabase Broadcast
class LiveRoomChatScreen extends ConsumerStatefulWidget {
  final String roomId;

  const LiveRoomChatScreen({super.key, required this.roomId});

  @override
  ConsumerState<LiveRoomChatScreen> createState() => _LiveRoomChatScreenState();
}

class _ChatMsg {
  final String senderId;
  final String senderUsername;
  final String content;
  final DateTime timestamp;

  _ChatMsg({
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.timestamp,
  });
}

class _LiveRoomChatScreenState extends ConsumerState<LiveRoomChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMsg> _messages = [];

  RealtimeChannel? _channel;
  String _roomTitle = '';
  int _participantCount = 0;
  String? _myUsername;

  @override
  void initState() {
    super.initState();
    _loadRoomInfo();
    _loadMyUsername();
    _subscribeToChannel();
  }

  Future<void> _loadRoomInfo() async {
    final supabase = ref.read(supabaseClientProvider);
    final res = await supabase
        .from('live_rooms')
        .select('title, participant_count')
        .eq('id', widget.roomId)
        .maybeSingle();
    if (res != null && mounted) {
      setState(() {
        _roomTitle = res['title'] as String? ?? 'Room';
        _participantCount = res['participant_count'] as int? ?? 0;
      });
    }
  }

  Future<void> _loadMyUsername() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final supabase = ref.read(supabaseClientProvider);
    final profile = await supabase
        .from('profiles')
        .select('username')
        .eq('id', user.id)
        .maybeSingle();
    if (profile != null && mounted) {
      _myUsername = profile['username'] as String? ?? 'anon';
    }
  }

  void _subscribeToChannel() {
    final supabase = ref.read(supabaseClientProvider);

    _channel = supabase.channel('room:${widget.roomId}');

    _channel!
        .onBroadcast(
          event: 'message',
          callback: (payload) {
            if (!mounted) return;
            setState(() {
              _messages.add(_ChatMsg(
                senderId: payload['sender_id'] as String? ?? '',
                senderUsername: payload['sender_username'] as String? ?? 'anon',
                content: payload['content'] as String? ?? '',
                timestamp: DateTime.tryParse(payload['timestamp'] as String? ?? '') ?? DateTime.now(),
              ));
            });
            _scrollToBottom();
          },
        )
        .subscribe();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final now = DateTime.now();

    // Broadcast to all subscribers (ephemeral, NOT stored in DB)
    _channel?.sendBroadcastMessage(
      event: 'message',
      payload: {
        'sender_id': user.id,
        'sender_username': _myUsername ?? 'anon',
        'content': text,
        'timestamp': now.toIso8601String(),
      },
    );

    // Also add locally so the sender sees it immediately
    setState(() {
      _messages.add(_ChatMsg(
        senderId: user.id,
        senderUsername: _myUsername ?? 'anon',
        content: text,
        timestamp: now,
      ));
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _roomTitle.isNotEmpty ? _roomTitle : 'Room ${widget.roomId.substring(0, 6)}',
              style: AppTypography.bodyMedium(color: primaryText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_participantCount participants',
                  style: AppTypography.caption(color: secondaryText),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Divider(height: 1, color: borderColor),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: secondaryText),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: AppTypography.bodySemiBold(color: primaryText),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the debate!',
                          style: AppTypography.caption(color: secondaryText),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == currentUserId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AvatarWidget(seed: msg.senderId.hashCode, size: 32),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '@${msg.senderUsername}',
                                          style: AppTypography.captionMedium(
                                            color: isMe ? primaryText : secondaryText,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _timeAgo(msg.timestamp),
                                        style: AppTypography.label(color: secondaryText),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    msg.content,
                                    style: AppTypography.body(color: primaryText),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send, color: primaryText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
