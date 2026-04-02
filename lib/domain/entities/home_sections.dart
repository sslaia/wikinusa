class HomeSections {
  final String featuredArticle;
  final String featuredPhoto;
  final String doYouKnow;
  final String thisMonthInHistory;

  HomeSections({
    required this.featuredArticle,
    required this.featuredPhoto,
    required this.doYouKnow,
    required this.thisMonthInHistory,
  });

  bool get hasContent =>
      featuredArticle.isNotEmpty ||
      featuredPhoto.isNotEmpty ||
      doYouKnow.isNotEmpty ||
      thisMonthInHistory.isNotEmpty;
}
