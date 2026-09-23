import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/rental_item.dart';
import '../widgets/rentmark_search_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/compact_item_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../screens/item_details_screen.dart';
import '../state/favorites_state.dart';
import '../state/auth_state.dart';
import '../data/owner_listings_store.dart';
import '../widgets/item_image.dart';

/// Dedicated Search screen — back button, live search field, filter
/// button, recent searches, category row, and results using the same
/// [CompactItemCard] as Home's Popular section.
class SearchScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SearchScreen({super.key, this.onBack});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ownerListings = OwnerListingsStore.instance;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  String _query = '';
  ItemCategory _category = ItemCategory.all;
  AvailabilityFilter _availability = AvailabilityFilter.available;
  SortOption _sort = SortOption.nearest;
  bool _gridView = false;
  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _ownerListings.addListener(_refreshListings);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ownerListings.loadPublic(context.read<AuthState>().accessToken);
      }
    });
  }

  @override
  void dispose() {
    _ownerListings.removeListener(_refreshListings);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _refreshListings() => setState(() {});

  bool get _hasQuery => _query.trim().isNotEmpty;
  bool get _hasActiveSearch => _hasQuery || _category != ItemCategory.all;

  List<RentalItem> get _results {
    final backendItems = _ownerListings.discoveryItems
        .map((item) => item.toRentalItem())
        .where((item) {
          final query = _query.trim().toLowerCase();
          final categoryMatches =
              _category == ItemCategory.all || item.category == _category;
          final queryMatches =
              query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query) ||
              item.category.label.toLowerCase().contains(query);
          return categoryMatches && queryMatches;
        });
    var results = backendItems.toList();

    if (_availability == AvailabilityFilter.available) {
      results = results.where((i) => i.isAvailable).toList();
    }

    switch (_sort) {
      case SortOption.nearest:
        results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      case SortOption.lowestPrice:
        results.sort(
          (a, b) => a.dailyPriceCentavos.compareTo(b.dailyPriceCentavos),
        );
        break;
      case SortOption.highestPrice:
        results.sort(
          (a, b) => b.dailyPriceCentavos.compareTo(a.dailyPriceCentavos),
        );
        break;
      case SortOption.highestRated:
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return results;
  }

  void _clearSearch() {
    setState(() {
      _controller.clear();
      _query = '';
      _category = ItemCategory.all;
    });
  }

  Future<void> _openFilters() async {
    final result = await showFilterSheet(
      context,
      current: FilterResult(
        category: _category,
        availability: _availability,
        sort: _sort,
      ),
    );
    if (result != null) {
      setState(() {
        _category = result.category;
        _availability = result.availability;
        _sort = result.sort;
      });
    }
  }

  void _openItem(RentalItem item) {
    context.read<FavoritesState>().recordViewed(item);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item)));
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap:
                        widget.onBack ?? () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySofter,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: RentMarkSearchBar(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      onFilterTap: _openFilters,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  if (!_hasQuery) ...[
                    Text(
                      'Recent Searches',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recentSearches.map((term) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          onTap: () {
                            _controller.text = term;
                            setState(() => _query = term);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.history_rounded,
                                  size: 15,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  term,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _recentSearches.remove(term),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  Text(
                    'Browse Categories',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ItemCategory.values.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final category = ItemCategory.values[i];
                        return CategoryChip(
                          category: category,
                          selected: _category == category,
                          onTap: () => setState(() => _category = category),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_hasActiveSearch) ...[
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (_hasQuery)
                          InputChip(
                            label: Text('Search: $_query'),
                            onDeleted: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          ),
                        if (_category != ItemCategory.all)
                          InputChip(
                            label: Text(_category.label),
                            onDeleted: () =>
                                setState(() => _category = ItemCategory.all),
                          ),
                        InputChip(
                          label: Text(_availability.name),
                          onDeleted: () => setState(
                            () => _availability = AvailabilityFilter.all,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearSearch,
                          child: const Text('CLEAR ALL'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _hasActiveSearch
                              ? 'Search Results (${results.length})'
                              : 'All Items (${results.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'List view',
                        onPressed: () => setState(() => _gridView = false),
                        color: !_gridView
                            ? AppColors.primary
                            : AppColors.textMuted,
                        icon: const Icon(Icons.view_list_rounded),
                      ),
                      IconButton(
                        tooltip: 'Grid view',
                        onPressed: () => setState(() => _gridView = true),
                        color: _gridView
                            ? AppColors.primary
                            : AppColors.textMuted,
                        icon: const Icon(Icons.grid_view_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (results.isEmpty)
                    EmptyState(onAction: _clearSearch)
                  else if (!_gridView)
                    Column(
                      children: results
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm + 2,
                              ),
                              child: CompactItemCard(
                                item: item,
                                onTap: () => _openItem(item),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: results.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.sm,
                            childAspectRatio: .78,
                          ),
                      itemBuilder: (_, index) => _SearchGridCard(
                        item: results[index],
                        onTap: () => _openItem(results[index]),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchGridCard extends StatelessWidget {
  final RentalItem item;
  final VoidCallback onTap;
  const _SearchGridCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ItemImage(
              imageUrl: item.imageUrl,
              icon: item.icon,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  item.priceLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
