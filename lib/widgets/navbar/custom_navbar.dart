import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

final List<SalomonBottomBarItem> _items = [
  SalomonBottomBarItem(
      icon: const Icon(Icons.security),
      title: const Text("Patroli"),
      selectedColor: Colors.white),
  SalomonBottomBarItem(
      icon: const Icon(Icons.notifications),
      title: const Text("Notifikasi"),
      selectedColor: Colors.white),
  SalomonBottomBarItem(
      icon: const Icon(Icons.edit_document),
      title: const Text("Kejadian"),
      selectedColor: Colors.white),
  SalomonBottomBarItem(
      icon: const Icon(Icons.person),
      title: const Text("Profil"),
      selectedColor: Colors.white)
];

class CustomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const CustomNavigationBar({
    required this.currentIndex,
    required this.onItemSelected,
    super.key,
  });

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff11c3a6b),
      child: Padding(
        padding: const EdgeInsets.only(
            top: 10.0, bottom: 0.0, left: 10.0, right: 10.0),
        child: SalomonBottomBar(
            items: _items,
            currentIndex: widget.currentIndex,
            onTap: widget.onItemSelected),
      ),
    );
  }
}
