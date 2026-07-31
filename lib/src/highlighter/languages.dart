/// Grammars for the languages Quill's Syntax module offers in its language
/// picker. They are transcriptions of the highlight.js definitions, trimmed to
/// the constructs that actually show up in code embedded in a document.
library;

import 'common_modes.dart';
import 'mode.dart';

/// No rules at all — `plain` renders as unhighlighted text.
const Language plainLanguage = Language(name: 'plain', root: Mode());

// ---------------------------------------------------------------------------
// bash
// ---------------------------------------------------------------------------

const Mode _shellVariable = Mode(
  scope: 'variable',
  variants: [
    Mode(begin: r'\$[\w#!?*@-]+'),
    Mode(begin: r'\$\{', end: r'\}'),
  ],
);

const Language bashLanguage = Language(
  name: 'bash',
  aliases: ['sh', 'shell', 'zsh'],
  root: Mode(
    keywords: {
      'keyword': [
        'if', 'then', 'else', 'elif', 'fi', 'for', 'while', 'until', 'in',
        'do', 'done', 'case', 'esac', 'function', 'select', 'time',
      ],
      'literal': ['true', 'false'],
      'built_in': [
        'break', 'cd', 'continue', 'eval', 'exec', 'exit', 'export', 'getopts',
        'hash', 'pwd', 'readonly', 'return', 'shift', 'test', 'trap', 'umask',
        'unset', 'alias', 'bind', 'builtin', 'command', 'declare', 'echo',
        'enable', 'help', 'let', 'local', 'logout', 'printf', 'read',
        'shopt', 'source', 'type', 'typeset', 'ulimit', 'unalias', 'set',
        'ls', 'cat', 'grep', 'sed', 'awk', 'mkdir', 'rm', 'cp', 'mv', 'git',
'npm', 'dart', 'flutter', 'sudo', 'curl', 'chmod',
      ],
    },
    contains: [
      hashComment,
      Mode(
        scope: 'string',
        begin: '"',
        end: '"',
        contains: [backslashEscape, _shellVariable],
      ),
      Mode(scope: 'string', begin: "'", end: "'"),
      _shellVariable,
      decimalNumber,
    ],
  ),
);

// ---------------------------------------------------------------------------
// C / C++
// ---------------------------------------------------------------------------

const Mode _preprocessor = Mode(scope: 'meta', begin: r'^[ \t]*#\s*\w+', end: r'$');

