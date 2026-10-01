import 'package:flutter_test/flutter_test.dart';
import 'package:wishbox/services/quick_capture.dart';

void main() {
  final createdAt = DateTime(2026, 9, 2, 10, 0);

  test('turns ordinary text into an uncategorized inbox item', () {
    final item = QuickCapture.itemFrom(
      '想研究一下这个天气可视化网站',
      createdAt: createdAt,
    );

    expect(item.title, '想研究一下这个天气可视化网站');
    expect(item.category, isEmpty);
    expect(item.categoryLabel, '未分类');
    expect(item.sourceUrl, isEmpty);
    expect(item.isInbox, isTrue);
    expect(item.createdAt, createdAt);
  });

  test('turns a URL into an inbox item with a local domain title', () {
    final item = QuickCapture.itemFrom(
      'https://www.example.com/product/123',
      createdAt: createdAt,
    );

    expect(item.title, 'example.com');
    expect(item.sourceUrl, 'https://www.example.com/product/123');
    expect(item.isInbox, isTrue);
  });

  test('keeps ordinary share text as the title while extracting its URL', () {
    final item = QuickCapture.itemFrom(
      '复制打开应用看看这个美瞳 https://v.douyin.com/AbCdEf/ ABC:/',
      createdAt: createdAt,
    );

    expect(item.title, contains('这个美瞳'));
    expect(item.sourceUrl, 'https://v.douyin.com/AbCdEf/');
    expect(item.isInbox, isTrue);
  });
}
