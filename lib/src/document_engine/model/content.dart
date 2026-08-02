import 'fragment.dart';
import 'schema.dart';

class MatchEdge {
  final NodeType type;
  final ContentMatch next;
  MatchEdge(this.type, this.next);
}

/// Instances of this class represent a match state of a node type's
/// content expression.
class ContentMatch {
  final bool validEnd;
  final List<MatchEdge> next = [];
  final List<dynamic> wrapCache = [];

  ContentMatch(this.validEnd);

  static ContentMatch parse(String string, Map<String, NodeType> nodeTypes) {
    TokenStream stream = TokenStream(string, nodeTypes);
    if (stream.next == null) return ContentMatch.empty;
    Expr expr = parseExpr(stream);
    if (stream.next != null) stream.err("Unexpected trailing text");
    ContentMatch match = dfa(nfa(expr));
    checkForDeadEnds(match, stream);
    return match;
  }

  ContentMatch? matchType(NodeType type) {
    for (int i = 0; i < next.length; i++) {
      if (next[i].type == type) return next[i].next;
    }
    return null;
  }

  ContentMatch? matchFragment(Fragment frag, [int start = 0, int? end]) {
    end ??= frag.childCount;
    ContentMatch? cur = this;
    for (int i = start; cur != null && i < end; i++) {
      cur = cur.matchType(frag.child(i).type);
    }
    return cur;
  }

  bool get inlineContent {
    return next.isNotEmpty && next[0].type.isInline;
  }

  NodeType? get defaultType {
    for (int i = 0; i < next.length; i++) {
      NodeType type = next[i].type;
      if (!(type.isText || type.hasRequiredAttrs())) return type;
    }
    return null;
  }

  bool compatible(ContentMatch other) {
    for (int i = 0; i < next.length; i++) {
      for (int j = 0; j < other.next.length; j++) {
        if (next[i].type == other.next[j].type) return true;
      }
    }
    return false;
  }

  Fragment? fillBefore(Fragment after, [bool toEnd = false, int startIndex = 0]) {
    List<ContentMatch> seen = [this];
    
    Fragment? search(ContentMatch match, List<NodeType> types) {
      ContentMatch? finished = match.matchFragment(after, startIndex);
      if (finished != null && (!toEnd || finished.validEnd)) {
        return Fragment.from(types.map((tp) => tp.createAndFill()!).toList());
      }

      for (int i = 0; i < match.next.length; i++) {
        NodeType type = match.next[i].type;
        ContentMatch nextMatch = match.next[i].next;
        if (!(type.isText || type.hasRequiredAttrs()) && !seen.contains(nextMatch)) {
          seen.add(nextMatch);
          Fragment? found = search(nextMatch, [...types, type]);
          if (found != null) return found;
        }
      }
      return null;
    }

    return search(this, []);
  }

  List<NodeType>? findWrapping(NodeType target) {
    for (int i = 0; i < wrapCache.length; i += 2) {
      if (wrapCache[i] == target) return wrapCache[i + 1] as List<NodeType>?;
    }
    List<NodeType>? computed = computeWrapping(target);
    wrapCache.add(target);
    wrapCache.add(computed);
    return computed;
  }

  List<NodeType>? computeWrapping(NodeType target) {
    Map<String, bool> seen = {};
    List<_Active> active = [_Active(this, null, null)];
    while (active.isNotEmpty) {
      _Active current = active.removeAt(0);
      ContentMatch match = current.match;
      if (match.matchType(target) != null) {
        List<NodeType> result = [];
        for (_Active? obj = current; obj != null && obj.type != null; obj = obj.via) {
          result.add(obj.type!);
        }
        return result.reversed.toList();
      }
      for (int i = 0; i < match.next.length; i++) {
        NodeType type = match.next[i].type;
        ContentMatch nextMatch = match.next[i].next;
        if (!type.isLeaf &&
            !type.hasRequiredAttrs() &&
            !seen.containsKey(type.name) &&
            (current.type == null || nextMatch.validEnd)) {
          active.add(_Active(type.contentMatch, type, current));
          seen[type.name] = true;
        }
      }
    }
    return null;
  }

  int get edgeCount => next.length;

  MatchEdge edge(int n) {
    if (n >= next.length) {
      throw RangeError("There's no ${n}th edge in this content match");
    }
    return next[n];
  }

  @override
  String toString() {
    List<ContentMatch> seen = [];
    void scan(ContentMatch m) {
      seen.add(m);
      for (int i = 0; i < m.next.length; i++) {
        if (!seen.contains(m.next[i].next)) scan(m.next[i].next);
      }
    }
    scan(this);
    return seen.asMap().entries.map((entry) {
      int i = entry.key;
      ContentMatch m = entry.value;
      String out = "$i${m.validEnd ? '*' : ' '} ";
      for (int j = 0; j < m.next.length; j++) {
        out += (j > 0 ? ", " : "") + "${m.next[j].type.name}->${seen.indexOf(m.next[j].next)}";
      }
      return out;
    }).join("\n");
  }

