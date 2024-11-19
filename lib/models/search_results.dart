class ResultStop {
  String? name;
  String? code;
  String? kunta;
  String? alue;
  String? mode;
  String? platform;

  ResultStop({
    required this.code,
    required this.kunta,
    required this.alue,
    required this.mode,
    required this.name,
    required this.platform,
  });

  factory ResultStop.fromJson(Map<String, dynamic> json) {
    return ResultStop(
      code: json['properties']['addendum']['GTFS']['code'],
      kunta: json['properties']['localadmin'],
      alue: json['properties']['neighbourhood'],
      mode: json['properties']['addendum']['GTFS']['modes'][0],
      name: json['properties']['name'],
      platform: json['properties']['addendum']['GTFS']['platform'],
    );
  }
}
