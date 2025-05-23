import "package:flutter/material.dart";

Widget InfoTileWidget(IconData icon, String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, color: Color(0xff11c3a6b), size: 24),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff11c3a6b))),
              Text(value, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    ),
  );
}
