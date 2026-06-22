import 'package:opinion_app/core/widgets/loading_gif_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/repositories/opinion_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/live_room_repository.dart';
import '../../../data/repositories/zero_repository.dart';

/// Screen to create a new opinion or a live room
class CreateOpinionScreen extends ConsumerStatefulWidget {
  const CreateOpinionScreen({super.key});

  @override
  ConsumerState<CreateOpinionScreen> createState() => _CreateOpinionScreenState();
}

class _CreateOpinionScreenState extends ConsumerState<CreateOpinionScreen> {
  // Opinion Controllers
  final _opinionTitleController = TextEditingController();
  final _opinionContentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isOpinionLoading = false;

  // Detected zeroes from content
  List<String> _detectedZeroes = [];

  // Live Room Controllers
  final _roomTitleController = TextEditingController();
  final _roomTopicController = TextEditingController();
  bool _isRoomLoading = false;
  int _selectedDuration = 10; // minutes
  bool _isCustomDuration = false;
  final _customHoursController = TextEditingController();
  final _customMinutesController = TextEditingController();
  final _customSecondsController = TextEditingController();

  static const _durationOptions = [5, 10, 15, 30, 60];

  /// Regex to detect 0word patterns (e.g. 0laptop, 0politics)
  /// Matches: word boundary + "0" + one or more word characters
  static final _zeroPattern = RegExp(r'(?:^|\s)0([a-zA-Z]\w*)', multiLine: true);

  @override
  void initState() {
    super.initState();
    _opinionContentController.addListener(_parseZeroes);
  }

  @override
  void dispose() {
    _opinionContentController.removeListener(_parseZeroes);
    _opinionTitleController.dispose();
    _opinionContentController.dispose();
    _roomTitleController.dispose();
    _roomTopicController.dispose();
    _customHoursController.dispose();
    _customMinutesController.dispose();
    _customSecondsController.dispose();
    super.dispose();
  }

  /// Parse the content field and extract all 0word mentions
  void _parseZeroes() {
    final content = _opinionContentController.text;
    final matches = _zeroPattern.allMatches(content);
    final zeroes = matches
        .map((m) => m.group(1)!.toLowerCase())
        .toSet() // unique
        .toList();

    if (_listsDiffer(_detectedZeroes, zeroes)) {
      setState(() => _detectedZeroes = zeroes);
    }
  }

  bool _listsDiffer(List<String> a, List<String> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

  Future<void> _submitOpinion() async {
    final title = _opinionTitleController.text.trim();
    final content = _opinionContentController.text.trim();

    if (title.isEmpty || content.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      AppErrorHandler.showErrorDialog(context, 'Error: Not authenticated.');
      return;
    }

    setState(() => _isOpinionLoading = true);
    try {
      final repo = ref.read(opinionRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);
      final zeroRepo = ref.read(zeroRepositoryProvider);

      // EXPLICIT CHECK: Ensure they have a profile before proceeding!
      final hasProfile = await authRepo.hasProfile(user.id);
      if (!hasProfile) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must complete your profile first! Redirecting...')),
          );
          context.go('/username-setup');
        }
        return;
      }

      // Resolve the first detected zero (find or create)
      String? resolvedZeroId;
      if (_detectedZeroes.isNotEmpty) {
        resolvedZeroId = await zeroRepo.findOrCreate(_detectedZeroes.first);
      }

      await repo.createOpinion(
        title: title,
        content: content,
        authorId: user.id,
        isAnonymous: _isAnonymous,
        zeroId: resolvedZeroId,
      );

