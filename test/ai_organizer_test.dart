import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wishbox/services/ai_organizer.dart';
import 'package:wishbox/services/deepseek_ai_organizer.dart';
import 'package:wishbox/services/quick_capture.dart';

void main() {
  final createdAt = DateTime(2026, 9, 2, 12);

  capture(String text) => QuickCapture.itemFrom(text, createdAt: createdAt);

  test('both providers without a key skip HTTP and preserve the Inbox item',
      () async {
    final client = MockClient((request) async {
      fail('An unconfigured provider must not send a network request.');
    });
    final providers = <AiOrganizer>[
      GeminiAiOrganizer(client: client, apiKey: ''),
      DeepSeekAiOrganizer(client: client, apiKey: ''),
    ];
    for (final provider in providers) {
      expect(provider.isConfigured, isFalse);
      final fallback = capture('A synthetic offline capture');
      final result = await provider.organize(
          input: fallback.rawInput, sourceUrl: fallback.sourceUrl);
      expect(result, isNull);
      final item = QuickCapture.applyOrganization(fallback, result);
      expect(item, same(fallback));
      expect(item.isInbox, isTrue);
      expect(item.aiPending, isFalse);
    }
    client.close();
  });

  test('high-confidence organization auto-categorizes all core text cases', () {
    final cases = [
      ('想买一副灰色日抛美瞳', '灰色日抛美瞳', '想买'),
      ('想去吃这家成都火锅', '成都火锅', '想吃'),
      ('北海道美瑛以后一定要去', '北海道美瑛', '想去'),
      ('这个天气可视化网站以后试试', '天气可视化网站', '想用'),
      ('做一个自动筛选租房信息的小程序', '租房筛选小程序', '想做'),
    ];

    for (final entry in cases) {
      final item = QuickCapture.applyOrganization(
        capture(entry.$1),
        AiOrganization(
            title: entry.$2, category: entry.$3, note: '', confidence: 0.95),
      );
      expect(item.category, entry.$3);
      expect(item.isInbox, isFalse);
      expect(item.aiOrganized, isTrue);
    }
  });

  test('low-confidence organization stays in Inbox with an AI suggestion', () {
    final item = QuickCapture.applyOrganization(
      capture('这个好像不错'),
      const AiOrganization(
          title: '一个不错的东西', category: '想买', note: '', confidence: 0.60),
    );

    expect(item.category, isEmpty);
    expect(item.isInbox, isTrue);
    expect(item.aiSuggestedCategory, '想买');
    expect(item.aiOrganized, isFalse);
  });

  test('AI failure leaves the fallback capture untouched in Inbox', () {
    final fallback = capture('https://unreadable.example/item');
    final item = QuickCapture.applyOrganization(fallback, null);

    expect(item, same(fallback));
    expect(item.isInbox, isTrue);
    expect(item.sourceUrl, 'https://unreadable.example/item');
  });

  test('an AI result preserves the pending guard until the database commits it',
      () {
    final pending = capture('想买一副灰色日抛美瞳').copyWith(aiPending: true);
    final item = QuickCapture.applyOrganization(
      pending,
      const AiOrganization(
          title: '灰色日抛美瞳', category: '想买', note: '', confidence: 0.98),
    );

    expect(item.aiPending, isTrue);
    expect(item.aiOrganized, isTrue);
  });

  test(
      'Gemini structured response is parsed and requests URL Context for a URL',
      () async {
    late Map<String, dynamic> requestBody;
    final client = MockClient((request) async {
      requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'steps': [
            {
              'type': 'model_output',
              'content': [
                {
                  'type': 'text',
                  'text': jsonEncode({
                    'title': '测试商品',
                    'category': '想买',
                    'note': '公开测试页面',
                    'confidence': 0.93,
                  }),
                },
              ],
            },
          ],
        })),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final organizer = GeminiAiOrganizer(
      client: client,
      apiKey: 'test-key',
      model: 'gemini-3.8-flash',
      enableUrlContext: true,
    );

    final result = await organizer.organize(
      input: '测试商品 https://example.com/item',
      sourceUrl: 'https://example.com/item',
    );

    expect(result?.category, '想买');
    expect(result?.confidence, 0.93);
    expect(requestBody['model'], 'gemini-3.8-flash');
    expect(requestBody['tools'], [
      {'type': 'url_context'}
    ]);
    expect((requestBody['response_format'] as Map)['schema'], isNotNull);
    expect((requestBody['generation_config'] as Map)['thinking_level'], 'low');
  });

  test('invalid Gemini category is rejected as a safe fallback', () {
    expect(
      AiOrganization.fromJson({
        'title': '测试',
        'category': '新分类',
        'note': '',
        'confidence': 0.9,
      }),
      isNull,
    );
  });
}
