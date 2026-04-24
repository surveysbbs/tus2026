import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/supabase_service.dart';
//import 'package:tus_listing_app/config/supabase_config.dart';

class SyncPage extends StatefulWidget {
  final SupabaseService supabaseService;
  final List<int>? selectedIndexes;

  const SyncPage({
    super.key,
    required this.supabaseService,
    this.selectedIndexes,
  });

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final box = Hive.box('surveyBox');

  bool syncing = false;
  int total = 0;
  int success = 0;
  int fail = 0;
  bool isSuccess = false;

  @override
  void initState() {
    super.initState();
    syncAll();
  }

  Future<void> syncAll() async {
    if (!mounted) return;
    setState(() => syncing = true);

    final List<Map<String, dynamic>> unsynced = [];
    final List<int> syncingIndexes = [];

    final bool selectedMode =
        widget.selectedIndexes != null && widget.selectedIndexes!.isNotEmpty;

    debugPrint("SYNC PAGE RECEIVED INDEXES = ${widget.selectedIndexes}");

    if (selectedMode) {
      for (final i in widget.selectedIndexes!) {
        final raw = box.getAt(i);

        if (raw is Map) {
          final bool fromServer = raw['fromServer'] == true;

          if (!fromServer) {
            unsynced.add(Map<String, dynamic>.from(raw));
            syncingIndexes.add(i);
          }
        }
      }
    } else {
      for (int i = 0; i < box.length; i++) {
        final raw = box.getAt(i);

        if (raw is Map) {
          final bool fromServer = raw['fromServer'] == true;

          if (!fromServer) {
            unsynced.add(Map<String, dynamic>.from(raw));
            syncingIndexes.add(i);
          }
        }
      }
    }

    debugPrint("UPLOAD COUNT = ${unsynced.length}");
    debugPrint("SYNCING INDEXES = $syncingIndexes");

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

      for (final i in syncingIndexes) {
        final raw = box.getAt(i);

        if (raw is Map) {
          final updated = Map<String, dynamic>.from(raw);
          updated['fromServer'] = true;
          await box.putAt(i, updated);
        }
      }

      success = total;
      isSuccess = true;
    } catch (err) {
      fail = total;
      isSuccess = false;
      debugPrint("Bulk Sync failed: $err");
    }

    if (!mounted) return;
    setState(() => syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      success > 0
          ? "সব তথ্য সফলভাবে সার্ভারে পাঠানো হয়েছে"
          : "তথ্য পাঠানো সম্ভব হয়নি, আবার চেষ্টা করুন।",
    ),
    duration: const Duration(seconds: 2),
  ),
);

if (success > 0) {
  await Future.delayed(const Duration(seconds: 2));

  if (mounted) {
    Navigator.pop(context);
  }
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
            : Text(
                isSuccess
                    ? "সার্ভারে সফলভাবে পাঠানো হয়েছে"
                    : "সার্ভারে পাঠানো যায়নি, আবার চেষ্টা করুন",
              ),
      ),
    );
  }
}
