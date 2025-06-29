import 'package:ciputra_patroli/views/kejadian/kejadian_list_page.dart';
import 'package:ciputra_patroli/views/notifikasi/notifikasi_list_page.dart';
import 'package:ciputra_patroli/views/patroli/patroli_page.dart';
import 'package:ciputra_patroli/views/profile/profile_page.dart';
import 'package:ciputra_patroli/views/alert/alert_page.dart';
import 'package:ciputra_patroli/widgets/appbar/appbar.dart';
import 'package:ciputra_patroli/widgets/navbar/custom_navbar.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  final List<String> titles = [
    "Patroli",
    "Notifikasi",
    "Alert",
    "Pelaporan Kejadian",
    "Profile"
  ];

  final List<Widget> pages = [
    const PatroliPage(),
    const NotifikasiListPage(),
    const AlertPage(),
    const KejadianListPage(),
    const ProfilePage(),
  ];

  void _onItemSelected(int index) {
    if (selectedIndex == index) return;

    setState(() {
      selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: selectedIndex == 2
          ? null
          : CustomAppbar(titleName: titles[selectedIndex]),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        children: pages,
      ),
    );
  }
}
