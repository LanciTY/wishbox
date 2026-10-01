import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/wish_item.dart';
import '../services/ai_provider.dart';
import '../services/database_service.dart';
import '../services/quick_capture.dart';
import 'detail_screen.dart';
import 'edit_item_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _quickCaptureController = TextEditingController();
  final _aiOrganizer = AiProvider.create();
  String? _category;
  String? _status;
  bool _inboxOnly = false;
  List<WishItem> _items = const [];
  Object? _loadError;
  bool _isLoading = true;
  bool _isCapturing = false;
  int _inboxCount = 0;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _reloadItems(showLoading: true);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _quickCaptureController.dispose();
    super.dispose();
  }

  Future<List<WishItem>> _loadItems() => DatabaseService.instance.getItems(
        query: _searchController.text,
        category: _category,
        status: _status,
        inboxOnly: _inboxOnly,
      );

  void _onSearchChanged() => _reloadItems();

  Future<void> _reloadItems({bool showLoading = false}) async {
    final version = ++_requestVersion;
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final itemsFuture = _loadItems();
      final inboxCountFuture = DatabaseService.instance.getInboxCount();
      final items = await itemsFuture;
      final inboxCount = await inboxCountFuture;
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _items = items;
        _inboxCount = inboxCount;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  Future<void> _quickCapture() async {
    final input = _quickCaptureController.text.trim();
    if (input.isEmpty || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final fallback = QuickCapture.itemFrom(input).copyWith(
        aiPending: _aiOrganizer.isConfigured,
      );
      final id = await DatabaseService.instance.insert(fallback);
      if (!mounted) return;
      _quickCaptureController.clear();
      await _reloadItems();
      if (!mounted) return;
      if (_aiOrganizer.isConfigured) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('已收好，正在整理…'), duration: Duration(seconds: 2)),
        );
        unawaited(_organizeSavedItem(fallback.copyWith(id: id)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('已收好，稍后整理'), duration: Duration(seconds: 1)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('暂时没能收好：$error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _organizeSavedItem(WishItem item) async {
    final organization = await _aiOrganizer.organize(
      input: item.rawInput,
      sourceUrl: item.sourceUrl,
    );
    if (!mounted) return;
    final organized = QuickCapture.applyOrganization(item, organization)
        .copyWith(aiPending: false);
    final didUpdate = await DatabaseService.instance.finishPendingAi(organized);
    if (didUpdate) {
      await _reloadItems();
    }
    if (!mounted) return;
    if (!didUpdate) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          organization == null
              ? '已收好，稍后整理'
              : organized.isInbox
                  ? '已收好，AI 建议稍后确认'
                  : '已收好并整理 ✓',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openEditor([WishItem? item]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditItemScreen(item: item)),
    );
    if (changed == true && mounted) await _reloadItems();
  }

  Future<void> _openDetail(WishItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DetailScreen(item: item)),
    );
    if (changed == true && mounted) await _reloadItems();
  }

  void _clearFilters() {
    setState(() {
      _category = null;
      _status = null;
      _inboxOnly = false;
    });
    _reloadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('灵感盒子', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 1),
            Text('把想做的事，轻轻收进这里',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _QuickCaptureField(
                controller: _quickCaptureController,
                saving: _isCapturing,
                onSubmit: _quickCapture,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _InboxChip(
                  count: _inboxCount,
                  selected: _inboxOnly,
                  onPressed: () {
                    setState(() => _inboxOnly = !_inboxOnly);
                    _reloadItems();
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '搜索标题或备注',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _searchController.clear,
                        ),
                ),
              ),
            ),
            _FilterBar(
              category: _category,
              status: _status,
              onCategoryChanged: (value) {
                setState(() => _category = value);
                _reloadItems();
              },
              onStatusChanged: (value) {
                setState(() => _status = value);
                _reloadItems();
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  Text(
                    _inboxOnly
                        ? '待整理 ${_items.length} 条'
                        : _items.isEmpty
                            ? '最近收集'
                            : '最近收集 · ${_items.length} 条',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (_category != null || _status != null || _inboxOnly)
                    TextButton(
                        onPressed: _clearFilters, child: const Text('清除筛选')),
                ],
              ),
            ),
            Expanded(
              child: _isLoading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? _LoadError(
                          onRetry: () => _reloadItems(showLoading: true))
                      : RefreshIndicator(
                          onRefresh: _reloadItems,
                          child: _items.isEmpty
                              ? ListView(
                                  children: [
                                    const SizedBox(height: 90),
                                    _EmptyState(inboxOnly: _inboxOnly),
                                  ],
                                )
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 100),
                                  itemCount: _items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (_, index) => _WishCard(
                                    key: ValueKey(_items[index].id),
                                    item: _items[index],
                                    onTap: () => _openDetail(_items[index]),
                                  ),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCaptureField extends StatelessWidget {
  const _QuickCaptureField({
    required this.controller,
    required this.saving,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onSubmit(),
        decoration: InputDecoration(
          hintText: '粘贴链接，或者随便记点什么……',
          prefixIcon: const Icon(Icons.add_link_outlined),
          suffixIcon: IconButton(
            onPressed: saving ? null : onSubmit,
            tooltip: '收进盒子',
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_upward_rounded),
          ),
        ),
      );
}

class _InboxChip extends StatelessWidget {
  const _InboxChip(
      {required this.count, required this.selected, required this.onPressed});

  final int count;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: const Icon(Icons.inbox_outlined, size: 18),
        label: Text('待整理 $count'),
        onPressed: onPressed,
        backgroundColor: selected
            ? Theme.of(context).colorScheme.secondaryContainer
            : Colors.white,
      );
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.category,
    required this.status,
    required this.onCategoryChanged,
    required this.onStatusChanged,
  });

  final String? category;
  final String? status;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _FilterMenu(
              label: category ?? '全部分类',
              icon: Icons.category_outlined,
              values: WishItem.categories,
              active: category,
              onSelected: onCategoryChanged,
            ),
            const SizedBox(width: 8),
            _FilterMenu(
              label: status ?? '全部状态',
              icon: Icons.flag_outlined,
              values: WishItem.statuses,
              active: status,
              onSelected: onStatusChanged,
            ),
          ],
        ),
      );
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.icon,
    required this.values,
    required this.active,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final List<String> values;
  final String? active;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String?>(
        onSelected: onSelected,
        itemBuilder: (_) => [
          const PopupMenuItem<String?>(value: null, child: Text('全部')),
          ...values
              .map((value) => PopupMenuItem(value: value, child: Text(value))),
        ],
        child: Chip(
          avatar: Icon(icon, size: 18),
          label: Text(label),
          side: BorderSide.none,
          backgroundColor: active == null
              ? Colors.white
              : Theme.of(context).colorScheme.secondaryContainer,
        ),
      );
}

