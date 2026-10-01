/// Extracts the first usable web URL from a plain URL or a copied share text.
///
/// This intentionally does not visit or expand links. It only works with the
/// text already pasted by the user, so it is safe for share text from any app.
class LinkExtractor {
  LinkExtractor._();

  static final RegExp _urlPattern = RegExp(
    r'''https?://[^\s<>"'，。！？；：、]+''',
    caseSensitive: false,
  );

  static const _trailingPunctuation = ".,!?;:)\\]}\"'，。！？；：、】【》〉）〕”’";

  /// Returns the first valid http(s) URL in [text], or null when there is none.
  static String? extract(String text) {
    for (final match in _urlPattern.allMatches(text)) {
      final candidate = _trimTrailingPunctuation(match.group(0)!);
      final uri = Uri.tryParse(candidate);
      if (uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }

  static String _trimTrailingPunctuation(String value) {
    var end = value.length;
    while (end > 0 && _trailingPunctuation.contains(value[end - 1])) {
      end--;
    }
    return value.substring(0, end);
  }
}
