/// Reusable grammar fragments, mirroring highlight.js' `MODES`.
library;

import 'mode.dart';

/// `\\x` — consumed as plain text so an escaped quote cannot close a string.
const Mode backslashEscape = Mode(begin: r'\\[\s\S]', skip: true);

const Mode apostropheString = Mode(
  scope: 'string',
  begin: "'",
  end: "'",
  illegal: r'\n',
  contains: [backslashEscape],
);

const Mode quoteString = Mode(
  scope: 'string',
  begin: '"',
  end: '"',
  illegal: r'\n',
  contains: [backslashEscape],
);

/// Both quote styles, for languages that treat them alike.
const Mode stringModes = Mode(
  scope: 'string',
  variants: [
    Mode(begin: '"', end: '"'),
    Mode(begin: "'", end: "'"),
  ],
  illegal: r'\n',
  contains: [backslashEscape],
);

const Mode lineComment = Mode(scope: 'comment', begin: '//', end: r'$');

const Mode hashComment = Mode(scope: 'comment', begin: '#', end: r'$');

const Mode blockComment = Mode(scope: 'comment', begin: r'/\*', end: r'\*/');

const List<Mode> cComments = [lineComment, blockComment];

/// Integers, floats, hex/binary/octal literals and numeric suffixes.
const Mode cNumber = Mode(
  scope: 'number',
  begin: r'\b(0[bB][01_]+|0[oO][0-7_]+|0[xX][a-fA-F0-9_]+'
      r'|(\d[\d_]*(\.[\d_]*)?|\.\d[\d_]*)([eE][-+]?\d+)?)'
      r'([uUlLfFdD]|[uU][lL]{1,2}|[lL]{1,2}[uU]?)?',
);

/// Decimal-only numbers, for languages without C literal syntax.
const Mode decimalNumber = Mode(
  scope: 'number',
  begin: r'\b(\d[\d_]*(\.[\d_]*)?|\.\d[\d_]*)([eE][-+]?\d+)?',
);

/// A bare identifier following a declaration keyword (`class Foo`).
const Mode titleMode = Mode(scope: 'title', begin: r'[A-Za-z_]\w*');
