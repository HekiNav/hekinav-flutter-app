class Itinerary {
  int? startTime;
  int? endTime;

  Itinerary({
    required this.startTime,
    required this.endTime,
  });

  factory Itinerary.fromJson(Map<String, dynamic>? json) {
    return Itinerary(
      startTime: json?['plan']['itineraries'][0]["startTime"],
      endTime:   json?['plan']['itineraries'][0]["endTime"], 
    );
  }
}