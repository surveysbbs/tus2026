import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'listing_form_page.dart';

// ===== PARTIAL LIST PAGE =====
class PartialListPage extends StatefulWidget {
  const PartialListPage({super.key});
   @override
  State<PartialListPage> createState() => _PartialListPageState();
}

class _PartialListPageState extends State<PartialListPage> {
  
  // get Hive box
  Box get box => Hive.box('surveyBox');
  Map<String, List<Map<String, dynamic>>> groupedData = {};
  List<String> psuTabs = [];
  String selectedPsu = '';

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
        title: const Text("আংশিক সংগৃহীত তালিকা"),
        backgroundColor:
            Colors.brown.shade800, // আংশিক তালিকার সাথে মিল রেখে কালার
        foregroundColor: Colors.white,
      ),

      // listen to Hive changes (auto refresh UI)
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          final List<int> indexes = [];

          // collect only partial data (isPartial = true)
          for (int i = 0; i < b.length; i++) {
            final data = b.getAt(i);

            if (data != null && data['isPartial'] == true) {
              indexes.add(i);
            }
          }

          // if no partial data found
          if (indexes.isEmpty) {
            return const Center(child: Text("কোনো আংশিক সংরক্ষিত তথ্য নেই"));
          }

          // show list
          return ListView.builder(
            itemCount: indexes.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (_, k) {
              final int i = indexes[k];
              final data = b.getAt(i);

              return Card(
                elevation: 0,
                // হালকা ব্যাকগ্রাউন্ড কালার (Light Orange/Amber)
                color: Colors.orange.shade50,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.orange.shade100),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),

                  // PSU ও Serial নম্বর
                  title: Text(
                    "PSU: ${data['psu']} | Serial: ${data['serial']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // household head name
                  subtitle: Text(
                    data['head']?.toString().isEmpty ?? true
                        ? "নাম নেই (আংশিক)"
                        : data['head'],
                    style: TextStyle(color: Colors.grey.shade800),
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ===== EDIT BUTTON =====
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.brown),
                        tooltip: "Edit",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListingFormPage(
                                editData: data,
                                editIndex: i,
                                isViewOnly: false,
                              ),
                            ),
                          );
                        },
                      ),

                      // ===== VIEW BUTTON =====
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.green),
                        tooltip: "View",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListingFormPage(
                                editData: data,
                                editIndex: i,
                                isViewOnly: true,
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
