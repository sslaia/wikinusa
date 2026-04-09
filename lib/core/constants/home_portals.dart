import 'package:flutter/material.dart';

class HomePortals {
  static Map<String, List<Map<String, dynamic>>> getPortals(BuildContext context) {
    return {
      'id': [
        {
          'title': 'portal_biography',
          'pageTitle': 'Portal:Biografi',
          'icon': Icons.person_outline,
          'color': const Color(0xFFE8F5E9),
          'iconColor': Colors.green[800],
        },
        {
          'title': 'portal_geography',
          'pageTitle': 'Portal:Geografi',
          'icon': Icons.map_outlined,
          'color': const Color(0xFFE0F7FA),
          'iconColor': Colors.cyan[900],
        },
        {
          'title': 'portal_chemistry',
          'pageTitle': 'Portal:Kimia',
          'icon': Icons.science,
          'color': const Color(0xFFFFF8E1),
          'iconColor': Colors.amber[900],
        },
        {
          'title': 'portal_community',
          'pageTitle': 'Portal:Komunitas',
          'icon': Icons.groups_outlined,
          'color': const Color(0xFFFCE4EC),
          'iconColor': Colors.pink,
        },
        {
          'title': 'portal_science',
          'pageTitle': 'Portal:Ilmu',
          'icon': Icons.science_outlined,
          'color': const Color(0xFFE1F5FE),
          'iconColor': Colors.lightBlue[900],
        },
        {
          'title': 'portal_history',
          'pageTitle': 'Portal:Sejarah',
          'icon': Icons.castle_outlined,
          'color': const Color(0xFFEFEBE9),
          'iconColor': Colors.brown,
        },
        {
          'title': 'portal_arts',
          'pageTitle': 'Portal:Seni',
          'icon': Icons.palette_outlined,
          'color': const Color(0xFFF3E5F5),
          'iconColor': Colors.deepPurple,
        },
        {
          'title': 'portal_technology',
          'pageTitle': 'Portal:Teknologi',
          'icon': Icons.memory_outlined,
          'color': const Color(0xFFF5F5F5),
          'iconColor': Colors.blueGrey[700],
        },
      ],
      'nia': [
        {
          'title': 'portal_religion',
          'pageTitle': 'Portal:Agama',
          'icon': Icons.account_balance,
          'color': const Color(0xFFE8EAF6),
          'iconColor': Colors.indigo,
        },
        {
          'title': 'portal_biology',
          'pageTitle': 'Portal:Biologi',
          'icon': Icons.eco,
          'color': const Color(0xFFE8F5E9),
          'iconColor': Colors.green,
        },
        {
          'title': 'portal_government',
          'pageTitle': 'Portal:Famatörö',
          'icon': Icons.gavel,
          'color': const Color(0xFFFFF8E1),
          'iconColor': Colors.amber[900],
        },
        {
          'title': 'portal_geography',
          'pageTitle': 'Portal:Geografi',
          'icon': Icons.public,
          'color': const Color(0xFFE0F7FA),
          'iconColor': Colors.cyan[900],
        },
        {
          'title': 'portal_culture',
          'pageTitle': 'Portal:Hada',
          'icon': Icons.theater_comedy,
          'color': const Color(0xFFFCE4EC),
          'iconColor': Colors.pink,
        },
        {
          'title': 'portal_maths',
          'pageTitle': 'Portal:Matematika',
          'icon': Icons.functions,
          'color': const Color(0xFFF3E5F5),
          'iconColor': Colors.deepPurple,
        },
        {
          'title': 'portal_media',
          'pageTitle': 'Portal:Media',
          'icon': Icons.newspaper,
          'color': const Color(0xFFFFF3E0),
          'iconColor': Colors.orange[900],
        },
        {
          'title': 'portal_science',
          'pageTitle': 'Portal:Sains',
          'icon': Icons.biotech,
          'color': const Color(0xFFE1F5FE),
          'iconColor': Colors.lightBlue[900],
        },
        {
          'title': 'portal_history',
          'pageTitle': 'Portal:Sejarah',
          'icon': Icons.history,
          'color': const Color(0xFFEFEBE9),
          'iconColor': Colors.brown,
        },
        {
          'title': 'portal_technology',
          'pageTitle': 'Portal:Teknologi',
          'icon': Icons.devices,
          'color': const Color(0xFFF5F5F5),
          'iconColor': Colors.blueGrey[700],
        },
      ],
      // You can add 'jv', 'en', 'bjn' lists here later...
    };
  }
}