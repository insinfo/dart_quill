/// XML namespace-aware usado pelo suporte a DOCX.
library;

export 'document/xml/dom.dart';
export 'document/xml/sax.dart'
    show
        XmlNameUtil,
        XmlParseException,
        XmlSaxAttribute,
        XmlSaxHandler,
        XmlSaxParser;
export 'document/xml/serializer.dart' show XmlEscape;
