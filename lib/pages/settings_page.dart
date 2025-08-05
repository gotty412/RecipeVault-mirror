import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_notifier.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('ダークテーマ'),
            subtitle: const Text('ライト / ダーク / 端末設定に従う'),
            trailing: DropdownButton<ThemeMode>(
              value: notifier.mode,
              onChanged: (mode) => notifier.update(mode!),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('システム')),
                DropdownMenuItem(value: ThemeMode.light,  child: Text('ライト')),
                DropdownMenuItem(value: ThemeMode.dark,   child: Text('ダーク')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
