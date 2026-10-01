import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/wish_item.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';
import 'edit_item_screen.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.item});
  final WishItem item;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late WishItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditItemScreen(item: _item)),
    );
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条记录？'),
        content: const Text('确定删除这条记录吗？删除后无法恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || _item.id == null) return;
    await DatabaseService.instance.delete(_item.id!);
    await ImageService.instance.deleteIfPresent(_item.imagePath);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _openSource() async {
    final uri = Uri.tryParse(_item.sourceUrl);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法打开这个来源链接')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _item.imagePath;
    final hasImage = imagePath != null && File(imagePath).existsSync();
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录详情'),
        actions: [
          IconButton(
              onPressed: _edit,
              tooltip: '编辑',
              icon: const Icon(Icons.edit_outlined)),
          IconButton(
              onPressed: _delete,
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child:
                  Image.file(File(imagePath), height: 240, fit: BoxFit.cover),
            ),
            const SizedBox(height: 18),
          ],
          Text(_item.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            Chip(label: Text(_item.categoryLabel)),
            if (_item.isInbox) const Chip(label: Text('待整理')),
            if (_item.isInbox && _item.aiSuggestedCategory.isNotEmpty)
              Chip(label: Text('AI 建议：${_item.aiSuggestedCategory}')),
            if (_item.aiOrganized) const Chip(label: Text('✨ AI 整理')),
            Chip(label: Text(_item.status)),
          ]),
          const SizedBox(height: 16),
          if (_item.note.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_item.note,
                    style: const TextStyle(fontSize: 16, height: 1.55)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_item.sourceUrl.isNotEmpty)
            FilledButton.tonalIcon(
              onPressed: _openSource,
              icon: const Icon(Icons.open_in_new),
              label: const Text('打开来源'),
            ),
          const SizedBox(height: 22),
          Text(
            '添加于 ${_item.createdAt.year}-${_item.createdAt.month.toString().padLeft(2, '0')}-${_item.createdAt.day.toString().padLeft(2, '0')} ${_item.createdAt.hour.toString().padLeft(2, '0')}:${_item.createdAt.minute.toString().padLeft(2, '0')}',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
