import 'package:hekinav/models/leg.dart';

class Itinerary{
  DateTime startTime;
  DateTime endTime;
  int duration;
  double walkDistance;
  List<Leg> legs;

  Itinerary({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.walkDistance,
    required this.legs,
  });

  factory Itinerary.fromJson(Map<String, dynamic>? json) {
    var legsObjsJson = json?['legs'] as List;
    List<Leg> legs = legsObjsJson.map((legJson) => Leg.fromJson(legJson)).toList();
    return Itinerary(
      duration: json?['duration'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json?['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(json?['endTime']),
      walkDistance: json?['walkDistance'],
      legs: legs
    );
  }
}