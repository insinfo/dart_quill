import 'dom.dart';
import 'html_dom.dart';

/// Provides access to the DOM adapter being used by the runtime.
/// Tests can swap the adapter to a fake implementation to avoid
/// touching the real browser DOM APIs.
class DomBindings {
  DomBindings._(this.adapter);

  DomAdapter adapter;
}

final DomBindings domBindings = DomBindings._(HtmlDomAdapter());
