/// Leitura, escrita e validação de WordprocessingML/DOCX.
library;

export 'document/docx/effective.dart' show FormatResolver;
export 'document/docx/model.dart';
export 'document/docx/numbering.dart'
    show
        NumberingCounters,
        WpAbstractNum,
        WpNum,
        WpNumbering,
        WpNumberingLevel,
        formatNumber;
export 'document/docx/reader.dart' show DocxFile, DocxReader;
export 'document/docx/styles.dart' show WpStyle, WpStyleSheet;
export 'document/docx/units.dart' show Units;
export 'document/docx/validator.dart' show DocxValidator;
export 'document/docx/writer.dart' show DocxWriter;
