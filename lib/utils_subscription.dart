import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:taskbreakdown/providers.dart';
import 'package:taskbreakdown/storage_purchases.dart';
import 'app_config.dart';

Future<List<IAPItem>> getSubscriptions() async {
  if (AppConfig.demoMode) return [];
  await FlutterInappPurchase.instance.isReady();
  List<IAPItem> items = await FlutterInappPurchase.instance
      .getSubscriptions(["com.dremmi.taskbreakdown.premium"]);
  return items;
}

Future<bool> verifyPurchase(
  String? purchaseToken,
) async {
  if (AppConfig.demoMode) {
    throw StateError(
        'Purchase verification is disabled in the portfolio demo.');
  }
  if (purchaseToken == null) {
    return false;
  }

  final url = AppConfig.purchaseVerificationUrl();
  try {
    final response = await http.post(
      url,
      body: purchaseToken,
    );
    if (response.statusCode == 200 && response.body == '1') {
      return true;
    } else {
      return false;
    }
  } on HandshakeException catch (_) {
    Fluttertoast.showToast(msg: "Connection terminated. Please try again.");
    return false;
  }
}

Future<void> verifyPurchaseOnLoad(BuildContext context) async {
  if (AppConfig.demoMode) return;
  try {
    final purchases =
        await FlutterInappPurchase.instance.getAvailablePurchases();
    if (!context.mounted || purchases == null || purchases.isEmpty) {
      return;
    }

    final storagePurchases = StoragePurchases();
    final invalidSubscriptions = storagePurchases.readInvalidSubscriptions();
    final provider = Provider.of<TreeProvider>(context, listen: false);

    for (final purchase in purchases) {
      final token = purchase.purchaseToken;
      if (token != null && !invalidSubscriptions.contains(token)) {
        provider.setLoading(true);
        try {
          final purchaseValid = await verifyPurchase(token);
          if (!context.mounted) {
            return;
          }
          if (!purchaseValid) {
            storagePurchases.addInvalidSubscription(token);
            provider.setPro(false);
          } else {
            provider.setPro(true);
          }
        } finally {
          if (context.mounted) {
            provider.setLoading(false);
          }
        }
      }
    }
  } on PlatformException catch (error, stackTrace) {
    debugPrint('Unable to check subscription purchases: '
        '${error.code}: ${error.message}');
    debugPrintStack(stackTrace: stackTrace);
    if (context.mounted) {
      await Fluttertoast.showToast(
        msg: 'Unable to check your subscription. Please try again later.',
      );
    }
  }
}
