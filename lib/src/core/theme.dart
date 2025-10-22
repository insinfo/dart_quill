import 'dart:html';
import 'quill.dart';

class Theme {
  final Quill quill;
  final Map<String, dynamic> options;
  final Map<String, dynamic> _styles = {};
  final Map<String, dynamic> _themes = {};

  Theme(this.quill, this.options) {
    _initStyles();
  }

  void _initStyles() {
    // Base editor styles
    addStyle('.ql-editor', {
      'box-sizing': 'border-box',
      'line-height': '1.42',
      'height': '100%',
      'outline': 'none',
      'overflow-y': 'auto',
      'padding': '12px 15px',
      'tab-size': '4',
      'text-align': 'left',
      'white-space': 'pre-wrap',
      'word-wrap': 'break-word'
    });

    // Base list styles
    addStyle('.ql-editor ol, .ql-editor ul', {
      'padding-left': '1.5em'
    });

    // Add additional base styles for different formats
    addStyle('.ql-editor p', {
      'margin': '0',
      'padding': '0'
    });

    // Bold style
    addStyle('.ql-editor strong', {
      'font-weight': 'bold'
    });

    // Italic style
    addStyle('.ql-editor em', {
      'font-style': 'italic'
    });

    // Code style
    addStyle('.ql-editor pre', {
      'background-color': '#f0f0f0',
      'border-radius': '3px',
      'padding': '5px',
      'margin': '5px 0'
    });
  }

  void addStyle(String selector, Map<String, String> rules) {
    _styles[selector] = rules;
    _applyStyle(selector, rules);
  }

  void _applyStyle(String selector, Map<String, String> rules) {
    final styleSheet = document.styleSheets![0] as CssStyleSheet;
    String ruleString = '$selector {';
    rules.forEach((key, value) {
      ruleString += '$key: $value;';
    });
    ruleString += '}';
    styleSheet.addRule(selector, ruleString);
  }

  void registerTheme(String name, Map<String, dynamic> theme) {
    _themes[name] = theme;
  }

  void applyTheme(String name) {
    final theme = _themes[name];
    if (theme != null) {
      theme.forEach((selector, rules) {
        if (rules is Map<String, String>) {
          addStyle(selector, rules);
        }
      });
    }
  }

  void init() {
    // Initialize any additional theme settings
    if (options.containsKey('theme')) {
      applyTheme(options['theme']);
    }
  }
}
