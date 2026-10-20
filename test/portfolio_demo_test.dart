import 'package:flutter/material.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskbreakdown/app_config.dart';
import 'package:taskbreakdown/banner.dart';
import 'package:taskbreakdown/main.dart' as app;
import 'package:taskbreakdown/providers.dart';
import 'package:taskbreakdown/settings_page.dart';
import 'package:taskbreakdown/subscription_page.dart';
import 'package:taskbreakdown/utils_subscription.dart';

class _DisabledBillingClient extends Fake implements FlutterInappPurchase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unconfigured production endpoints fail explicitly', () {
    expect(AppConfig.purchaseVerificationUrl, throwsStateError);
    expect(AppConfig.reviewerVerificationUrl, throwsStateError);
  });

  group('portfolio demo', () {
    late FlutterInappPurchase originalClient;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      originalClient = FlutterInappPurchase.instance;
      // Any billing call fails: this fake implements no billing operations.
      FlutterInappPurchase.instance = _DisabledBillingClient();
    });

    tearDown(() {
      FlutterInappPurchase.instance = originalClient;
    });

    test('premium cannot be revoked by subscription state', () {
      final provider = TreeProvider();
      addTearDown(provider.dispose);
      expect(provider.isPro, isTrue);
      provider.setPro(false);
      provider.reset();
      expect(provider.isPro, isTrue);
    });

    test('billing helpers never contact the store or verification server',
        () async {
      expect(await getSubscriptions(), isEmpty);
      await expectLater(verifyPurchase('sample-token'), throwsStateError);
    });

    testWidgets('subscription page displays demo information without billing',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SubscriptionPage()));
      expect(find.textContaining('Purchases are disabled'), findsOneWidget);
      expect(find.text('Apply'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });

    testWidgets('banner never loads ads', (tester) async {
      final provider = TreeProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: Scaffold(body: BannerAdWidget())),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    });

    testWidgets('startup and sample generation work without cloud services',
        (tester) async {
      await tester.runAsync(app.main);
      await tester.pumpAndSettle();
      expect(find.textContaining('Portfolio demo - premium unlocked'),
          findsOneWidget);

      final context = tester.element(find.byType(app.MainApp));
      final provider = context.read<TreeProvider>();
      expect(provider.trees, hasLength(1));
      await verifyPurchaseOnLoad(context);
      final root = provider.trees.single;
      await provider.generateSubtree(root, 'Plan a trip', context);
      await tester.pumpAndSettle();

      expect(root.children, hasLength(3));
      for (final child in root.children.values.cast<TreeNode>()) {
        expect(child.data['content'], startsWith('Sample:'));
        expect(child.children, hasLength(2));
      }
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('trees'), contains('Sample: clarify the goal'));
      expect(provider.isLoading, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('settings expose unlocked samples but no subscription action',
        (tester) async {
      final provider = TreeProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Manage subscription'), findsNothing);
      final tile = find.widgetWithText(
          SwitchListTile, 'Add sample subtasks after speech-to-text');
      expect(tester.widget<SwitchListTile>(tile).onChanged, isNotNull);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('autoGenerateAIList'), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    });
  }, skip: !AppConfig.demoMode);
}
