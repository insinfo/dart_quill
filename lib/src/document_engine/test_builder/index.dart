import '../model/index.dart';
import 'schema.dart';

final Expando<Map<String, int>> nodeTags = Expando<Map<String, int>>();

extension TaggedNode on PMNode {
  Map<String, int> get tag => nodeTags[this] ?? {};
  set tag(Map<String, int> tags) => nodeTags[this] = tags;
}

class _MarkedContent {
  final Mark mark;
  final List<dynamic> content;
  _MarkedContent(this.mark, this.content);
}

class _FlatResult {
  final List<PMNode> nodes;
  final Map<String, int> tags;
  _FlatResult(this.nodes, this.tags);
}

_FlatResult _flattenAndMergeMarks(List<dynamic> items, [List<Mark> marks = const []]) {
  List<PMNode> result = [];
  Map<String, int> tags = {};
  int currentOffset = 0;

  for (var item in items) {
    if (item is String) {
      RegExp tagRegex = RegExp(r'<([a-zA-Z0-9_]+)>');
      int lastIndex = 0;
      String textContent = "";
      
      for (var match in tagRegex.allMatches(item)) {
        String before = item.substring(lastIndex, match.start);
        if (before.isNotEmpty) {
          result.add(testSchema.text(before, marks));
          currentOffset += before.length;
          textContent += before;
        }
        tags[match.group(1)!] = currentOffset;
        lastIndex = match.end;
      }
      
      String remaining = item.substring(lastIndex);
      if (remaining.isNotEmpty) {
        result.add(testSchema.text(remaining, marks));
        currentOffset += remaining.length;
      } else if (textContent.isEmpty && lastIndex > 0) {
        // String was just tags, no text node created
      }
    } else if (item is PMNode) {
      List<Mark> newMarks = List.from(item.marks);
      for (var m in marks) {
        newMarks = m.addToSet(newMarks);
      }
      PMNode newNode = item.mark(newMarks);
      if (!identical(newNode, item)) {
        newNode.tag = item.tag;
      }
      
      // Merge child tags
      Map<String, int> childTags = newNode.tag;
      childTags.forEach((key, value) {
        tags[key] = currentOffset + 1 + value; // +1 for the node opening
      });
      
      result.add(newNode);
      currentOffset += newNode.nodeSize;
    } else if (item is List) {
      _FlatResult childRes = _flattenAndMergeMarks(item, marks);
      result.addAll(childRes.nodes);
      childRes.tags.forEach((key, value) {
        tags[key] = currentOffset + value;
      });
      for (var n in childRes.nodes) currentOffset += n.nodeSize;
    } else if (item is _MarkedContent) {
      _FlatResult childRes = _flattenAndMergeMarks(item.content, [...marks, item.mark]);
      result.addAll(childRes.nodes);
      childRes.tags.forEach((key, value) {
        tags[key] = currentOffset + value;
      });
      for (var n in childRes.nodes) currentOffset += n.nodeSize;
    }
  }
  return _FlatResult(result, tags);
}

PMNode _node(String type, [dynamic attrsOrContent, dynamic content]) {
  Map<String, dynamic>? attrs;
  List<dynamic> children = [];
  
  if (attrsOrContent is Map<String, dynamic>) {
    attrs = attrsOrContent;
    if (content != null) {
      children = content is List ? content : [content];
    }
  } else if (attrsOrContent != null) {
    children = attrsOrContent is List ? attrsOrContent : [attrsOrContent];
  }
  
  NodeType nodeType = testSchema.nodes[type]!;
  _FlatResult res = _flattenAndMergeMarks(children);
  PMNode node = nodeType.create(attrs, res.nodes);
  node.tag = res.tags;
  return node;
}

_MarkedContent _mark(String type, [dynamic attrsOrContent, dynamic content]) {
  Map<String, dynamic>? attrs;
  List<dynamic> children = [];
  
  if (attrsOrContent is Map<String, dynamic>) {
    attrs = attrsOrContent;
    if (content != null) {
      children = content is List ? content : [content];
    }
  } else if (attrsOrContent != null) {
    children = attrsOrContent is List ? attrsOrContent : [attrsOrContent];
  }
  
  MarkType markType = testSchema.marks[type]!;
  return _MarkedContent(markType.create(attrs), children);
}

// Nodes
PMNode doc([dynamic a, dynamic b, dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h, dynamic i, dynamic j]) => _node('doc', [a, b, c, d, e, f, g, h, i, j].where((e) => e != null).toList());
PMNode p([dynamic a, dynamic b, dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h, dynamic i, dynamic j]) => _node('paragraph', [a, b, c, d, e, f, g, h, i, j].where((e) => e != null).toList());
PMNode blockquote([dynamic a, dynamic b, dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h, dynamic i, dynamic j]) => _node('blockquote', [a, b, c, d, e, f, g, h, i, j].where((e) => e != null).toList());
PMNode h1([dynamic a, dynamic b, dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h, dynamic i, dynamic j]) => _node('heading', {'level': 1}, [a, b, c, d, e, f, g, h, i, j].where((e) => e != null).toList());
PMNode h2([dynamic a, dynamic b, dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h, dynamic i, dynamic j]) => _node('heading', {'level': 2}, [a, b, c, d, e, f, g, h, i, j].where((e) => e != null).toList());
PMNode hr() => _node('horizontal_rule');
PMNode br() => _node('hard_break');
PMNode img(Map<String, dynamic> attrs) => _node('image', attrs);
PMNode ul([dynamic a, dynamic b, dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h, dynamic i, dynamic j]) => _node('bullet_list', [a, b, c, d, e, f, g, h, i, j].where((e) => e != null).toList());
PMNode ol([dynamic a, dynamic b, dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h, dynamic i, dynamic j]) => _node('ordered_list', [a, b, c, d, e, f, g, h, i, j].where((e) => e != null).toList());
PMNode li([dynamic a, dynamic b, dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h, dynamic i, dynamic j]) => _node('list_item', [a, b, c, d, e, f, g, h, i, j].where((e) => e != null).toList());
PMNode pre([dynamic a, dynamic b, dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h, dynamic i, dynamic j]) => _node('code_block', [a, b, c, d, e, f, g, h, i, j].where((e) => e != null).toList());

// Marks
dynamic em([dynamic a, dynamic b, dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h, dynamic i, dynamic j]) => _mark('em', [a, b, c, d, e, f, g, h, i, j].where((e) => e != null).toList());
dynamic strong([dynamic a, dynamic b, dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h, dynamic i, dynamic j]) => _mark('strong', [a, b, c, d, e, f, g, h, i, j].where((e) => e != null).toList());
dynamic a(Map<String, dynamic> attrs, [dynamic a, dynamic b, dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h, dynamic i, dynamic j]) => _mark('link', attrs, [a, b, c, d, e, f, g, h, i, j].where((e) => e != null).toList());
dynamic code([dynamic a, dynamic b, dynamic c, dynamic d, dynamic e, dynamic f, dynamic g, dynamic h, dynamic i, dynamic j]) => _mark('code', [a, b, c, d, e, f, g, h, i, j].where((e) => e != null).toList());

// General
Schema get schema => testSchema;
