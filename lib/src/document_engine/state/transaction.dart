import '../model/index.dart';
import '../transform/index.dart';
import 'selection.dart';
import 'state.dart';

typedef Command = bool Function(EditorState state, [void Function(Transaction tr)? dispatch, dynamic view]);

const int UPDATED_SEL = 1;
const int UPDATED_MARKS = 2;
const int UPDATED_SCROLL = 4;

class Transaction extends Transform {
  int time;
  Selection _curSelection;
  int _curSelectionFor = 0;
  int _updated = 0;
  final Map<String, dynamic> _meta = {};
  List<Mark>? storedMarks;

  Transaction(EditorState state)
      : time = DateTime.now().millisecondsSinceEpoch,
        _curSelection = state.selection,
        storedMarks = state.storedMarks,
        super(state.doc);

  Selection get selection {
    if (_curSelectionFor < steps.length) {
      _curSelection = _curSelection.map(doc, mapping.slice(_curSelectionFor));
      _curSelectionFor = steps.length;
    }
    return _curSelection;
  }

  Transaction setSelection(Selection selection) {
    if (selection.fromRes.doc != doc) {
      throw RangeError("Selection passed to setSelection must point at the current document");
    }
    _curSelection = selection;
    _curSelectionFor = steps.length;
    _updated = (_updated | UPDATED_SEL) & ~UPDATED_MARKS;
    storedMarks = null;
    return this;
  }

  bool get selectionSet => (_updated & UPDATED_SEL) > 0;

  Transaction setStoredMarks(List<Mark>? marks) {
    storedMarks = marks;
    _updated |= UPDATED_MARKS;
    return this;
  }

  Transaction ensureMarks(List<Mark> marks) {
    if (!Mark.sameSet(storedMarks ?? selection.fromRes.marks(), marks)) {
      setStoredMarks(marks);
    }
    return this;
  }

  Transaction addStoredMark(Mark mark) {
    return ensureMarks(mark.addToSet(storedMarks ?? selection.headRes.marks()));
  }

  Transaction removeStoredMark(dynamic mark) {
    return ensureMarks(mark.removeFromSet(storedMarks ?? selection.headRes.marks()));
  }

  bool get storedMarksSet => (_updated & UPDATED_MARKS) > 0;

  @override
  void addStep(Step step, PMNode doc) {
    super.addStep(step, doc);
    _updated = _updated & ~UPDATED_MARKS;
    storedMarks = null;
  }

  Transaction setTime(int time) {
    this.time = time;
    return this;
  }

  Transaction replaceSelection(Slice slice) {
    selection.replace(this, slice);
    return this;
  }

  Transaction replaceSelectionWith(PMNode node, [bool inheritMarks = true]) {
    Selection sel = selection;
    if (inheritMarks) {
      node = node.mark(storedMarks ?? (sel.empty ? sel.fromRes.marks() : (sel.fromRes.marksAcross(sel.toRes) ?? [])));
    }
    sel.replaceWith(this, node);
    return this;
  }

  Transaction deleteSelection() {
    selection.replace(this);
    return this;
  }

  Transaction insertText(String text, [int? from, int? to]) {
    Schema schema = doc.type.schema;
    if (from == null) {
      if (text.isEmpty) return deleteSelection();
      return replaceSelectionWith(schema.text(text), true);
    } else {
      to ??= from;
      if (text.isEmpty) return deleteRange(from, to) as Transaction;
      List<Mark>? marks = storedMarks;
      if (marks == null) {
        ResolvedPos fromRes = doc.resolve(from);
        marks = to == from ? fromRes.marks() : fromRes.marksAcross(doc.resolve(to));
      }
      replaceRangeWith(from, to, schema.text(text, marks));
      if (!selection.empty && selection.to == from + text.length) {
        setSelection(Selection.near(selection.toRes));
      }
      return this;
    }
  }

  Transaction setMeta(dynamic key, dynamic value) {
    _meta[key is String ? key : key.key] = value;
    return this;
  }

  dynamic getMeta(dynamic key) {
    return _meta[key is String ? key : key.key];
  }

  bool get isGeneric {
    for (var _ in _meta.keys) return false;
    return true;
  }

  Transaction scrollIntoView() {
    _updated |= UPDATED_SCROLL;
    return this;
  }

  bool get scrolledIntoView => (_updated & UPDATED_SCROLL) > 0;
}

void selectionToInsertionEnd(Transaction tr, int startLen, int bias) {
  int last = tr.steps.length - 1;
  if (last < startLen) return;
  Step step = tr.steps[last];
  if (!(step is ReplaceStep || step is ReplaceAroundStep)) return;
  StepMap map = tr.mapping.maps[last];
  int end = 0;
  map.forEach((_oldStart, _oldEnd, _newStart, newEnd) {
    if (end == 0) end = newEnd;
  });
  tr.setSelection(Selection.near(tr.doc.resolve(end), bias));
}
