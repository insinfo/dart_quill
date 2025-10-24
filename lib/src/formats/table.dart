import '../blots/abstract/blot.dart';
import '../blots/block.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class TableBlot extends Block {
  static const String kBlotName = 'table';

  TableBlot(DomElement node) : super(node);

  static Blot create(Object value) {
    if (value is DomElement) {
      return TableBlot(value);
    }
    final element = domBindings.adapter.document.createElement('table');
    return TableBlot(element);
  }
}

