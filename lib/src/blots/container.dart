import 'abstract/blot.dart';
import '../platform/dom.dart';

abstract class Container extends ContainerBlot {
  Container(DomElement domNode) : super(domNode);
}