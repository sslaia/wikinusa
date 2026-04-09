import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/create_page_screen.dart';

class ContributeCard extends StatelessWidget {
  const ContributeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.primary,
      ),
      child: Column(
        children: [
          Icon(
            Icons.edit_note_outlined,
            color: isDark ? theme.colorScheme.primary : Colors.white,
            size: 48,
          ),
          const SizedBox(height: 24),
          Text(
            'contribute'.tr().toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.montserratAlternates(
              textStyle: theme.textTheme.headlineSmall?.copyWith(
                color: isDark ? theme.colorScheme.onSurface : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'contribute_description'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.offside(
              textStyle: theme.textTheme.bodySmall?.copyWith(
                color: (isDark ? theme.colorScheme.onSurface : Colors.white)
                    .withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePageScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? theme.colorScheme.primary
                  : Colors.white,
              foregroundColor: isDark
                  ? Colors.white
                  : theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: Text(
              'contribute_button'.tr().toUpperCase(),
              style: GoogleFonts.offside(
                textStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
