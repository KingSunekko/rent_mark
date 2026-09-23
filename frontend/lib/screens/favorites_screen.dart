import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/favorites_state.dart';
import '../theme/app_theme.dart';
import '../widgets/compact_item_card.dart';
import '../widgets/empty_state.dart';
import 'item_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesState>().items;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Saved Items')),
      body: favorites.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.favorite_border_rounded,
                title: 'No saved items yet',
                message: 'Tap the heart on an item to save it here.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: favorites.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, index) {
                final item = favorites[index];
                return CompactItemCard(
                  item: item,
                  onTap: () {
                    context.read<FavoritesState>().recordViewed(item);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ItemDetailsScreen(item: item),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
