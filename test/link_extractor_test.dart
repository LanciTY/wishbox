import 'package:flutter_test/flutter_test.dart';
import 'package:wishbox/services/link_extractor.dart';

void main() {
  group('LinkExtractor.extract', () {
    test('keeps a normal https URL', () {
      expect(LinkExtractor.extract('https://example.com/item?id=1'),
          'https://example.com/item?id=1');
    });

    test('keeps a normal http URL', () {
      expect(LinkExtractor.extract('http://example.com/item'),
          'http://example.com/item');
    });

    test('extracts a Douyin share link from full share text', () {
      expect(
        LinkExtractor.extract(
            '3.28 复制打开抖音，看看【小美的作品】这个美瞳很好看 https://v.douyin.com/AbCdEf/ ABC:/ 08/21'),
        'https://v.douyin.com/AbCdEf/',
      );
    });

    test('keeps a Douyin short link', () {
      expect(LinkExtractor.extract('https://v.douyin.com/AbCdEf/'),
          'https://v.douyin.com/AbCdEf/');
    });

    test('extracts a Xiaohongshu share link from full share text', () {
      expect(
        LinkExtractor.extract(
            '发现一个超好看的东西！复制后打开【小红书】查看笔记 https://xhslink.com/abcDeFg'),
        'https://xhslink.com/abcDeFg',
      );
    });

    test('keeps a Xiaohongshu short link', () {
      expect(LinkExtractor.extract('https://xhslink.com/abcDeFg'),
          'https://xhslink.com/abcDeFg');
    });

    test('removes trailing Chinese punctuation', () {
      expect(LinkExtractor.extract('看看这个 https://example.com/item。'),
          'https://example.com/item');
    });

    test('removes trailing English punctuation', () {
      expect(LinkExtractor.extract('See https://example.com/item!'),
          'https://example.com/item');
    });

    test('uses the first valid URL when several are present', () {
      expect(
        LinkExtractor.extract(
            '先看 https://first.example.com，再看 https://second.example.com'),
        'https://first.example.com',
      );
    });

    test('returns null for ordinary text without a URL', () {
      expect(LinkExtractor.extract('这个美瞳真的很好看'), isNull);
    });

    test('returns null for an empty string', () {
      expect(LinkExtractor.extract(''), isNull);
    });

    test('finds a URL after a line break', () {
      expect(LinkExtractor.extract('复制后打开应用\nhttps://example.com/note'),
          'https://example.com/note');
    });
  });
}
