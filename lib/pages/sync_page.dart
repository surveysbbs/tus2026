import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/supabase_service.dart';
//import 'package:tus_listing_app/config/supabase_config.dart';

class SyncPage extends StatefulWidget {
  final SupabaseService supabaseService;

  const SyncPage({super.key, required this.supabaseService});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final box = Hive.box('surveyBox');

  bool syncing = false;
  int total = 0;
  int success = 0;
  int fail = 0;

  @override
  void initState() {
    super.initState();
    syncAll();
  }

  Future<void> syncAll() async {
    if (!mounted) return;
    setState(() => syncing = true);

    final List<Map<String, dynamic>> unsynced = box.values
        .where((e) {
          final data = e as Map;
          return (data['fromServer'] == false || data['fromServer'] == null);
        })
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    total = unsynced.length;
    success = 0;
    fail = 0;

    if (total == 0) {
      if (!mounted) return;
      setState(() => syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("সার্ভারে পাঠানোর মতো নতুন তথ্য নেই")),
      );
      return;
    }

    try {
      final List<Map<String, dynamic>> uploadData = unsynced.map((e) {
        return {
          'username': e['username'],
          'house_id': e['house_id'] ?? "${e['psu']}_${e['serial']}",
          'serial': e['serial'] ?? '',
          'psu': e['psu'] ?? '',
          'division': e['division'],
          'district': e['district'],
          'ctn': e['ctn'],
          'upazila': e['upazila'],
          'psn': e['psn'],
          'union_name': e['union_name'],
          'mouza': e['mouza'],
          'village': e['village'],
          'division_code': e['division_code'],
          'district_code': e['district_code'],
          'ctc': e['ctc'],
          'upazila_code': e['upazila_code'],
          'psc': e['psc'],
          'union_code': e['union_code'],
          'mouza_code': e['mouza_code'],
          'village_code': e['village_code'],
          'rmo_tus': e['rmo_tus'],
          'rmo_phc': e['rmo_phc'],
          'ea_code': e['ea_code'],
          'head': e['head'] ?? '',
          'mother': e['mother'] ?? '',
          'father': e['father'] ?? '',
          'address': e['address'] ?? '',
          'mobile': e['mobile'] ?? '',
          'profession': e['profession'] ?? '',
          'total_member': e['totalMember'],
          'female': e['female'],
          'male': e['male'],
          'comment': e['comment'] ?? '',
          'is_partial': e['isPartial'] ?? false,
          'latitude': e['latitude'],
          'longitude': e['longitude'],
          'data_status': e['data_status'],
          'updated_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      await widget.supabaseService.bulkUpsert(uploadData);

      for (int i = 0; i < box.length; i++) {
        final raw = box.getAt(i);
        if (raw is Map) {
          final updated = Map<String, dynamic>.from(raw);
          final shouldSync =
              (updated['fromServer'] == false || updated['fromServer'] == null);

          if (shouldSync) {
            updated['fromServer'] = true;
            await box.putAt(i, updated);
          }
        }
      }

      success = total;
    } catch (err) {
      fail = total;
      debugPrint("Bulk Sync failed: $err");
    }

    if (!mounted) return;
    setState(() => syncing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success > 0
              ? "সব তথ্য সফলভাবে সার্ভারে পাঠানো হয়েছে"
              : "তথ্য পাঠানো সম্ভব হয়নি, ইন্টারনেট চেক করুন।",
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    if (success > 0) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("সার্ভারে পাঠানো হচ্ছে...")),
      body: Center(
        child: syncing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text("প্রেরিত হচ্ছে..."),
                ],
              )
            : Text("সার্ভারে পাঠানো হয়েছে"),
      ),
    );
  }
}
