import 'dart:convert';

import 'package:hekinav/models/place.dart';

class Origin {
  late Place? place;

  static Origin placeholder = Origin(
    place: Place.fromJson(
      jsonDecode("""{
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          24.6562,
          60.17662
        ]
      },
      "properties": {
        "id": "GTFS:HSL:2431252#E4314",
        "gid": "gtfshsl:stop:GTFS:HSL:2431252#E4314",
        "layer": "stop",
        "source": "gtfshsl",
        "source_id": "GTFS:HSL:2431252#E4314",
        "name": "Latokaski",
        "postalcode": "02340",
        "postalcode_gid": "whosonfirst:postalcode:421473305",
        "confidence": 1,
        "accuracy": "centroid",
        "region": "Uusimaa",
        "region_gid": "whosonfirst:region:85683067",
        "localadmin": "Espoo",
        "localadmin_gid": "whosonfirst:localadmin:907198517",
        "locality": "Espoo",
        "locality_gid": "whosonfirst:locality:101748415",
        "neighbourhood": "Latokaskenmäki",
        "neighbourhood_gid": "whosonfirst:neighbourhood:1108729333",
        "label": "Latokaski, Latokaskenmäki, Espoo",
        "addendum": {
          "GTFS": {
            "modes": [
              "BUS"
            ],
            "code": "E4314"
          }
        }
      }
    }"""),
    ),
  );

  Origin({
    required this.place,
  });
}

class Destination {
  late Place? place;

  static Destination placeholder = Destination(
    place: Place.fromJson(
      jsonDecode("""{
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          25.04432,
          60.292038
        ]
      },
      "properties": {
        "id": "GTFS:HSL:4610504#V0614",
        "gid": "gtfshsl:stop:GTFS:HSL:4610504#V0614",
        "layer": "stop",
        "source": "gtfshsl",
        "source_id": "GTFS:HSL:4610504#V0614",
        "name": "Tikkurila",
        "postalcode": "01300",
        "postalcode_gid": "whosonfirst:postalcode:421473179",
        "confidence": 1,
        "accuracy": "centroid",
        "region": "Uusimaa",
        "region_gid": "whosonfirst:region:85683067",
        "localadmin": "Vantaa",
        "localadmin_gid": "whosonfirst:localadmin:907199651",
        "locality": "Vantaa",
        "locality_gid": "whosonfirst:locality:101748419",
        "neighbourhood": "Jokiniemi",
        "neighbourhood_gid": "whosonfirst:neighbourhood:1108729527",
        "label": "Tikkurila, Jokiniemi, Vantaa",
        "addendum": {
          "GTFS": {
            "platform": "4",
            "modes": [
              "RAIL"
            ],
            "code": "V0614"
          }
        }
      }
    }"""),
    ),
  );

  Destination({
    required this.place,
  });
}
