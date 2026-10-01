import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wishbox/services/ai_organizer.dart';

class _IntentCase {
  const _IntentCase(this.name, this.input, this.category);

  final String name;
  final String input;
  final String category;
}

const _cases = [
  _IntentCase('婚纱写真', '这种法式婚纱写真也太好看了，以后一定要拍这种', '想做'),
  _IntentCase('婚纱商品', '这条 Vera Wang 婚纱以后结婚想买', '想买'),
  _IntentCase('穿搭灵感', '法式秋冬穿搭配色参考，之后可以照着搭', '想做'),
  _IntentCase('衣服商品', '这件黑色风衣好好看，准备买同款', '想买'),
  _IntentCase('餐厅', '成都这家火锅看起来太香了，下次去吃', '想吃'),
  _IntentCase('旅行', '北海道美瑛这个冬天也太漂亮了，以后一定去', '想去'),
  _IntentCase('菜谱', '焦糖三文鱼教程，下次自己试着做', '想做'),
  _IntentCase('食物', '这个焦糖三文鱼看起来好好吃，想去尝尝', '想吃'),
  _IntentCase('摄影店', '成都这家写真馆拍得好好看，以后想去拍一套', '想做'),
  _IntentCase('展览', '这个莫奈展以后想去看看', '想去'),
  _IntentCase('AI 工具', '这个AI数据清洗工具以后试试看', '想用'),
  _IntentCase('开发灵感', '这个旅行地图做得不错，我以后也想做一个类似的', '想做'),
];

void main() {
  test('intent regression catalog covers high-risk ambiguous cases', () {
    expect(_cases, hasLength(12));
    expect(
        _cases.map((item) => item.category),
        containsAll(<String>[
          '想买',
          '想吃',
          '想去',
          '想用',
          '想做',
        ]));
  });

  test(
    'live Gemini classifies intent rather than just visible objects',
    () async {
      final organizer = GeminiAiOrganizer(
        proxy: Platform.environment['GEMINI_HTTP_PROXY'],
      );
      expect(organizer.isConfigured, isTrue);

      for (final item in _cases) {
        final result = await organizer.organize(
          input: item.input,
          sourceUrl: '',
        );
        expect(result, isNotNull, reason: '${item.name} should return JSON');
        expect(result!.category, item.category, reason: item.name);
        expect(result.confidence, inInclusiveRange(0.0, 1.0));
      }
    },
    skip: Platform.environment['RUN_LIVE_GEMINI_TESTS'] != 'true'
        ? 'Requires a local Gemini key and explicit opt-in.'
        : false,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