  static final ContentMatch empty = ContentMatch(true);
}

class _Active {
  final ContentMatch match;
  final NodeType? type;
  final _Active? via;
  _Active(this.match, this.type, this.via);
}

class TokenStream {
  bool? inline;
  int pos = 0;
  List<String> tokens;
  final String string;
  final Map<String, NodeType> nodeTypes;

  TokenStream(this.string, this.nodeTypes) : tokens = [] {
    tokens = string.split(RegExp(r'\s*(?=\b|\W|$)'));
    if (tokens.isNotEmpty && tokens.last.isEmpty) tokens.removeLast();
    if (tokens.isNotEmpty && tokens.first.isEmpty) tokens.removeAt(0);
  }

  String? get next => pos < tokens.length ? tokens[pos] : null;

  bool eat(String tok) {
    if (next == tok) {
      pos++;
      return true;
    }
    return false;
  }

  void err(String str) {
    throw FormatException("$str (in content expression '$string')");
  }
}

abstract class Expr {
  String get type;
}

class ChoiceExpr extends Expr {
  @override
  String get type => "choice";
  final List<Expr> exprs;
  ChoiceExpr(this.exprs);
}

class SeqExpr extends Expr {
  @override
  String get type => "seq";
  final List<Expr> exprs;
  SeqExpr(this.exprs);
}

class PlusExpr extends Expr {
  @override
  String get type => "plus";
  final Expr expr;
  PlusExpr(this.expr);
}

class StarExpr extends Expr {
  @override
  String get type => "star";
  final Expr expr;
  StarExpr(this.expr);
}

class OptExpr extends Expr {
  @override
  String get type => "opt";
  final Expr expr;
  OptExpr(this.expr);
}

class RangeExpr extends Expr {
  @override
  String get type => "range";
  final int min;
  final int max;
  final Expr expr;
  RangeExpr(this.min, this.max, this.expr);
}

class NameExpr extends Expr {
  @override
  String get type => "name";
  final NodeType value;
  NameExpr(this.value);
}

Expr parseExpr(TokenStream stream) {
  List<Expr> exprs = [];
  do {
    exprs.add(parseExprSeq(stream));
  } while (stream.eat("|"));
  return exprs.length == 1 ? exprs[0] : ChoiceExpr(exprs);
}

Expr parseExprSeq(TokenStream stream) {
  List<Expr> exprs = [];
  do {
    exprs.add(parseExprSubscript(stream));
  } while (stream.next != null && stream.next != ")" && stream.next != "|");
  return exprs.length == 1 ? exprs[0] : SeqExpr(exprs);
}

Expr parseExprSubscript(TokenStream stream) {
  Expr expr = parseExprAtom(stream);
  while (true) {
    if (stream.eat("+")) {
      expr = PlusExpr(expr);
    } else if (stream.eat("*")) {
      expr = StarExpr(expr);
    } else if (stream.eat("?")) {
      expr = OptExpr(expr);
    } else if (stream.eat("{")) {
      expr = parseExprRange(stream, expr);
    } else {
      break;
    }
  }
  return expr;
}

int parseNum(TokenStream stream) {
  if (stream.next != null && RegExp(r'\D').hasMatch(stream.next!)) {
    stream.err("Expected number, got '${stream.next}'");
  }
  int result = int.parse(stream.next!);
  stream.pos++;
  return result;
}

Expr parseExprRange(TokenStream stream, Expr expr) {
  int min = parseNum(stream);
  int max = min;
  if (stream.eat(",")) {
    if (stream.next != "}") {
      max = parseNum(stream);
    } else {
      max = -1;
    }
  }
  if (!stream.eat("}")) stream.err("Unclosed braced range");
  return RangeExpr(min, max, expr);
}

List<NodeType> resolveName(TokenStream stream, String name) {
  Map<String, NodeType> types = stream.nodeTypes;
  NodeType? type = types[name];
  if (type != null) return [type];
  List<NodeType> result = [];
  for (String typeName in types.keys) {
    NodeType t = types[typeName]!;
    if (t.isInGroup(name)) result.add(t);
  }
  if (result.isEmpty) stream.err("No node type or group '$name' found");
  return result;
}

Expr parseExprAtom(TokenStream stream) {
  if (stream.eat("(")) {
    Expr expr = parseExpr(stream);
    if (!stream.eat(")")) stream.err("Missing closing paren");
    return expr;
  } else if (stream.next != null && !RegExp(r'\W').hasMatch(stream.next!)) {
    List<Expr> exprs = resolveName(stream, stream.next!).map((type) {
      if (stream.inline == null) {
        stream.inline = type.isInline;
      } else if (stream.inline != type.isInline) {
        stream.err("Mixing inline and block content");
      }
      return NameExpr(type);
    }).toList();
    stream.pos++;
    return exprs.length == 1 ? exprs[0] : ChoiceExpr(exprs);
  } else {
    stream.err("Unexpected token '${stream.next}'");
    throw Exception(); // unreachable
  }
}

