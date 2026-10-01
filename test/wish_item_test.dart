import 'package:flutter_test/flutter_test.dart';
import 'package:wishbox/models/wish_item.dart';

void main() {
  test('WishItem preserves data through a database map', () {
    final createdAt = DateTime(2026, 9, 1, 9, 30);
    const title = '东京 teamLab';
    final original = WishItem(
      id: 7,
      title: title,
      category: '想去',
      note: '下次东京行安排进去',
      sourceUrl: 'https://example.com/teamlab',
      imagePath: '/data/images/teamlab.jpg',
      createdAt: createdAt,
      status: '想要',
    );

    final restored = WishItem.fromMap(original.toMap());

    expect(restored.id, 7);
    expect(restored.title, title);
    expect(restored.category, '想去');
    expect(restored.note, contains('东京行'));
    expect(restored.createdAt, createdAt);
    expect(restored.isInbox, isFalse);
  });

  test('copyWith changes status without changing creation time', () {
    final createdAt = DateTime(2026, 9, 1, 9, 30);
    final item = WishItem(title: '一副墨镜', category: '想买', createdAt: createdAt);

    final completed = item.copyWith(status: '已完成');

    expect(completed.status, '已完成');
    expect(completed.createdAt, createdAt);
  });

  test('copyWith can move an inbox item out after it is categorized', () {
    final item = WishItem(
      title: '一条链接',
      category: '',
      createdAt: DateTime(2026, 9, 2),
      isInbox: true,
    );

    final organized = item.copyWith(category: '想买', isInbox: false);

    expect(organized.category, '想买');
    expect(organized.isInbox, isFalse);
  });
}
