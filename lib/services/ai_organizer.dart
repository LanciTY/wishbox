import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../models/wish_item.dart';

class AiOrganization {
  const AiOrganization({
    required this.title,
    required this.category,
    required this.note,
    required this.confidence,
  });

  final String title;
  final String category;
  final String note;
  final double confidence;

  static AiOrganization? fromJson(Object? value) {
    if (value is! Map) return null;
    final title = value['title'];
    final category = value['category'];
    final note = value['note'];
    final confidence = value['confidence'];
    if (title is! String ||
        category is! String ||
        note is! String ||
        confidence is! num) {
      return null;
    }
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty || !WishItem.categories.contains(category)) {
      return null;
    }
    return AiOrganization(
      title: normalizedTitle,
      category: category,
      note: note.trim(),
      confidence: confidence.toDouble().clamp(0.0, 1.0).toDouble(),
    );
  }
}

abstract class AiOrganizer {
  bool get isConfigured;

  Future<AiOrganization?> organize(
      {required String input, required String sourceUrl});
}

class GeminiAiOrganizer implements AiOrganizer {
  GeminiAiOrganizer({
    http.Client? client,
    String? apiKey,
    String? model,
    bool? enableUrlContext,
    String? proxy,
  })  : _client = client ?? _createClient(proxy),
        _apiKeyOverride = apiKey,
        _modelOverride = model,
        _urlContextOverride = enableUrlContext;

  static const _configuredApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _configuredModel =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.8-flash');
  static const _configuredUrlContext =
      bool.fromEnvironment('GEMINI_URL_CONTEXT', defaultValue: true);
  static const _configuredProxy = String.fromEnvironment('GEMINI_HTTP_PROXY');
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/interactions';

  final http.Client _client;
  final String? _apiKeyOverride;
  final String? _modelOverride;
  final bool? _urlContextOverride;

  String get _apiKey => _apiKeyOverride ?? _configuredApiKey;
  String get _model => _modelOverride ?? _configuredModel;
  bool get _urlContextEnabled => _urlContextOverride ?? _configuredUrlContext;

  static http.Client _createClient(String? proxy) {
    final configuredProxy = (proxy ?? _configuredProxy).trim();
    if (configuredProxy.isEmpty) return http.Client();
    final client = HttpClient()..findProxy = (_) => 'PROXY $configuredProxy';
    return IOClient(client);
  }

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  Future<AiOrganization?> organize(
      {required String input, required String sourceUrl}) async {
    if (!isConfigured) return null;
    try {
      final request = <String, Object?>{
        'model': _model,
        'input': buildIntentPrompt(input: input, sourceUrl: sourceUrl),
        'response_format': {
          'type': 'text',
          'mime_type': 'application/json',
          'schema': _responseSchema,
        },
        'generation_config': {
          'thinking_level': 'low',
        },
      };
      if (_urlContextEnabled && sourceUrl.isNotEmpty) {
        request['tools'] = [
          {'type': 'url_context'},
        ];
      }
      final response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey
            },
            body: jsonEncode(request),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      return AiOrganization.fromJson(jsonDecode(_outputText(decoded)));
    } catch (_) {
      return null;
    }
  }

  static String _outputText(Map decoded) {
    final steps = decoded['steps'];
    if (steps is! List) {
      throw const FormatException('Missing interaction steps');
    }
    for (final step in steps) {
      if (step is! Map || step['type'] != 'model_output') continue;
      final content = step['content'];
      if (content is! List) continue;
      for (final part in content) {
        if (part is Map && part['type'] == 'text' && part['text'] is String) {
          return part['text'] as String;
        }
      }
    }
    throw const FormatException('Missing interaction text output');
  }

  static const _responseSchema = <String, Object>{
    'type': 'object',
    'properties': {
      'title': {
        'type': 'string',
        'description': 'Short natural Chinese title.'
      },
      'category': {
        'type': 'string',
        'enum': ['想买', '想吃', '想去', '想用', '想做', '其他'],
      },
      'note': {
        'type': 'string',
        'description': 'A concise reminder of at most 30 Chinese characters.'
      },
      'confidence': {'type': 'number', 'minimum': 0, 'maximum': 1},
    },
    'required': ['title', 'category', 'note', 'confidence'],
  };

  static String buildIntentPrompt({
    required String input,
    required String sourceUrl,
  }) =>
      '''
你是 Wishbox 的轻量整理助手。请判断用户为什么保存这条内容，以及用户未来最可能执行什么动作；不要只根据内容中出现的物品、地点或食物分类。只返回符合 JSON schema 的结果，不输出分析过程。

分类只能为：想买、想吃、想去、想用、想做、其他。

分类按未来动作决定：
- 想买：明确想购买具体实体商品，例如商品、同款、型号、种草或购买意图。
- 想吃：未来想吃某种食物，或去餐厅、咖啡店主要为了吃喝。地点加餐饮通常优先想吃。
- 想去：未来想去旅行、参观、逛、看展，主要体验地点本身。
- 想用：未来想使用软件、网站、App、在线服务、API 或数字工具。
- 想做：未来想尝试、学习、制作、拍摄、复刻、完成项目或体验活动。灵感、风格参考、教程、攻略、创意类内容通常优先考虑想做。
- 其他：只有无法合理判断未来动作时使用；不确定时降低 confidence，而不是滥用其他。

重要反例：出现商品不等于想买（婚纱写真灵感、穿搭拍照姿势可为想做）；出现地点不等于想去（餐厅推荐主要为想吃）；出现食物不等于想吃（菜谱或教程、自己试做为想做）。例如“以后一定要拍这种法式婚纱写真”应为想做；“这条婚纱以后结婚想买”才是想买。

信息优先级：原始分享文字中明确的用户意图最高，其次是可读取网页的标题或正文，最后才是 URL 域名或平台。淘宝、京东、拼多多等域名只可作为想买的弱信号，不能覆盖明确语义；小红书不代表任何固定分类。

title 简洁自然，不写营销文案，不编造没有提供的名称。note 用一句简短提醒说明保存目的或内容特点，最多约 30 个中文字符。confidence 表示对用户意图和分类的把握，不是对内容对象的把握；意图含糊时降低 confidence。

原始输入：
$input

来源链接：
${sourceUrl.isEmpty ? '无' : sourceUrl}
''';
}
