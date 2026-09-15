import '../models/analysis_result.dart';
import '../models/crash_report.dart';
import '../models/parsed_crash_context.dart';
import 'real_analysis_service.dart';

/// Abstract interface for the on-device LLM inference layer.
/// Implementations: [MockLLMInferenceService] (default), [GemmaInferenceService] (stub).
abstract class LLMInferenceService {
  /// Analyze the parsed crash context and return a structured [AnalysisResult].
  Future<AnalysisResult> analyze(ParsedCrashContext context);

  /// Human-readable name of this backend (shown in Settings).
  String get modelName;

  /// Approximate on-disk size of the model.
  String get modelSize;

  /// Whether this is a genuine on-device model (vs. mock / cloud).
  bool get isOnDevice;
}

// ---------------------------------------------------------------------------
// Mock Backend — realistic deterministic results, 100% on-device, zero network
// ---------------------------------------------------------------------------

class MockLLMInferenceService implements LLMInferenceService {
  @override
  String get modelName => 'CrashLens Mock Engine v1.0';
  @override
  String get modelSize => '< 1 MB';
  @override
  bool get isOnDevice => true;

  @override
  Future<AnalysisResult> analyze(ParsedCrashContext context) async {
    // Simulate realistic on-device inference time (2–3 s)
    await Future.delayed(const Duration(milliseconds: 2200));
    return _buildResult(context);
  }

  AnalysisResult _buildResult(ParsedCrashContext ctx) {
    final type = ctx.exceptionType.toLowerCase();

    if (type.contains('nullpointer') || type.contains('nullreference')) {
      return _nullPointerResult(ctx);
    } else if (type.contains('indexoutofbounds') || type.contains('arrayindex')) {
      return _indexOutOfBoundsResult(ctx);
    } else if (type.contains('networkonmainthread')) {
      return _networkOnMainThreadResult(ctx);
    } else if (type.contains('stackoverflow')) {
      return _stackOverflowResult(ctx);
    } else if (type.contains('classcast')) {
      return _classCastResult(ctx);
    } else if (type.contains('outofmemory')) {
      return _outOfMemoryResult(ctx);
    } else {
      return _genericResult(ctx);
    }
  }

  AnalysisResult _nullPointerResult(ParsedCrashContext ctx) {
    final file = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.fileName
        : 'MainActivity.kt';
    final method = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.methodName
        : 'onCreate';
    final line = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.lineNumber
        : 42;

    return AnalysisResult(
      rootCauseSummary:
          'Null dereference in $method() — object reference not initialized before use.',
      confidenceScore: 91,
      explanationText:
          'The crash occurs because your code is trying to access a method or property '
          'on an object that hasn\'t been initialized yet (it\'s null). '
          'In Android development, this commonly happens when:\n\n'
          '• A View is accessed before setContentView() is called\n'
          '• An Activity or Fragment reference is used after it\'s been destroyed\n'
          '• A variable is declared but never assigned before use\n\n'
          'The fix adds a null-check guard before accessing the object. '
          'Consider also using Kotlin\'s safe-call operator (?.) for more idiomatic null safety.',
      patch: [
        DiffLine(type: DiffLineType.context, content: 'fun $method() {'),
        DiffLine(type: DiffLineType.removed, content: '    val result = userRepository.getUser().name'),
        DiffLine(type: DiffLineType.added,   content: '    val result = userRepository.getUser()?.name ?: "Unknown"'),
        DiffLine(type: DiffLineType.context, content: '    updateUI(result)'),
        DiffLine(type: DiffLineType.context, content: '}'),
      ],
      sourceFileReference: '$file:$line',
      sourceSnippet:
          'fun $method() {\n'
          '    // Line $line — getUser() may return null\n'
          '    val result = userRepository.getUser().name\n'
          '    updateUI(result)\n'
          '}',
      implicatedLineNumber: line,
      analysisMode: AnalysisMode.onDevice,
    );
  }

  AnalysisResult _indexOutOfBoundsResult(ParsedCrashContext ctx) {
    final file = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.fileName
        : 'RecyclerAdapter.kt';
    final line = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.lineNumber
        : 88;

    return AnalysisResult(
      rootCauseSummary:
          'List index out of bounds — accessing element beyond list size.',
      confidenceScore: 87,
      explanationText:
          'Your code is trying to access a list item at an index that doesn\'t exist. '
          'This typically happens in RecyclerView adapters when the dataset changes '
          'but getItemCount() returns a stale value, or when directly indexing a list '
          'without a bounds check.\n\n'
          'The fix adds a bounds check before accessing the list. '
          'If you\'re modifying a list on a background thread, ensure you\'re using '
          'thread-safe operations and calling notifyDataSetChanged() on the main thread.',
      patch: [
        DiffLine(type: DiffLineType.context, content: 'override fun onBindViewHolder(holder: ViewHolder, position: Int) {'),
        DiffLine(type: DiffLineType.removed, content: '    val item = dataList[position]'),
        DiffLine(type: DiffLineType.added,   content: '    if (position >= dataList.size) return'),
        DiffLine(type: DiffLineType.added,   content: '    val item = dataList[position]'),
        DiffLine(type: DiffLineType.context, content: '    holder.bind(item)'),
        DiffLine(type: DiffLineType.context, content: '}'),
      ],
      sourceFileReference: '$file:$line',
      sourceSnippet:
          'override fun onBindViewHolder(holder: ViewHolder, position: Int) {\n'
          '    // Line $line — no bounds check\n'
          '    val item = dataList[position]\n'
          '    holder.bind(item)\n'
          '}',
      implicatedLineNumber: line,
      analysisMode: AnalysisMode.onDevice,
    );
  }

