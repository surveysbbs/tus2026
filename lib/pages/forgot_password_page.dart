import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final usernameController = TextEditingController();
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool verified = false;

  Map<String, dynamic>? verifiedUser;

  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> resetPassword() async {
    final username = usernameController.text.trim();
    final mobile = mobileController.text.trim();
    final newPassword = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (username.isEmpty ||
        mobile.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("সব তথ্য দিন")));
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("পাসওয়ার্ড মিলছে না")));
      return;
    }

    setState(() => loading = true);

    try {
      final user = await Supabase.instance.client
          .from('enumerators')
          .select()
          .eq('username', username)
          .eq('mobile', mobile)
          .maybeSingle();

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("তথ্য মিলছে না")));

        setState(() => loading = false);
        return;
      }

      await Supabase.instance.client
          .from('enumerators')
          .update({'password_hash': hashPassword(newPassword)})
          .eq('username', user['username']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("পাসওয়ার্ড পরিবর্তন হয়েছে")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);

    if (newPassword != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("পাসওয়ার্ড মিলছে না")));
      return;
    }
  }

  Future<void> verifyUser() async {
    final username = usernameController.text.trim();
    final mobile = mobileController.text.trim();

    if (username.isEmpty || mobile.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("সব তথ্য দিন")));
      return;
    }

    setState(() => loading = true);

    try {
      final user = await Supabase.instance.client
          .from('enumerators')
          .select()
          .eq('username', username)
          .eq('mobile', mobile)
          .maybeSingle();

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("তথ্য মিলছে না")));

        setState(() => loading = false);
        return;
      }

      verifiedUser = user;

      setState(() {
        verified = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Mobile Number"),
            ),

            

            const SizedBox(height: 15),

            if (verified) ...[
              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password"),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                ),
              ),
            ],
            ElevatedButton(
              onPressed: loading
                  ? null
                  : verified
                  ? resetPassword
                  : verifyUser,

              child: Text(verified ? "Reset Password" : "Verify"),
            ),
          ],
        ),
      ),
    );
  }
}
