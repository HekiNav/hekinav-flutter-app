import 'package:hekinav/models/stop.dart';

class From {
  double lat;
  double lon;
  Stop? stop;

  From({
    required this.lat,
    required this.lon,
    required this.stop,
  });

  factory From.fromJson(Map<String, dynamic> json) {
    return From(
      lat: json['lat'],
      lon: json['lon'],
      stop: json['stop'] == null ? null : Stop.fromJson(json['stop']),
    );
  }
}

class To {
  double lat;
  double lon;
  Stop? stop;

  To({
    required this.lat,
    required this.lon,
    required this.stop,
  });

  factory To.fromJson(Map<String, dynamic> json) {
    return To(
      lat: json['lat'],
      lon: json['lon'],
      stop: json['stop'] == null ? null : Stop.fromJson(json['stop']),
    );
  }
}