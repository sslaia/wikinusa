import 'package:flutter/material.dart';
import '../../domain/entities/article.dart';
import '../pages/article_screen.dart';

class ArticleCard extends StatelessWidget {
  final Article article;

  const ArticleCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ArticleScreen(pageTitle: article.title),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F1B1C1C), // 6% black/onSurface
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if (article.isFeatured)
            //   Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //     margin: const EdgeInsets.only(bottom: 12),
            //     decoration: BoxDecoration(
            //       color: theme.colorScheme.tertiaryFixedDim,
            //       borderRadius: BorderRadius.circular(4),
            //     ),
            //     child: Text(
            //       'FEATURED',
            //       style: theme.textTheme.labelMedium?.copyWith(
            //         color: theme.colorScheme.onTertiaryFixed,
            //       ),
            //     ),
            //   ),
            Text(article.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              article.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge,
            ),
            // const SizedBox(height: 12),
            // Text(
            //   '${article.author} • ${article.lastEdited.toString().split(" ")[0]}',
            //   style: theme.textTheme.labelMedium?.copyWith(
            //     color: theme.colorScheme.primary,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
