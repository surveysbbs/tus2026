import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  final Map<String, List<Map<String, String>>> supportByDivision = const {

    "Rajshahi Division": [
      {
        "name": "Mosammat Sayeeda Begum",
        "role": "Senior Programmer",
        "phone": "01552319752",
      },
    ],

    "Rangpur Division": [
      {
        "name": "Md. Faroque Sohel",
        "role": "Senior Programmer",
        "phone": "01552422291",
      },
    ],

    "Chittagong Division": [
      {
        "name": "Md. Meraz Ali",
        "role": "Assistant Programmer",
        "phone": "01744507892",
      },
    ],

    "Khulna Division": [
      {
        "name": "Md. Aminul Islam",
        "role": "Assistant Programmer",
        "phone": "01521205479",
      },
    ],

    "Dhaka Division": [
      {
        "name": "Md. Faisal Ahmed",
        "role": "Cartographer",
        "phone": "01793590705",
      },
    ],

    "Sylhet Division": [
      {
        "name": "Md. Azizur Rahman",
        "role": "Assistant Programmer",
        "phone": "01713624094",
      },
    ],

    "Mymensingh Division": [
      {
        "name": "Mahmud Al Hasan",
        "role": "Statistical Officer",
        "phone": "01764646846",
      },
    ],

    "Barishal Division": [
      {
        "name": "Sudipta Datta",
        "role": "Statistical Officer",
        "phone": "01626316714",
      },
    ],
  };

  // ================= CALL FUNCTION =================

  Future<void> _callNumber(String phone) async {

    final Uri callUri = Uri(
      scheme: 'tel',
      path: phone,
    );

    if (await canLaunchUrl(callUri)) {

      await launchUrl(
        callUri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ================= CARD =================

  Widget divisionCard(
    String division,
    Map<String, String> officer,
  ) {

    return InkWell(

      borderRadius: BorderRadius.circular(10),

      onTap: () => _callNumber(officer["phone"]!),

      child: Card(

        elevation: 2,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),

        child: Padding(

          padding: const EdgeInsets.all(8),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              // ================= DIVISION =================

              Text(

                division,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),

              const Divider(height: 10),

              // ================= NAME =================

              Text(

                officer["name"]!,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              // ================= ROLE =================

              Text(

                officer["role"]!,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black87,
                ),
              ),

              const Spacer(),

              // ================= PHONE =================

              Row(

                children: [

                  const Icon(
                    Icons.phone,
                    size: 12,
                    color: Colors.green,
                  ),

                  const SizedBox(width: 4),

                  Expanded(

                    child: Text(

                      officer["phone"]!,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 11,
                      ),
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

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {

    final divisions = supportByDivision.keys.toList();

    return Scaffold(

      appBar: AppBar(
        title: const Text("কারিগরি সহায়তা"),
        centerTitle: true,
      ),

      body: Padding(

        padding: const EdgeInsets.all(6),

        child: GridView.builder(

          physics: const NeverScrollableScrollPhysics(),

          itemCount: divisions.length,

          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(

            // 2 Columns
            crossAxisCount: 2,

            // Space
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,

            // Compact Height
            childAspectRatio: 2.7,
          ),

          itemBuilder: (context, index) {

            final division = divisions[index];

            final officer =
                supportByDivision[division]![0];

            return divisionCard(
              division,
              officer,
            );
          },
        ),
      ),
    );
  }
}