      if (mounted) {
        _opinionTitleController.clear();
        _opinionContentController.clear();
        setState(() {
          _detectedZeroes.clear();
          _isAnonymous = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opinion Posted')),
          );
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showErrorDialog(context, e);
      }
    } finally {
      if (mounted) setState(() => _isOpinionLoading = false);
    }
  }

  Future<void> _submitLiveRoom() async {
    final title = _roomTitleController.text.trim();
    final topic = _roomTopicController.text.trim();

    if (title.isEmpty || topic.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Not authenticated.')),
      );
      return;
    }

    setState(() => _isRoomLoading = true);
    try {
      final repo = ref.read(liveRoomRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);

      final hasProfile = await authRepo.hasProfile(user.id);
      if (!hasProfile) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must complete your profile first! Redirecting...')),
          );
          context.go('/username-setup');
        }
        return;
      }

      int finalDurationSeconds = _selectedDuration * 60;
      if (_isCustomDuration) {
        final h = int.tryParse(_customHoursController.text.trim()) ?? 0;
        final m = int.tryParse(_customMinutesController.text.trim()) ?? 0;
        final s = int.tryParse(_customSecondsController.text.trim()) ?? 0;
        final totalSecs = (h * 3600) + (m * 60) + s;
        if (totalSecs > 0) {
          finalDurationSeconds = totalSecs;
        }
      }

      final roomId = await repo.createRoom(
        title: title,
        topic: topic,
        hostId: user.id,
        durationSeconds: finalDurationSeconds,
      );

      if (mounted) {
        _roomTitleController.clear();
        _roomTopicController.clear();
        setState(() {
          _selectedDuration = 10;
          _isCustomDuration = false;
          _customHoursController.clear();
          _customMinutesController.clear();
          _customSecondsController.clear();
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
            final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
            
            return Dialog(
              backgroundColor: isDark ? AppColors.black : AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.podcasts, color: primaryText, size: 64),
                    const SizedBox(height: 16),
                    Text('Room Created', style: AppTypography.h2(color: primaryText)),
                    const SizedBox(height: 8),
                    Text(
                      'Your live room is ready to host the debate.',
                      style: AppTypography.body(color: secondaryText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
          context.go('/live/$roomId');
        }
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showErrorDialog(context, e);
      }
    } finally {
      if (mounted) setState(() => _isRoomLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Create', style: AppTypography.h3(color: primaryText)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.go('/home'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Opinion'),
              Tab(text: 'Live Room'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOpinionForm(context),
            _buildLiveRoomForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOpinionForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            TextField(
              controller: _opinionTitleController,
              style: AppTypography.h2(color: primaryText),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'What is your opinion?',
                hintStyle: AppTypography.h2(color: secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryText, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Content Field
            TextField(
              controller: _opinionContentController,
              style: AppTypography.body(color: primaryText),
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Expand on your thoughts...\n\nMention zeroes like 0technology 0politics',
                hintStyle: AppTypography.body(color: secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryText, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Detected Zeroes (live preview)
            if (_detectedZeroes.isNotEmpty) ...[
              Divider(color: borderColor),
              const SizedBox(height: 12),
              Text('Detected Zeroes', style: AppTypography.captionMedium(color: secondaryText)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _detectedZeroes.map((zero) {
                  final isFirst = zero == _detectedZeroes.first;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFirst ? primaryText : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryText),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '0$zero',
                          style: AppTypography.captionMedium(
                            color: isFirst
                                ? (isDark ? AppColors.black : AppColors.white)
                                : primaryText,
                          ),
                        ),
                        if (isFirst) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: isDark ? AppColors.black : AppColors.white,
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
              Text(
                'The first zero (0${_detectedZeroes.first}) will be tagged',
                style: AppTypography.label(color: secondaryText),
              ),
              const SizedBox(height: 16),
            ],

            if (_detectedZeroes.isEmpty) ...[
              Divider(color: borderColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: secondaryText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Type 0 followed by a topic name (e.g. 0laptop) to tag a zero',
                      style: AppTypography.label(color: secondaryText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Anonymity Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Post Anonymously', style: AppTypography.captionMedium(color: primaryText)),
                    const SizedBox(height: 4),
                    Text('Your identity will be hidden.', style: AppTypography.caption(color: secondaryText)),
                  ],
                ),
                Switch(
                  value: _isAnonymous,
                  onChanged: (val) => setState(() => _isAnonymous = val),
                  activeColor: isDark ? Colors.white : Colors.black,
                ),
              ],
            ),
            if (_isAnonymous) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: primaryText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warning: Truly anonymous posts cannot be edited or deleted once posted.',
                      style: AppTypography.captionMedium(color: primaryText),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),

            // Submit
            PrimaryButton(
              label: 'Post Opinion',
              onPressed: _submitOpinion,
              isLoading: _isOpinionLoading,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveRoomForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            TextField(
              controller: _roomTitleController,
              style: AppTypography.h2(color: primaryText),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Live Room Title',
                hintStyle: AppTypography.h2(color: secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryText, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Topic Field
            TextField(
              controller: _roomTopicController,
              style: AppTypography.body(color: primaryText),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'What is the debate topic?',
                hintStyle: AppTypography.body(color: secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryText, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Duration Picker
            Text('Room Duration', style: AppTypography.captionMedium(color: primaryText)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._durationOptions.map((mins) {
                  final isSelected = !_isCustomDuration && _selectedDuration == mins;
                  final label = mins >= 60 ? '${mins ~/ 60} hr' : '$mins min';
                  return GestureDetector(
                    onTap: () => setState(() {
                      _isCustomDuration = false;
                      _selectedDuration = mins;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryText : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryText),
                      ),
                      child: Text(
                        label,
                        style: AppTypography.captionMedium(
                          color: isSelected
                              ? (isDark ? AppColors.black : AppColors.white)
                              : primaryText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                GestureDetector(
                  onTap: () => setState(() => _isCustomDuration = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isCustomDuration ? primaryText : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryText),
                    ),
                    child: Text(
                      'Custom',
                      style: AppTypography.captionMedium(
                        color: _isCustomDuration
                            ? (isDark ? AppColors.black : AppColors.white)
                            : primaryText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isCustomDuration) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customHoursController,
                      keyboardType: TextInputType.number,
                      style: AppTypography.body(color: primaryText),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'HH',
                        hintStyle: AppTypography.body(color: secondaryText),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryText, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(':', style: AppTypography.h3(color: primaryText)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _customMinutesController,
                      keyboardType: TextInputType.number,
                      style: AppTypography.body(color: primaryText),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'MM',
                        hintStyle: AppTypography.body(color: secondaryText),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryText, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(':', style: AppTypography.h3(color: primaryText)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _customSecondsController,
                      keyboardType: TextInputType.number,
                      style: AppTypography.body(color: primaryText),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'SS',
                        hintStyle: AppTypography.body(color: secondaryText),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryText, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),

            // Submit
            PrimaryButton(
              label: 'Create Live Room',
              onPressed: _submitLiveRoom,
              isLoading: _isRoomLoading,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
