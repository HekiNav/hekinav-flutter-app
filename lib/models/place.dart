class Place {
  double lat;
  double lon;
  String? region;
  String? localadmin;
  String? locality;
  String? neighbourhood;

  String? postalcode;

  String name;
  String? type;
  String? code;
  String? platform;
  List modes;

  Place({
    required this.lat,
    required this.lon,
    required this.name,
    required this.region,
    required this.localadmin,
    required this.locality,
    required this.neighbourhood,
    required this.postalcode,
    required this.type,
    required this.code,
    required this.platform,
    required this.modes,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      lat: json['geometry']['coordinates'][1],
      lon: json['geometry']['coordinates'][0],
      region: json['properties']['region'],
      name: json['properties']['name'],
      neighbourhood: json['properties']['neighbourhood'],
      postalcode: json['properties']['postalcode'],
      localadmin: json['properties']['localadmin'],
      locality: json['properties']['locality'],
      type: json['properties']['layer'],
      code: json['properties']?['addendum']?['GTFS']?['code'],
      platform: json['properties']?['addendum']?['GTFS']?['platform'],
      modes: json['properties']?['addendum']?['GTFS']?['modes'] ?? [],
    );
  }
}
