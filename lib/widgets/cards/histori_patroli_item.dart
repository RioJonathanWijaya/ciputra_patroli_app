import 'package:flutter/material.dart';

class HistoriPatroliItem extends StatefulWidget {
  @override
  _HistoriPatroliItemState createState() => _HistoriPatroliItemState();
}

class _HistoriPatroliItemState extends State<HistoriPatroliItem> {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Column(
        children: [
          ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 80,
                height: 85,
                color: Color(0xff11c3a6b),
                child: const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nama Satpam",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              "Cluster Emerald Timur",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          color: Color(0xff00FF09),
                          size: 40,
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Jumat, 10 Jan 2025",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Jam Mulai Patroli",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.normal),
                            ),
                            Text(
                              "09:30:00",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      ],
                    ),
                    SizedBox(width: 15),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          color: Color(0xffFF0000),
                          size: 40,
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Jumat, 10 Jan 2025",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Jam Selesai Patroli",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.normal),
                            ),
                            Text(
                              "09:30:00",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text("Durasi"),
                Text("10 Menit", style: TextStyle(fontWeight: FontWeight.bold))
              ],
            ),
          )
        ],
      ),
    );
  }
}
