/// Lightweight performance tracer for locating UI-response bottlenecks.
///
/// Usage:
/// ```dart
/// final traceId = PerformanceTracer.startTrace('escort_start_tap',
///     input: {'destination': '...'});
/// final spanId = PerformanceTracer.startSpan(traceId, 'getPreciseLocation');
/// // ... do work ...
/// PerformanceTracer.endSpan(spanId, output: {'lat': 22.5, 'lng': 114.0});
/// PerformanceTracer.endTrace(traceId);
/// ```
///
/// Each call to [endTrace] prints a formatted summary of the full call chain
/// with millisecond-precision timestamps, sorted by start time.
class PerformanceTracer {
  PerformanceTracer._();

  static final PerformanceTracer _instance = PerformanceTracer._();
  static PerformanceTracer get instance => _instance;

  final Map<String, _TraceSpan> _spans = {};
  final List<String> _stack = [];
  int _nextIdCounter = 0;

  bool _enabled = true;

  /// The currently-active trace ID (top of stack), or empty string if none.
  String get currentTraceId => _stack.isNotEmpty ? _stack.last : '';

  void disable() => _enabled = false;
  void enable() => _enabled = true;

  // ────────────────────────────
  // Public API
  // ────────────────────────────

  /// Begin a new top-level trace (usually triggered by a UI tap).
  String startTrace(String name, {Map<String, dynamic>? input}) {
    if (!_enabled) return '';
    final id = _nextId();
    _spans[id] = _TraceSpan(
      id: id,
      name: name,
      startTime: DateTime.now(),
      input: input,
      thread: 'main',
    );
    return id;
  }

  /// Begin a child span inside [parentId].
  String startSpan(
    String parentId, {
    required String name,
    Map<String, dynamic>? input,
    String thread = 'main',
  }) {
    if (!_enabled || parentId.isEmpty) return '';
    final id = _nextId();
    _spans[id] = _TraceSpan(
      id: id,
      parentId: parentId,
      name: name,
      startTime: DateTime.now(),
      input: input,
      thread: thread,
    );
    final parent = _spans[parentId];
    if (parent != null) {
      parent.children.add(id);
    }
    return id;
  }

  /// Close a span.
  void endSpan(String spanId, {Map<String, dynamic>? output}) {
    if (!_enabled || spanId.isEmpty) return;
    final span = _spans[spanId];
    if (span == null) return;
    span.endTime = DateTime.now();
    span.output = output;
  }

  /// Close the root trace and print the complete call-chain summary.
  void endTrace(String traceId, {Map<String, dynamic>? output}) {
    if (!_enabled || traceId.isEmpty) return;
    _stack.remove(traceId);
    final root = _spans[traceId];
    if (root == null) return;
    root.endTime = DateTime.now();
    root.output = output;
    _printSummary(root);
    _purge(traceId);
  }

  /// Push [traceId] onto the current-trace stack. Subsequent [autoSpan]
  /// calls will attach to this trace without needing the ID passed explicitly.
  void pushTrace(String traceId) {
    if (!_enabled || traceId.isEmpty) return;
    _stack.add(traceId);
  }

  /// Pop the most recent trace from the stack.
  void popTrace(String traceId) {
    _stack.remove(traceId);
  }

  /// Create a child span under [currentTraceId] if one is active.
  /// Returns the span ID, or empty string if no trace is active.
  String autoSpan(String name,
      {Map<String, dynamic>? input, String thread = 'main'}) {
    final parentId = currentTraceId;
    if (parentId.isEmpty) return '';
    return startSpan(parentId, name: name, input: input, thread: thread);
  }

  // ────────────────────────────
  // Convenience wrappers
  // ────────────────────────────

  /// Run [body] inside a new top-level trace, auto-closing on completion.
  /// Also pushes onto the current-trace stack so nested [autoSpan] calls work.
  Future<T> trace<T>(String name, Future<T> Function() body,
      {Map<String, dynamic>? input}) async {
    final traceId = startTrace(name, input: input);
    pushTrace(traceId);
    try {
      final result = await body();
      endTrace(traceId, output: _resultMap(result));
      return result;
    } catch (e) {
      endTrace(traceId, output: {'error': e.toString()});
      rethrow;
    }
  }

