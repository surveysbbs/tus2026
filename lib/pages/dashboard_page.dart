import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'about_page.dart';
import 'help_page.dart';
import 'listing_form_page.dart';
import 'partial_list_page.dart';
import 'saved_list_page.dart';
import 'sync_page.dart';
import 'support_page.dart';
import 'login_page.dart';

import '../config/supabase_config.dart';

// ===== DASHBOARD PAGE =====
class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardPage({super.key, required this.user});
  // const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final Box surveyBox = Hive.box('surveyBox'); // local survey data
  final Box metaBox = Hive.box('metaBox'); // meta info (username, psu etc.)
  late String currentUserUsername;
  final service = SupabaseService(url: supabaseUrl, anonKey: supabaseKey);

  final supabase = Supabase.instance.client;

  List<String> assignedPsus = []; // PSU list
  Map<String, Map<String, dynamic>> psuGeoMap = {}; // PSU → geocode map

  TabController? _tabController;

  // ===== LOAD PSU FROM DATABASE =====
  Future<void> loadAssignedPsus() async {
    try {
      final username = metaBox.get('username');

      if (username == null) return;

      // get enumerator info
      final userData = await supabase
          .from('enumerators')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (userData == null) return;

      final psuString = userData['psu']?.toString() ?? '';

      final psuList = psuString
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (psuList.isEmpty) return;

      // 🔥 ONE API CALL
      final geoList = await supabase
          .from('geocode_master')
          .select()
          .inFilter('psu_code', psuList);

      // 🔄 Map তৈরি
      final Map<String, Map<String, dynamic>> tempGeo = {};

      for (final geo in geoList) {
        final psuCode = geo['psu_code'].toString();
        tempGeo[psuCode] = Map<String, dynamic>.from(geo);
      }

      if (!mounted) return;

      _tabController?.dispose();

      _tabController = TabController(length: psuList.length, vsync: this);

      // save default PSU (first tab)
      metaBox.put('selected_psu', psuList.first);

      // listen tab change → save selected PSU
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          metaBox.put('selected_psu', psuList[_tabController!.index]);
        }
      });

      setState(() {
        assignedPsus = psuList;
        psuGeoMap = tempGeo;
      });
    } catch (e) {
      debugPrint("PSU load error: $e");
    }
  }

  Future<void> checkForceLogout() async {
    final username = currentUserUsername; // login time save করা

    debugPrint('Current user: $currentUserUsername');

    final status = await service.getLoginStatus(username);

    debugPrint('Login status: $status');

    if (!mounted) return;

    if (status == 0) {
      // 🔥 force logout
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have been logged out by admin')),
      );
    }
  }

  Future<void> loadDataInBackground() async {
    try {
      final metaBox = Hive.box('metaBox');
      final surveyBox = Hive.box('surveyBox');

      final username = metaBox.get('username');
      if (username == null) return;

      final supabaseService = SupabaseService(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );

      final serverData = await supabaseService.getUserData(username);

      // ⚠️ UI freeze এড়াতে batch update
      for (final item in serverData) {
        final data = Map<String, dynamic>.from(item);

        final exists = surveyBox.values.any(
          (e) => e['house_id'] == data['house_id'],
        );

        if (!exists) {
          await surveyBox.add(data);
        }
      }
    } catch (e) {
      debugPrint("Dashboard background load error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    currentUserUsername =
        widget.user['username']?.toString() ??
        metaBox.get('username')?.toString() ??
        '';
    Future.delayed(const Duration(seconds: 1), () {
      checkForceLogout();
    });
    loadAssignedPsus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadDataInBackground();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // ===== COUNT PARTIAL =====
  int countPartial(Box box) =>
      box.values.where((e) => (e as Map)['isPartial'] == true).length;

  // ===== SMALL STAT CARD =====
  Widget statCard(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        // হালকা ব্যাকগ্রাউন্ড কালার
        color: color.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.lerp(
                          color,
                          Colors.black,
                          0.4,
                        ), // কাস্টম এক্সটেনশন বা সরাসরি কালার
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== MENU BUTTON =====
  Widget menuButton(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
    Color bgColor,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: bgColor, // বাটনের ব্যাকগ্রাউন্ড কালার
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white,
        ),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }

  // ===== PSU GEO INFO UI =====
  Widget buildGeoInfo(String psu) {
    final geo = psuGeoMap[psu];
    if (geo == null) return const Center(child: Text("তথ্য পাওয়া যায়নি"));

    TextStyle labelStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Color.fromARGB(221, 68, 10, 212),
    );
    TextStyle valueStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Color.fromARGB(137, 90, 2, 20),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black),
          children: [
            TextSpan(text: "বিভাগ: ", style: labelStyle),
            TextSpan(text: "${geo['division'] ?? ''},   ", style: valueStyle),
            TextSpan(text: "জেলা: ", style: labelStyle),
            TextSpan(text: "${geo['district'] ?? ''},   ", style: valueStyle),
            TextSpan(text: "সিটি কর্পোরেশন: ", style: labelStyle),
            TextSpan(text: "${geo['ctn'] ?? ''}, \n", style: valueStyle),
            TextSpan(text: "উপজেলা: ", style: labelStyle),
            TextSpan(text: "${geo['upazila'] ?? ''},   ", style: valueStyle),
            TextSpan(text: "পৌরসভা: ", style: labelStyle),
            TextSpan(text: "${geo['psn'] ?? ''},   ", style: valueStyle),
            TextSpan(text: "ইউনিয়ন: ", style: labelStyle),
            TextSpan(
              text: "${geo['union_name'] ?? ',  '}, \n",
              style: valueStyle,
            ),
            TextSpan(text: "মৌজা: ", style: labelStyle),
            TextSpan(text: "${geo['mouza'] ?? ''},   ", style: valueStyle),
            TextSpan(text: "গ্রাম: ", style: labelStyle),
            TextSpan(text: "${geo['village'] ?? ''},   ", style: valueStyle),
            TextSpan(text: "ইএ (জনশুমারি ও গৃহগণনা ২০২২): ", style: labelStyle),
            TextSpan(text: "${geo['ea_code'] ?? ''}.", style: valueStyle),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "লিস্টিং ড্যাশবোর্ডে স্বাগতম",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              metaBox.get('name', defaultValue: ''),
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              metaBox.get('mobile', defaultValue: ''),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: surveyBox.listenable(),
        builder: (context, Box box, _) {
          final deviceSaved = box.values
              .where(
                (e) =>
                    (e as Map)['isPartial'] == false &&
                    (e['fromServer'] == false || e['fromServer'] == null),
              )
              .length;

          // সার্ভারে অলরেডি পাঠানো হয়েছে এমন ডাটা
          final serverSaved = box.values
              .where(
                (e) =>
                    (e as Map)['isPartial'] == false && e['fromServer'] == true,
              )
              .length;

          // আংশিক ডাটা
          final partial = box.values
              .where((e) => (e as Map)['isPartial'] == true)
              .length;

          // সম্পূর্ণ সংগৃহীত = লোকাল ফুল + সার্ভার ফুল
          final fullyCollected = deviceSaved + serverSaved;

          // মোট সংগৃহীত = ফুল + পার্শিয়াল
          final saved = deviceSaved + serverSaved + partial;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // স্ট্যাটাস কার্ডস (Row 1)
              Row(
                children: [
                  statCard("মোট সংগৃহীত", saved, Icons.assessment, Colors.blue),
                  statCard(
                    "সম্পূর্ণ সংগৃহীত",
                    fullyCollected,
                    Icons.verified,
                    Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // স্ট্যাটাস কার্ডস (Row 2)
              Row(
                children: [
                  statCard(
                    "আংশিক সংরক্ষিত",
                    partial,
                    Icons.pending,
                    Colors.brown,
                  ),
                  statCard(
                    "সার্ভারে প্রেরিত",
                    serverSaved,
                    Icons.cloud_done,
                    Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ===== PSU TAB =====
              if (_tabController != null)
                Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Colors.blue.shade800, // সিলেক্টেড কালার
                      unselectedLabelColor: Colors.grey, // আন-সিলেক্টেড কালার
                      indicatorColor: Colors.blue.shade800,
                      indicatorWeight: 3,
                      tabs: assignedPsus
                          .map((psu) => Tab(text: "PSU $psu"))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    // Geo Info Box
                    SizedBox(
                      height: 90, // উচ্চতা একটু বাড়ানো হয়েছে
                      child: TabBarView(
                        controller: _tabController,
                        children: assignedPsus
                            .map((psu) => buildGeoInfo(psu))
                            .toList(),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 15),
              // ===== MENU =====
              menuButton(
                context,
                "নতুন ফর্ম",
                Icons.add_circle,
                const ListingFormPage(),
                Colors.blue.shade700,
              ),
              menuButton(
                context,
                "সংগৃহীত তালিকা",
                Icons.list_alt,
                const SavedListPage(),
                Colors.teal.shade600,
              ),
              menuButton(
                context,
                "আংশিক সংরক্ষিত",
                Icons.history,
                const PartialListPage(),
                Colors.brown.shade700,
              ),
              menuButton(
                context,
                "সার্ভারে প্রেরণ",
                Icons.sync,
                SyncPage(
                  supabaseService: SupabaseService(
                    url: supabaseUrl,
                    anonKey: supabaseKey,
                  ),
                ),
                Colors.indigo.shade600,
              ),
              menuButton(
                context,
                "নির্দেশনা",
                Icons.menu_book,
                const HelpPage(),
                Colors.blueGrey,
              ),
              menuButton(
                context,
                "কারিগরি সহায়তা",
                Icons.headset_mic,
                const SupportPage(),
                Colors.deepPurple.shade400,
              ),
              menuButton(
                context,
                "আমাদের সম্পর্কে",
                Icons.info_outline,
                const AboutPage(),
                Colors.grey.shade700,
              ),
            ],
          );
        },
      ),
    );
  }
}
