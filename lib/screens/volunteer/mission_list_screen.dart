import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../components/mission_card.dart';

class MissionListScreen extends StatefulWidget {
  const MissionListScreen({super.key});

  @override
  State<MissionListScreen> createState() => _MissionListScreenState();
}

class _MissionListScreenState extends State<MissionListScreen> {
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final provider = Provider.of<MissionProvider>(context, listen: false);
      provider.fetchMissions();
      provider.fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    Provider.of<MissionProvider>(context, listen: false).fetchMissions(
      category: _selectedCategory,
      search: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.clay,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              _buildSearchBar(),

              const SizedBox(height: 16),

              // Category Filter Chips
              _buildCategoryFilters(),

              const SizedBox(height: 32),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'In Progress',
                    style: AppTheme.lightTheme.textTheme.displaySmall,
                  ),
                  Consumer<MissionProvider>(
                    builder: (context, provider, _) {
                      final activeCount = provider.missions
                          .where((m) => m.isRegistered)
                          .length;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromRGBO(0, 0, 0, 0.06),
                          ),
                        ),
                        child: Text(
                          '$activeCount active',
                          style: AppTheme.lightTheme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Mission List
              Consumer<MissionProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(child: Text('Error: ${provider.error}'));
                  }

                  if (provider.missions.isEmpty) {
                    return const Center(child: Text('No missions found.'));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.missions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MissionCard(mission: provider.missions[index]),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 100), // Bottom nav padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.06)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {});
          _onFilterChanged();
        },
        decoration: InputDecoration(
          hintText: 'Search missions...',
          hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.ink.withValues(alpha: 0.4),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.ink.withValues(alpha: 0.4),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppTheme.ink.withValues(alpha: 0.4),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onFilterChanged();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FILTER BY CATEGORY',
          style: AppTheme.lightTheme.textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Consumer<MissionProvider>(
            builder: (context, provider, _) {
              return Row(
                children: [
                  _buildCategoryChip(null, 'All'),
                  ...provider.categories.map(
                    (category) =>
                        _buildCategoryChip(category.name, category.name),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? null : category;
        });
        _onFilterChanged();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.forest : Colors.white,
          border: Border.all(
            color: isSelected
                ? AppTheme.forest
                : const Color.fromRGBO(0, 0, 0, 0.1),
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.forest.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: isSelected ? Colors.white : AppTheme.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
