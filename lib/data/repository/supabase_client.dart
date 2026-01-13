import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pmv_report.dart';

class SupabaseClient {
  // Get the pre-initialized Supabase client
  final _supabase = Supabase.instance.client;

  // Save a new PMV report to the database
  Future<void> insertReport(PmvReport report) async {
    await _supabase.from('pmv_reports').insert(report.toMap());
  }

  // Stream live reports from the database (for real-time map updates)
  Stream<List<PmvReport>> getLiveReports() {
    return _supabase
        .from('pmv_reports')
        .stream(primaryKey: ['id'])
        .order('reported_at', ascending: false)
        .map((maps) => maps.map((map) => PmvReport.fromMap(map)).toList());
  }

  // (Optional) Clean up old reports that have expired
  Future<void> deleteExpiredReports() async {
    await _supabase
        .from('pmv_reports')
        .delete()
        .lt('expires_at', DateTime.now().toUtc().toIso8601String());
  }
}
