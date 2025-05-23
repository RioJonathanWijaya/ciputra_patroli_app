class TitikPatroli {
  final double lat;
  final double lng;

  TitikPatroli({
    required this.lat,
    required this.lng,
  });

  factory TitikPatroli.fromMap(Map<String, dynamic> data) {
    return TitikPatroli(
        lat: (data['lat'] as num).toDouble(),
        lng: (data['lng'] as num).toDouble());
  }
}
