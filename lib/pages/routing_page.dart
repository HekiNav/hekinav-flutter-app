import 'package:flutter/material.dart';
import 'package:hekinav/main.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

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
  late MapboxMap mapboxMap;

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
  }

  @override
  Widget build(BuildContext context) {
    var themeState = context.watch<ThemeProvider>();
    return Stack(
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
                      child: Column(
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
                              const Card(
                                child: TextField(
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.place),
                                    border: OutlineInputBorder(),
                                    hintText: 'Origin',
                                  ),
                                ),
                              ),
                              const Card(
                                child: TextField(
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.place),
                                    border: OutlineInputBorder(),
                                    hintText: 'Destination',
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  print("Getting route");
                                },
                                label: const Text('Get route'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            })
      ],
    );
  }
}