  /// Run [body] inside a child span under [currentTraceId], auto-closing.
  /// Does nothing if no trace is active.
  Future<T> traceAuto<T>(String name, Future<T> Function() body,
      {Map<String, dynamic>? input, String thread = 'main'}) async {
    final spanId = autoSpan(name, input: input, thread: thread);
    if (spanId.isEmpty) return body();
    try {
      final result = await body();
      endSpan(spanId, output: _resultMap(result));
      return result;
    } catch (e) {
      endSpan(spanId, output: {'error': e.toString()});
      rethrow;
    }
  }

  /// Run [body] inside a child span, auto-closing on completion.
  Future<T> traceSpan<T>(
    String parentId,
    String name,
    Future<T> Function() body, {
    Map<String, dynamic>? input,
    String thread = 'main',
  }) async {
    final spanId = startSpan(parentId, name: name, input: input, thread: thread);
    try {
      final result = await body();
      endSpan(spanId, output: _resultMap(result));
      return result;
    } catch (e) {
      endSpan(spanId, output: {'error': e.toString()});
      rethrow;
    }
  }

  // ────────────────────────────
  // Internal
  // ────────────────────────────

  String _nextId() => '${++_nextIdCounter}';

  void _purge(String rootId) {
    final toRemove = <String>[rootId];
    final root = _spans[rootId];
    if (root != null) _collectIds(root, toRemove);
    for (final id in toRemove) {
      _spans.remove(id);
    }
  }

  void _collectIds(_TraceSpan span, List<String> ids) {
    for (final childId in span.children) {
      final child = _spans[childId];
      if (child != null) {
        ids.add(childId);
        _collectIds(child, ids);
      }
    }
  }

  void _printSummary(_TraceSpan root) {
    final buf = StringBuffer();
    final totalMs = root.durationMs;

    buf.writeln('');
    buf.writeln('╔══════════════════════════════════════════════════════════════╗');
    buf.writeln('║  PERF TRACE  —  ${root.name}');
    buf.writeln('║  总耗时: ${totalMs}ms');
    buf.writeln('╠══════════════════════════════════════════════════════════════╣');
    _printSpan(root, buf, 0, totalMs);
    buf.writeln('╚══════════════════════════════════════════════════════════════╝');
    buf.writeln('');
    print(buf.toString());
  }

  void _printSpan(_TraceSpan span, StringBuffer buf, int depth, int rootMs) {
    final indent = '  ' * depth;
    final prefix = depth == 0
        ? '\u25C6'
        : (span.children.isEmpty ? '\u2514\u2500' : '\u251C\u2500');
    final ms = span.durationMs;
    final pct =
        rootMs > 0 ? '${(ms / rootMs * 100).toStringAsFixed(0)}%' : '-';
    final threadTag = span.thread != 'main' ? ' [${span.thread}]' : '';

    buf.writeln('║ $indent$prefix ${span.name}$threadTag  \u2014  ${ms}ms ($pct)');

    if (span.input != null && span.input!.isNotEmpty) {
      buf.writeln('║ $indent  \u2502 \u5165\u53C2: ${_formatMap(span.input!)}');
    }
    if (span.output != null && span.output!.isNotEmpty) {
      buf.writeln('║ $indent  \u2502 \u51FA\u53C2: ${_formatMap(span.output!)}');
    }

    for (final childId in span.children) {
      final child = _spans[childId];
      if (child != null) _printSpan(child, buf, depth + 1, rootMs);
    }
  }

  String _formatMap(Map<String, dynamic> m) {
    final parts = m.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${_truncateValue(e.value)}')
        .take(6);
    return parts.join(', ');
  }

  String _truncateValue(dynamic v) {
    final s = v.toString();
    return s.length > 40 ? '${s.substring(0, 40)}\u2026' : s;
  }

  Map<String, dynamic>? _resultMap(dynamic result) {
    if (result == null) return null;
    if (result is Map<String, dynamic>) return result;
    return {'value': result.toString()};
  }
}

class _TraceSpan {
  final String id;
  final String? parentId;
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  final Map<String, dynamic>? input;
  Map<String, dynamic>? output;
  final String thread;
  final List<String> children;

  _TraceSpan({
    required this.id,
    this.parentId,
    required this.name,
    required this.startTime,
    this.endTime,
    this.input,
    this.output,
    this.thread = 'main',
    List<String>? children,
  }) : children = children ?? [];

  int get durationMs => endTime != null
      ? endTime!.difference(startTime).inMilliseconds
      : DateTime.now().difference(startTime).inMilliseconds;
}
