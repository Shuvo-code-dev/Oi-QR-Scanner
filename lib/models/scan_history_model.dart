class ScanHistory {
  int? id;
  final String content;      // scanned/generated text
  final String type;         // 'qr' or 'barcode'
  final String resultType;   // 'url', 'phone', 'text', 'email'
  final DateTime scannedAt;
  final bool isGenerated;
  final bool isFavorite;
  final String category;

  ScanHistory({
    this.id,
    required this.content,
    required this.type,
    required this.resultType,
    required this.scannedAt,
    this.isGenerated = false,
    this.isFavorite = false,
    this.category = 'Other',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'type': type,
      'resultType': resultType,
      'scannedAt': scannedAt.toIso8601String(),
      'isGenerated': isGenerated ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'category': category,
    };
  }

  factory ScanHistory.fromMap(Map<String, dynamic> map) {
    return ScanHistory(
      id: map['id'],
      content: map['content'],
      type: map['type'],
      resultType: map['resultType'],
      scannedAt: DateTime.parse(map['scannedAt']),
      isGenerated: map['isGenerated'] == 1,
      isFavorite: map['isFavorite'] == 1,
      category: map['category'] ?? 'Other',
    );
  }
}