  AnalysisResult _networkOnMainThreadResult(ParsedCrashContext ctx) {
    final file = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.fileName
        : 'ApiClient.kt';
    final line = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.lineNumber
        : 55;

    return AnalysisResult(
      rootCauseSummary:
          'Network operation on main thread — Android blocks I/O on the UI thread.',
      confidenceScore: 95,
      explanationText:
          'Android\'s StrictMode prevents network calls from running on the main (UI) '
          'thread to keep the app responsive. Your code is making a synchronous HTTP '
          'request directly on the main thread.\n\n'
          'The fix wraps the network call in a coroutine with the IO dispatcher, '
          'which runs it on a background thread pool. Make sure you update the UI '
          'only from the main thread (use withContext(Dispatchers.Main) or LiveData).',
      patch: [
        DiffLine(type: DiffLineType.context, content: 'fun fetchData() {'),
        DiffLine(type: DiffLineType.removed, content: '    val response = apiService.getData()'),
        DiffLine(type: DiffLineType.removed, content: '    updateUI(response)'),
        DiffLine(type: DiffLineType.added,   content: '    viewModelScope.launch(Dispatchers.IO) {'),
        DiffLine(type: DiffLineType.added,   content: '        val response = apiService.getData()'),
        DiffLine(type: DiffLineType.added,   content: '        withContext(Dispatchers.Main) { updateUI(response) }'),
        DiffLine(type: DiffLineType.added,   content: '    }'),
        DiffLine(type: DiffLineType.context, content: '}'),
      ],
      sourceFileReference: '$file:$line',
      sourceSnippet:
          'fun fetchData() {\n'
          '    // Line $line — synchronous network call on main thread\n'
          '    val response = apiService.getData()\n'
          '    updateUI(response)\n'
          '}',
      implicatedLineNumber: line,
      analysisMode: AnalysisMode.onDevice,
    );
  }

  AnalysisResult _stackOverflowResult(ParsedCrashContext ctx) {
    final file = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.fileName
        : 'DataProcessor.kt';
    final line = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.lineNumber
        : 120;

    return AnalysisResult(
      rootCauseSummary:
          'Infinite recursion detected — function calls itself without a base case.',
      confidenceScore: 88,
      explanationText:
          'A StackOverflowError means a function is calling itself (directly or indirectly) '
          'without a termination condition, exhausting the call stack. '
          'Common causes:\n\n'
          '• Missing or incorrect base case in a recursive function\n'
          '• Circular object references during serialization\n'
          '• Accidental property getter calling itself\n\n'
          'The fix adds a proper base case to stop the recursion. '
          'For large datasets, consider converting the recursion to an iterative loop.',
      patch: [
        DiffLine(type: DiffLineType.context, content: 'fun processNode(node: Node): Int {'),
        DiffLine(type: DiffLineType.added,   content: '    if (node.children.isEmpty()) return node.value'),
        DiffLine(type: DiffLineType.context, content: '    return node.children.sumOf { processNode(it) }'),
        DiffLine(type: DiffLineType.context, content: '}'),
      ],
      sourceFileReference: '$file:$line',
      sourceSnippet:
          'fun processNode(node: Node): Int {\n'
          '    // Line $line — no base case, infinite recursion\n'
          '    return node.children.sumOf { processNode(it) }\n'
          '}',
      implicatedLineNumber: line,
      analysisMode: AnalysisMode.onDevice,
    );
  }

  AnalysisResult _classCastResult(ParsedCrashContext ctx) {
    final file = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.fileName
        : 'ViewHolder.kt';
    final line = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.lineNumber
        : 67;

    return AnalysisResult(
      rootCauseSummary:
          'Invalid type cast — object cannot be cast to the expected type.',
      confidenceScore: 82,
      explanationText:
          'A ClassCastException means you\'re trying to cast an object to a type '
          'it isn\'t actually an instance of at runtime. This often happens when:\n\n'
          '• Using unchecked casts from generic collections\n'
          '• Incorrect View binding (wrong view type in RecyclerView)\n'
          '• Deserializing data with mismatched types\n\n'
          'The fix uses a safe cast (as?) with a null check instead of a forced cast.',
      patch: [
        DiffLine(type: DiffLineType.context, content: 'val view = parent.inflate(R.layout.item)'),
        DiffLine(type: DiffLineType.removed, content: '    val button = view.findViewById(R.id.btn) as Button'),
        DiffLine(type: DiffLineType.added,   content: '    val button = view.findViewById<Button>(R.id.btn)'),
        DiffLine(type: DiffLineType.added,   content: '        ?: error("Button not found in layout")'),
      ],
      sourceFileReference: '$file:$line',
      sourceSnippet:
          'val view = parent.inflate(R.layout.item)\n'
          '// Line $line — forced cast may fail\n'
          'val button = view.findViewById(R.id.btn) as Button',
      implicatedLineNumber: line,
      analysisMode: AnalysisMode.onDevice,
    );
  }

