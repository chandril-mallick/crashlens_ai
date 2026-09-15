import 'package:flutter/foundation.dart';
import '../models/crash_report.dart';
import '../services/database_service.dart';

/// Manages the list of past crash reports from SQLite.
class HistoryProvider extends ChangeNotifier {
  final DatabaseService _db;

  HistoryProvider({DatabaseService? db}) : _db = db ?? DatabaseService();

  List<CrashReport> _reports = [];
  List<CrashReport> get reports => List.unmodifiable(_reports);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Load all reports from the database.
  Future<void> loadReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _db.getAllReports();
    } catch (e) {
      _error = 'Failed to load history: $e';
      debugPrint('HistoryProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a report by ID and refresh.
  Future<void> deleteReport(String id) async {
    try {
      await _db.deleteReport(id);
      _reports.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete report: $e';
      notifyListeners();
    }
  }

  /// Clear all history.
  Future<void> clearAll() async {
    try {
      await _db.clearAll();
      _reports = [];
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear history: $e';
      notifyListeners();
    }
  }
}
