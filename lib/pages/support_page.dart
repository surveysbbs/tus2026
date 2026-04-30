import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  final Map<String, List<Map<String, String>>> supportByDivision = const {
    "Barishal Division": [
      {
        "name": "MD. FAROQUE SOHEL",
        "role": "Senior Programmer",
        "phone": "01552422291",
      },
    ],
    "Chittagong Division": [
      {
        "name": "Sadek Hossain Khoka",
        "role": "Programmer",
        "phone": "01550041221",
      },
    ],
    "Dhaka Division": [
      {
        "name": "MOSAMMAT SAYEEDA BEGUM",
        "role": "Senior Programmer",
        "phone": "01552319752",
      },
    ],
    "Khulna Division": [
      {
        "name": "Md. Liakat Ali",
        "role": "Assistant Programmer",
        "phone": "01681688604",
      },
    ],
    "Mymensingh Division": [
      {
        "name": "MOSAMMAT SAYEEDA BEGUM",
        "role": "Senior Programmer",
        "phone": "01552319752",
      },
    ],
    "Rajshahi Division": [
      {
        "name": "MOSAMMAT SAYEEDA BEGUM",
        "role": "Senior Programmer",
        "phone": "01552319752",
      },
    ],
    "Rangpur Division": [
      {
        "name": "Proloy Kumar Goswami",
        "role": "Programmer",
        "phone": "01719254983",
      },
    ],
    "Sylhet Division": [
      {
        "name": "Md. Azizur Rahman",
        "role": "Assistant Programmer",
        "phone": "01713624094",
      },
    ],
  };

  Future<void> _callNumber(String phone) async {
    final Uri callUri = Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri, mode: LaunchMode.externalApplication);
    }
  }

  Widget divisionTile(String division, Map<String, String> officer) {
    return InkWell(
      onTap: () => _callNumber(officer["phone"]!),
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.indigo.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              division,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.indigo,
              ),
            ),
            const Divider(height: 10, thickness: 1),
            Text(
              officer["name"]!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              officer["role"]!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  officer["phone"]!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget divisionCard(String division, Map<String, String> officer) {
    return InkWell(
      onTap: () => _callNumber(officer["phone"]!),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                division,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Divider(),

              Text(
                officer["name"]!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              Text(officer["role"]!),

              const SizedBox(height: 5),

              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(officer["phone"]!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final divisions = supportByDivision.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("কারিগরি সহায়তা")),

      body: Column(
        children: [
          const SizedBox(height: 4),

          // ===== GRID VIEW (Responsive) =====
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: divisions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 column
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 3.0,
              ),
              itemBuilder: (context, index) {
                final division = divisions[index];
                final officer = supportByDivision[division]![0];

                return divisionCard(division, officer);
              },
            ),
          ),
        ],
      ),
    );
  }
}
