import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/wish_item.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';
import '../services/link_extractor.dart';

class EditItemScreen extends StatefulWidget {
  const EditItemScreen({super.key, this.item});

  final WishItem? item;

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _urlController = TextEditingController();
  String _category = '';
  String _status = WishItem.statuses.first;
  File? _pickedImage;
  bool _removeImage = false;
  bool _saving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _titleController.text = item.title;
      _noteController.text = item.note;
      _urlController.text = item.sourceUrl;
      _category = item.category;
      _status = item.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (file != null && mounted) {
      setState(() {
        _pickedImage = File(file.path);
        _removeImage = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final oldItem = widget.item;
      final sourceUrl = LinkExtractor.extract(_urlController.text);
      String? imagePath = oldItem?.imagePath;
      if (_pickedImage != null) {
        imagePath =
            await ImageService.instance.copyIntoAppStorage(_pickedImage!);
        if (oldItem?.imagePath != null) {
          await ImageService.instance.deleteIfPresent(oldItem!.imagePath);
        }
      } else if (_removeImage) {
        await ImageService.instance.deleteIfPresent(oldItem?.imagePath);
        imagePath = null;
      }
      final item = WishItem(
        id: oldItem?.id,
        title: _titleController.text.trim(),
        category: _category,
        note: _noteController.text.trim(),
        sourceUrl: sourceUrl ?? '',
        imagePath: imagePath,
        createdAt: oldItem?.createdAt ?? DateTime.now(),
        status: _status,
        isInbox: _category.isEmpty,
        aiPending: false,
      );
      if (_isEditing) {
        await DatabaseService.instance.update(item);
      } else {
        await DatabaseService.instance.insert(item);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalImage = widget.item?.imagePath;
    final hasOriginalImage =
        originalImage != null && File(originalImage).existsSync();
    final preview = _pickedImage ??
        (hasOriginalImage && !_removeImage ? File(originalImage) : null);
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑记录' : '添加记录')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                decoration: const InputDecoration(
                    labelText: '标题 *', hintText: '例如：东京 teamLab'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '请输入标题' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: '分类（可稍后整理）'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('未分类')),
                  ...WishItem.categories.map((value) =>
                      DropdownMenuItem(value: value, child: Text(value))),
                ],
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _noteController,
                minLines: 3,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                    labelText: '备注', hintText: '为什么想把它记下来？'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '来源链接 / 分享文本',
                  hintText: '粘贴链接或整段分享内容',
                  helperText: '可直接粘贴抖音、小红书等分享内容',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return LinkExtractor.extract(value) == null
                      ? '没有识别到有效链接'
                      : null;
                },
              ),
              const SizedBox(height: 18),
              Text('图片（可选）', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (preview != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(preview,
                      height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _pickedImage = null;
                      _removeImage = true;
                    }),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('移除图片'),
                  ),
                ),
              ],
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(preview == null ? '从相册选择一张图片' : '更换图片'),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: '状态'),
                items: WishItem.statuses
                    .map((value) =>
                        DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) => setState(() => _status = value!),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEditing ? '保存修改' : '收进盒子'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
