import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../config/supabase_config.dart';

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

  Future<void> downloadUserData() async {
    final metaBox = Hive.box('metaBox');
    final surveyBox = Hive.box('surveyBox');

    final username = metaBox.get('username');
    if (username == null) return;

    final supabaseService = SupabaseService(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );

    final serverData = await supabaseService.getUserData(username);

    final existingMap = <String, int>{};

    for (int i = 0; i < surveyBox.length; i++) {
      final item = surveyBox.getAt(i);

      if (item is Map) {
        final houseId = item['house_id'];
        if (houseId != null) {
          existingMap[houseId.toString()] = i;
        }
      }
    }

    for (final item in serverData) {
      final raw = Map<String, dynamic>.from(item);

      final houseId = raw['house_id']?.toString();
      if (houseId == null || houseId.isEmpty) continue;

      final data = {
        ...raw,

        // server field -> app field
        'totalMember': raw['total_member'],
        'isPartial': raw['is_partial'] ?? false,

        // server থেকে আসা মানে already synced
        'fromServer': true,
      };

      if (existingMap.containsKey(houseId)) {
        await surveyBox.putAt(existingMap[houseId]!, data);
      } else {
        await surveyBox.add(data);
      }
    }

    final Map<String, int> maxSerialByPsu = {};

    for (final item in surveyBox.values) {
      if (item is Map) {
        final psu = item['psu']?.toString() ?? '';
        final serialStr = item['serial']?.toString() ?? '';
        final serialNum = int.tryParse(serialStr) ?? 0;

        if (psu.isNotEmpty && serialNum > (maxSerialByPsu[psu] ?? 0)) {
          maxSerialByPsu[psu] = serialNum;
        }
      }
    }

    for (final entry in maxSerialByPsu.entries) {
      await metaBox.put('serial_${entry.key}', entry.value + 1);
    }
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

      final metaBox = Hive.box('metaBox');
      await metaBox.put('user_id', userData['id']);
      await metaBox.put('username', userData['username']);
      await metaBox.put('name', userData['name']);
      await metaBox.put('mobile', userData['mobile']);
      await metaBox.put('psu', userData['psu']);
      await metaBox.put('is_logged_in', true);

      await Supabase.instance.client
          .from('enumerators')
          .update({'login_status': 1})
          .eq('username', userData['username']);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DashboardPage(user: Map<String, dynamic>.from(userData)),
        ),
      );
      Future.microtask(() async {
        try {
          await downloadUserData();
        } catch (e) {
          debugPrint("Download error: $e");
        }
      });
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

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'flutter_assets/logo.jpeg',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 20),
                  Image.asset(
                    'flutter_assets/tus.jpeg',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text(
                "গণপ্রজাতন্ত্রী বাংলাদেশ সরকার",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const Text(
                "বাংলাদেশ পরিসংখ্যান ব্যুরো",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const Text(
                "টাইম ইউজ সার্ভে ২০২৬",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(221, 93, 42, 235),
                ),
              ),
              const Text(
                "লিস্টিং অপারেশন",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: Color.fromARGB(221, 93, 79, 227),
                ),
              ),
              const Text(
                "ব্যবহারকারী লগইন",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(221, 133, 108, 234),
                ),
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
