import 'package:flutter_web_plugins/url_strategy.dart';

/// Clean URLs on the web build: `/join/ABC123` rather than `/#/join/ABC123`.
///
/// Shareable invite links are a headline feature, so they should not carry a
/// `#`. `vercel.json` already rewrites unknown paths to `index.html`, which is
/// what makes deep links work on a refresh.
void configureUrlStrategy() => usePathUrlStrategy();
