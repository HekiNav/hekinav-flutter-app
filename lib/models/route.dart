class TransitRoute {
  String shortName;
  String longName;
  int type;

  TransitRoute({
    required this.shortName,
    required this.longName,
    required this.type,
  });

  factory TransitRoute.fromJson(Map<String, dynamic> json) {
    return TransitRoute(
      shortName: json['shortName'],
      longName: json['longName'],
      type: json['type'],
    );
  }
}