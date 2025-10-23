import '../blots/block.dart';
import '../blots/abstract/blot.dart';
import '../platform/dom.dart';

class TableBlot extends Block {
  static const String kBlotName = 'table';

  TableBlot(DomNode node) : super(node);

  static Blot create(Object value) {
    // TODO: Check if we need to pass the node here
    throw UnimplementedError();
  }
}

