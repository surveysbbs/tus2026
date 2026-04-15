import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  final Map<String, dynamic> developerTeam = const {
    "Director": {
      "Kabir Uddin Ahmed, 01711": {},
    },
    "System Analyst": {
      "JATAN KUMAR SAHA, 0171": {},
      "S. M AHASAN KABIR, 015": {},
    },
    "Maintenance Engineer": {
      "Mohammad Anamul Haque, 01552408806": {},
    },
    "Programmer": {
      "Tarana Nasrin, 01915796209": {},
      "Proloy Kumar Goswami, 01719254983": {},
    },
    "Assistant Programmer": {
      "Aminul, 0909": {},
      "Meraj, 0786": {},
    },
  };

  final Map<String, dynamic> projectTeam = const {
    "Project Director": {
      "Asma, 019": {},
    },
    "Deputy Director": {
      "Aminul, 0909": {},
      "Meraj, 0786": {},
    },
    "Statistical Officer": {
      "Aminul, 0909": {},
      "Meraj, 0786": {},
    },
    "Database Specialist": {},
  };

  List<String> flattenTree(Map<String, dynamic> node, [String prefix = ""]) {
    final result = <String>[];

    node.forEach((key, value) {
      result.add("$prefix$key");
      if (value is Map<String, dynamic> && value.isNotEmpty) {
        result.addAll(flattenTree(value, "$prefix  └─ "));
      }
    });

    return result;
  }

  Widget buildTeamColumn(String title, Map<String, dynamic> team) {
    final list = flattenTree(team);

    return Expanded(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(list[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About Us")),
      body: Row(
        children: [
          buildTeamColumn("👨‍💻 Software Development Team", developerTeam),
          buildTeamColumn("📊 Project Team", projectTeam),
        ],
      ),
    );
  }
}