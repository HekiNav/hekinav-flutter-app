class Trip {
  String gtfsId;
  String tripHeadsign;

  Trip({
    required this.gtfsId,
    required this.tripHeadsign,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      gtfsId: json['gtfsId'],
      tripHeadsign: json['tripHeadsign'],
    );
  }
}