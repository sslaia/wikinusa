class HomePageSection {
  final String titleKey;
  final String textHtml;
  final Map<String, String?> data;

  HomePageSection({
    required this.titleKey,
    required this.textHtml,
    required this.data,
  });

  /// Helper to get the image HTML using the dynamic key
  String? get imageHtml => data['${titleKey}ImageHtml'] ?? data['imageHtml'];

  /// Helper to get the image URL using the dynamic key
  String? get imageUrl {
    final url = data['${titleKey}ImageUrl'] ?? data['imageUrl'];
    if (url != null && url.isNotEmpty) return url;
    final html = imageHtml;
    if (html != null && html.isNotEmpty) {
      final match = RegExp(r'src="([^"]+)"').firstMatch(html);
      if (match != null) return match.group(1);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'titleKey': titleKey,
        'textHtml': textHtml,
        'data': data,
      };

  factory HomePageSection.fromJson(Map<String, dynamic> json) => HomePageSection(
        titleKey: json['titleKey'],
        textHtml: json['textHtml'],
        data: Map<String, String?>.from(json['data'] ?? {}),
      );
}
