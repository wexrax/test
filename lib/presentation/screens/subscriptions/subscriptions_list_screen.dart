// lib/presentation/screens/subscriptions/subscriptions_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/subscription_list_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionsListScreen extends ConsumerStatefulWidget {
  const SubscriptionsListScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<SubscriptionsListScreen> createState() =>
      _SubscriptionsListScreenState();
}

class _SubscriptionsListScreenState
    extends ConsumerState<SubscriptionsListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _categoryFilter = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(activeSubscriptionsProvider);
    final archived = ref.watch(archivedSubscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подписки'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.activeSubscriptions),
            Tab(text: l10n.archivedSubscriptions),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_categoryFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text('Категория: $_categoryFilter'),
                  onDeleted: () => setState(() => _categoryFilter = null),
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(active),
                _buildList(archived),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<SubscriptionData> list) {
    final query = _searchController.text.toLowerCase();
    final category = _categoryFilter;
    final filtered = list.where((s) {
      final matchesQuery = s.name.toLowerCase().contains(query);
      final matchesCategory = category == null || s.category == category;
      return matchesQuery && matchesCategory;
    }).toList();
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) => SubscriptionListTile(
        subscription: filtered[i],
        onTap: () => context.push('/subscriptions/${filtered[i].id}'),
      ),
    );
  }
}
