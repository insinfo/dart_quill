import 'package:dart_quill/src/ui/picker.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// Port of `referencias/quilljs/test/unit/ui/picker.spec.ts`.
({
  FakeDomElement container,
  Picker picker,
  FakeDomElement pickerElement,
}) _setup() {
  final container = testAdapter.document.createElement('div') as FakeDomElement;
  testAdapter.document.body.append(container);
  container.innerHTML =
      '<select><option selected>0</option><option value="1">1</option></select>';
  final select = container.firstChild! as FakeDomElement;
  final picker = Picker(select);
  final pickerElement =
      container.querySelector('.ql-picker')! as FakeDomElement;
  return (
    container: container,
    picker: picker,
    pickerElement: pickerElement,
  );
}

void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  group('Picker', () {
    test('initialization', () {
      final fixture = _setup();
      expect(fixture.container.querySelector('.ql-picker'), isNotNull);
      expect(fixture.container.querySelector('.ql-active'), isNull);
      final items = fixture.container.querySelectorAll('.ql-picker-item');
      expect(
        items[0],
        EqualHTML(
          '<span tabindex="0" role="button" '
          'class="ql-picker-item ql-selected" data-label="0"></span>',
          includeOuterTag: true,
        ),
      );
      expect(
        items[1],
        EqualHTML(
          '<span tabindex="0" role="button" class="ql-picker-item" '
          'data-value="1" data-label="1"></span>',
          includeOuterTag: true,
        ),
      );
    });

    test('escape charcters', () {
      final fixture = _setup();
      final select =
          testAdapter.document.createElement('select') as FakeDomElement;
      final option =
          testAdapter.document.createElement('option') as FakeDomElement;
      fixture.container.append(select);
      select.append(option);
      const value = '"Helvetica Neue", \'Helvetica\', sans-serif';
      option.value = value;
      final escaped = value.replaceAll('"', r'\"');
      expect(select.querySelector('option[value="$escaped"]'), option);
    });

    test('label is initialized with the correct aria attributes', () {
      final fixture = _setup();
      final label = fixture.pickerElement.querySelector('.ql-picker-label')!;
      final options =
          fixture.pickerElement.querySelector('.ql-picker-options')!;
      expect(label.getAttribute('aria-expanded'), 'false');
      expect(label.getAttribute('aria-controls'), options.id);
    });

    test('options container is initialized with the correct aria attributes',
        () {
      final fixture = _setup();
      final label = fixture.pickerElement.querySelector('.ql-picker-label')!;
      final options =
          fixture.pickerElement.querySelector('.ql-picker-options')!;
      expect(options.getAttribute('aria-hidden'), 'true');
      expect(options.id, label.getAttribute('aria-controls'));
      expect(options.getAttribute('tabindex'), '-1');
    });

    test(
        'aria attributes toggle correctly when the picker is opened via enter key',
        () {
      final fixture = _setup();
      final label = fixture.pickerElement.querySelector('.ql-picker-label')!
          as FakeDomElement;
      label.dispatchEvent(
        'keydown',
        FakeDomKeyboardEvent(type: 'keydown', target: label, key: 'Enter'),
      );
      expect(label.getAttribute('aria-expanded'), 'true');
      expect(
        fixture.pickerElement
            .querySelector('.ql-picker-options')!
            .getAttribute('aria-hidden'),
        'false',
      );
    });

    test(
        'aria attributes toggle correctly when the picker is opened via mousedown',
        () {
      final fixture = _setup();
      final label = fixture.pickerElement.querySelector('.ql-picker-label')!
          as FakeDomElement;
      label.dispatchEvent(
        'mousedown',
        FakeDomMouseEvent(type: 'mousedown', target: label),
      );
      expect(label.getAttribute('aria-expanded'), 'true');
      expect(
        fixture.pickerElement
            .querySelector('.ql-picker-options')!
            .getAttribute('aria-hidden'),
        'false',
      );
    });

    test('aria attributes toggle correctly when an item is selected via click',
        () {
      final fixture = _setup();
      final label = fixture.pickerElement.querySelector('.ql-picker-label')!;
      label.click();
      fixture.pickerElement.querySelector('.ql-picker-item')!.click();
      expect(label.getAttribute('aria-expanded'), 'false');
      expect(
        fixture.pickerElement
            .querySelector('.ql-picker-options')!
            .getAttribute('aria-hidden'),
        'true',
      );
    });

    test('aria attributes toggle correctly when an item is selected via enter',
        () {
      final fixture = _setup();
      final label = fixture.pickerElement.querySelector('.ql-picker-label')!;
      label.click();
      final item = fixture.pickerElement.querySelector('.ql-picker-item')!
          as FakeDomElement;
      item.dispatchEvent(
        'keydown',
        FakeDomKeyboardEvent(type: 'keydown', target: item, key: 'Enter'),
      );
      expect(label.getAttribute('aria-expanded'), 'false');
      expect(
        fixture.pickerElement
            .querySelector('.ql-picker-options')!
            .getAttribute('aria-hidden'),
        'true',
      );
    });

    test(
        'aria attributes toggle correctly when the picker is closed via clicking on the label again',
        () {
      final fixture = _setup();
      final label = fixture.pickerElement.querySelector('.ql-picker-label')!;
      label
        ..click()
        ..click();
      expect(label.getAttribute('aria-expanded'), 'false');
      expect(
        fixture.pickerElement
            .querySelector('.ql-picker-options')!
            .getAttribute('aria-hidden'),
        'true',
      );
    });

    test(
        'aria attributes toggle correctly when the picker is closed via escaping out of it',
        () {
      final fixture = _setup();
      final label = fixture.pickerElement.querySelector('.ql-picker-label')!
          as FakeDomElement;
      label.click();
      label.dispatchEvent(
        'keydown',
        FakeDomKeyboardEvent(type: 'keydown', target: label, key: 'Escape'),
      );
      expect(label.getAttribute('aria-expanded'), 'false');
      expect(
        fixture.pickerElement
            .querySelector('.ql-picker-options')!
            .getAttribute('aria-hidden'),
        'true',
      );
    });
  });
}
