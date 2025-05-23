import 'package:flutter/material.dart';

Widget TitleAnimation(String title) {
  return TweenAnimationBuilder(
    duration: Duration(milliseconds: 600),
    tween: Tween<double>(begin: 0, end: 1),
    builder: (context, double value, child) {
      return Opacity(
        opacity: value,
        child: Padding(
          padding: EdgeInsets.only(bottom: 8 * value),
          child: Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff11c3a6b))),
        ),
      );
    },
  );
}
