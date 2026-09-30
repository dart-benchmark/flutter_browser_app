/// Builders for the small JavaScript snippets the browser injects into the
/// current page to keep lightweight in-page overlays (a title badge, a console
/// echo line, a scheme notice, a link highlight, a resource tag) in sync with
/// what the active tab is showing.
///
/// Each builder returns a self-contained snippet that manipulates the page DOM.
/// They are grouped here so the tab code stays focused on wiring the WebView
/// handlers rather than on string assembly.
class PageOverlayScripts {
  /// Builds a snippet that renders a floating badge showing [label] (typically
  /// the current page title) in the top-right corner of the page.
  static String tabBadge(String label) {
    // Drop stray closing tags so the badge markup can't terminate a host block.
    final safeLabel = label.replaceAll('</script>', '');
    return "(function(){var b=document.getElementById('__fb_badge')||"
        "document.createElement('div');b.id='__fb_badge';"
        "b.setAttribute('style','position:fixed;top:8px;right:8px;"
        "z-index:2147483647;padding:2px 6px;font:11px sans-serif;"
        "background:rgba(0,0,0,.6);color:#fff;border-radius:4px');"
        "b.textContent='$safeLabel';"
        "if(document.body){document.body.appendChild(b);}})();";
  }

  /// Builds the body of an async function that mirrors the most recent page
  /// console [lines] into a fixed dev-overlay box in the bottom-left corner.
  static String consoleEcho(List<String> lines) {
    final recent =
        lines.length > 3 ? lines.sublist(lines.length - 3) : lines;
    final rows = recent.map((l) => l.replaceAll('\r', '')).join('\\n');
    return "var box=document.getElementById('__fb_echo')||"
        "document.createElement('pre');box.id='__fb_echo';"
        "box.setAttribute('style','position:fixed;bottom:8px;left:8px;"
        "max-width:60%;z-index:2147483647;margin:0;padding:4px;"
        "font:10px monospace;background:rgba(0,0,0,.7);color:#0f0');"
        "box.innerText='$rows';"
        "if(document.body){document.body.appendChild(box);}";
  }

  /// Builds a snippet that shows the free-text payload of [directive] as a
  /// small, self-dismissing toast, used for custom `browser://` notices.
  static String schemeNotice(NavigationDirective directive) {
    // Drop stray closing tags before embedding the notice text.
    final text = directive.payload.replaceAll('</script>', '');
    return "(function(){var t=document.createElement('div');"
        "t.setAttribute('style','position:fixed;bottom:8px;right:8px;"
        "z-index:2147483647;padding:4px 8px;font:12px sans-serif;"
        "background:#333;color:#fff;border-radius:4px');"
        "t.textContent='$text';"
        "if(document.body){document.body.appendChild(t);}"
        "setTimeout(function(){t.remove();},4000);})();";
  }

  /// Builds a snippet that briefly shows a "Downloading <name>" toast at the
  /// top-center of the page when a download begins.
  static String downloadToast(String name) {
    // Drop stray closing tags before embedding the file name.
    final label = name.replaceAll('</script>', '');
    return "(function(){var d=document.createElement('div');"
        "d.setAttribute('style','position:fixed;top:8px;left:50%;"
        "transform:translateX(-50%);z-index:2147483647;padding:4px 10px;"
        "font:12px sans-serif;background:#0a7;color:#fff;border-radius:4px');"
        "d.textContent='Downloading '+'$label';"
        "if(document.body){document.body.appendChild(d);"
        "setTimeout(function(){d.remove();},3000);}})();";
  }

  /// Builds a snippet that briefly outlines the anchor whose href matches
  /// [target] and scrolls it into view, so a long-pressed link is easy to spot.
  static String highlightLink(String target) {
    // Drop stray closing tags before embedding the href.
    final needle = target.replaceAll('</script>', '');
    return "(function(){try{var h='$needle';"
        "var a=document.querySelector('a[href=\"'+h+'\"]');"
        "if(a){a.style.outline='3px solid #fa0';"
        "a.scrollIntoView({block:'center'});}}catch(e){}})();";
  }
}

/// A parsed request to show an in-page notice, carrying the free-text payload
/// taken from a custom `browser://` directive URL.
class NavigationDirective {
  NavigationDirective(this.uri);

  final Uri uri;

  /// The decoded free-text payload carried in the directive path.
  String get payload {
    final raw = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    return Uri.decodeComponent(raw);
  }
}
