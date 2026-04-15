import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'package:geolocator/geolocator.dart';
import '../config/supabase_config.dart';

import 'sync_page.dart';

class ListingFormPage extends StatefulWidget {
  // existing record for edit/view
  final Map? editData;
  final int? editIndex;
  final bool isViewOnly;

  const ListingFormPage({
    super.key,
    this.editData,
    this.editIndex,
    this.isViewOnly = false,
  });

  @override
  State<ListingFormPage> createState() => _ListingFormPageState();
}

class _ListingFormPageState extends State<ListingFormPage> {
  // local Hive boxes
  final box = Hive.box('surveyBox');
  final meta = Hive.box('metaBox');

  // Supabase client
  final supabase = Supabase.instance.client;

  // form controllers
  final serial = TextEditingController();
  final head = TextEditingController();
  final mother = TextEditingController();
  final father = TextEditingController();
  final address = TextEditingController();
  final mobile = TextEditingController();
  final profession = TextEditingController();
  final totalMember = TextEditingController();
  final female = TextEditingController();
  final male = TextEditingController();
  final comment = TextEditingController();

  // ১. শুধুমাত্র ইংরেজি ইনপুট নিশ্চিত করার জন্য ফিল্টার
  // এটি বাংলা বা অন্য কোনো ভাষা টাইপ করতে বাধা দেবে
  final englishOnlyFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[a-zA-Z0-9\s!@#$%^&*(),.?":{}|<>]'),
  );
  final digitsOnlyFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9]'),
  );

  // show validation errors after user tries complete save/send
  bool showValidationError = false;

  // return error text for required field
  String? requiredError(TextEditingController controller) {
    if (!showValidationError) return null;

    if (controller.text.trim().isEmpty) {
      return "এই ঘরটি পূরণ করতে হবে";
    }

    return null;
  }

  // check required fields for complete save/send
  bool hasRequiredFields() {
    return selectedPsu.isNotEmpty &&
        serial.text.trim().isNotEmpty &&
        head.text.trim().isNotEmpty &&
        mother.text.trim().isNotEmpty &&
        father.text.trim().isNotEmpty &&
        address.text.trim().isNotEmpty &&
        mobile.text.trim().isNotEmpty &&
        profession.text.trim().isNotEmpty &&
        totalMember.text.trim().isNotEmpty &&
        female.text.trim().isNotEmpty &&
        male.text.trim().isNotEmpty;
  }

  // selected PSU and geocode data
  String selectedPsu = '';
  Map<String, dynamic>? selectedGeo;

  @override
  void initState() {
    super.initState();
    loadSelectedPsuAndGeo();

    // fill existing data in edit/view mode
    if (widget.editData != null) {
      final d = widget.editData!;

      serial.text = d['serial']?.toString() ?? '';
      head.text = d['head']?.toString() ?? '';
      mother.text = d['mother']?.toString() ?? '';
      father.text = d['father']?.toString() ?? '';
      address.text = d['address']?.toString() ?? '';
      mobile.text = d['mobile']?.toString() ?? '';
      profession.text = d['profession']?.toString() ?? '';
      totalMember.text = d['totalMember']?.toString() ?? '';
      female.text = d['female']?.toString() ?? '';
      male.text = d['male']?.toString() ?? '';
      comment.text = d['comment']?.toString() ?? '';
    } else {
      // generate PSU-wise serial for new record
      final psu = meta.get('selected_psu')?.toString() ?? '';
      final key = 'serial_$psu';
      final current = meta.get(key) ?? 1;
      serial.text = current.toString().padLeft(3, '0');
    }
  }

  @override
  void dispose() {
    serial.dispose();
    head.dispose();
    mother.dispose();
    father.dispose();
    address.dispose();
    mobile.dispose();
    profession.dispose();
    totalMember.dispose();
    female.dispose();
    male.dispose();
    comment.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // load selected PSU from Hive and fetch geocode from Supabase
  Future<void> loadSelectedPsuAndGeo() async {
    try {
      final psu = meta.get('selected_psu')?.toString() ?? '';

      if (psu.isEmpty) return;

      final geo = await supabase
          .from('geocode_master')
          .select()
          .eq('psu_code', psu.trim())
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        selectedPsu = psu;
        selectedGeo = geo;
      });
    } catch (e) {
      debugPrint('Geo load error: $e');
    }
  }

  // reusable text field with required highlight
  Widget field(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    bool readOnly = false,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: type,
        readOnly: readOnly || widget.isViewOnly,
        // ইনপুট ফরম্যাটার যোগ করা হয়েছে
        inputFormatters: [
          type == TextInputType.number
              ? digitsOnlyFormatter
              : englishOnlyFormatter,
        ],
        //onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: required ? "$label *" : label,
          labelStyle: const TextStyle(color: Colors.blueGrey),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          errorText: required ? requiredError(controller) : null,
          fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          filled: true,
        ),
      ),
    );
  }

  // mobile field with real-time validation + required highlight
  Widget mobileField() {
    final requiredMsg = showValidationError && mobile.text.trim().isEmpty
        ? "এই ঘরটি পূরণ করতে হবে"
        : null;

    final mobileMsg = mobile.text.trim().isNotEmpty ? getMobileError() : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: mobile,
        readOnly: widget.isViewOnly,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
        ],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: "মোবাইল নম্বর *",
          border: const OutlineInputBorder(),
          errorText: requiredMsg ?? mobileMsg,
        ),
      ),
    );
  }

  Widget numberFieldWithRefresh(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        readOnly: widget.isViewOnly,
        inputFormatters: [digitsOnlyFormatter],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: "$label *",
          labelStyle: const TextStyle(color: Colors.blueGrey),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          errorText: requiredError(controller),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  // real-time mobile validation
  String? getMobileError() {
    final phone = mobile.text.trim();

    const validPrefixes = [
      '011',
      '012',
      '013',
      '014',
      '015',
      '016',
      '017',
      '018',
      '019',
    ];

    if (phone.isEmpty) return null;

    if (phone.length != 11) {
      return "মোবাইল নম্বর ১১ ডিজিট হতে হবে";
    }

    if (!validPrefixes.any((p) => phone.startsWith(p))) {
      return "মোবাইল নম্বর 011-019 দিয়ে শুরু হতে হবে";
    }

    return null;
  }

  // member rule: total member must be >= female + male
  String? getMemberError() {
    final total = int.tryParse(totalMember.text.trim()) ?? 0;
    final f = int.tryParse(female.text.trim()) ?? 0;
    final m = int.tryParse(male.text.trim()) ?? 0;

    if (totalMember.text.isEmpty && female.text.isEmpty && male.text.isEmpty) {
      return null;
    }

    if (total < (f + m)) {
      return "মোট সদস্য সংখ্যা মহিলা (১৫+) ও পুরুষ (১৫+) এর যোগফলের চেয়ে কম হতে পারবে না";
    }

    return null;
  }

  // validate form before complete save/send
  bool validateForm({required bool requireAllFields}) {
    setState(() {
      showValidationError = requireAllFields;
    });

    if (requireAllFields && !hasRequiredFields()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("সব ঘর পূরণ করতে হবে")));
      return false;
    }

    final mobileError = getMobileError();
    if (mobile.text.trim().isNotEmpty && mobileError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mobileError)));
      return false;
    }

    final memberError = getMemberError();
    if (totalMember.text.trim().isNotEmpty ||
        female.text.trim().isNotEmpty ||
        male.text.trim().isNotEmpty) {
      if (memberError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(memberError)));
        return false;
      }
    }

    return true;
  }

  // PSU geocode box
  Widget buildPsuGeoBox() {
    if (selectedPsu.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Text(
          "⚠️ ড্যাশবোর্ড থেকে কোনো PSU নির্বাচন করা হয়নি",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50, // লাইট ব্যাকগ্রাউন্ড
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.blue),
              const SizedBox(width: 5),
              Text(
                "PSU: $selectedPsu",
                style: const TextStyle(
                  fontWeight: FontWeight.bold, // বোল্ড লেটার
                  fontSize: 18,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.blue),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Color.fromARGB(221, 240, 50, 50),
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text: "বিভাগ: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "${selectedGeo?['division'] ?? ''}, "),
                const TextSpan(
                  text: "জেলা: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "${selectedGeo?['district'] ?? ''}, "),
                const TextSpan(
                  text: "সিটি কর্পোরেশন: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "${selectedGeo?['ctn'] ?? ''}, "),
                const TextSpan(
                  text: "উপজেলা: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "${selectedGeo?['upazila'] ?? ''}, "),
                const TextSpan(
                  text: "পৌরসভা: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "${selectedGeo?['psn'] ?? ''}, "),
                const TextSpan(
                  text: "ইউনিয়ন: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "${selectedGeo?['union_name'] ?? ''}, "),
                const TextSpan(
                  text: "মৌজা: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "${selectedGeo?['mouza'] ?? ''}, "),
                const TextSpan(
                  text: "গ্রাম: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "${selectedGeo?['village'] ?? ''}, "),
                const TextSpan(
                  text: "গণনা এলাকা: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "${selectedGeo?['ea_code'] ?? ''}"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSaving = false;
  // save partial/complete locally
  Future<void> saveLocal(bool partial) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    if (!validateForm(requireAllFields: !partial)) {
      setState(() => _isSaving = false);
      return;
    }
    try {
      // লোকেশন নেওয়া
      Position? pos = await _getCurrentLocation();

      // স্ট্যাটাস নির্ধারণ (আংশিক = ০, পূর্ণাঙ্গ = ১)
      int status = partial ? 0 : 1;
      // যদি এডিট মোড হয় এবং ডাটাটি আগে থেকেই সার্ভারে পাঠানো হয়ে থাকে (fromServer: true), তবে স্ট্যাটাস ২ (Updated)
      if (widget.editData != null &&
          widget.editData!['fromServer'] == true &&
          !partial) {
        status = 2;
      }
      final data = {
        'username': meta.get('username'),
        'house_id': "${selectedPsu}_${serial.text.trim()}", // Primary Key
        'latitude': pos?.latitude,
        'longitude': pos?.longitude,
        'data_status': status,
        'serial': serial.text.trim(),
        'psu': selectedPsu,
        'division': selectedGeo?['division'],
        'district': selectedGeo?['district'],
        'ctn': selectedGeo?['ctn'],
        'upazila': selectedGeo?['upazila'],
        'psn': selectedGeo?['psn'],
        'union_name': selectedGeo?['union_name'],
        'mouza': selectedGeo?['mouza'],
        'village': selectedGeo?['village'],
        'ea_code': selectedGeo?['ea_code'],
        'head': head.text.trim(),
        'mother': mother.text.trim(),
        'father': father.text.trim(),
        'address': address.text.trim(),
        'mobile': mobile.text.trim(),
        'profession': profession.text.trim(),
        'totalMember': totalMember.text.trim().isEmpty
            ? null
            : int.tryParse(totalMember.text.trim()),
        'female': female.text.trim().isEmpty
            ? null
            : int.tryParse(female.text.trim()),
        'male': male.text.trim().isEmpty
            ? null
            : int.tryParse(male.text.trim()),
        'comment': comment.text.trim(),
        'isPartial': partial,
        'fromServer': false,
      };

      if (widget.editIndex == null) {
        bool exists = box.values.any((e) => e['house_id'] == data['house_id']);
        if (!exists) {
          await box.add(data);
          final key = 'serial_$selectedPsu';
          final next = (meta.get(key) ?? 1) + 1;
          await meta.put(key, next);
        }
      } else {
        await box.putAt(widget.editIndex!, data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(partial ? "আংশিক সংরক্ষণ হয়েছে" : "সংরক্ষণ হয়েছে"),
        ),
      );

      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false); // Kaj shesh hole abar false kora
      }
    }
  }

  ///data save kore server e preron
  Future<void> sendToServer() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    if (!validateForm(requireAllFields: true)) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      Position? pos = await _getCurrentLocation();

      // স্ট্যাটাস নির্ধারণ
      int status =
          (widget.editData != null && widget.editData!['fromServer'] == true)
          ? 2
          : 1;
      // ২. ডাটা লোকাল Hive-এ সেভ করার জন্য ম্যাপ তৈরি
      final localData = {
        'username': meta.get('username'),
        'house_id': "${selectedPsu}_${serial.text.trim()}",
        'latitude': pos?.latitude,
        'longitude': pos?.longitude,
        'data_status': status,
        'serial': serial.text.trim(),
        'psu': selectedPsu,
        'division': selectedGeo?['division'],
        'district': selectedGeo?['district'],
        'ctn': selectedGeo?['ctn'],
        'upazila': selectedGeo?['upazila'],
        'psn': selectedGeo?['psn'],
        'union_name': selectedGeo?['union_name'],
        'mouza': selectedGeo?['mouza'],
        'village': selectedGeo?['village'],
        'ea_code': selectedGeo?['ea_code'],
        'head': head.text.trim(),
        'mother': mother.text.trim(),
        'father': father.text.trim(),
        'address': address.text.trim(),
        'mobile': mobile.text.trim(),
        'profession': profession.text.trim(),
        'totalMember': totalMember.text.trim().isEmpty
            ? null
            : int.tryParse(totalMember.text.trim()),
        'female': female.text.trim().isEmpty
            ? null
            : int.tryParse(female.text.trim()),
        'male': male.text.trim().isEmpty
            ? null
            : int.tryParse(male.text.trim()),
        'comment': comment.text.trim(),
        'isPartial': false, // যেহেতু সার্ভারে পাঠাচ্ছেন, তাই এটি পূর্ণাঙ্গ ডাটা
        'fromServer': false, // এখনো সার্ভারে পৌঁছায়নি, SyncPage এটি পাঠাবে
      };

      // ৩. Hive বক্সে ডাটা আপডেট বা নতুন করে যোগ করা
      if (widget.editIndex != null) {
        await box.putAt(widget.editIndex!, localData);
      } else {
        final exists = box.values.any(
          (e) => e['house_id'] == localData['house_id'],
        );

        if (!exists) {
          await box.add(localData);

          final key = 'serial_$selectedPsu';
          final next = (meta.get(key) ?? 1) + 1;
          await meta.put(key, next);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("এই খানার তথ্য আগে থেকেই আছে")),
          );
          return;
        }
      }

      if (!mounted) return;

      // ৪. সরাসরি SyncPage-এ পাঠিয়ে দেওয়া
      // pushReplacement যাতে ব্যাক করলে আবার ফর্মে না ফিরে আসে
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SyncPage(
            supabaseService: SupabaseService(
              url: supabaseUrl,
              anonKey: supabaseKey,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint("Send to server prep error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "সার্ভারে প্রেরণের জন্য ডাটা প্রস্তুত করতে সমস্যা হয়েছে",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberError = getMemberError();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isViewOnly ? "ফরম দেখুন" : "লিস্টিং ফরম"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildPsuGeoBox(),

            field("খানার ক্রমিক নম্বর", serial, readOnly: true),
            field("খানা প্রধানের নাম", head), // নামগুলো ইংরেজিতে দিতে হবে
            field("মাতার নাম", mother),
            field("পিতা/স্বামীর নাম", father),
            field("ঠিকানা ও হোল্ডিং নম্বর", address),

            // মোবাইল নম্বর ফিল্ড (আগের লজিক অনুযায়ী ইংরেজি ডিজিট লক করা)
            mobileField(),

            field("পেশা", profession),

            // সংখ্যা ইনপুট ফিল্ড (শুধুমাত্র ইংরেজি নম্বর কাজ করবে)
            numberFieldWithRefresh("মোট সদস্য সংখ্যা", totalMember),
            numberFieldWithRefresh("মহিলা (১৫+)", female),
            numberFieldWithRefresh("পুরুষ (১৫+)", male),

            if (memberError != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  memberError,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            field("মন্তব্য", comment, required: false),

            const SizedBox(height: 25),

            if (!widget.isViewOnly)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => saveLocal(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "আংশিক সংরক্ষণ",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => saveLocal(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("সংরক্ষণ", textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : sendToServer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "সার্ভারে প্রেরণ",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