class _Edge {
  final NodeType? term;
  int? to;
  _Edge(this.term, this.to);
}

List<List<_Edge>> nfa(Expr expr) {
  List<List<_Edge>> nfaObj = [[]];
  
  int node() {
    nfaObj.add([]);
    return nfaObj.length - 1;
  }
  
  _Edge edge(int from, [int? to, NodeType? term]) {
    _Edge e = _Edge(term, to);
    nfaObj[from].add(e);
    return e;
  }
  
  void connect(List<_Edge> edges, int to) {
    for (var e in edges) {
      e.to = to;
    }
  }
  
  List<_Edge> compile(Expr expr, int from) {
    if (expr is ChoiceExpr) {
      return expr.exprs.expand((e) => compile(e, from)).toList();
    } else if (expr is SeqExpr) {
      for (int i = 0;; i++) {
        List<_Edge> next = compile(expr.exprs[i], from);
        if (i == expr.exprs.length - 1) return next;
        from = node();
        connect(next, from);
      }
    } else if (expr is StarExpr) {
      int loop = node();
      edge(from, loop);
      connect(compile(expr.expr, loop), loop);
      return [edge(loop)];
    } else if (expr is PlusExpr) {
      int loop = node();
      connect(compile(expr.expr, from), loop);
      connect(compile(expr.expr, loop), loop);
      return [edge(loop)];
    } else if (expr is OptExpr) {
      return [edge(from), ...compile(expr.expr, from)];
    } else if (expr is RangeExpr) {
      int cur = from;
      for (int i = 0; i < expr.min; i++) {
        int next = node();
        connect(compile(expr.expr, cur), next);
        cur = next;
      }
      if (expr.max == -1) {
        connect(compile(expr.expr, cur), cur);
      } else {
        for (int i = expr.min; i < expr.max; i++) {
          int next = node();
          edge(cur, next);
          connect(compile(expr.expr, cur), next);
          cur = next;
        }
      }
      return [edge(cur)];
    } else if (expr is NameExpr) {
      return [edge(from, null, expr.value)];
    } else {
      throw Exception("Unknown expr type");
    }
  }

  connect(compile(expr, 0), node());
  return nfaObj;
}

int _cmp(int a, int b) => b - a;

List<int> nullFrom(List<List<_Edge>> nfaObj, int startNode) {
  List<int> result = [];
  
  void scan(int node) {
    List<_Edge> edges = nfaObj[node];
    if (edges.length == 1 && edges[0].term == null) return scan(edges[0].to!);
    result.add(node);
    for (int i = 0; i < edges.length; i++) {
      NodeType? term = edges[i].term;
      int to = edges[i].to!;
      if (term == null && !result.contains(to)) scan(to);
    }
  }
  
  scan(startNode);
  result.sort(_cmp);
  return result;
}

ContentMatch dfa(List<List<_Edge>> nfaObj) {
  Map<String, ContentMatch> labeled = {};
  
  ContentMatch explore(List<int> states) {
    List<List<dynamic>> out = [];
    for (int node in states) {
      for (_Edge edge in nfaObj[node]) {
        if (edge.term == null) continue;
        List<int>? set;
        for (var pair in out) {
          if (pair[0] == edge.term) set = pair[1] as List<int>;
        }
        for (int toNode in nullFrom(nfaObj, edge.to!)) {
          if (set == null) {
            set = [];
            out.add([edge.term, set]);
          }
          if (!set.contains(toNode)) set.add(toNode);
        }
      }
    }
    
    String stateKey = states.join(",");
    ContentMatch state = ContentMatch(states.contains(nfaObj.length - 1));
    labeled[stateKey] = state;
    
    for (var pair in out) {
      NodeType term = pair[0] as NodeType;
      List<int> nextStates = pair[1] as List<int>;
      nextStates.sort(_cmp);
      String nextKey = nextStates.join(",");
      state.next.add(MatchEdge(term, labeled[nextKey] ?? explore(nextStates)));
    }
    return state;
  }

  return explore(nullFrom(nfaObj, 0));
}

void checkForDeadEnds(ContentMatch match, TokenStream stream) {
  List<ContentMatch> work = [match];
  for (int i = 0; i < work.length; i++) {
    ContentMatch state = work[i];
    bool dead = !state.validEnd;
    List<String> nodes = [];
    for (int j = 0; j < state.next.length; j++) {
      NodeType type = state.next[j].type;
      ContentMatch next = state.next[j].next;
      nodes.add(type.name);
      if (dead && !(type.isText || type.hasRequiredAttrs())) dead = false;
      if (!work.contains(next)) work.add(next);
    }
    if (dead) {
      stream.err("Only non-generatable nodes (${nodes.join(", ")}) in a required position");
    }
  }
}
