import '../models/wish_item.dart';
import 'ai_organizer.dart';
import 'link_extractor.dart';

class QuickCapture {
  QuickCapture._();

  static const confidenceThreshold = 0.85;

  /// Builds an inbox item without accessing the network or enriching the URL.
  static WishItem itemFrom(String input, {DateTime? createdAt}) {
    final text = input.trim();
    final sourceUrl = LinkExtractor.extract(text) ?? '';
    final isOnlyUrl = sourceUrl.isNotEmpty && text == sourceUrl;

    return WishItem(
      title: isOnlyUrl ? _titleForUrl(sourceUrl) : text,
      category: '',
      sourceUrl: sourceUrl,
      createdAt: createdAt ?? DateTime.now(),
      status: WishItem.statuses.first,
      isInbox: true,
      rawInput: text,
    );
  }

  static WishItem applyOrganization(
      WishItem item, AiOrganization? organization) {
    if (organization == null) return item;
    final isHighConfidence = organization.confidence >= confidenceThreshold;
    return item.copyWith(
      title: organization.title,
      category: isHighConfidence ? organization.category : '',
      note: organization.note,
      isInbox: !isHighConfidence,
      aiOrganized: isHighConfidence,
      aiConfidence: organization.confidence,
      aiSuggestedCategory: isHighConfidence ? '' : organization.category,
    );
  }

  static String _titleForUrl(String sourceUrl) {
    final host = Uri.parse(sourceUrl).host;
    return host.startsWith('www.') ? host.substring(4) : host;
  }
}
