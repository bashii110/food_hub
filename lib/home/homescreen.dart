import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_hub/home/profile_screen.dart';

import '../components/app_constants.dart';
import '../components/app_string.dart';
import '../presentation/providers/cart_provider.dart';
import '../presentation/providers/food_provider_api.dart';
import '../presentation/providers/theme_provider.dart';

import '../widgets/food_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_state_widget.dart';
import '../cart/cart_screen.dart';
// ← ADD: import ProfileScreen

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: AppConstants.animationDurationNormal,
      vsync: this,
    );
    _fabAnimationController.forward();

    _scrollController.addListener(() {
      if (_scrollController.offset > 100 &&
          !_fabAnimationController.isCompleted) {
        _fabAnimationController.forward();
      } else if (_scrollController.offset <= 100 &&
          _fabAnimationController.isCompleted) {
        _fabAnimationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final displayedFoods = ref.watch(displayedFoodsProvider);
    final popularFoods = ref.watch(popularFoodsProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(displayedFoodsProvider);
          ref.invalidate(popularFoodsProvider);
          ref.invalidate(categoriesProvider);
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ══════════════════════════════════════════════════
            // APP BAR
            // ══════════════════════════════════════════════════
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              actions: [
                // ── Theme Toggle ────────────────────────────────
                IconButton(
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),

                // ── Cart Icon with Badge ────────────────────────
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CartScreen(),
                          ),
                        );
                      },
                    ),
                    if (cartItemCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            cartItemCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),

                // ── Profile Icon ────────────────────────────────
                IconButton(
                  icon: const Icon(Icons.person_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  AppStrings.appName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ══════════════════════════════════════════════════
            // SEARCH BAR
            // ══════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppStrings.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.5),
                  ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                ),
              ),
            ),

            // ══════════════════════════════════════════════════
            // CATEGORIES
            // ══════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppStrings.categories,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 45,
                    child: categoriesAsync.when(
                      loading: () => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 5,
                        itemBuilder: (context, index) => const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: CategoryChipShimmer(),
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Text(
                          'Error loading categories',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      data: (categories) => ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = selectedCategory == category;

                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              ref.read(selectedCategoryProvider.notifier).state =
                                  category;
                            },
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.5),
                            selectedColor:
                            Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            showCheckmark: false,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ══════════════════════════════════════════════════
            // POPULAR SECTION (only show if not searching)
            // ══════════════════════════════════════════════════
            if (_searchController.text.isEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppStrings.popular,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 280,
                      child: popularFoods.when(
                        data: (foods) => foods.isEmpty
                            ? const Center(child: Text('No popular items'))
                            : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: foods.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: 200,
                                child: FoodCard(
                                  food: foods[index],
                                  index: index,
                                ),
                              ),
                            );
                          },
                        ),
                        loading: () => ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: 3,
                          itemBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: SizedBox(
                              width: 200,
                              child: FoodCardShimmer(),
                            ),
                          ),
                        ),
                        error: (error, stack) => Center(
                          child: Text('Error: $error'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

            // ══════════════════════════════════════════════════
            // ALL FOODS SECTION
            // ══════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _searchController.text.isEmpty
                      ? AppStrings.allFoods
                      : 'Search Results',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Food Grid
            displayedFoods.when(
              data: (foods) => foods.isEmpty
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.only(left: 2, right: 2),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.71,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => FoodCard(
                      food: foods[index],
                      index: index,
                    ),
                    childCount: foods.length,
                  ),
                ),
              ),
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => const FoodCardShimmer(),
                    childCount: 6,
                  ),
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: ErrorStateWidget(
                  message: AppStrings.errorLoadingData,
                  onRetry: () {
                    ref.invalidate(displayedFoodsProvider);
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}