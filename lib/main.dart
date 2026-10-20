import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:taskbreakdown/utils_subscription.dart';

import 'app_config.dart';
import 'firebase_options.dart';
import 'providers.dart';
import 'simple_tree_view.dart';
import 'speech_to_text_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppConfig.demoMode) {
    AppConfig.purchaseVerificationUrl();
    AppConfig.reviewerVerificationUrl();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await MobileAds.instance.initialize();
    await FlutterInappPurchase.instance.initialize();
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => TreeProvider()),
    ChangeNotifierProvider(create: (context) => RecognizedTextProvider()),
    ChangeNotifierProvider(create: (context) => CircleSizeProvider()),
    ChangeNotifierProvider(create: (context) => SpeechToTextModel()),
  ], child: const MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Timer? verifySubscriptionTimer;

  @override
  initState() {
    super.initState();
    if (AppConfig.demoMode) return;
    verifyPurchaseOnLoad(context);
    verifySubscriptionTimer = Timer.periodic(
      const Duration(days: 1),
      (timer) => verifyPurchaseOnLoad(context),
    );
  }

  @override
  void dispose() {
    if (!AppConfig.demoMode) {
      FlutterInappPurchase.instance.finalize();
    }
    verifySubscriptionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (AppConfig.demoMode)
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Portfolio demo - premium unlocked. '
                    'Task generation uses local samples, not AI.',
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(child: SimpleTreeView()),
            ],
          ),
        ),
      ),
    );
  }
}