class _WishCard extends StatelessWidget {
  const _WishCard({super.key, required this.item, required this.onTap});

  final WishItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imagePath = item.imagePath;
    final hasImage = imagePath != null && File(imagePath).existsSync();
    return Card(
      shadowColor: const Color(0xFF6C5545).withValues(alpha: 0.08),
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(imagePath),
                      width: 88, height: 88, fit: BoxFit.cover),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1),
                    ),
                    const SizedBox(height: 7),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      _Tag(text: item.categoryLabel),
                      if (item.isInbox)
                        const _Tag(text: '待整理', highlighted: true),
                      if (item.isInbox && item.aiSuggestedCategory.isNotEmpty)
                        _Tag(text: 'AI 建议：${item.aiSuggestedCategory}'),
                      if (item.aiOrganized)
                        const _Tag(text: '✨ AI 整理', highlighted: true),
                      _Tag(
                          text: item.status, highlighted: item.status == '已完成'),
                    ]),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.note,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Text(
                      '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(Icons.chevron_right, color: Color(0xFF8C817A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.highlighted = false});
  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: highlighted
              ? Theme.of(context).colorScheme.secondaryContainer
              : const Color(0xFFF1ECE7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.inboxOnly = false});
  final bool inboxOnly;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome_outlined,
                    size: 34, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 14),
              Text(
                inboxOnly ? '待整理里暂时是空的' : '还没有收进盒子的灵感',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                inboxOnly ? '看到什么就先扔进来，之后再慢慢整理。' : '在上方随手记一条，或点击右下角「添加」。',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: FilledButton.tonalIcon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('重新读取记录'),
        ),
      );
}
