import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'providers.dart'; // Update this import
import 'subscription_page.dart'; // Add this import

import 'banner.dart';
import 'app_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoGenerateAIList = false;
  bool _autoStartSpeechToText = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoGenerateAIList = prefs.getBool('autoGenerateAIList') ?? false;
      _autoStartSpeechToText =
          prefs.getBool('autoStartSpeechToText') ?? false; // Add this line
    });
  }

  Future<void> _updateAutoGenerateAIList(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoGenerateAIList = value;
      prefs.setBool('autoGenerateAIList', value);
    });
  }

  Future<void> _updateAutoStartSpeechToText(bool value) async {
    // Add this method
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoStartSpeechToText = value;
      prefs.setBool('autoStartSpeechToText', value);
    });
  }

  Future<void> _factoryReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _autoGenerateAIList = false;
      _autoStartSpeechToText = false;
    });
    Provider.of<TreeProvider>(context, listen: false).reset();
    Navigator.pop(context); // Navigate back to the main screen
  }

  Future<void> _showResetConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Reset'),
          content: const Text(
              'This action will delete all data and is irreversible. Do you want to proceed?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                // Navigator.of(context).pop(); // Close the dialog
                _factoryReset(); // Perform the reset
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SwitchListTile(
                    // Add this block
                    title: const Text(
                        'Automatically start speech-to-text after creating a new tree'),
                    value: _autoStartSpeechToText,
                    onChanged: _updateAutoStartSpeechToText,
                  ),
                  Consumer<TreeProvider>(
                    builder: (context, treeProvider, child) {
                      return GestureDetector(
                        onTap: treeProvider.isPro
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SubscriptionPage(),
                                  ),
                                );
                              },
                        child: AbsorbPointer(
                          absorbing: !treeProvider.isPro,
                          child: SwitchListTile(
                            title: const Text(AppConfig.demoMode
                                ? 'Add sample subtasks after speech-to-text'
                                : 'Auto-generate task subtree after speech-to-text'),
                            value: treeProvider.isPro
                                ? _autoGenerateAIList
                                : false,
                            onChanged: treeProvider.isPro
                                ? _updateAutoGenerateAIList
                                : null,
                            activeColor:
                                treeProvider.isPro ? null : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (!AppConfig.demoMode)
                    ElevatedButton(
                      onPressed: () {
                        TreeProvider treeProvider =
                            Provider.of<TreeProvider>(context, listen: false);

                        if (treeProvider.isPro) {
                          launchUrl(
                            Uri.parse(
                              "https://play.google.com/store/account/subscriptions?package=com.dremmi.taskbreakdown",
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SubscriptionPage(),
                            ),
                          );
                        }
                      },
                      child: const Text('Manage subscription'),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showResetConfirmationDialog,
                    style: ElevatedButton.styleFrom(
                      surfaceTintColor: Colors.red,
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
