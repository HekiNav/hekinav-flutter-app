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
import 'package:hekinav/icon/first_icons_icons.dart';
import 'package:hekinav/models/search_results.dart';

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
    //remove previous markers
    pointAnnotationManager.deleteAll();

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
  void showRoute(Itinerary itinerary, bool selected) async {
    //draw shapes and transfer stops
    for (int i = 0; i < itinerary.legs.length; i++) {
      //get color of route type
      var color =
          colorFromRouteType(selected ? itinerary.legs[i].route?.type : null);

      //google polyline encoded -> [[lat, lon], [lat, lon]]
      var points = PolylineCodec.decode(itinerary.legs[i].geometry.points);

      //[[lat, lon], [lat, lon]] -> [Position, Position]
      List<Position> posList = [];
      for (var point in points) {
        posList.add(Position(point[1], point[0]));
      }

      if (selected) {}

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

  final bottomDrawerKey = GlobalKey<NavigatorState>();
  final searchNavigatorKey = GlobalKey<NavigatorState>();

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
          Navigator(
            key: searchNavigatorKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => mainSheet(),
              );
            },
          )
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
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => searchNavigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => searchPlace("Origin"),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.place),
                  Text("Origin"),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => searchNavigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => searchPlace("Destination"),
                ),
              ),
              child: Container(
                child: const Row(
                  children: [
                    Icon(Icons.place),
                    Text("Destination"),
                  ],
                ),
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
                  onPressed: getRoutes,
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

  void getRoutes() async {
    log("Getting route");
    var routes = fetchRoute();

    var routeList = await routes;
    bottomDrawerKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => mainView(context, routeList),
      ),
    );
    final ByteData bytesR = await rootBundle.load('assets/images/pin_red.png');
    final Uint8List imageDataR = bytesR.buffer.asUint8List();

    final ByteData bytesG =
        await rootBundle.load('assets/images/pin_green.png');
    final Uint8List imageDataG = bytesG.buffer.asUint8List();

    pointAnnotationManager.create(PointAnnotationOptions(
      geometry: Point(
        coordinates: Position(
            routeList[0].legs[0].from.lon, routeList[0].legs[0].from.lat),
      ), // Example coordinates
      image: imageDataR,
      iconSize: 0.1,
      iconAnchor: IconAnchor.BOTTOM,
    ));
    pointAnnotationManager.create(PointAnnotationOptions(
      geometry: Point(
        coordinates: Position(
            routeList[0].legs.last.to.lon, routeList[0].legs.last.to.lat),
      ), // Example coordinates
      image: imageDataG,
      iconSize: 0.1,
      iconAnchor: IconAnchor.BOTTOM,
    ));
    selectRoute(routeList, 0);
  }

  void selectRoute(List routeList, int index) {
    circleAnnotationManager.deleteAll();
    polylineAnnotationManager.deleteAll();
    for (var i = 0; i < routeList.length; i++) {
      Itinerary itinerary = routeList[i];
      if (i != index) {
        showRoute(itinerary, false);
      }
    }
    showRoute(routeList[index], true);
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

  Column mainView(BuildContext context, List routes) {
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
            for (var i = 0; i < routes.length; i++)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8.0),
                child: InkWell(
                  onTap: () => selectRoute(routes, i),
                  child: Material(
                    elevation: 5,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
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
                                    "${timeToString(routes[i].startTime)} - ${timeToString(routes[i].endTime)}")
                              ],
                            ),
                            routePreview(routes[i]),
                          ],
                        ),
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

  LayoutBuilder searchPlace(String text) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ElevatedButton(
                  onPressed: () {
                    searchNavigatorKey.currentState?.pop();
                  },
                  child: const Text("Close"),
                ),
                if (text == "Origin")
                  TextField(
                    controller: fromController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.place),
                      border: OutlineInputBorder(),
                      hintText: 'Origin',
                    ),
                  ),
                if (text == "Destination")
                  TextField(
                    controller: toController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.place),
                      border: OutlineInputBorder(),
                      hintText: 'Destination',
                    ),
                  ),
                searchResults(text == "Origin" ? "Tikkurila" : "Latokaski")
              ],
            ),
          ),
        ),
      ),
    );
  }

  LayoutBuilder mainSheet() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            DraggableScrollableSheet(
                minChildSize: 0.1,
                maxChildSize: 0.9,
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
                            key: bottomDrawerKey,
                            onGenerateRoute: (route) => MaterialPageRoute(
                              settings: route,
                              builder: (context) => searchView(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }));
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

