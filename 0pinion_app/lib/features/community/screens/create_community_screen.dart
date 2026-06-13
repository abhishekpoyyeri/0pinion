import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/providers/community_provider.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../data/repositories/zero_repository.dart';

/// Screen to create a new community with name, description, and zero tags
class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends ConsumerState<CreateCommunityScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _zeroSearchController = TextEditingController();
  final List<Map<String, String>> _selectedZeroes = []; // [{id, name}]
  List<Map<String, dynamic>> _availableZeroes = [];
  bool _isLoading = false;
  bool _isNameAvailable = true;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _loadZeroes();
  }

  Future<void> _loadZeroes() async {
    final zeroRepo = ref.read(zeroRepositoryProvider);
    final zeroes = await zeroRepo.fetchAll();
    if (mounted) {
      setState(() => _availableZeroes = zeroes);
    }
  }

  Future<void> _checkNameAvailability(String name) async {
    if (name.trim().isEmpty) {
      setState(() {
        _isNameAvailable = true;
        _nameError = null;
      });
      return;
    }
    final repo = ref.read(communityRepositoryProvider);
    final available = await repo.isNameAvailable(name.trim());
    if (mounted) {
      setState(() {
        _isNameAvailable = available;
        _nameError = available ? null : 'This name is already taken';
      });
    }
  }

  void _addZero(Map<String, dynamic> zero) {
    final id = zero['id'] as String;
    if (_selectedZeroes.any((z) => z['id'] == id)) return;
    setState(() {
      _selectedZeroes.add({'id': id, 'name': zero['name'] as String});
      _zeroSearchController.clear();
    });
  }

  void _removeZero(String id) {
    setState(() {
      _selectedZeroes.removeWhere((z) => z['id'] == id);
    });
  }

  Future<void> _createCommunity() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      return;
    }
    if (!_isNameAvailable) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(communityRepositoryProvider);
      final community = await repo.createCommunity(
        name: name,
        description: description,
        zeroIds: _selectedZeroes.map((z) => z['id']!).toList(),
      );

      // Refresh the communities list
      ref.invalidate(communitiesProvider);

      if (mounted) {
        context.pop();
        context.push('/community/${community.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create community: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _zeroSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    // Preview avatar seed from name
    final previewSeed = _nameController.text.hashCode;

    // Filter zeroes for search
    final searchText = _zeroSearchController.text.toLowerCase();
    final filteredZeroes = searchText.isEmpty
        ? <Map<String, dynamic>>[]
        : _availableZeroes
            .where((z) => (z['name'] as String).toLowerCase().contains(searchText))
            .where((z) => !_selectedZeroes.any((sel) => sel['id'] == z['id']))
            .take(5)
            .toList();

    final canCreate = _nameController.text.trim().isNotEmpty && _isNameAvailable && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Community', style: AppTypography.h2(color: primaryText)),
        leading: IconButton(
          icon: Icon(Icons.close, color: primaryText),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: canCreate ? _createCommunity : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: canCreate ? primaryText : (isDark ? AppColors.darkDisabled : AppColors.lightDisabled),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? AppColors.black : AppColors.white,
                        ),
                      )
                    : Text(
                        'Create',
                        style: AppTypography.button(
                          color: canCreate
                              ? (isDark ? AppColors.black : AppColors.white)
                              : secondaryText,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar preview
            Center(
              child: Column(
                children: [
                  AvatarWidget(seed: previewSeed, size: 72),
                  const SizedBox(height: 8),
                  Text('Auto-generated avatar', style: AppTypography.caption(color: secondaryText)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Name
            Text('Community Name', style: AppTypography.captionMedium(color: primaryText)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _nameError != null ? Theme.of(context).colorScheme.error : borderColor),
              ),
              child: TextField(
                controller: _nameController,
                onChanged: (value) {
                  setState(() {});
                  _checkNameAvailability(value);
                },
                style: AppTypography.body(color: primaryText),
                decoration: InputDecoration(
                  hintText: 'e.g. Tech Enthusiasts',
                  hintStyle: AppTypography.body(color: secondaryText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            if (_nameError != null) ...[
              const SizedBox(height: 6),
              Text(_nameError!, style: AppTypography.caption(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),

            // Description
            Text('Description', style: AppTypography.captionMedium(color: primaryText)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: AppTypography.body(color: primaryText),
                decoration: InputDecoration(
                  hintText: 'What is this community about?',
                  hintStyle: AppTypography.body(color: secondaryText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Zero tags
            Text('Tag Zeroes', style: AppTypography.captionMedium(color: primaryText)),
            const SizedBox(height: 4),
            Text(
              'Categorize your community by linking it to existing zeroes',
              style: AppTypography.caption(color: secondaryText),
            ),
            const SizedBox(height: 8),

            // Selected zeroes chips
            if (_selectedZeroes.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedZeroes.map((zero) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryText,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          zero['name']!,
                          style: AppTypography.label(
                            color: isDark ? AppColors.black : AppColors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _removeZero(zero['id']!),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: isDark ? AppColors.black : AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Zero search
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _zeroSearchController,
                onChanged: (_) => setState(() {}),
                style: AppTypography.body(color: primaryText),
                decoration: InputDecoration(
                  hintText: 'Search zeroes to tag...',
                  hintStyle: AppTypography.body(color: secondaryText),
                  prefixIcon: Icon(Icons.exposure_zero, color: secondaryText, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Search results
            if (filteredZeroes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: filteredZeroes.map((zero) {
                    return InkWell(
                      onTap: () => _addZero(zero),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.exposure_zero, size: 16, color: secondaryText),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                zero['name'] as String,
                                style: AppTypography.bodyMedium(color: primaryText),
                              ),
                            ),
                            Icon(Icons.add, size: 18, color: secondaryText),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
