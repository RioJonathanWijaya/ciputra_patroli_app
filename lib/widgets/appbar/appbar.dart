import 'package:flutter/material.dart';

class CustomAppbar extends StatefulWidget implements PreferredSizeWidget {
  final String titleName;
  const CustomAppbar({super.key, required this.titleName});

  @override
  State<CustomAppbar> createState() => _CustomAppbarState();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppbarState extends State<CustomAppbar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        widget.titleName,
        style: const TextStyle(
            fontSize: 24.0, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xff11c3a6b),
    );
  }
}
