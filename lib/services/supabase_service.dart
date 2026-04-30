import 'package:supabase/supabase.dart';
//import 'package:tus_listing_app/config/supabase_config.dart';

class SupabaseService {
  final SupabaseClient supabase;

  SupabaseService({required String url, required String anonKey})
    : supabase = SupabaseClient(url, anonKey);

  // পুরানো ডাটা রিড করতে
  Future<List<dynamic>> getSurveys() async {
    final data = await supabase.from('surveys').select();
    return data;
  }

  // একক ডাটা insert/update
  Future<void> upsertSurvey(Map<String, dynamic> surveyData) async {
    await supabase.from('surveys').upsert(surveyData, onConflict: 'house_id');
  }

  // অনেকগুলো ডাটা একসাথে insert/update
  Future<void> bulkUpsert(List<Map<String, dynamic>> allData) async {
    if (allData.isEmpty) return;

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
