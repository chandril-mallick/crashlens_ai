import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/crash_report.dart';
import '../models/parsed_crash_context.dart';
import '../services/database_service.dart';
import '../services/llm_inference_service.dart';
import '../services/stack_trace_parser.dart';

enum AnalysisStep {
  idle,
  parsing,
  locatingContext,
  runningModel,
  rankingFixes,
  complete,
  error,
}

extension AnalysisStepLabel on AnalysisStep {
  String get label => switch (this) {
        AnalysisStep.idle => 'Ready',
        AnalysisStep.parsing => 'Parsing stack trace…',
        AnalysisStep.locatingContext => 'Locating source context…',
        AnalysisStep.runningModel => 'Running on-device model…',
        AnalysisStep.rankingFixes => 'Ranking fixes…',
        AnalysisStep.complete => 'Analysis complete',
        AnalysisStep.error => 'Analysis failed',
      };

  int get stepIndex => switch (this) {
        AnalysisStep.parsing => 0,
        AnalysisStep.locatingContext => 1,
        AnalysisStep.runningModel => 2,
        AnalysisStep.rankingFixes => 3,
        _ => -1,
      };
}

/// Orchestrates the full crash analysis pipeline:
/// parse → locate context → LLM inference → rank → persist.
class CrashAnalysisProvider extends ChangeNotifier {
  final DatabaseService _db;
  final LLMInferenceService _llm;
  final _uuid = const Uuid();

  CrashAnalysisProvider({
    DatabaseService? db,
    LLMInferenceService? llm,
  })  : _db = db ?? DatabaseService(),
        _llm = llm ?? MockLLMInferenceService();

  AnalysisStep _currentStep = AnalysisStep.idle;
  AnalysisStep get currentStep => _currentStep;

  CrashReport? _lastReport;
  CrashReport? get lastReport => _lastReport;

  ParsedCrashContext? _parsedContext;
  ParsedCrashContext? get parsedContext => _parsedContext;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAnalyzing => _currentStep != AnalysisStep.idle &&
      _currentStep != AnalysisStep.complete &&
      _currentStep != AnalysisStep.error;

  /// Run the full analysis pipeline for [rawTrace].
  Future<void> analyze(String rawTrace, {LLMInferenceService? customLlm}) async {
    _errorMessage = null;
    _lastReport = null;
    _parsedContext = null;

    final engine = customLlm ?? _llm;

    try {
      // Step 1 — Parse
      _setStep(AnalysisStep.parsing);
      await Future.delayed(const Duration(milliseconds: 600));
      final context = StackTraceParser.parse(rawTrace);
      _parsedContext = context;

      // Step 2 — Locate context
      _setStep(AnalysisStep.locatingContext);
      await Future.delayed(const Duration(milliseconds: 700));

      // Step 3 — Real LLM inference
      _setStep(AnalysisStep.runningModel);
      final result = await engine.analyze(context);

      // Step 4 — Rank / finalize
      _setStep(AnalysisStep.rankingFixes);
      await Future.delayed(const Duration(milliseconds: 500));

      // Persist to SQLite
      final report = CrashReport(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        exceptionType: context.exceptionType,
        stackTraceRaw: rawTrace,
        rootCauseSummary: result.rootCauseSummary,
        confidenceScore: result.confidenceScore,
        suggestedPatch: result.patchText,
        explanationText: result.explanationText,
        sourceFileReference: result.sourceFileReference,
        analysisMode: result.analysisMode,
      );
      await _db.insertCrashReport(report);
      _lastReport = report;

      _setStep(AnalysisStep.complete);
    } catch (e, st) {
      _errorMessage = 'Analysis failed: $e';
      debugPrint('CrashAnalysisProvider error: $e\n$st');
      _setStep(AnalysisStep.error);
    }
  }

  /// Reset to idle state (used when navigating back to Import).
  void reset() {
    _currentStep = AnalysisStep.idle;
    _lastReport = null;
    _parsedContext = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setStep(AnalysisStep step) {
    _currentStep = step;
    notifyListeners();
  }
}
