import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/repositories/live_room_repository.dart';

/// Live Room Chat screen — ephemeral real-time debate via Supabase Broadcast
/// Features: Presence counting, countdown timer, topic header, admin close, conclusion
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
  Timer? _countdownTimer;

  // Room info
  String _roomTitle = '';
  String _roomTopic = '';
  String? _hostId;
  String? _hostUsername;
  int _durationMinutes = 10;
  DateTime? _createdAt;
  String _roomStatus = 'active';
  String? _conclusion;
  int _presenceCount = 0;
  String? _myUsername;
  bool _isLoaded = false;

  // Countdown
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadRoomInfo();
    _loadMyUsername();
    _subscribeToChannel();
  }

  Future<void> _loadRoomInfo() async {
    final repo = ref.read(liveRoomRepositoryProvider);
    final room = await repo.fetchRoom(widget.roomId);
    if (room != null && mounted) {
      setState(() {
        _roomTitle = room['title'] as String? ?? 'Room';
        _roomTopic = room['topic'] as String? ?? '';
        _hostId = room['host_id'] as String?;
        _durationMinutes = room['duration_minutes'] as int? ?? 10;
        _createdAt = DateTime.tryParse(room['created_at'] as String? ?? '');
        _roomStatus = room['status'] as String? ?? 'active';
        _conclusion = room['conclusion'] as String?;

        final profileData = room['profiles'];
        _hostUsername = profileData != null && profileData is Map
            ? (profileData['username'] as String? ?? 'unknown')
            : 'unknown';
        _isLoaded = true;
      });
      _startCountdown();
    }
    
    // Fetch message history
    try {
      final supabase = ref.read(supabaseClientProvider);
      final msgRes = await supabase
          .from('live_room_messages')
          .select('*, profiles(username)')
          .eq('room_id', widget.roomId)
          .order('created_at', ascending: true);
          
      if (mounted) {
        setState(() {
          for (final row in msgRes) {
            final profileData = row['profiles'];
            final username = profileData != null && profileData is Map
                ? (profileData['username'] as String? ?? 'unknown')
                : 'unknown';
                
            _messages.add(_ChatMsg(
              senderId: row['sender_id'] as String,
              senderUsername: username,
              content: row['content'] as String,
              timestamp: DateTime.parse(row['created_at'] as String).toLocal(),
            ));
          }
        });
        _scrollToBottom();
      }
    } catch (_) {
      // Ignore if history fails to load
    }
  }

  void _startCountdown() {
    if (_createdAt == null || _roomStatus == 'closed') return;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final endTime = _createdAt!.add(Duration(minutes: _durationMinutes));
      final remaining = endTime.difference(DateTime.now());

      if (remaining.isNegative) {
        // Time's up — auto-close if we're the host
        _countdownTimer?.cancel();
        if (_isHost && _roomStatus == 'active') {
          _autoClose();
        }
        setState(() {
          _remaining = Duration.zero;
          _roomStatus = 'closed';
        });
      } else {
        setState(() => _remaining = remaining);
      }
    });
  }

  Future<void> _autoClose() async {
    try {
      final repo = ref.read(liveRoomRepositoryProvider);
      await repo.closeRoom(
        roomId: widget.roomId,
        conclusion: 'Room timed out — no conclusion was provided.',
      );
      _channel?.sendBroadcastMessage(
        event: 'room_closed',
        payload: {
          'conclusion': 'Room timed out — no conclusion was provided.',
        },
      );
      if (mounted) {
        setState(() {
          _roomStatus = 'closed';
          _conclusion = 'Room timed out — no conclusion was provided.';
        });
      }
    } catch (_) {}
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
    final user = ref.read(currentUserProvider);

    _channel = supabase.channel('room:${widget.roomId}');

    // Listen for chat messages
    _channel!.onBroadcast(
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
    );

    // Listen for room_closed event
    _channel!.onBroadcast(
      event: 'room_closed',
      callback: (payload) {
        if (!mounted) return;
        setState(() {
          _roomStatus = 'closed';
          _conclusion = payload['conclusion'] as String? ?? 'Room closed.';
        });
        _countdownTimer?.cancel();
      },
    );

    // Track presence for accurate participant count
    _channel!.onPresenceSync((payload) {
      if (!mounted) return;
      final presences = _channel!.presenceState();
      setState(() => _presenceCount = presences.length);
    });

    // Subscribe and track this user
    _channel!.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _channel!.track({
          'user_id': user?.id ?? 'anonymous',
          'username': _myUsername ?? 'anon',
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _roomStatus == 'closed') return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final now = DateTime.now();

    _channel?.sendBroadcastMessage(
      event: 'message',
      payload: {
        'sender_id': user.id,
        'sender_username': _myUsername ?? 'anon',
        'content': text,
        'timestamp': now.toIso8601String(),
      },
    );

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
    
    // Also save to database for history
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('live_room_messages').insert({
        'room_id': widget.roomId,
        'sender_id': user.id,
        'content': text,
        'created_at': now.toUtc().toIso8601String(),
      });
    } catch (_) {}
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

  bool get _isHost {
    final user = ref.read(currentUserProvider);
    return user != null && user.id == _hostId;
  }

  void _showCloseRoomDialog() {
    final conclusionController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Close Room', style: AppTypography.h3(color: primaryText)),
              const SizedBox(height: 8),
              Text(
                'Write a conclusion for this debate. All participants will see this for the next 3 hours.',
                style: AppTypography.caption(color: secondaryText),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: conclusionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'What was the takeaway from this debate?',
                  hintStyle: AppTypography.body(color: secondaryText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                style: AppTypography.body(color: primaryText),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Cancel', style: AppTypography.captionMedium(color: secondaryText)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final conclusion = conclusionController.text.trim();
                        if (conclusion.isEmpty) return;

                        Navigator.of(ctx).pop();

                        final repo = ref.read(liveRoomRepositoryProvider);
                        await repo.closeRoom(roomId: widget.roomId, conclusion: conclusion);

                        // Broadcast to all participants
                        _channel?.sendBroadcastMessage(
                          event: 'room_closed',
                          payload: {'conclusion': conclusion},
                        );

                        _countdownTimer?.cancel();
                        if (mounted) {
                          setState(() {
                            _roomStatus = 'closed';
                            _conclusion = conclusion;
                          });
                        }
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Close Room', style: AppTypography.captionMedium(color: Colors.black)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _channel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final currentUserId = ref.watch(currentUserProvider)?.id;

    if (!_isLoaded) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text('Loading...', style: AppTypography.bodyMedium(color: primaryText)),
        ),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

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
              _roomTitle.isNotEmpty ? _roomTitle : 'Room',
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
                    color: _roomStatus == 'active' ? Colors.white : Colors.black,
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _roomStatus == 'active'
                      ? '$_presenceCount online  ·  ${_formatDuration(_remaining)} left'
                      : 'CLOSED',
                  style: AppTypography.caption(color: secondaryText),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_isHost && _roomStatus == 'active')
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.white),
              tooltip: 'Close Room',
              onPressed: _showCloseRoomDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // Topic header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.topic_outlined, size: 16, color: secondaryText),
                    const SizedBox(width: 6),
                    Text('Debate Topic', style: AppTypography.label(color: secondaryText)),
                    const Spacer(),
                    if (_hostUsername != null)
                      Text('by @$_hostUsername', style: AppTypography.label(color: secondaryText)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _roomTopic.isNotEmpty ? _roomTopic : 'No topic set',
                  style: AppTypography.bodySemiBold(color: primaryText),
                ),
              ],
            ),
          ),

          // Conclusion banner (when closed)
          if (_roomStatus == 'closed' && _conclusion != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0FF),
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gavel, size: 16, color: primaryText),
                      const SizedBox(width: 6),
                      Text('Debate Conclusion', style: AppTypography.captionMedium(color: primaryText)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _conclusion!,
                    style: AppTypography.body(color: primaryText),
                  ),
                ],
              ),
            ),

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
                          _roomStatus == 'closed' ? 'Room is closed' : 'No messages yet',
                          style: AppTypography.bodySemiBold(color: primaryText),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _roomStatus == 'closed' ? 'This debate has ended.' : 'Start the debate!',
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

          // Message input (hidden when room is closed)
          if (_roomStatus == 'active')
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

          // Closed room footer
          if (_roomStatus == 'closed')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: SafeArea(
                child: Text(
                  'This room has been closed. The conclusion will be visible for 3 hours.',
                  style: AppTypography.caption(color: secondaryText),
                  textAlign: TextAlign.center,
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
