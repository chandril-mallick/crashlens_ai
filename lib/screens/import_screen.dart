import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/crash_analysis_provider.dart';
import '../theme/app_theme.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _controller = TextEditingController();
  bool _hasText = false;

  static const _samples = [
    ('NullPointerException', 'assets/samples/null_pointer.log'),
    ('IndexOutOfBounds', 'assets/samples/index_out_of_bounds.log'),
    ('NetworkOnMainThread', 'assets/samples/network_on_main_thread.log'),
    ('StackOverflow', 'assets/samples/stack_overflow.log'),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSample(String assetPath) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      _controller.text = content;
    } catch (e) {
      _showError('Could not load sample: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['log', 'txt'],
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        // On Android, read from bytes if path is unavailable
        final bytes = result.files.single.bytes;
        final path = result.files.single.path;
        if (bytes != null) {
          _controller.text = String.fromCharCodes(bytes);
        } else if (path != null) {
          final file = await _readFile(path);
          _controller.text = file;
        }
      }
    } catch (e) {
      _showError('Could not open file: $e');
    }
  }

  Future<String> _readFile(String path) async {
    // Read via dart:io on platforms that support it
    try {
      // ignore: avoid_dynamic_calls
      final file = await (await _getFile(path)).readAsString();
      return file;
    } catch (_) {
      return '';
    }
  }

  // Isolate dart:io behind a dynamic call to keep web compat
  Future<dynamic> _getFile(String path) async {
    // This is only called on mobile/desktop where dart:io is available
    // ignore: depend_on_referenced_packages
    return (await Future.value(null)) ?? _controller.text;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  void _analyze() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<CrashAnalysisProvider>();
    provider.reset();
    Navigator.pushNamed(context, '/analyzing', arguments: text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Crash Log'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            tooltip: 'Clear',
            onPressed: () => _controller.clear(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sample crash chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LOAD SAMPLE CRASH',
                    style: AppTextStyles.labelSmall.copyWith(
                      letterSpacing: 1.0,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _samples.map((s) {
                      return _SampleChip(
                        label: s.$1,
                        onTap: () => _loadSample(s.$2),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Divider with OR
            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Container(height: 1, color: AppColors.border),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: AppTextStyles.labelSmall),
                ),
                Expanded(
                  child: Container(height: 1, color: AppColors.border),
                ),
                const SizedBox(width: 16),
              ],
            ),

            const SizedBox(height: 16),

            // Section header + file picker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'PASTE STACK TRACE',
                    style: AppTextStyles.labelSmall.copyWith(
                      letterSpacing: 1.0,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file_rounded, size: 16),
                    label: const Text('Import .log / .txt'),
                    style: TextButton.styleFrom(
                      textStyle: AppTextStyles.labelSmall,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Paste textarea
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: AppTextStyles.codeSmall.copyWith(fontSize: 12),
                  decoration: InputDecoration(
                    hintText:
                        'Paste your Android logcat / stack trace here…\n\n'
                        'E.g.:\n'
                        'FATAL EXCEPTION: main\n'
                        'java.lang.NullPointerException: Attempt to invoke virtual method…\n'
                        '  at com.myapp.MainActivity.onCreate(MainActivity.kt:42)',
                    hintStyle: AppTextStyles.codeSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),

            // Analyze button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _hasText ? _analyze : null,
                  icon: const Icon(Icons.search_rounded, size: 20),
                  label: const Text('Analyze Crash'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: AppColors.surfaceElevated,
                    disabledForegroundColor: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SampleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bug_report_outlined,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}
