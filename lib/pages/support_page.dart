import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'login_page.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  final Map<String, List<Map<String, String>>> supportByDivision = const {
    "Barishal": [
      {
        "name": "MD. FAROQUE SOHEL",
        "role": "Senior Programmer",
        "phone": "01552422291",
      },
    ],
    "Chittagong": [
      {
        "name": "Sadek Hossain Khoka",
        "role": "Programmer",
        "phone": "01550041221",
      },
    ],
    "Dhaka": [
      {
        "name": "Jatan Kumar Saha",
        "role": "System Analyst",
        "phone": "017xxxxxxx",
      },
    ],
    "Khulna": [
      {
        "name": "S M Ahsan Kabir",
        "role": "System Analyst",
        "phone": "017xxxxxxx",
      },
    ],
    "Mymensingh": [
      {
        "name": "Mosammat Sayeeda Begum",
        "role": "Senior Programmer",
        "phone": "017xxxxxxx",
      },
    ],
    "Rajshahi": [
      {"name": "Tarana Nasrin", "role": "Programmer", "phone": "01552319752"},
    ],
    "Rangpur": [
      {
        "name": "Proloy Kumar Goswami",
        "role": "Programmer",
        "phone": "01719254983",
      },
    ],
    "Sylhet": [
      {
        "name": "Md. Azizur Rahman",
        "role": "Assistant Programmer",
        "phone": "01713624094",
      },
    ],
  };

  // ===== CALL FUNCTION =====
  Future<void> _callNumber(String phone) async {
    final Uri callUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  // ===== SINGLE CARD =====
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
          const SizedBox(height: 8),

          // ===== GRID VIEW (Responsive) =====
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: divisions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 column
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3.7,
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
