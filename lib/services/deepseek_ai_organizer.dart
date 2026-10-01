import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_organizer.dart';

class DeepSeekAiOrganizer implements AiOrganizer {
  DeepSeekAiOrganizer({http.Client? client, String? apiKey, String? model})
      : _client = client ?? http.Client(),
        _apiKeyOverride = apiKey,
        _modelOverride = model;

  static const _configuredKey = String.fromEnvironment('DEEPSEEK_API_KEY');
  static const _configuredModel = String.fromEnvironment('DEEPSEEK_MODEL',
      defaultValue: 'deepseek-v4-flash');
  static const _endpoint = 'https://api.deepseek.com/chat/completions';
  final http.Client _client;
  final String? _apiKeyOverride;
  final String? _modelOverride;

  String get _apiKey => _apiKeyOverride ?? _configuredKey;
  String get _model => _modelOverride ?? _configuredModel;
  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  Future<AiOrganization?> organize(
      {required String input, required String sourceUrl}) async {
    if (!isConfigured) return null;
    final started = DateTime.now();
    try {
      final response = await _client
          .post(Uri.parse(_endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_apiKey',
              },
              body: jsonEncode({
                'model': _model,
                'messages': [
                  {
                    'role': 'system',
                    'content':
                        '${GeminiAiOrganizer.buildIntentPrompt(input: input, sourceUrl: sourceUrl)}\n'
                            'Return a JSON object only, for example {"title":"灰色日抛美瞳","category":"想买","note":"商品种草","confidence":0.98}.',
                  }
                ],
                'response_format': {'type': 'json_object'},
                'thinking': {'type': 'disabled'},
                'max_tokens': 180,
                'stream': false,
              }))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final choices = decoded['choices'];
      final message =
          choices is List && choices.isNotEmpty && choices.first is Map
              ? choices.first['message']
              : null;
      final content = message is Map ? message['content'] : null;
      if (content is! String) return null;
      final result = AiOrganization.fromJson(jsonDecode(content));
      if (result != null && kDebugMode) {
        final usage = DeepSeekUsage.fromJson(decoded['usage']);
        debugPrint(
            'DeepSeek organize: category=${result.category}, confidence=${result.confidence}, '
            'input_tokens=${usage.inputTokens}, cached_tokens=${usage.cachedTokens}, '
            'output_tokens=${usage.outputTokens}, total_tokens=${usage.totalTokens}, '
            'off_peak_usd=${usage.offPeakCostUsd.toStringAsFixed(8)}, '
            'peak_usd=${usage.peakCostUsd.toStringAsFixed(8)}, '
            'latency_ms=${DateTime.now().difference(started).inMilliseconds}');
      }
      return result;
    } catch (_) {
      return null;
    }
  }
}

class DeepSeekUsage {
  const DeepSeekUsage(this.inputTokens, this.cachedTokens, this.outputTokens,
      this.reasoningTokens, this.totalTokens);
  static const priceSnapshotDate = '2026-09-05';
  final int inputTokens,
      cachedTokens,
      outputTokens,
      reasoningTokens,
      totalTokens;
  int get cacheMissTokens => (inputTokens - cachedTokens).clamp(0, inputTokens);
  double get offPeakCostUsd =>
      cachedTokens * .007 / 1e6 +
      cacheMissTokens * .22 / 1e6 +
      outputTokens * .66 / 1e6;
  double get peakCostUsd =>
      cachedTokens * .014 / 1e6 +
      cacheMissTokens * .44 / 1e6 +
      outputTokens * 1.32 / 1e6;
  static DeepSeekUsage fromJson(Object? raw) {
    final value = raw is Map ? raw : const <String, Object?>{};
    int number(Object? item) => item is num ? item.toInt() : 0;
    final inDetail = value['input_tokens_details'];
    final outDetail = value['output_tokens_details'];
    return DeepSeekUsage(
        number(value['input_tokens'] ?? value['prompt_tokens']),
        number(value['cached_tokens'] ??
            (inDetail is Map ? inDetail['cached_tokens'] : null)),
        number(value['output_tokens'] ?? value['completion_tokens']),
        number(value['reasoning_tokens'] ??
            (outDetail is Map ? outDetail['reasoning_tokens'] : null)),
        number(value['total_tokens']));
  }
}
