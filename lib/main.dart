import 'dart:convert';
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hekinav/pages/main_page.dart';
import 'package:hekinav/pages/routing_page.dart';
import 'package:hekinav/pages/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import './models/route.dart';
import 'package:graphql/client.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Pass your access token to MapboxOptions so you can load a map
  String ACCESS_TOKEN = "sk.eyJ1IjoiaGVraW5hdiIsImEiOiJjbTM4cHBsaWwwcTgzMmpzNWlmNjBoN3IwIn0.rOgUhgiyHa8iXB2p0OWHIw";
  MapboxOptions.setAccessToken(ACCESS_TOKEN);


  runApp(MultiProvider(providers: [
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
      ),
    ], child: const MyApp()),);

  fetchRoute();
}

class ThemeProvider with ChangeNotifier {
  var theme = ThemeMode.system;

  dynamic toggleTheme(bool isDark) {
    theme = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
final GraphQLClient client = GraphQLClient(
    cache: GraphQLCache(),
    link: HttpLink(
        "https://api.digitransit.fi/routing/v1/routers/hsl/index/graphql?digitransit-subscription-key=bbc7a56df1674c59822889b1bc84e7ad"),
);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class MyAppState extends ChangeNotifier {
  var playedAnimation = false;
  void AnimationPlayed() {
    playedAnimation = true;
    notifyListeners();
  }

  var currentPage = 0;
  void switchPage(index) {
    currentPage = index;
    notifyListeners();
  }
}

class _MyAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.system;
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ),
        themeMode: Provider.of<ThemeProvider>(context).theme,

        home: const MyHomePage(),
      ),
    );
  }
}

Future fetchRoute() async {
  String routeRequest = """
  {
  plan(
    from: {lat: 60.168992, lon: 24.932366}
    to: {lat: 60.175294, lon: 24.684855}
    numItineraries: 3
  ) {
    itineraries {
      startTime
      legs {
        startTime
        endTime
        mode
        duration
        realTime
        distance
        transitLeg
      }
    }
  }
}
""";

  final QueryOptions options = QueryOptions(document: gql(routeRequest));

  final QueryResult result = await client.query(options);

  var data = Itinerary.fromJson(result.data);
  print(data.startTime);
  print(data.endTime);
  return(data);
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    Widget page;
    switch (appState.currentPage) {
      case 0:
        page = const MainPage();
        break;
      case 1:
        page = const RoutingPage();
        break;
      case 2:
        page = const SettingsPage();
        break;
      default:
        throw UnimplementedError('no widget for ${appState.currentPage}');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        bottomNavigationBar: NavigationBar(
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.alt_route),
              label: 'Routing',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings),
              label: 'Settings',
            )
          ],
          selectedIndex: appState.currentPage,
          onDestinationSelected: (value) {
            appState.switchPage(value);
          },
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

Future fetchData(url) async {
  final response = await http.post(Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/graphql',
      },
      body: jsonEncode(<String>{
        '{"query":"{\n  plan(\n    from: {lat: 60.168992, lon: 24.932366}\n    to: {lat: 60.175294, lon: 24.684855}\n    numItineraries: 3\n  ) {\n    itineraries {\n      startTime\n      endTime\n      legs {\n        startTime\n        endTime\n        mode\n        duration\n        realTime\n        distance\n        transitLeg\n      }\n    }\n  }\n}"}'
      }));
  print(response);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final route = Itinerary.fromJson(
      data[1],
    );
    log("fetch return");
    return (route);
  } else {
    throw Exception('Failed to fetch');
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      elevation: 20,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          text,
          style: style,
        ),
      ),
    );
  }
}
