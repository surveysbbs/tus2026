import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController captchaController = TextEditingController();

  bool obscurePassword = true;

  bool isLoading = false;
  String captchaCode = "";

  @override
  void initState() {
    super.initState();
    generateCaptcha();
  }

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    captchaController.dispose();
    super.dispose();
  }

  void generateCaptcha() {
    const chars =
        "ABCDEFGHJKLMNPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz";
    final rnd = Random();
    captchaCode = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
    setState(() {});
  }

  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> login() async {
    if (userController.text.trim().isEmpty ||
        passController.text.trim().isEmpty ||
        captchaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("সব ঘর পূরণ করতে হবে")));
      return;
    }

    if (captchaController.text.trim() != captchaCode) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ক্যাপচা ভুল দেয়া হয়েছে")));
      generateCaptcha();
      captchaController.clear();
      return;
    }

    setState(() => isLoading = true);

    try {
      final hashedPassword = hashPassword(passController.text.trim());
      final userData = await Supabase.instance.client
          .from('enumerators')
          .select()
          .eq('username', userController.text.trim())
          .eq('password_hash', hashedPassword)
          .maybeSingle();

      if (!mounted) return;

      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ভুল ইউজারনেম বা পাসওয়ার্ড")),
        );
        generateCaptcha();
        captchaController.clear();
        return;
      }

      if ((userData['login_status'] ?? 0) == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("এই ব্যবহারকারী ইতোমধ্যে লগইন করেছেন")),
        );
        generateCaptcha(); // add
        captchaController.clear(); // add
        return;
      }

      await Supabase.instance.client
          .from('enumerators')
          .update({'login_status': 1})
          .eq('id', userData['id']);

      final metaBox = Hive.box('metaBox');
      await metaBox.put('user_id', userData['id']);
      await metaBox.put('username', userData['username']);
      await metaBox.put('name', userData['name']);
      await metaBox.put('mobile', userData['mobile']);
      await metaBox.put('psu', userData['psu']);
      await metaBox.put('is_logged_in', true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      if (!mounted) return;

      // debug console এ full error
      debugPrint("Login error: $e");

      // user কে clean message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("লগইন করতে সমস্যা হয়েছে, আবার চেষ্টা করুন"),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              Center(
                child: Image.asset(
                  'flutter_assets/logo.jpeg',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "টাইম ইউজ সার্ভে (TUS) ২০২৬",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                "লিস্টিং অপারেশন",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const Text(
                "ব্যবহারকারী লগইন",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: userController,
                decoration: const InputDecoration(
                  labelText: "লগইন আইডি",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: passController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: "পাসওয়ার্ড",
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      captchaCode,
                      style: const TextStyle(
                        fontSize: 22,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    onPressed: generateCaptcha,
                  ),
                ],
              ),

              const SizedBox(height: 15),

              TextField(
                controller: captchaController,
                decoration: const InputDecoration(
                  labelText: "ক্যাপচা টাইপ করুন",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading ? null : login,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("লগইন করুন", style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 50),

              const Text(
                "© All Rights Reserved | Computer Wing • BBS",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
