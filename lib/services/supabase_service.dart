import 'package:supabase/supabase.dart';
import '../config/app_config.dart';

class SupabaseService {
  final SupabaseClient supabase;

  SupabaseService({required String url, required String anonKey})
    : supabase = SupabaseClient(url, anonKey);

  // পুরানো ডাটা রিড করতে
  Future<List<dynamic>> getSurveys() async {
    final data = await supabase.from('surveys').select();
    return data;
  }
  // ===================================
  // Remove null fields before upload
  // যেগুলো overwrite হলে data loss হবে
  // ===================================

  void removeNullFields(Map<String, dynamic> row) {
    row.removeWhere((key, value) => value == null && key != 'remarks');
  }

  Future<bool> isVersionAllowed() async {
    final setting = await supabase
        .from('app_settings')
        .select()
        .eq('id', 1)
        .single();

    return setting['active_phase'] == AppConfig.surveyPhase;
  }

  // একক ডাটা insert/update
  Future<void> upsertSurvey(Map<String, dynamic> surveyData) async {
    if (!await isVersionAllowed()) {
      throw Exception("এই অ্যাপ ভার্সন বন্ধ করা হয়েছে");
    }

    removeNullFields(surveyData);

    await supabase.from('surveys').upsert(surveyData, onConflict: 'house_id');
  }

  // অনেকগুলো ডাটা একসাথে insert/update
  Future<void> bulkUpsert(List<Map<String, dynamic>> allData) async {
    if (!await isVersionAllowed()) {
      throw Exception("এই অ্যাপ ভার্সন বন্ধ করা হয়েছে");
    }

    if (allData.isEmpty) return;

    for (var row in allData) {
      removeNullFields(row);
    }

    await supabase.from('surveys').upsert(allData, onConflict: 'house_id');
  }

  //login er por data load
  Future<List<dynamic>> getUserData(String username) async {
    final data = await supabase
        .from('surveys')
        .select()
        .eq('username', username);

    return data;
  }

  Future<int> getLoginStatus(String username) async {
    final data = await supabase
        .from('enumerators')
        .select('login_status')
        .eq('username', username)
        .maybeSingle();

    return data?['login_status'] ?? 0;
  }
}
