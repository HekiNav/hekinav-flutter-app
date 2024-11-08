import 'package:flutter/material.dart';
import 'package:hekinav/main.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    var themeState = context.watch<ThemeProvider>();
    return ListView(children: [
      const BigCard(text: "Settings"),
      ListTile(
        title: const Text("Dark mode"),
        trailing: Switch.adaptive(
          value: themeState.theme == ThemeMode.dark ? true : false,
          onChanged: (state) {
              themeState.toggleTheme(state);
            }
          ),
      )
      ]);
  }
}
