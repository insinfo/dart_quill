import 'dart:async';
import 'dart:html' as html;

import 'package:ngdart/angular.dart';

import '../core/emitter.dart';
import '../core/initialization.dart';
import '../core/quill.dart';
import '../core/theme.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../platform/html_dom.dart';

@Component(
  selector: 'quill-editor',
  template: '<div class="quill-editor-host" #editorHost></div>',
  styles: [
    ':host { display: block; }',
    '.quill-editor-host { min-height: 200px; }',
  ],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class QuillEditorComponent implements AfterViewInit, OnDestroy {
  QuillEditorComponent(this._ngZone);

  static const List<List<dynamic>> _defaultToolbar = [
    [
      {'header': '1'},
      {'header': '2'},
      {'header': '3'},
      {'header': false},
    ],
    ['bold', 'italic', 'underline', 'strike'],
    [
      {'list': 'ordered'},
      {'list': 'bullet'},
    ],
    ['link', 'image', 'code'],
    ['clean'],
  ];

  final NgZone _ngZone;

  @ViewChild('editorHost')
  html.DivElement? editorHost;

  @Input()
  bool showToolbar = true;

  @Input()
  String theme = 'snow';

  @Input()
  String? placeholder;

  @Input()
  set value(String value) {
    _pendingValue = value;
    if (_quill != null && !_settingFromEditor) {
      _setEditorValue(value);
    }
    _settingFromEditor = false;
  }

  String get value => _pendingValue;

  final _valueChanges = StreamController<String>.broadcast();

  @Output()
  Stream<String> get valueChange => _valueChanges.stream;

  Quill? _quill;
  Function? _textChangeHandler;
  String _pendingValue = '';
  bool _settingFromEditor = false;

  void ngAfterViewInit() {
    initializeQuill();
    final host = editorHost;
    if (host == null) {
      return;
    }

    final container = HtmlDomElement(host);
    final modules = <String, dynamic>{
      if (showToolbar)
        'toolbar': <String, dynamic>{
          'container': _defaultToolbar,
        },
    };

    final options = ThemeOptions(
      theme: theme,
      modules: modules,
    );

    _ngZone.runOutsideAngular(() {
      _quill = Quill(container, options: options);
      if (placeholder != null && placeholder!.isNotEmpty) {
        _quill!.root.setAttribute('data-placeholder', placeholder!);
      }
      _setEditorValue(_pendingValue);
      _listenForChanges();
    });
  }

  void _listenForChanges() {
    if (_quill == null) {
      return;
    }

    void handler(dynamic payload) {
      if (payload is List && payload.length >= 3) {
        final source = payload[2] as String?;
        if (source != EmitterSource.USER) {
          return;
        }
      }
      if (_quill == null) {
        return;
      }
      final rawText = _quill!.getText();
      final normalized = rawText.endsWith('\n')
          ? rawText.substring(0, rawText.length - 1)
          : rawText;
      _settingFromEditor = true;
      _pendingValue = normalized;
      _valueChanges.add(normalized);
      _settingFromEditor = false;
    }

    _textChangeHandler = handler;
    _quill!.emitter.on(EmitterEvents.TEXT_CHANGE, handler);
  }

  void _setEditorValue(String value) {
    if (_quill == null) {
      return;
    }
    final delta = Delta();
    if (value.isNotEmpty) {
      delta.insert(value);
      if (!value.endsWith('\n')) {
        delta.insert('\n');
      }
    } else {
      delta.insert('\n');
    }
    _quill!.setContents(delta, source: EmitterSource.SILENT);
  }

  Quill? get quill => _quill;

  void ngOnDestroy() {
    if (_quill != null && _textChangeHandler != null) {
      _quill!.emitter.off(EmitterEvents.TEXT_CHANGE, _textChangeHandler);
    }
    _valueChanges.close();
    _quill = null;
    _textChangeHandler = null;
  }
}
