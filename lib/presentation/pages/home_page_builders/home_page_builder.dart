import 'package:flutter/material.dart';

abstract class HomePageBuilder {
  Widget build(
    BuildContext context,
    String pageTitle,
    String html,
    String langCode,
    Orientation orientation,
  );
}
