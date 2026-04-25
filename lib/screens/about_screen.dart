import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wikinusa/widgets/wiki_footer.dart';

class AboutScreen extends StatelessWidget {
  final String title;
  final String body;

  const AboutScreen({super.key, required this.title, required this.body});

  static const List<String> galleryImages = [
    'assets/images/greeting.webp',
    'assets/images/language.webp',
    'assets/images/bookmark.webp',
    'assets/images/share-edit.webp',
    'assets/images/search.webp',
    'assets/images/shortcuts.webp',
    'assets/images/reference.webp',
    'assets/images/setting.webp',
    'assets/images/woman_reading_a_book_on_lap.webp',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            iconTheme: IconThemeData(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            floating: true,
            expandedHeight: 250,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                title.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [const Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/woman_reading_a_book_on_lap.webp',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
              child: Column(
                children: [
                  HtmlWidget(
                    body,
                    onTapUrl: (url) {
                      launchUrl(Uri.parse(url));
                      return true;
                    },
                  ),
                  WikiFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
