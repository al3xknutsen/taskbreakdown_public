import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskbreakdown/providers.dart';
import 'package:taskbreakdown/utils_subscription.dart';
import 'package:taskbreakdown/app_config.dart';

class _PurchaseClient extends Fake implements FlutterInappPurchase {
  Future<List<PurchasedItem>?> Function() query = () async => [];
  int availablePurchaseQueries = 0;

  @override
  Future<List<PurchasedItem>?> getAvailablePurchases() {
    availablePurchaseQueries++;
    return query();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterInappPurchase originalClient;
  late _PurchaseClient client;
  late TreeProvider provider;
  late BuildContext context;
  late List<MethodCall> toastCalls;
  const toastChannel = MethodChannel('PonnamKarthik/fluttertoast');

  setUp(() {
    originalClient = FlutterInappPurchase.instance;
    client = _PurchaseClient();
    FlutterInappPurchase.instance = client;
    provider = TreeProvider();
    toastCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (call) async {
      toastCalls.add(call);
      return true;
    });
  });

  tearDown(() {
    FlutterInappPurchase.instance = originalClient;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, null);
    provider.dispose();
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<TreeProvider>.value(
        value: provider,
        child: Builder(builder: (value) {
          context = value;
          return const SizedBox.shrink();
        }),
      ),
    );
  }

  testWidgets('queries current purchases instead of purchase history',
      (tester) async {
    await mount(tester);

    await verifyPurchaseOnLoad(context);

    expect(client.availablePurchaseQueries, 1);
    expect(provider.isLoading, isFalse);
    expect(provider.isPro, isFalse);
    expect(toastCalls, isEmpty);
  }, skip: AppConfig.demoMode);

  testWidgets('reports billing failure without changing existing entitlement',
      (tester) async {
    client.query = () async => throw PlatformException(
          code: 'getAvailableItemsByType',
          message: 'E_UNKNOWN',
        );
    provider.setPro(true);
    await mount(tester);

    await verifyPurchaseOnLoad(context);

    expect(provider.isPro, isTrue);
    expect(provider.isLoading, isFalse);
    expect(toastCalls.single.method, 'showToast');
    expect(
      toastCalls.single.arguments['msg'],
      'Unable to check your subscription. Please try again later.',
    );
  }, skip: AppConfig.demoMode);

  testWidgets('handles a null purchase list', (tester) async {
    client.query = () async => null;
    await mount(tester);

    await verifyPurchaseOnLoad(context);

    expect(provider.isPro, isFalse);
    expect(provider.isLoading, isFalse);
    expect(toastCalls, isEmpty);
  }, skip: AppConfig.demoMode);

  testWidgets('does not use a disposed context after the store query',
      (tester) async {
    final purchases = Completer<List<PurchasedItem>?>();
    client.query = () => purchases.future;
    await mount(tester);
    final verification = verifyPurchaseOnLoad(context);
    await tester.pumpWidget(const SizedBox.shrink());

    purchases.complete([
      PurchasedItem.fromJSON({'purchaseToken': 'valid-token'}),
    ]);
    await verification;

    expect(provider.isPro, isFalse);
    expect(toastCalls, isEmpty);
  }, skip: AppConfig.demoMode);
}
