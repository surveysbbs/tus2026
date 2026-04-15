import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login_page.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  final Map<String, List<Map<String, String>>> supportByDivision = const {
    "Barishal Division": [
      {
        "name": "MD. FAROQUE SOHEL",
        "role": "Senior Programmer",
        "phone": "01552422291"
      },
    ],
    "Chittagong Division": [
      {
        "name": "Sadek Hossain Khoka",
        "role": "Programmer",
        "phone": "01550041221"
      },
    ],
    "Dhaka Division": [
      {"name": "Rahim Y Uddin", "role": "Senior Programmer", "phone": "017xxxxxxx"},
    ],
    "Khulna Division": [
      {"name": "Rahim B Uddin", "role": "Division ICT Officer", "phone": "017xxxxxxx"},
    ],
    "Mymensingh Division": [
      {"name": "Rahim C Uddin", "role": "Division ICT Officer", "phone": "017xxxxxxx"},
    ],
    "Rajshahi Division": [
      {
        "name": "MOSAMMAT SAYEEDA BEGUM",
        "role": "Senior Programmer",
        "phone": "01552319752"
      },
    ],
    "Rangpur Division": [
      {"name": "Proloy Kumar Goswami", "role": "Programmer", "phone": "01719254983"},
    ],
    "Sylhet Division": [
      {"name": "Md. Azizur Rahman", "role": "Assistant Programmer", "phone": "01713624094"},
    ],
  };

  Future<void> _callNumber(String phone) async {
    final Uri callUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  Widget divisionTile(String division, Map<String, String> officer) {
    return Expanded(
      child: InkWell(
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final divisions = supportByDivision.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Help & Support")),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    divisionTile(divisions[0], supportByDivision[divisions[0]]![0]),
                    divisionTile(divisions[1], supportByDivision[divisions[1]]![0]),
                  ],
                ),
                Row(
                  children: [
                    divisionTile(divisions[2], supportByDivision[divisions[2]]![0]),
                    divisionTile(divisions[3], supportByDivision[divisions[3]]![0]),
                  ],
                ),
                Row(
                  children: [
                    divisionTile(divisions[4], supportByDivision[divisions[4]]![0]),
                    divisionTile(divisions[5], supportByDivision[divisions[5]]![0]),
                  ],
                ),
                Row(
                  children: [
                    divisionTile(divisions[6], supportByDivision[divisions[6]]![0]),
                    divisionTile(divisions[7], supportByDivision[divisions[7]]![0]),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}