import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  // Define instruction items with type
  final List<Map<String, dynamic>> instructions = const [
    {
      'text': "Ensure your device has a stable internet connection.",
      'type': 'info',
    },
    {
      'text': "Do not close the app while syncing data to the server.",
      'type': 'warning',
    },
    {
      'text':
          "Fully filled surveys will be sent to the server; partial surveys remain on the device.",
      'type': 'info',
    },
    {'text': "If sync fails, try again after some time.", 'type': 'warning'},
    {
      'text': "Contact support if you encounter repeated server errors.",
      'type': 'tip',
    },
    {
      'text': "For any UI issues, restart the app and try again.",
      'type': 'tip',
    },
    {
      'text': "Keep the app updated to the latest version for new features.",
      'type': 'info',
    },
  ];

  // Map type to icon and color
  IconData _getIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning;
      case 'tip':
        return Icons.lightbulb;
      case 'info':
      default:
        return Icons.info;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.red.shade400;
      case 'tip':
        return Colors.orange.shade400;
      case 'info':
      default:
        return Colors.blue.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("নির্দেশিকা")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: instructions.length,
          itemBuilder: (context, index) {
            var item = instructions[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _getIcon(item['type']),
                      color: _getColor(item['type']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['text'],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
