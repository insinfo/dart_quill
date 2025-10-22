import '../platform/dom.dart';
import 'abstract/blot.dart';

/// Base class for inline embeds. Concrete embeds should extend this and
/// implement the abstract members inherited from [EmbedBlot].
abstract class Embed extends EmbedBlot {
  Embed(DomElement domNode) : super(domNode);
}
