import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/db_helper.dart';

class ExportImportService {
  static Future<bool> exportData() async {
    try {
      final data = await DBHelper.instance.exportAll();
      final json = const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getTemporaryDirectory();
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${dir.path}/habit_backup_$timestamp.json');
      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Habit Tracker Backup',
        text: 'Your habit tracker data backup',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<({bool success, String message})> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return (success: false, message: 'No file selected');
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (data['version'] == null ||
          data['habits'] == null ||
          data['logs'] == null) {
        return (success: false, message: 'Invalid backup file format');
      }

      await DBHelper.instance.importAll(data);
      return (success: true, message: 'Data imported successfully');
    } catch (e) {
      return (success: false, message: 'Import failed: $e');
    }
  }
}
