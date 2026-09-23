import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/owner_listings_store.dart';
import '../models/owner_listing.dart';
import '../models/rental_item.dart';
import '../theme/app_theme.dart';
import '../state/auth_state.dart';
import 'add_edit_item_screen.dart';

class OwnerListingsScreen extends StatefulWidget {
  final String community;
  final bool showBack;
  const OwnerListingsScreen({
    super.key,
    required this.community,
    this.showBack = true,
  });

  @override
  State<OwnerListingsScreen> createState() => _OwnerListingsScreenState();
}

class _OwnerListingsScreenState extends State<OwnerListingsScreen> {
  final store = OwnerListingsStore.instance;

  @override
  void initState() {
    super.initState();
    store.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthState>();
        store.loadOwner(auth.accessToken, ownerId: auth.currentUser?.id);
      }
    });
  }

  @override
  void dispose() {
    store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _openEditor([OwnerListing? item]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddEditItemScreen(item: item, community: widget.community),
      ),
    );
  }

  Future<void> _delete(OwnerListing item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('Remove "${item.name}" from your listings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      try {
        await store.removeRemote(
          item.id,
          context.read<AuthState>().accessToken,
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = store.items;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBack,
        title: const Text('My Listings'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (store.error != null)
              Container(
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        store.error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final auth = context.read<AuthState>();
                        store.loadOwner(
                          auth.accessToken,
                          ownerId: auth.currentUser?.id,
                        );
                      },
                      child: const Text('RETRY'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: store.isLoading && items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 58,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No listings yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Add your first item and make it available to your community.',
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        96,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, index) => _ListingCard(
                        item: items[index],
                        onEdit: () => _openEditor(items[index]),
                        onDelete: () => _delete(items[index]),
                        onToggleAvailability: () async {
                          final token = context.read<AuthState>().accessToken;
                          try {
                            await store.toggleAvailabilityRemote(
                              items[index].id,
                              token,
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final OwnerListing item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  const _ListingCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final unavailable = item.availability == AvailabilityStatus.unavailable;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: item.imageUrl.isEmpty
                ? Container(
                    color: AppColors.primarySofter,
                    child: Icon(item.icon, size: 52, color: AppColors.primary),
                  )
                : item.imageUrl.startsWith('http')
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallbackImage(item),
                  )
                : Image.file(
                    File(item.imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallbackImage(item),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit item')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete item'),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '${item.category.label} • ${item.condition}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      item.priceLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: unavailable
                            ? AppColors.errorSoft
                            : const Color(0xFFEAF7F0),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        item.availability.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: unavailable
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onToggleAvailability,
                    icon: Icon(
                      unavailable
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    label: Text(
                      unavailable ? 'MARK AVAILABLE' : 'MARK UNAVAILABLE',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _fallbackImage(OwnerListing item) => Container(
  color: AppColors.primarySofter,
  child: Icon(item.icon, size: 52, color: AppColors.primary),
);
