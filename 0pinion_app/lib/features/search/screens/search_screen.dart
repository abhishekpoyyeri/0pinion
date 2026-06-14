
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/opinion_card.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/opinion.dart';

/// Search screen â€” unified search with smart prefixes
/// @username â†’ users, 0topic â†’ zeroes/opinions, default â†’ opinions
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isLoading = false;

  // Search History
  List<Map<String, dynamic>> _searchHistory = [];
  bool _isLoadingHistory = false;
  // Results
  List<Opinion> _opinionResults = [];
  List<Map<String, dynamic>> _userResults = [];
  List<Map<String, dynamic>> _zeroResults = [];

  // What kind of search is active
  String _searchMode = 'all'; // 'all', 'users', 'zeroes'

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final supabase = ref.read(supabaseClientProvider);
    if (supabase.auth.currentUser == null) return;
    
    setState(() => _isLoadingHistory = true);
    try {
      final res = await supabase
          .from('search_history')
          .select()
          .order('created_at', ascending: false)
          .limit(20);
      setState(() {
        _searchHistory = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      debugPrint('Load history error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _addHistory(String query) async {
    final supabase = ref.read(supabaseClientProvider);
    if (supabase.auth.currentUser == null) return;
    if (query.trim().isEmpty) return;

    try {
      await supabase.from('search_history').insert({
        'user_id': supabase.auth.currentUser!.id,
        'query': query.trim(),
      });
      _loadHistory();
    } catch (e) {
      debugPrint('Add history error: $e');
    }
  }

  Future<void> _clearAllHistory() async {
    final supabase = ref.read(supabaseClientProvider);
    if (supabase.auth.currentUser == null) return;

    try {
      await supabase
          .from('search_history')
          .delete()
          .eq('user_id', supabase.auth.currentUser!.id);
      _loadHistory();
    } catch (e) {
      debugPrint('Clear all history error: $e');
    }
  }

  Future<void> _deleteHistory(String id) async {
    final supabase = ref.read(supabaseClientProvider);
    
    try {
      await supabase
          .from('search_history')
          .delete()
          .eq('id', id);
      _loadHistory();
    } catch (e) {
      debugPrint('Delete history error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _opinionResults = [];
        _userResults = [];
        _zeroResults = [];
        _searchMode = 'all';
      });
      return;
    }

    setState(() => _isLoading = true);

    final supabase = ref.read(supabaseClientProvider);

    try {
      if (query.startsWith('@')) {
        // â”€â”€â”€ USER SEARCH â”€â”€â”€
        final username = query.substring(1).trim().toLowerCase();
        _searchMode = 'users';
        if (username.isEmpty) {
          _userResults = [];
        } else {
          final res = await supabase
              .from('profiles')
              .select()
              .ilike('username', '%$username%')
              .limit(20);
          _userResults = List<Map<String, dynamic>>.from(res);
        }
        _opinionResults = [];
        _zeroResults = [];
      } else if (query.startsWith('0')) {
        // â”€â”€â”€ ZERO SEARCH â”€â”€â”€
        final zeroName = query.substring(1).trim().toLowerCase();
        _searchMode = 'zeroes';
        if (zeroName.isEmpty) {
          // Show all zeroes
          final zeroRes = await supabase
              .from('zeroes')
              .select()
              .order('opinions_count', ascending: false);
          _zeroResults = List<Map<String, dynamic>>.from(zeroRes);
          _opinionResults = [];
        } else {
          // Search zeroes matching name
          final zeroRes = await supabase
              .from('zeroes')
              .select()
              .ilike('name', '%$zeroName%')
              .order('opinions_count', ascending: false);
          _zeroResults = List<Map<String, dynamic>>.from(zeroRes);

          // Also fetch opinions tagged with matching zeroes
          if (_zeroResults.isNotEmpty) {
            final zeroIds = _zeroResults.map((z) => z['id'] as String).toList();
            final opRes = await supabase
                .from('opinions')
                .select('*, profiles(username), zeroes(name), arguments(id, type)')
                .inFilter('zero_id', zeroIds)
                .order('created_at', ascending: false)
                .limit(30);
            _opinionResults = List<Map<String, dynamic>>.from(opRes)
                .map((json) => Opinion.fromJson(json))
                .toList();
          } else {
            _opinionResults = [];
          }
        }
        _userResults = [];
      } else {
        // â”€â”€â”€ GENERAL SEARCH (opinions by title/content) â”€â”€â”€
        _searchMode = 'all';
        final searchTerm = query.trim().toLowerCase();

        final opRes = await supabase
            .from('opinions')
            .select('*, profiles(username), zeroes(name), arguments(id, type)')
            .or('title.ilike.%$searchTerm%,content.ilike.%$searchTerm%')
            .order('created_at', ascending: false)
            .limit(30);
        _opinionResults = List<Map<String, dynamic>>.from(opRes)
            .map((json) => Opinion.fromJson(json))
            .toList();

        _userResults = [];
        _zeroResults = [];
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text('Search', style: AppTypography.h2(color: primaryText)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                setState(() => _query = v);
                _performSearch(v);
              },
              onSubmitted: (v) {
                _addHistory(v);
              },
              decoration: InputDecoration(
                hintText: 'Search here',
                prefixIcon: Icon(Icons.search, color: secondaryText),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: secondaryText),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                          _performSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Search mode hint
          if (_query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryText.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _searchMode == 'users'
                          ? 'Searching Users'
                          : _searchMode == 'zeroes'
                              ? 'Searching Zeroes'
                              : 'Searching Opinions',
                      style: AppTypography.label(color: secondaryText),
                    ),
                  ),
                ],
              ),
            ),

          Divider(height: 1, color: borderColor),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _query.isEmpty
                    ? _buildEmptyState(secondaryText, primaryText)
                    : _buildResults(primaryText, secondaryText, borderColor, surfaceColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color secondaryText, Color primaryText) {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchHistory.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Search History', style: AppTypography.bodySemiBold(color: primaryText)),
                TextButton(
                  onPressed: _clearAllHistory,
                  child: Text('Clear All', style: AppTypography.caption(color: secondaryText)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final history = _searchHistory[index];
                final query = history['query'] as String;
                final id = history['id'] as String;

                return ListTile(
                  leading: Icon(Icons.history, color: secondaryText),
                  title: Text(query, style: AppTypography.body(color: primaryText)),
                  trailing: IconButton(
                    icon: Icon(Icons.close, color: secondaryText),
                    onPressed: () => _deleteHistory(id),
                  ),
                  onTap: () {
                    _searchController.text = query;
                    setState(() => _query = query);
                    _performSearch(query);
                    _addHistory(query);
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 48, color: secondaryText),
          const SizedBox(height: 16),
          Text('Search 0pinion', style: AppTypography.bodySemiBold(color: primaryText)),
          const SizedBox(height: 8),
          Text(
            'Type @username to find users\nType 0topic to find zeroes\nOr just type to search opinions',
            style: AppTypography.caption(color: secondaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResults(Color primaryText, Color secondaryText, Color borderColor, Color surfaceColor) {
    final bool hasResults = _opinionResults.isNotEmpty ||
        _userResults.isNotEmpty ||
        _zeroResults.isNotEmpty;

    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: secondaryText),
            const SizedBox(height: 16),
            Text('No results found', style: AppTypography.bodySemiBold(color: primaryText)),
            const SizedBox(height: 8),
            Text('Try a different search term', style: AppTypography.caption(color: secondaryText)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // â”€â”€â”€ Users Section â”€â”€â”€
        if (_userResults.isNotEmpty) ...[
          Text('Users', style: AppTypography.captionMedium(color: secondaryText)),
          const SizedBox(height: 8),
          ..._userResults.map((user) => _buildUserTile(user, primaryText, secondaryText, borderColor, surfaceColor)),
          const SizedBox(height: 24),
        ],

        // â”€â”€â”€ Zeroes Section â”€â”€â”€
        if (_zeroResults.isNotEmpty) ...[
          Text('Zeroes', style: AppTypography.captionMedium(color: secondaryText)),
          const SizedBox(height: 8),
          ..._zeroResults.map((zero) => _buildZeroTile(zero, primaryText, secondaryText, borderColor, surfaceColor)),
          const SizedBox(height: 24),
        ],

        // â”€â”€â”€ Opinions Section â”€â”€â”€
        if (_opinionResults.isNotEmpty) ...[
          Text(
            _searchMode == 'zeroes' ? 'Opinions in this Zero' : 'Opinions',
            style: AppTypography.captionMedium(color: secondaryText),
          ),
          const SizedBox(height: 8),
          ..._opinionResults.map((opinion) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OpinionCard(
                  opinion: opinion,
                  onTap: () => context.push('/opinion/${opinion.id}'),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, Color primaryText, Color secondaryText, Color borderColor, Color surfaceColor) {
    final username = user['username'] as String? ?? 'unknown';
    final displayName = user['display_name'] as String?;
    final avatarSeed = user['avatar_seed'] as int? ?? 1;
    final reputation = user['reputation_score'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            AvatarWidget(seed: avatarSeed, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@$username', style: AppTypography.bodySemiBold(color: primaryText)),
                  if (displayName != null && displayName.isNotEmpty)
                    Text(displayName, style: AppTypography.caption(color: secondaryText)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                '$reputation rep',
                style: AppTypography.label(color: secondaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZeroTile(Map<String, dynamic> zero, Color primaryText, Color secondaryText, Color borderColor, Color surfaceColor) {
    final name = zero['name'] as String? ?? '';
    final description = zero['description'] as String?;
    final opinionsCount = zero['opinions_count'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryText,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '0',
                  style: AppTypography.h3(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.black
                        : AppColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('0$name', style: AppTypography.bodySemiBold(color: primaryText)),
                  if (description != null && description.isNotEmpty)
                    Text(description, style: AppTypography.caption(color: secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(
              '$opinionsCount opinions',
              style: AppTypography.caption(color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
