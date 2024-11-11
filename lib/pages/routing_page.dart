import 'dart:developer';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hekinav/main.dart';
import 'package:hekinav/models/leg.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hekinav/models/itinerary.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:polyline_codec/polyline_codec.dart';
import 'package:intl/intl.dart';

HttpLink link = HttpLink(
    "https://api.digitransit.fi/routing/v2/routers/hsl/index/graphql",
    defaultHeaders: {
      "digitransit-subscription-key": "a1e437f79628464c9ea8d542db6f6e94"
    });

final GraphQLClient client = GraphQLClient(
  cache: GraphQLCache(),
  link: link,
);

class RoutingPage extends StatefulWidget {
  const RoutingPage({super.key});

  @override
  State<RoutingPage> createState() => _RoutingPageState();
}

class _RoutingPageState extends State<RoutingPage> {
  CameraOptions camera = CameraOptions(
    center: Point(coordinates: Position(24.941430272857485, 60.17185691732062)),
    zoom: 12,
    bearing: 0,
    pitch: 0,
  );
  late CircleAnnotation circleAnnotation;
  late CircleAnnotationManager circleAnnotationManager;
  late PolylineAnnotation polylineAnnotation;
  late PolylineAnnotationManager polylineAnnotationManager;
  late PointAnnotation pointAnnotation;
  late PointAnnotationManager pointAnnotationManager;
  late MapboxMap mapboxMap;

  final fromController = TextEditingController();
  final toController = TextEditingController();

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    mapboxMap.style.addSource(VectorSource(id: "finland-stops", tiles: [
      "https://cdn.digitransit.fi/map/v2/finland-stop-map/{z}/{x}/{y}.pbf"
    ]));

    mapboxMap.style.addLayer(CircleLayer(
        id: "finland-stops-layer",
        sourceId: "finland-stops",
        sourceLayer: "stops"));
    await mapboxMap.style.addLayer(LineLayer(
        id: "tile-debug",
        sourceId: "finland-stops",
        lineColor: Colors.red.value,
        lineWidth: 1));

    circleAnnotationManager =
        await mapboxMap.annotations.createCircleAnnotationManager();

    polylineAnnotationManager =
        await mapboxMap.annotations.createPolylineAnnotationManager();

    pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
  }

  Future<List> fetchRoute() async {
    //remove previous markers and polylines
    circleAnnotationManager.deleteAll();
    polylineAnnotationManager.deleteAll();

    var fromRes = await http.get(Uri.parse(
        'https://api.digitransit.fi/geocoding/v1/search?digitransit-subscription-key=bbc7a56df1674c59822889b1bc84e7ad&text=${fromController.text == "" ? "Latokaski" : fromController.text}&size=1&boundary.rect.max_lat=61.6&boundary.rect.min_lat=59.95&boundary.rect.min_lon=23.8&boundary.rect.max_lon=27.2'));
    if (fromRes.statusCode != 200) {
      throw Exception('Failed to fetch origin');
    }
    var fromCoords =
        json.decode(fromRes.body)['features'][0]["geometry"]["coordinates"];

    var toRes = await http.get(Uri.parse(
        'https://api.digitransit.fi/geocoding/v1/search?digitransit-subscription-key=bbc7a56df1674c59822889b1bc84e7ad&text=${toController.text == "" ? "Tikkurila" : toController.text}&size=1&boundary.rect.max_lat=61.6&boundary.rect.min_lat=59.95&boundary.rect.min_lon=23.8&boundary.rect.max_lon=27.2'));
    if (toRes.statusCode != 200) {
      throw Exception('Failed to fetch destination');
    }
    var toCoords =
        json.decode(toRes.body)['features'][0]["geometry"]["coordinates"];

    String epicRequest = """
  {
  plan(
    from: {lat: ${fromCoords[1]}, lon: ${fromCoords[0]}}
    to: {lat: ${toCoords[1]}, lon: ${toCoords[0]}}
    time: "${startTime?.hour}:${startTime?.minute}:00"
    date: "${DateFormat("yyyy-MM-dd")}"
  ) {
    itineraries {
      duration
      fares {
        type
        currency
        cents
      }
      walkDistance
      startTime
      endTime
      legs {
        start {
          scheduledTime
          estimated {
            time
            delay
          }
        }
        end {
          scheduledTime
          estimated {
            time
            delay
          }
        }
        mode
        duration
        realTime
        realtimeState
        distance
        transitLeg
        from {
          lat
          lon
          stop {
            code
            name
          }
        }
        to {
          lat
          lon
          stop {
            code
            name
          }
        }
        trip {
          gtfsId
          tripHeadsign
        }
        route {
          shortName
          longName
          type
        }
        legGeometry {
          length  
          points
        }
      }
    }
  }
}
""";

    final QueryOptions options = QueryOptions(document: gql(epicRequest));

    final QueryResult response = await client.query(options);

    if (response.data == null) {
      log(response.toString());
      throw Exception('Failed to fetch');
    }

    var data = response.data?['plan']['itineraries'];

    List<Itinerary> routeList = [];
    int length = data.length;
    for (int i = 0; i < length; i++) {
      routeList.add(
        Itinerary.fromJson(
          data[i],
        ),
      );
    }
    return routeList;
  }

  //despite its name, currently only shows one route (half true)
  void showRoutes(routes) async {
    var routeList = await routes;
    var itinerary = routeList[0];

    navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => mainView(context, routeList)));
    //draw shapes and transfer stops
    for (int i = 0; i < itinerary.legs.length; i++) {
      //get color of route type
      var color = colorFromRouteType(itinerary.legs[i].route?.type);

      //google polyline encoded -> [[lat, lon], [lat, lon]]
      var points = PolylineCodec.decode(itinerary.legs[i].geometry.points);

      //[[lat, lon], [lat, lon]] -> [Position, Position]
      List<Position> posList = [];
      for (var point in points) {
        posList.add(Position(point[1], point[0]));
      }

      //draw the shape
      polylineAnnotationManager
          .create(PolylineAnnotationOptions(
            geometry: LineString(coordinates: posList),
            lineWidth: 5.0,
            lineColor: color.value,
          ))
          .then((value) => polylineAnnotation = value);

      //draw the circle
      circleAnnotationManager
          .create(CircleAnnotationOptions(
            geometry: Point(
                coordinates: Position(
                    itinerary.legs[i].from.lon, itinerary.legs[i].from.lat)),
            circleStrokeColor: color.value,
            circleStrokeWidth: 3.0,
            circleColor: const Color.fromARGB(255, 255, 255, 255).value,
            circleRadius: 9.0,
          ))
          .then((value) => circleAnnotation = value);
    }
  }

  final navigatorKey = GlobalKey<NavigatorState>();

  bool placeholder = true;
  @override
  Widget build(BuildContext context) {
    var themeState = context.watch<ThemeProvider>();
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Options",
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.add_circle),
                  title: Text(
                    placeholder ? "Setting" : "Sitting",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  trailing: Switch(
                    value: placeholder,
                    onChanged: (bool value) {
                      setState(() {
                        placeholder = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          MapWidget(
            onMapCreated: _onMapCreated,
            cameraOptions: camera,
            styleUri: themeState.theme == ThemeMode.dark
                ? MapboxStyles.DARK
                : MapboxStyles.STANDARD,
          ),
          DraggableScrollableSheet(
              minChildSize: 0.1,
              maxChildSize: 0.6,
              initialChildSize: 0.4,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        topLeft: Radius.circular(20),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Navigator(
                          key: navigatorKey,
                          onGenerateRoute: (route) => MaterialPageRoute(
                            settings: route,
                            builder: (context) => searchView(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              })
        ],
      ),
    );
  }

  TimeOfDay? startTime = TimeOfDay.now();
  DateTime startDate = DateTime.now();
  DateFormat greatFormat = DateFormat("dd-MM-yyyy");
  Column searchView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Routing",
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 30,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fromController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.place),
                border: OutlineInputBorder(),
                hintText: 'Origin',
              ),
            ),
            TextField(
              controller: toController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.place),
                border: OutlineInputBorder(),
                hintText: 'Destination',
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    startTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    setState(() {});
                  },
                  label: Text(startTime!.format(context)),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    startDate = (await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
                        lastDate: DateTime(102111111989749)))!;
                    setState(() {});
                  },
                  label: Text(greatFormat.format(startDate).toString()),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    log("Getting route");
                    var routes = fetchRoute();
                    showRoutes(routes);
                  },
                  label: const Text('Get route'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text("Settings"),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget legBox(Leg leg) {
    if (leg.mode == "WALK") {
      return const Icon(
        Icons.directions_walk,
        size: 18,
      );
    } else if (leg.route?.shortName != null) {
      return Text(
        leg.route!.shortName,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      );
    } else if (leg.route?.longName != null) {
      return Text(
        leg.route!.longName,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      );
    }
    return const Text("NO NAME");
  }

  Column mainView(BuildContext context, List<Itinerary> routes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back_ios),
            ),
            Text(
              "Itineraries",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 30,
              ),
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (Itinerary itinerary in routes)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8.0),
                child: Material(
                  elevation: 5,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                  "${timeToString(itinerary.startTime)} - ${timeToString(itinerary.endTime)}")
                            ],
                          ),
                          routePreview(itinerary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  LayoutBuilder routePreview(Itinerary itinerary) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Row(
              children: [
                for (var leg in itinerary.legs)
                  SizedBox(
                    width: leg.duration /
                        itinerary.duration *
                        constraints.maxWidth,
                    height: 20,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: colorFromRouteType(leg.route?.type),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(4))),
                        child: Center(
                          child: legBox(leg),
                        )),
                  ),
              ],
            ));
  }
}

String timeToString(DateTime time) {
  return "${padNumber10(time.hour)}:${padNumber10(time.minute)}:${padNumber10(time.second)}";
}

String padNumber10(number) {
  return number < 10 ? "0$number" : number.toString();
}

Color colorFromRouteType(int? route_type) {
  switch (route_type) {
    case null: //walk
      return Colors.grey;
    case 0: //tram
      return Colors.green;
    case 1: //metro
      return Colors.red;
    case 4: //ferry
      return Colors.teal;
    case 102: //long distance train
      return Colors.green;
    case 109: //short distance train
      return Colors.purple;
    case 3: //bus
    case 700: //bus
    case 701: //bus
      return Colors.blue;
    case 702: //trunk bus
      return const Color(0xffEA7000);
    case 704: //lähibussi
    case 712: //lähibussi
      return Colors.cyan;
    case 900: //speedtram
      return const Color(0xff006400);
    case 1104: //airplane
      return const Color(0xff00008B);
    default:
      return Colors.pink;
  }
}

epicFunction() {}
