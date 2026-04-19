import 'package:flutter/material.dart';
import '../../../domain/entities/wiki_project.dart';

abstract class HomePageBuilder {
  Widget build(
    BuildContext context,
    String pageTitle,
    String html,
    String langCode,
    Orientation orientation,
    WikiProject project,
  );
}
