import 'package:flutter/material.dart';
import 'package:hekinav/main.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

Future sleep1() {
  return Future.delayed(const Duration(seconds: 1), () => "1");
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/images/background.png"),
              fit: BoxFit.cover)),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(20))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          const BigCard(text: "Hekinav"),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              appState.switchPage(1);
            },
            label: const Text('Go to routing'),
          ),
        ]),
      ),
    )
        ]),
      ),
    );
  }
}