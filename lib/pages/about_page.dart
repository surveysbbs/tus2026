import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  final Map<String, dynamic> developerTeam = const {
    "Director": {"Kabir Uddin Ahmed, 01711022636": {}},
    "System Analyst": {
      "Jatan Kumar Saha, 01711461891": {},
      "S. M. Ahasan Kabir, 01552323492": {},
    },
    "Maintenance Engineer": {"Mohammad Anamul Haque, 01552408806": {}},
    "Programmer": {
      "Tarana Nasrin, 01915796209": {},
      "Proloy Kumar Goswami, 01719254983": {},
    },
    "Assistant Programmer": {
      "Md. Aminul Islam, 01521205479": {},
      "Md. Meraz Ali, 01744507892": {},
    },
  };

  Widget buildRoleIcon(String role) {
    IconData icon;
    Color color;

    if (role.contains("Director")) {
      icon = Icons.workspace_premium;
      color = Colors.deepPurple;
    } else if (role.contains("System Analyst")) {
      icon = Icons.query_stats;
      color = Colors.blue;
    } else if (role.contains("Maintenance")) {
      icon = Icons.handyman;
      color = Colors.teal;
    } else if (role.contains("Programmer") && !role.contains("Assistant")) {
      icon = Icons.laptop_mac;
      color = Colors.indigo;
    } else if (role.contains("Assistant Programmer")) {
      icon = Icons.engineering;
      color = Colors.orange;
    } else {
      icon = Icons.person;
      color = Colors.grey;
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, size: 16, color: color),
    );
  }

  List<Map<String, String>> flattenTree(Map<String, dynamic> node) {
    final result = <Map<String, String>>[];

    node.forEach((role, members) {
      result.add({"type": "role", "text": role});

      if (members is Map<String, dynamic>) {
        members.forEach((name, _) {
          result.add({"type": "member", "role": role, "text": name});
        });
      }
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final list = flattenTree(developerTeam);

    return Scaffold(
      appBar: AppBar(title: const Text("About Us")),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "👨‍💻 Computer Wing - Software Development Team",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),

                const SizedBox(height: 6),
                const Divider(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final item = list[i];

                      /// 🔹 ROLE TITLE
                      if (item["type"] == "role") {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              buildRoleIcon(item["text"]!),
                              const SizedBox(width: 8),
                              Text(
                                item["text"]!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      /// 🔹 MEMBER
                      return Padding(
                        padding: const EdgeInsets.only(left: 36, bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item["text"]!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
