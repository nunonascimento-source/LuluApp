import 'dart:html' as html;

Future<void> exitApp() async {
  // Try to close the current tab/window.
  html.window.close();

  // Fallback: navigate to a blank page in the same tab.
  // This provides a "closed" effect when browsers block window.close().
  try {
    html.window.open('', '_self');
  } catch (_) {
    // ignore
  }
  html.window.location.assign('about:blank');
}