  AnalysisResult _outOfMemoryResult(ParsedCrashContext ctx) {
    final file = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.fileName
        : 'ImageLoader.kt';
    final line = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.lineNumber
        : 34;

    return AnalysisResult(
      rootCauseSummary:
          'Out of memory — large bitmap loaded without sampling or caching.',
      confidenceScore: 79,
      explanationText:
          'Android devices have limited heap memory for apps. Loading full-resolution '
          'images directly into memory is a common OOM cause. '
          'The fix samples the image down to the required display size before decoding, '
          'dramatically reducing memory usage. For production, use Coil or Glide '
          'which handle this automatically.',
      patch: [
        DiffLine(type: DiffLineType.removed, content: '    val bitmap = BitmapFactory.decodeFile(path)'),
        DiffLine(type: DiffLineType.added,   content: '    val options = BitmapFactory.Options().apply {'),
        DiffLine(type: DiffLineType.added,   content: '        inJustDecodeBounds = true'),
        DiffLine(type: DiffLineType.added,   content: '        BitmapFactory.decodeFile(path, this)'),
        DiffLine(type: DiffLineType.added,   content: '        inSampleSize = calculateInSampleSize(this, reqWidth, reqHeight)'),
        DiffLine(type: DiffLineType.added,   content: '        inJustDecodeBounds = false'),
        DiffLine(type: DiffLineType.added,   content: '    }'),
        DiffLine(type: DiffLineType.added,   content: '    val bitmap = BitmapFactory.decodeFile(path, options)'),
      ],
      sourceFileReference: '$file:$line',
      sourceSnippet:
          '// Line $line — no sampling, full resolution loaded\n'
          'val bitmap = BitmapFactory.decodeFile(path)',
      implicatedLineNumber: line,
      analysisMode: AnalysisMode.onDevice,
    );
  }

  AnalysisResult _genericResult(ParsedCrashContext ctx) {
    final type = ctx.exceptionType;
    final file = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.fileName
        : 'Application.kt';
    final method = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.methodName
        : 'unknown';
    final line = ctx.topAppFrames.isNotEmpty
        ? ctx.topAppFrames.first.lineNumber
        : 1;

    return AnalysisResult(
      rootCauseSummary:
          '$type thrown in $method() — see stack frames for call chain.',
      confidenceScore: 64,
      explanationText:
          'This ${ctx.exceptionType} was thrown at $file:$line. '
          'Based on the stack trace, the error originates in your application code.\n\n'
          '${ctx.exceptionMessage.isNotEmpty ? 'Exception message: "${ctx.exceptionMessage}"\n\n' : ''}'
          'Suggested steps:\n'
          '• Add logging around the failing call to inspect runtime values\n'
          '• Verify any external inputs (user data, network responses) are validated\n'
          '• Check if the error is intermittent (race condition) or deterministic',
      patch: [
        DiffLine(type: DiffLineType.context, content: 'fun $method() {'),
        DiffLine(type: DiffLineType.added,   content: '    try {'),
        DiffLine(type: DiffLineType.context, content: '        // Your existing code here'),
        DiffLine(type: DiffLineType.added,   content: '    } catch (e: $type) {'),
        DiffLine(type: DiffLineType.added,   content: '        Log.e(TAG, "Caught $type in $method", e)'),
        DiffLine(type: DiffLineType.added,   content: '        // Handle error appropriately'),
        DiffLine(type: DiffLineType.added,   content: '    }'),
        DiffLine(type: DiffLineType.context, content: '}'),
      ],
      sourceFileReference: '$file:$line',
      sourceSnippet: '// $file — line $line\nfun $method() {\n    // Exception thrown here\n}',
      implicatedLineNumber: line,
      analysisMode: AnalysisMode.onDevice,
    );
  }
}

// ---------------------------------------------------------------------------
// Gemma Inference Service — Real on-device model execution
// ---------------------------------------------------------------------------

class GemmaInferenceService implements LLMInferenceService {
  final RealAnalysisService _realService = RealAnalysisService();

  @override
  String get modelName => 'Gemma 2B (GGUF, Q4_K_M)';
  @override
  String get modelSize => '~1.5 GB';
  @override
  bool get isOnDevice => true;

  @override
  Future<AnalysisResult> analyze(ParsedCrashContext context) async {
    return _realService.analyze(context);
  }
}
