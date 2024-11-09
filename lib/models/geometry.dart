class LegGeometry {
  int length;
  String points;

  LegGeometry({
    required this.length,
    required this.points,
  });

  factory LegGeometry.fromJson(Map<String, dynamic> json) {
    return LegGeometry(
      length: json['length'],
      points: json['points'],
    );
  }
}