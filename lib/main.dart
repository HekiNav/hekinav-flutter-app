import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hekinav/pages/main_page.dart';
import 'package:hekinav/pages/routing_page.dart';
import 'package:hekinav/pages/settings_page.dart';
import 'package:hekinav/icon/search_icons_icons.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

Future loadTokens() async {
  return json.decode(
      await rootBundle.loadString('auth/secrets.json'))['MAPBOX_SECRET_TOKEN'];
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pass your access token to MapboxOptions so you can load a map
  var ACCESS_TOKEN = /* await loadTokens(); */
      const String.fromEnvironment("ACCESS_TOKEN");
  MapboxOptions.setAccessToken(ACCESS_TOKEN);

  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
      ),
    ], child: const MyApp()),
  );
}

class ThemeProvider with ChangeNotifier {
  var theme = ThemeMode.light;

  dynamic toggleTheme(bool isDark) {
    theme = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

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
