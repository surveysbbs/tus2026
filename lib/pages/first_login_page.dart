import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import 'dashboard_page.dart';

class FirstLoginPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const FirstLoginPage({super.key, required this.userData});

  @override
  State<FirstLoginPage> createState() => _FirstLoginPageState();
}

class _FirstLoginPageState extends State<FirstLoginPage> {
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;

  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> saveInfo() async {
    if (nameController.text.trim().isEmpty ||
        mobileController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("সব তথ্য দিন")));
      return;
    }

    setState(() => loading = true);

    try {
      await Supabase.instance.client
          .from('enumerators')
          .update({
            'name': nameController.text.trim(),
            'mobile': mobileController.text.trim(),
            'password_hash': hashPassword(passwordController.text.trim()),
            'first_login': false,
            'login_status': 0,
            'force_password_reset': false,
          })
          .eq('username', widget.userData['username']);

      final metaBox = Hive.box('metaBox');

      await metaBox.put('is_logged_in', true);
      await metaBox.put('user_id', widget.userData['id']);
      await metaBox.put('username', widget.userData['username']);
      await metaBox.put('name', nameController.text.trim());
      await metaBox.put('mobile', mobileController.text.trim());
      await metaBox.put('psu', widget.userData['psu']);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DashboardPage(user: Map<String, dynamic>.from(widget.userData)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("পাসওয়ার্ড মিলছে না")));

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("প্রথম লগইন")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "নাম"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "মোবাইল নম্বর"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "নতুন পাসওয়ার্ড"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "পাসওয়ার্ড নিশ্চিত করুন",
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : saveInfo,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("সংরক্ষণ করুন"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
