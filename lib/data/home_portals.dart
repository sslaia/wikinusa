import 'package:flutter/material.dart';

class HomePortals {
  static Map<String, Map<String, List<Map<String, dynamic>>>> getPortals(
    BuildContext context,
  ) {
    return {
      'en': {'wikipedia': [], 'wiktionary': [], 'wikibooks': []},
      'id': {
        'wikipedia': [
          {'label': 'portal_biography', 'title': 'Portal:Biografi'},
          {'label': 'portal_geography', 'title': 'Portal:Geografi'},
          {'label': 'portal_chemistry', 'title': 'Portal:Kimia'},
          {'label': 'portal_community', 'title': 'Portal:Komunitas'},
          {'label': 'portal_science', 'title': 'Portal:Ilmu'},
          {'label': 'portal_history', 'title': 'Portal:Sejarah'},
          {'label': 'portal_arts', 'title': 'Portal:Seni'},
          {'label': 'portal_technology', 'title': 'Portal:Teknologi'},
        ],
        'wiktionary': [],
        'wikibooks': [],
      },
      'nia': {
        'wikipedia': [
          {'label': 'portal_religion', 'title': 'Portal:Agama'},
          {'label': 'portal_biology', 'title': 'Portal:Biologi'},
          {'label': 'portal_government', 'title': 'Portal:Famatörö'},
          {'label': 'portal_geography', 'title': 'Portal:Geografi'},
          {'label': 'portal_culture', 'title': 'Portal:Hada'},
          {'label': 'portal_maths', 'title': 'Portal:Matematika'},
          {'label': 'portal_media', 'title': 'Portal:Media'},
          {'label': 'portal_science', 'title': 'Portal:Sains'},
          {'label': 'portal_history', 'title': 'Portal:Sejarah'},
          {'label': 'portal_technology', 'title': 'Portal:Teknologi'},
        ],
        'wiktionary': [
          {"label": "portal_religion", "title": "Kategori:Agama"},
          {"label": "portal_animals", "title": "Kategori:Aurifö"},
          {"label": "portal_business", "title": "Kategori:Bisnis"},
          {"label": "portal_german", "title": "Kategori:Deutsch"},
          {"label": "portal_english", "title": "Kategori:Inggris"},
          {"label": "portal_government", "title": "Kategori:Famatörö"},
          {"label": "portal_health", "title": "Kategori:Fökhö"},
          {"label": "portal_custom", "title": "Kategori:Hada"},
          {"label": "portal_indonesian", "title": "Kategori:Indonesia"},
          {"label": "portal_colours", "title": "Kategori:La'a-la'a"},
          {"label": "portal_anatomy", "title": "Kategori:Ndroto-ndroto mboto"},
          {"label": "portal_nias", "title": "Kategori:Nias"},
          {"label": "portal_arts", "title": "Kategori:Seni"},
          {"label": "portal_plants", "title": "Kategori:Sinumbua"},
          {"label": "portal_technology", "title": "Kategori:Teknologi"},
          {"label": "portal_transport", "title": "Kategori:Transpor"},
        ],
        'wikibooks': [],
      },
    };
  }
}
