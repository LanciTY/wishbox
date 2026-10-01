class WishItem {
  const WishItem({
    this.id,
    required this.title,
    required this.category,
    this.note = '',
    this.sourceUrl = '',
    this.imagePath,
    required this.createdAt,
    this.status = '想要',
    this.isInbox = false,
    this.rawInput = '',
    this.aiOrganized = false,
    this.aiConfidence,
    this.aiSuggestedCategory = '',
    this.aiPending = false,
  });

  final int? id;
  final String title;
  final String category;
  final String note;
  final String sourceUrl;
  final String? imagePath;
  final DateTime createdAt;
  final String status;
  final bool isInbox;
  final String rawInput;
  final bool aiOrganized;
  final double? aiConfidence;
  final String aiSuggestedCategory;
  final bool aiPending;

  String get categoryLabel => category.isEmpty ? '未分类' : category;

  static const categories = ['想买', '想吃', '想去', '想用', '想做', '其他'];
  static const statuses = ['想要', '已完成', '放弃'];

  WishItem copyWith({
    int? id,
    String? title,
    String? category,
    String? note,
    String? sourceUrl,
    String? imagePath,
    bool clearImage = false,
    DateTime? createdAt,
    String? status,
    bool? isInbox,
    String? rawInput,
    bool? aiOrganized,
    double? aiConfidence,
    bool clearAiConfidence = false,
    String? aiSuggestedCategory,
    bool? aiPending,
  }) {
    return WishItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      note: note ?? this.note,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      imagePath: clearImage ? null : imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isInbox: isInbox ?? this.isInbox,
      rawInput: rawInput ?? this.rawInput,
      aiOrganized: aiOrganized ?? this.aiOrganized,
      aiConfidence:
          clearAiConfidence ? null : aiConfidence ?? this.aiConfidence,
      aiSuggestedCategory: aiSuggestedCategory ?? this.aiSuggestedCategory,
      aiPending: aiPending ?? this.aiPending,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'note': note,
        'source_url': sourceUrl,
        'image_path': imagePath,
        'created_at': createdAt.toIso8601String(),
        'status': status,
        'is_inbox': isInbox ? 1 : 0,
        'raw_input': rawInput,
        'ai_organized': aiOrganized ? 1 : 0,
        'ai_confidence': aiConfidence,
        'ai_suggested_category': aiSuggestedCategory,
        'ai_pending': aiPending ? 1 : 0,
      };

  factory WishItem.fromMap(Map<String, Object?> map) => WishItem(
        id: map['id'] as int?,
        title: map['title'] as String,
        category: map['category'] as String,
        note: (map['note'] as String?) ?? '',
        sourceUrl: (map['source_url'] as String?) ?? '',
        imagePath: map['image_path'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        status: map['status'] as String,
        isInbox: (map['is_inbox'] as int? ?? 0) == 1,
        rawInput: (map['raw_input'] as String?) ?? '',
        aiOrganized: (map['ai_organized'] as int? ?? 0) == 1,
        aiConfidence: (map['ai_confidence'] as num?)?.toDouble(),
        aiSuggestedCategory: (map['ai_suggested_category'] as String?) ?? '',
        aiPending: (map['ai_pending'] as int? ?? 0) == 1,
      );
}
