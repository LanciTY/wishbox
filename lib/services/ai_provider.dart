import 'ai_organizer.dart';
import 'deepseek_ai_organizer.dart';

class AiProvider {
  static const _configured =
      String.fromEnvironment('AI_PROVIDER', defaultValue: 'gemini');

  static AiOrganizer create() => _configured.toLowerCase() == 'deepseek'
      ? DeepSeekAiOrganizer()
      : GeminiAiOrganizer();
}
