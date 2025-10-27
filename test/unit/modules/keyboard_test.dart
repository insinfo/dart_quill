import 'package:dart_quill/src/modules/keyboard.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

class _TestKeyboardEvent implements DomEvent {
  _TestKeyboardEvent({
    required this.key,
    this.shiftKey = false,
    this.metaKey = false,
    this.ctrlKey = false,
    this.altKey = false,
  });

  final String key;
  final bool shiftKey;
  final bool metaKey;
  final bool ctrlKey;
  final bool altKey;

  int? get keyCode => null;

  bool _defaultPrevented = false;

  @override
  bool get defaultPrevented => _defaultPrevented;

  @override
  void preventDefault() {
    _defaultPrevented = true;
  }

  @override
  DomNode? get target => null;

  @override
  dynamic get rawEvent => this;

  dynamic operator [](Object? name) {
    switch (name) {
      case 'shiftKey':
        return shiftKey;
      case 'metaKey':
        return metaKey;
      case 'ctrlKey':
        return ctrlKey;
      case 'altKey':
        return altKey;
      default:
        return null;
    }
  }
}

_TestKeyboardEvent _createKeyboardEvent(
  String key, {
  Map<String, bool>? override,
}) {
  final values = {
    'shiftKey': false,
    'metaKey': false,
    'ctrlKey': false,
    'altKey': false,
  };
  if (override != null) {
    override.forEach((name, value) {
      values[name] = value;
    });
  }
  return _TestKeyboardEvent(
    key: key,
    shiftKey: values['shiftKey'] ?? false,
    metaKey: values['metaKey'] ?? false,
    ctrlKey: values['ctrlKey'] ?? false,
    altKey: values['altKey'] ?? false,
  );
}

void main() {
  group('Keyboard', () {
    group('match', () {
      test('no modifiers', () {
        final binding = normalize({'key': 'a'})!;
        expect(Keyboard.match(_createKeyboardEvent('a'), binding), isTrue);
        expect(
          Keyboard.match(
            _createKeyboardEvent('A', override: {'altKey': true}),
            binding,
          ),
          isFalse,
        );
      });

      test('simple modifier', () {
        final binding = normalize({'key': 'a', 'altKey': true})!;
        expect(Keyboard.match(_createKeyboardEvent('a'), binding), isFalse);
        expect(
          Keyboard.match(
            _createKeyboardEvent('a', override: {'altKey': true}),
            binding,
          ),
          isTrue,
        );
      });

      test('optional modifier', () {
        final binding = normalize({'key': 'a', 'altKey': null})!;
        expect(Keyboard.match(_createKeyboardEvent('a'), binding), isTrue);
        expect(
          Keyboard.match(
            _createKeyboardEvent('a', override: {'altKey': true}),
            binding,
          ),
          isTrue,
        );
      });

      test('shortkey modifier', () {
        final binding = normalize({'key': 'a', 'shortKey': true})!;
        expect(Keyboard.match(_createKeyboardEvent('a'), binding), isFalse);
        expect(
          Keyboard.match(
            _createKeyboardEvent('a', override: {SHORTKEY: true}),
            binding,
          ),
          isTrue,
        );
      });

      test('native shortkey modifier', () {
        final binding = normalize({'key': 'a', SHORTKEY: true})!;
        expect(Keyboard.match(_createKeyboardEvent('a'), binding), isFalse);
        expect(
          Keyboard.match(
            _createKeyboardEvent('a', override: {SHORTKEY: true}),
            binding,
          ),
          isTrue,
        );
      });
    });
  });
}
