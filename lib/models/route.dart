class Route {
  String shortName;
  String longName;
  int type;

  Route({
    required this.shortName,
    required this.longName,
    required this.type,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      shortName: json['shortName'],
      longName: json['longName'],
      type: json['type'],
    );
  }
}