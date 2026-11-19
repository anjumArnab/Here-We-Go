import 'package:flutter/services.dart' show rootBundle;

/// Loads the Leaflet page from `assets/map/` and inlines the CSS, JS and
/// runtime config (`loadHtmlString` has no base URL for relative files).
class MapAssets {
  MapAssets._();

  static const _html = 'assets/map/map.html';
  static const _css = 'assets/map/map.css';
  static const _js = 'assets/map/map.js';

  static Future<String> buildHtml({required String config}) async {
    final results = await Future.wait([
      rootBundle.loadString(_html),
      rootBundle.loadString(_css),
      rootBundle.loadString(_js),
    ]);
    return results[0]
        .replaceFirst('{{CSS}}', results[1])
        .replaceFirst('{{CONFIG}}', config)
        .replaceFirst('{{JS}}', results[2]);
  }
}
