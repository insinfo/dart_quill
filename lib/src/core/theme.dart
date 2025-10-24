import '../platform/dom.dart';
import 'quill.dart';

/// Options for theme configuration
class ThemeOptions {
  final String? theme;
  final DomElement? bounds;
  final Map<String, dynamic> modules;

  ThemeOptions({
    this.theme,
    this.bounds,
    Map<String, dynamic>? modules,
  }) : modules = modules != null
            ? Map<String, dynamic>.from(modules)
            : <String, dynamic>{};

  ThemeOptions copyWith({
    String? theme,
    DomElement? bounds,
    Map<String, dynamic>? modules,
  }) {
    return ThemeOptions(
      theme: theme ?? this.theme,
      bounds: bounds ?? this.bounds,
      modules: modules ?? Map<String, dynamic>.from(this.modules),
    );
  }
}

class Theme {
  final Quill quill;
  final ThemeOptions options;
  final Map<String, dynamic> modules = {};
  final Map<String, dynamic> _styles = {};
  final Map<String, dynamic> _themes = {};

  Theme(this.quill, ThemeOptions options)
      : options = options,
        super() {
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
    // Placeholder - styles would be applied via platform-specific mechanism
    // In a real implementation, this would inject CSS rules into the document
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
    // Apply named theme styles if available
    final themeName = options.theme;
    if (themeName != null) {
      applyTheme(themeName);
    }

    options.modules.forEach((name, config) {
      if (config == null || config == false) {
        return;
      }
      addModule(name);
    });
  }

  dynamic addModule(String name) {
    if (modules.containsKey(name)) {
      return modules[name];
    }
    final module = Quill.createModule(
      quill,
      name,
      options.modules[name] == true ? <String, dynamic>{} : options.modules[name],
    );
    if (module != null) {
      modules[name] = module;
    }
    return module;
  }
}
