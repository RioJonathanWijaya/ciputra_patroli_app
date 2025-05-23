import 'package:ciputra_patroli/widgets/appbar/appbar.dart';
import 'package:ciputra_patroli/widgets/cards/histori_patroli_item.dart';
import 'package:ciputra_patroli/widgets/searchbar/custom_searchbar.dart';
import 'package:flutter/material.dart';

class HistoriPatroli extends StatefulWidget {
  const HistoriPatroli({super.key});

  @override
  State<HistoriPatroli> createState() => _HistoriPatroliState();
}

class _HistoriPatroliState extends State<HistoriPatroli> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(titleName: "Rekap Patroli"),
      body: Column(
        children: [
          CustomSearchBar(),
          SizedBox(height: 20),
          HistoriPatroliItem()
        ],
      ),
    );
  }
}