const Language cppLanguage = Language(
  name: 'cpp',
  aliases: ['c', 'cc', 'h', 'hpp', 'c++'],
  root: Mode(
    keywords: {
      'keyword': [
        'alignas', 'alignof', 'and', 'asm', 'auto', 'break', 'case', 'catch',
        'class', 'concept', 'const', 'consteval', 'constexpr', 'constinit',
        'const_cast', 'continue', 'co_await', 'co_return', 'co_yield',
        'decltype', 'default', 'delete', 'do', 'dynamic_cast', 'else', 'enum',
        'explicit', 'export', 'extern', 'final', 'for', 'friend', 'goto', 'if',
        'inline', 'mutable', 'namespace', 'new', 'noexcept', 'not', 'operator',
        'or', 'override', 'private', 'protected', 'public', 'register',
        'reinterpret_cast', 'requires', 'return', 'sizeof', 'static',
        'static_assert', 'static_cast', 'struct', 'switch', 'template', 'this',
        'thread_local', 'throw', 'try', 'typedef', 'typeid', 'typename',
        'union', 'using', 'virtual', 'volatile', 'while', 'xor',
      ],
      'type': [
        'bool', 'char', 'char8_t', 'char16_t', 'char32_t', 'double', 'float',
        'int', 'int8_t', 'int16_t', 'int32_t', 'int64_t', 'long', 'short',
        'signed', 'size_t', 'unsigned', 'uint8_t', 'uint32_t', 'uint64_t',
        'void', 'wchar_t',
      ],
      'literal': ['true', 'false', 'nullptr', 'NULL'],
      'built_in': [
        'std', 'string', 'wstring', 'vector', 'map', 'unordered_map', 'set',
        'array', 'list', 'deque', 'pair', 'tuple', 'optional', 'variant',
        'shared_ptr', 'unique_ptr', 'cout', 'cerr', 'cin', 'endl', 'printf',
        'scanf', 'malloc', 'free', 'memcpy', 'strlen',
      ],
    },
    contains: [
      lineComment,
      blockComment,
      _preprocessor,
      quoteString,
      Mode(scope: 'string', begin: r"'", end: r"'", illegal: r'\n', contains: [backslashEscape]),
      cNumber,
      Mode(
        beginKeywords: ['class', 'struct', 'union', 'enum', 'namespace'],
        end: r'[{;:<>=\n]',
        excludeEnd: true,
        contains: [titleMode],
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// C#
// ---------------------------------------------------------------------------

const Language csharpLanguage = Language(
  name: 'cs',
  aliases: ['csharp', 'c#'],
  root: Mode(
    keywords: {
      'keyword': [
        'abstract', 'as', 'base', 'break', 'case', 'catch', 'checked', 'class',
        'const', 'continue', 'default', 'delegate', 'do', 'else', 'enum',
        'event', 'explicit', 'extern', 'finally', 'fixed', 'for', 'foreach',
        'goto', 'if', 'implicit', 'in', 'init', 'interface', 'internal', 'is',
        'lock', 'namespace', 'new', 'operator', 'out', 'override', 'params',
        'private', 'protected', 'public', 'readonly', 'record', 'ref',
        'return', 'sealed', 'sizeof', 'stackalloc', 'static', 'struct',
        'switch', 'this', 'throw', 'try', 'typeof', 'unchecked', 'unsafe',
        'using', 'virtual', 'void', 'volatile', 'while', 'async', 'await',
        'get', 'set', 'value', 'var', 'when', 'where', 'yield', 'nameof',
        'partial', 'global', 'from', 'select', 'group', 'into', 'orderby',
        'join', 'let', 'on', 'equals', 'by', 'ascending', 'descending',
      ],
      'type': [
        'bool', 'byte', 'char', 'decimal', 'double', 'dynamic', 'float', 'int',
        'long', 'object', 'sbyte', 'short', 'string', 'uint', 'ulong',
        'ushort', 'Task', 'List', 'Dictionary', 'IEnumerable',
      ],
      'literal': ['null', 'true', 'false', 'default'],
    },
    contains: [
      lineComment,
      blockComment,
      _preprocessor,
      Mode(
        scope: 'string',
        variants: [
          Mode(begin: r'\$?@"', end: '"'),
          Mode(begin: r'\$"', end: '"', illegal: r'\n'),
        ],
        contains: [backslashEscape],
      ),
      quoteString,
      apostropheString,
      cNumber,
      Mode(scope: 'meta', begin: r'\[[A-Za-z]', returnBegin: true, end: r'\]', contains: [
        Mode(scope: 'meta-string', begin: '"', end: '"'),
      ]),
      Mode(
        beginKeywords: ['class', 'interface', 'struct', 'enum', 'record', 'namespace'],
        end: r'[{;:<\n]',
        excludeEnd: true,
        contains: [titleMode],
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// CSS
// ---------------------------------------------------------------------------

/// The right-hand side of a declaration. Inlined into the value mode below:
/// a mode without `begin` can never be entered on its own.
const List<Mode> _cssValueContents = [
  blockComment,
  Mode(scope: 'meta', begin: r'!important'),
  Mode(scope: 'number', begin: r'#[0-9a-fA-F]{3,8}\b'),
  Mode(
    scope: 'number',
    begin: r'\b(\d+(\.\d*)?|\.\d+)'
        r'(%|px|em|rem|ex|ch|vh|vw|vmin|vmax|cm|mm|in|pt|pc|deg|rad|turn|s|ms|fr)?',
  ),
  stringModes,
  Mode(
    scope: 'built_in',
    begin: r'\b(?:url|rgba?|hsla?|calc|var|linear-gradient|radial-gradient'
        r'|translate[XYZ]?|rotate|scale|cubic-bezier)(?=\()',
  ),
];

const Language cssLanguage = Language(
  name: 'css',
  caseInsensitive: true,
  root: Mode(
    contains: [
      blockComment,
      Mode(scope: 'keyword', begin: r'@[a-z-]+'),
      Mode(scope: 'selector-pseudo', begin: r'::?[a-z][a-z0-9-]*(\([^)]*\))?'),
      Mode(scope: 'selector-class', begin: r'\.[a-zA-Z0-9_-]+'),
      Mode(scope: 'selector-id', begin: r'#[a-zA-Z0-9_-]+'),
      Mode(scope: 'selector-attr', begin: r'\[', end: r'\]', illegal: r'\n'),
      Mode(
        scope: 'selector-tag',
        begin: r'\b(?:html|body|div|span|p|a|ul|ol|li|table|tr|td|th|input|'
            r'button|select|option|label|form|img|h[1-6]|header|footer|nav|'
            r'section|article|aside|main|pre|code|strong|em|blockquote)\b',
      ),
      // Declaration block: property names and values live here.
      Mode(
        begin: r'\{',
        end: r'\}',
        contains: [
          blockComment,
          Mode(scope: 'attribute', begin: r'\b[a-zA-Z-]+(?=\s*:)'),
          Mode(begin: r':', end: r'(?=[;}])', contains: _cssValueContents),
        ],
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// diff
// ---------------------------------------------------------------------------

const Language diffLanguage = Language(
  name: 'diff',
  aliases: ['patch'],
  root: Mode(
    contains: [
      Mode(
        scope: 'meta',
        variants: [
          Mode(begin: r'^@@ .*? @@$'),
          Mode(begin: r'^\*\*\* .*? \*\*\*\*$'),
          Mode(begin: r'^(?:diff --git|index |---|\+\+\+|===).*$'),
        ],
      ),
      Mode(scope: 'addition', begin: r'^\+.*$'),
      Mode(scope: 'deletion', begin: r'^-.*$'),
    ],
  ),
);

// ---------------------------------------------------------------------------
// HTML / XML
// ---------------------------------------------------------------------------

const Language xmlLanguage = Language(
  name: 'xml',
  aliases: ['html', 'xhtml', 'svg'],
  caseInsensitive: true,
  root: Mode(
    contains: [
      Mode(scope: 'comment', begin: r'<!--', end: r'-->'),
      Mode(scope: 'meta', begin: r'<[!?]', end: r'>'),
      Mode(scope: 'symbol', begin: r'&[a-zA-Z#][a-zA-Z0-9]*;'),
      Mode(
        scope: 'tag',
        begin: r'</?[A-Za-z][A-Za-z0-9._:-]*',
        end: r'/?>',
        contains: [
          Mode(scope: 'string', begin: '"', end: '"'),
          Mode(scope: 'string', begin: "'", end: "'"),
          Mode(scope: 'attr', begin: r'[A-Za-z_:][A-Za-z0-9._:-]*'),
        ],
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Java
// ---------------------------------------------------------------------------

const Language javaLanguage = Language(
  name: 'java',
  root: Mode(
    keywords: {
      'keyword': [
        'abstract', 'assert', 'break', 'case', 'catch', 'class', 'const',
        'continue', 'default', 'do', 'else', 'enum', 'extends', 'final',
        'finally', 'for', 'goto', 'if', 'implements', 'import', 'instanceof',
        'interface', 'native', 'new', 'non-sealed', 'package', 'permits',
        'private', 'protected', 'public', 'record', 'return', 'sealed',
        'static', 'strictfp', 'super', 'switch', 'synchronized', 'this',
        'throw', 'throws', 'transient', 'try', 'var', 'volatile', 'while',
        'yield',
      ],
      'type': [
        'boolean', 'byte', 'char', 'double', 'float', 'int', 'long', 'short',
        'void', 'String', 'Integer', 'Boolean', 'Long', 'Double', 'Object',
        'List', 'Map', 'Set', 'ArrayList', 'HashMap', 'Optional', 'Stream',
      ],
      'literal': ['true', 'false', 'null'],
    },
    contains: [
      lineComment,
      blockComment,
      quoteString,
      apostropheString,
      cNumber,
      Mode(scope: 'meta', begin: r'@[A-Za-z]\w*'),
      Mode(
        beginKeywords: ['class', 'interface', 'enum', 'record'],
        end: r'[{<(\n]',
        excludeEnd: true,
        contains: [_inheritanceKeywords, titleMode],
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// JavaScript / TypeScript
// ---------------------------------------------------------------------------

const Map<String, List<String>> _jsKeywords = {
  'keyword': [
    'as', 'async', 'await', 'break', 'case', 'catch', 'class', 'const',
    'continue', 'debugger', 'default', 'delete', 'do', 'else', 'enum',
    'export', 'extends', 'finally', 'for', 'from', 'function', 'get', 'if',
    'implements', 'import', 'in', 'instanceof', 'interface', 'let', 'new',
    'of', 'package', 'private', 'protected', 'public', 'return', 'set',
    'static', 'super', 'switch', 'this', 'throw', 'try', 'typeof', 'var',
    'void', 'while', 'with', 'yield', 'readonly', 'declare', 'namespace',
    'type', 'abstract', 'override', 'satisfies', 'keyof', 'infer', 'is',
  ],
  'literal': ['true', 'false', 'null', 'undefined', 'NaN', 'Infinity'],
  'built_in': [
    'Array', 'Boolean', 'Date', 'Error', 'Function', 'JSON', 'Map', 'Math',
    'Number', 'Object', 'Promise', 'Proxy', 'RegExp', 'Set', 'String',
    'Symbol', 'WeakMap', 'console', 'document', 'window', 'globalThis',
    'require', 'module', 'exports', 'process', 'setTimeout', 'setInterval',
    'clearTimeout', 'fetch', 'parseInt', 'parseFloat', 'isNaN', 'eval',
  ],
};

const Mode _jsTitle = Mode(scope: 'title', begin: r'[A-Za-z_$][\w$]*');

/// Declared before the title mode so `extends`/`implements` stay keywords: on
/// a tie the earlier candidate wins.
const Mode _inheritanceKeywords =
    Mode(scope: 'keyword', begin: r'\b(?:extends|implements|permits)\b');

const Mode _templateSubstitution = Mode(
  scope: 'subst',
  begin: r'\$\{',
  end: r'\}',
  keywords: _jsKeywords,
  contains: [decimalNumber],
);

const Language javascriptLanguage = Language(
  name: 'javascript',
  aliases: ['js', 'jsx', 'ts', 'typescript', 'mjs', 'cjs'],
  root: Mode(
    keywords: _jsKeywords,
    contains: [
      lineComment,
      blockComment,
      Mode(
        scope: 'string',
        begin: '`',
        end: '`',
        contains: [backslashEscape, _templateSubstitution],
      ),
      quoteString,
      apostropheString,
      cNumber,
      // `function name(` and `class Name` get a title, like upstream does.
      // The `end` stays on the same line so an unfinished declaration cannot
      // swallow the rest of the document.
      Mode(
        beginKeywords: ['function'],
        end: r'[({;\n]',
        excludeEnd: true,
        contains: [_jsTitle],
      ),
      Mode(
        beginKeywords: ['class', 'interface', 'enum'],
        end: r'[{;\n]',
        excludeEnd: true,
        contains: [_inheritanceKeywords, _jsTitle],
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Markdown
// ---------------------------------------------------------------------------

const Language markdownLanguage = Language(
  name: 'markdown',
  aliases: ['md', 'mkdown'],
  root: Mode(
    contains: [
      Mode(scope: 'section', begin: r'^#{1,6} .*$'),
      Mode(scope: 'section', begin: r'^.+\n[=-]{2,}$'),
      // Single-match modes (no `end`): the whole fence/span is one token.
      Mode(
        scope: 'code',
        variants: [
          Mode(begin: r'^```[\s\S]*?^```'),
          Mode(begin: r'`[^`\n]*`'),
          Mode(begin: r'^(?: {4}|\t).*$'),
        ],
      ),
      Mode(scope: 'quote', begin: r'^>.*$'),
      Mode(scope: 'bullet', begin: r'^\s*(?:[*+-]|\d+\.)\s'),
      Mode(scope: 'strong', begin: r'\*\*[^\n]+?\*\*'),
      Mode(scope: 'strong', begin: r'__[^\n]+?__'),
      Mode(scope: 'emphasis', begin: r'\*[^\s*][^\n*]*?\*'),
      Mode(scope: 'emphasis', begin: r'_[^\s_][^\n_]*?_'),
      Mode(scope: 'link', begin: r'!?\[[^\]\n]*\]\([^)\n]*\)'),
      Mode(scope: 'link', begin: r'^\[[^\]\n]*\]:.*$'),
      Mode(scope: 'strong', begin: r'^(?:---|\*\*\*|___)$'),
    ],
  ),
);

// ---------------------------------------------------------------------------
// PHP
// ---------------------------------------------------------------------------

const Language phpLanguage = Language(
  name: 'php',
  aliases: ['php8'],
  root: Mode(
    keywords: {
      'keyword': [
        'abstract', 'and', 'array', 'as', 'break', 'callable', 'case', 'catch',
        'class', 'clone', 'const', 'continue', 'declare', 'default', 'do',
        'echo', 'else', 'elseif', 'empty', 'enddeclare', 'endfor',
        'endforeach', 'endif', 'endswitch', 'endwhile', 'enum', 'extends',
        'final', 'finally', 'fn', 'for', 'foreach', 'function', 'global',
        'goto', 'if', 'implements', 'include', 'include_once', 'instanceof',
        'insteadof', 'interface', 'isset', 'list', 'match', 'namespace', 'new',
        'or', 'print', 'private', 'protected', 'public', 'readonly', 'require',
        'require_once', 'return', 'static', 'switch', 'throw', 'trait', 'try',
        'unset', 'use', 'var', 'while', 'xor', 'yield',
      ],
      'type': ['int', 'float', 'bool', 'string', 'void', 'iterable', 'object', 'mixed', 'never'],
      'literal': ['true', 'false', 'null', 'TRUE', 'FALSE', 'NULL'],
      'built_in': [
        'array_map', 'array_filter', 'array_merge', 'array_keys', 'count',
        'implode', 'explode', 'sprintf', 'printf', 'strlen', 'str_replace',
        'json_encode', 'json_decode', 'var_dump', 'preg_match', 'preg_replace',
        'in_array', 'is_array', 'isset', 'die', 'exit',
      ],
    },
    contains: [
      lineComment,
      blockComment,
      hashComment,
      Mode(scope: 'meta', begin: r'<\?(?:php|=)?|\?>'),
      Mode(scope: 'variable', begin: r'\$+[A-Za-z_]\w*'),
      quoteString,
      apostropheString,
      cNumber,
      Mode(
        beginKeywords: ['class', 'interface', 'trait', 'enum'],
        end: r'[{;\n]',
        excludeEnd: true,
        contains: [_inheritanceKeywords, titleMode],
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Python
// ---------------------------------------------------------------------------

const Language pythonLanguage = Language(
  name: 'python',
  aliases: ['py', 'gyp'],
  root: Mode(
    keywords: {
      'keyword': [
        'and', 'as', 'assert', 'async', 'await', 'break', 'class', 'continue',
        'def', 'del', 'elif', 'else', 'except', 'finally', 'for', 'from',
        'global', 'if', 'import', 'in', 'is', 'lambda', 'match', 'nonlocal',
        'not', 'or', 'pass', 'raise', 'return', 'try', 'while', 'with',
        'yield',
      ],
      'literal': ['True', 'False', 'None', 'NotImplemented', 'Ellipsis'],
      'built_in': [
        'abs', 'all', 'any', 'bool', 'bytes', 'callable', 'chr', 'dict',
        'dir', 'divmod', 'enumerate', 'eval', 'filter', 'float', 'format',
        'frozenset', 'getattr', 'hasattr', 'hash', 'hex', 'id', 'input',
        'int', 'isinstance', 'issubclass', 'iter', 'len', 'list', 'map',
        'max', 'min', 'next', 'object', 'oct', 'open', 'ord', 'pow', 'print',
        'property', 'range', 'repr', 'reversed', 'round', 'set', 'setattr',
        'slice', 'sorted', 'staticmethod', 'str', 'sum', 'super', 'tuple',
        'type', 'vars', 'zip', 'self',
      ],
    },
    contains: [
      hashComment,
      Mode(
        scope: 'string',
        variants: [
          Mode(begin: '[uUbBrRfF]*"""', end: '"""'),
          Mode(begin: "[uUbBrRfF]*'''", end: "'''"),
          Mode(begin: '[uUbBrRfF]*"', end: '"', illegal: r'\n'),
          Mode(begin: "[uUbBrRfF]*'", end: "'", illegal: r'\n'),
        ],
        contains: [backslashEscape],
      ),
      Mode(scope: 'meta', begin: r'^[ \t]*@[\w.]+'),
      cNumber,
      Mode(
        beginKeywords: ['def', 'class'],
        end: r'[:(\n]',
        excludeEnd: true,
        contains: [titleMode],
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Ruby
// ---------------------------------------------------------------------------

const Language rubyLanguage = Language(
  name: 'ruby',
  aliases: ['rb', 'gemspec', 'ruby'],
  root: Mode(
    keywords: {
      'keyword': [
        'alias', 'and', 'begin', 'break', 'case', 'class', 'def', 'defined?',
        'do', 'each', 'else', 'elsif', 'end', 'ensure', 'for', 'if', 'in',
        'module', 'next', 'not', 'or', 'redo', 'rescue', 'retry', 'return',
        'self', 'super', 'then', 'throw', 'undef', 'unless', 'until', 'when',
        'while', 'yield', 'lambda', 'proc', 'require', 'require_relative',
        'include', 'extend', 'attr_accessor', 'attr_reader', 'attr_writer',
        'private', 'protected', 'public', 'raise', 'new',
      ],
      'literal': ['true', 'false', 'nil'],
      'built_in': ['puts', 'print', 'p', 'gets', 'loop', 'format', 'Array', 'Hash', 'String'],
    },
    contains: [
      hashComment,
      Mode(scope: 'comment', begin: r'^=begin', end: r'^=end'),
      Mode(
        scope: 'string',
        variants: [
          Mode(begin: '"', end: '"'),
          Mode(begin: "'", end: "'"),
          Mode(begin: r'%[qQwWi]?\(', end: r'\)'),
        ],
        contains: [
          backslashEscape,
          Mode(scope: 'subst', begin: r'#\{', end: r'\}'),
        ],
      ),
      Mode(scope: 'symbol', begin: r':[A-Za-z_]\w*[?!=]?'),
      Mode(scope: 'variable', begin: r'@{1,2}[A-Za-z_]\w*'),
      Mode(scope: 'variable', begin: r'\$[A-Za-z_]\w*'),
      cNumber,
      Mode(
        beginKeywords: ['class', 'module', 'def'],
        end: r'[\n;(]',
        excludeEnd: true,
        contains: [Mode(scope: 'title', begin: r'[A-Za-z_][\w:.]*[?!=]?')],
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// SQL
// ---------------------------------------------------------------------------

const Language sqlLanguage = Language(
  name: 'sql',
  caseInsensitive: true,
  root: Mode(
    keywords: {
      'keyword': [
        'add', 'all', 'alter', 'and', 'any', 'as', 'asc', 'begin', 'between',
        'by', 'cascade', 'case', 'check', 'column', 'commit', 'constraint',
        'create', 'cross', 'default', 'delete', 'desc', 'distinct', 'drop',
        'else', 'end', 'exists', 'foreign', 'from', 'full', 'grant', 'group',
        'having', 'if', 'in', 'index', 'inner', 'insert', 'into', 'is',
        'join', 'key', 'left', 'like', 'limit', 'not', 'null', 'offset', 'on',
        'or', 'order', 'outer', 'primary', 'references', 'returning', 'right',
        'rollback', 'select', 'set', 'table', 'then', 'transaction',
        'truncate', 'union', 'unique', 'update', 'using', 'values', 'view',
        'when', 'where', 'with',
      ],
      'type': [
        'bigint', 'binary', 'bit', 'blob', 'boolean', 'char', 'date',
        'datetime', 'decimal', 'double', 'float', 'int', 'integer', 'json',
        'jsonb', 'numeric', 'real', 'serial', 'smallint', 'text', 'time',
        'timestamp', 'uuid', 'varchar',
      ],
      'literal': ['true', 'false', 'null'],
      'built_in': [
        'avg', 'cast', 'coalesce', 'concat', 'count', 'current_date',
        'current_timestamp', 'extract', 'lower', 'max', 'min', 'now', 'round',
        'substring', 'sum', 'trim', 'upper',
      ],
    },
    contains: [
      Mode(scope: 'comment', begin: '--', end: r'$'),
      blockComment,
      Mode(
        scope: 'string',
        begin: "'",
        end: "'",
        contains: [Mode(begin: "''", skip: true)],
      ),
      Mode(scope: 'string', begin: '"', end: '"'),
      Mode(scope: 'string', begin: '`', end: '`'),
      decimalNumber,
      Mode(scope: 'variable', begin: r'[@:]\w+'),
    ],
  ),
);

/// Every grammar this highlighter ships with, keyed by name *and* alias, so
/// `SyntaxLanguage.key` values from Quill's picker resolve directly.
final Map<String, Language> languages = _index([
  plainLanguage,
  bashLanguage,
  cppLanguage,
  csharpLanguage,
  cssLanguage,
  diffLanguage,
  xmlLanguage,
  javaLanguage,
  javascriptLanguage,
  markdownLanguage,
  phpLanguage,
  pythonLanguage,
  rubyLanguage,
  sqlLanguage,
]);

Map<String, Language> _index(List<Language> all) {
  final index = <String, Language>{};
  for (final language in all) {
    index[language.name] = language;
    for (final alias in language.aliases) {
      index.putIfAbsent(alias, () => language);
    }
  }
  return index;
}