Padding searchResults(stopInputString) {
  if (stopInputString == "") {
    return const Padding(
      padding: EdgeInsets.all(0.0),
      child: Center(child: Text("no fooba just yet")),
    );
  } else {
    var data = fetchStops(
        'https://api.digitransit.fi/geocoding/v1/search?digitransit-subscription-key=bbc7a56df1674c59822889b1bc84e7ad&text=$stopInputString&size=1000&sources=gtfsMATKA%2CgtfsHSL%2CgtfsLINKKI%2Cgtfstampere%2CgtfsOULU%2Cgtfsdigitraffic%2CgtfsRauma%2CgtfsHameenlinna%2CgtfsKotka%2CgtfsKouvola%2CgtfsLappeenranta%2CgtfsMikkeli%2CgtfsVaasa%2CgtfsJoensuu%2CgtfsFOLI%2CgtfsLahti%2CgtfsKuopio%2CgtfsRovaniemi%2CgtfsKajaani%2CgtfsSalo%2CgtfsPori%2CgtfsRaasepori%2CgtfsVARELY%2CgtfsHarma%2CgtfsVikingline&layers=stop%2Cstation');
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: FutureBuilder(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                primary: false,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: snapshot.data?.length,
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Row(
                      children: [
                        modeIcon(snapshot.data?[index].mode),
                        const Text(" "),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(snapshot.data?[index].name),
                              stopExtraInfo(snapshot.data?[index]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                });
          } else if (snapshot.hasError) {
            return Center(child: Text('ERROR ${snapshot.error}'));
          }
          // By default, show a loading spinner.
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

Icon modeIcon(mode) {
  return const Icon(Icons.ac_unit);
  if (mode == "BUS") {
    return const Icon(FirstIcons.bus);
  } else if (mode == "RAIL") {
    return const Icon(FirstIcons.train);
  } else if (mode == "TRAM") {
    return const Icon(FirstIcons.tram);
  } else if (mode == "FERRY") {
    return const Icon(FirstIcons.directions_boat);
  } else if (mode == "AIRPLANE") {
    return const Icon(FirstIcons.airplanemode_active);
  } else if (mode == "SPEEDTRAM") {
    return const Icon(Icons.bolt);
  } else {
    return const Icon(Icons.question_mark);
  }
}

Wrap stopExtraInfo(data) {
  return Wrap(
    spacing: 5,
    children: [
      if (data.kunta != null)
        if (data.alue != null)
          Text("${data.kunta} (${data.alue})")
        else
          Text("${data.kunta}"),
      if (data.code != null)
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            color: Color.fromARGB(255, 204, 204, 204),
          ),
          child: Text(" ${data.code} "),
        ),
      if (data.platform != null)
        Wrap(
          children: [
            const Text("platform "),
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                color: Color.fromARGB(255, 204, 204, 204),
              ),
              child: Text(" ${data.platform} "),
            ),
          ],
        )
    ],
  );
}

Future<List> fetchStops(url) async {
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    int length = data['features'].length;
    List resultsList = [];
    for (var i = 0; i < length; i++) {
      resultsList.add(ResultStop.fromJson(data['features'][i]));
    }
    return (resultsList);
  } else {
    throw Exception('Failed to fetch');
  }
}

epicFunction() {}
