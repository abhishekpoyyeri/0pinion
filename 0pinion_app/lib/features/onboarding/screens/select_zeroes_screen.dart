import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/zero_chip.dart';


/// Select Zeroes screen — choose interest communities
class SelectZeroesScreen extends StatefulWidget {
  const SelectZeroesScreen({super.key});

  @override
  State<SelectZeroesScreen> createState() => _SelectZeroesScreenState();
}

class _SelectZeroesScreenState extends State<SelectZeroesScreen> {
  final Set<String> _selectedZeroes = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/username-setup'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Text(
                'Select Zeroes',
                style: AppTypography.h1(color: primaryText),
              ),
              const SizedBox(height: 8),
              Text(
                'Follow ideas, not people. Choose the topics that interest you.',
                style: AppTypography.body(color: secondaryText),
              ),
              const SizedBox(height: 8),
              Text(
                'Select at least 3',
                style: AppTypography.caption(color: secondaryText),
              ),
              const SizedBox(height: 32),

              // Zeroes grid
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ['Technology', 'Politics', 'Philosophy', 'Science'].map((name) {
                      final isSelected = _selectedZeroes.contains(name);
                      return ZeroChip(
                        name: name,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedZeroes.remove(name);
                            } else {
                              _selectedZeroes.add(name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Continue button
              Padding(
                padding: const EdgeInsets.only(bottom: 32, top: 16),
                child: PrimaryButton(
                  label: 'Continue (${_selectedZeroes.length} selected)',
                  onPressed: _selectedZeroes.length >= 3
                      ? () => context.go('/welcome')
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
