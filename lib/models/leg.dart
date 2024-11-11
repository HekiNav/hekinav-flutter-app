import 'package:hekinav/models/start_end.dart';
import 'package:hekinav/models/from_to.dart';
import 'package:hekinav/models/trip.dart';
import 'package:hekinav/models/route.dart';
import 'package:hekinav/models/geometry.dart';

class Leg {
  Start start;
  End end;
  String mode;
  double duration;
  bool? realtime;
  double distance;
  From from;
  To to;
  Trip? trip;
  TransitRoute? route;
  LegGeometry geometry;

  Leg({
    required this.start,
    required this.end,
    required this.mode,
    required this.duration,
    required this.realtime,
    required this.distance,
    required this.from,
    required this.to,
    required this.trip,
    required this.route,
    required this.geometry,
  });

  factory Leg.fromJson(Map<String, dynamic> json) {
    return Leg(
      start: Start.fromJson(json['start']),
      end: End.fromJson(json['end']),
      mode: json['mode'],
      duration: json['duration'],
      realtime: json['realtime'],
      distance: json['distance'],
      from: From.fromJson(json['from']),
      to: To.fromJson(json['to']),
      trip: json['trip'] == null ? null : Trip.fromJson(json['trip']),
      route: json['route'] == null ? null : TransitRoute.fromJson(json['route']),
      geometry: LegGeometry.fromJson(json['legGeometry'])
    );
  }
}

