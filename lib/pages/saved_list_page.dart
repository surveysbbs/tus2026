import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/supabase_service.dart'; // supabase সার্ভিস ইম্পোর্ট
import 'listing_form_page.dart';
import 'sync_page.dart'; // SyncPage ইম্পোর্ট
import 'package:tus_listing_app/config/supabase_config.dart';

class SavedListPage extends StatefulWidget {
  const SavedListPage({super.key});
  @override
  State<SavedListPage> createState() => _SavedListPageState();
}

class _SavedListPageState extends State<SavedListPage> {
  Map<String, List<Map<String, dynamic>>> groupedData = {};
  List<String> psuTabs = [];
  String selectedPsu = '';

  // সিলেকশন ট্র্যাক করার জন্য সেট
  final Set<int> selectedIndexes = {};

  Box get box => Hive.box('surveyBox');

  // ===== SyncPage-এ পাঠানোর ফাংশন =====
  void goToSyncPage() {
    if (selectedIndexes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("প্রথমে তালিকা থেকে তথ্য সিলেক্ট করুন")),
      );
      return;
    }

    debugPrint("SELECTED INDEXES = $selectedIndexes");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SyncPage(
          supabaseService: SupabaseService(
            url: supabaseUrl,
            anonKey: supabaseKey,
          ),
          selectedIndexes: selectedIndexes.toList(),
        ),
      ),
    ).then((_) {
      // সিঙ্ক শেষ করে ফিরে আসলে সিলেকশন ক্লিয়ার করে দেওয়া
      setState(() {
        selectedIndexes.clear();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    loadGroupedData();
  }

  void loadGroupedData() {
    final rawItems = box.values.toList().asMap().entries.map((e) {
      final data = Map<String, dynamic>.from(e.value as Map);
      data['_index'] = e.key;
      return data;
    }).toList();

    groupedData.clear();

    for (final item in rawItems) {
      final psu = item['psu']?.toString() ?? 'Unknown';

      groupedData.putIfAbsent(psu, () => []);
      groupedData[psu]!.add(item);
    }

    // latest first
    for (final psu in groupedData.keys) {
      groupedData[psu]!.sort((a, b) {
        final aIndex = a['_index'] ?? 0;
        final bIndex = b['_index'] ?? 0;

        return bIndex.compareTo(aIndex);
      });
    }

    psuTabs = groupedData.keys.toList();

    // latest PSU first
    psuTabs.sort((a, b) {
      final aLatest = groupedData[a]!.first['_index'] ?? 0;
      final bLatest = groupedData[b]!.first['_index'] ?? 0;

      return bLatest.compareTo(aLatest);
    });

    if (psuTabs.isNotEmpty) {
      selectedPsu = psuTabs.first;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("সংগৃহীত তালিকা"),
        actions: [
          // উপরে ডানদিকের বাটন
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              onPressed: goToSyncPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              icon: const Icon(Icons.cloud_upload, size: 18),
              label: const Text("সার্ভারে প্রেরণ"),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          final List<int> indexes = [];

          for (int i = 0; i < b.length; i++) {
            final d = b.getAt(i);
            if (d != null && d['isPartial'] == false) {
              indexes.add(i);
            }
          }

          if (indexes.isEmpty) {
            return const Center(child: Text("কোনো তথ্য সংরক্ষিত নেই"));
          }

          return ListView.builder(
            itemCount: indexes.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (_, k) {
              final i = indexes[k];
              final d = b.getAt(i);
              final bool isSelected = selectedIndexes.contains(i);
              final bool alreadyInServer = d['fromServer'] ?? false;

              return Card(
                elevation: 0,
                color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  // বাম পাশে চেক বক্স (যদি অলরেডি সার্ভারে না থাকে)
                  leading: alreadyInServer
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : Checkbox(
                          value: isSelected,
                          activeColor: Colors.blue,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedIndexes.add(i);
                              } else {
                                selectedIndexes.remove(i);
                              }
                            });
                          },
                        ),
                  title: Text(
                    "PSU: ${d['psu']} | Serial: ${d['serial']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text("Head: ${d['head'] ?? ''}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ===== সার্ভার আইকন এখানে যোগ করা হলো =====
                      Icon(
                        alreadyInServer ? Icons.cloud_done : Icons.cloud_off,
                        color: alreadyInServer ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8), // আইকনগুলোর মাঝে গ্যাপ

                      IconButton(
                        icon: const Icon(
                          Icons.visibility,
                          color: Colors.teal,
                          size: 22,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListingFormPage(
                                editData: d,
                                editIndex: i,
                                isViewOnly: true,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 22,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListingFormPage(
                                editData: d,
                                editIndex: i,
                                isViewOnly: false,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
