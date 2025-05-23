import 'package:flutter/material.dart';

class PatroliButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onPressed;

  const PatroliButton(
      {super.key, required this.icon, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GestureDetector(
        onTap: onPressed,
        child: SizedBox(
          height: 180,
          width: 330,
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            shadowColor: Colors.black.withOpacity(0.6),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, size: 52.0),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(text, style: const TextStyle(fontSize: 18.0))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
