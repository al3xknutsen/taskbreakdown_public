import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:taskbreakdown/banner.dart';
import 'package:taskbreakdown/main.dart';
import 'package:taskbreakdown/providers.dart';
import 'package:taskbreakdown/subscription_period_widget.dart';
import 'package:taskbreakdown/utils_subscription.dart';
import 'app_config.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late Future<List<IAPItem>> _products;
  StreamSubscription<PurchasedItem?>? purchaseUpdated;
  StreamSubscription<PurchaseResult?>? purchaseError;
  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (AppConfig.demoMode) return;

    _products = getSubscriptions();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      TreeProvider treeProvider =
          Provider.of<TreeProvider>(context, listen: false);

      purchaseUpdated =
          FlutterInappPurchase.purchaseUpdated.listen((productItem) {
        if (productItem?.productId == "com.dremmi.taskbreakdown.premium" &&
            productItem?.purchaseStateAndroid == PurchaseState.purchased &&
            productItem?.purchaseToken != null) {
          // settingsModel.setLoading(true);
          debugPrint("Verifying purchase...");
          verifyPurchase(
            productItem?.purchaseToken,
          ).then((value) {
            if (value) {
              debugPrint("Verified!");
              FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
                productItem?.purchaseToken ?? "",
              );
              treeProvider.setPro(true);
              treeProvider.setLoading(false);
              // settingsModel.setPro(true);
              // settingsModel.setLoading(false);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainApp()),
                (Route<dynamic> route) => false,
              );
            }
          });
        } else {
          treeProvider.setPro(false);
          // settingsModel.setPro(false);
          // SHOW ERROR MESSAGE
          showDialog(
            context: context,
            builder: (context) => const AlertDialog(
              title: Text("Error"),
              content: Text("Something went wrong! Please try again."),
            ),
          );
        }
      });

      purchaseError =
          FlutterInappPurchase.purchaseError.listen((purchaseError) {
        print('purchase-error: $purchaseError');
        treeProvider.setPro(false);
        // settingsModel.setPro(false);
        print(purchaseError?.responseCode);
        if (![1, 7].contains(purchaseError?.responseCode)) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Error"),
              content: Text(purchaseError?.message ?? ""),
            ),
          );
        }
      });
    });
  }

  Map<String, dynamic> getSubscriptionInfo(IAPItem? item, String basePlanId) {
    if (item == null) {
      return {};
    }

    List<String?> offerTokens =
        item.subscriptionOffersAndroid?.map((e) => e.offerToken).toList() ?? [];

    List<SubscriptionOfferAndroid>? androidMonthlySubscriptionOffers =
        item.subscriptionOffersAndroid
            ?.where(
              (element) => element.basePlanId == basePlanId,
            )
            .toList();
    List<SubscriptionOfferAndroid> relevantOffers =
        androidMonthlySubscriptionOffers
                ?.where(
                  (element) => element.pricingPhases?.length == 2,
                )
                .toList() ??
            [];

    double? trialPrice;
    String? trialPeriod;
    double fullPrice;
    int offerTokenIndex;

    if (relevantOffers.isEmpty) {
      SubscriptionOfferAndroid? thisOffer =
          androidMonthlySubscriptionOffers?.first;
      if (thisOffer == null) {
        return {};
      }
      List<PricingPhaseAndroid>? pricingPhases = thisOffer.pricingPhases;
      trialPrice = null;
      trialPeriod = null;
      fullPrice = double.tryParse(pricingPhases?[0].price ?? "0.0") ?? 0.0;
      offerTokenIndex = offerTokens.indexOf(thisOffer.offerToken ?? "");
    } else {
      SubscriptionOfferAndroid thisOffer = relevantOffers.first;
      List<PricingPhaseAndroid>? pricingPhases = thisOffer.pricingPhases;
      trialPrice = double.tryParse(pricingPhases?[0].price ?? "0.0") ?? 0.0;
      trialPeriod = pricingPhases?[0].billingPeriod ?? "";
      fullPrice = double.tryParse(pricingPhases?[1].price ?? "0.0") ?? 0.0;
      offerTokenIndex = offerTokens.indexOf(thisOffer.offerToken ?? "");
    }

    return {
      "trialPrice": trialPrice,
      "trialPeriod": trialPeriod,
      "fullPrice": fullPrice,
      "offerTokenIndex": offerTokenIndex,
    };
  }

  @override
  void dispose() {
    super.dispose();
    purchaseUpdated?.cancel();
    purchaseError?.cancel();
    _couponController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.demoMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Portfolio demo')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Premium features are unlocked. Purchases are disabled. '
            'Task generation uses local sample subtasks, not live AI.',
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscribe to unlock premium features:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const ListTile(
              leading: Icon(Icons.auto_awesome),
              title: Text('Access to AI completion'),
              subtitle: Text('Generate multi-level task trees using AI.'),
            ),
            const ListTile(
              leading: Icon(Icons.block),
              title: Text('No ads'),
              subtitle: Text('Enjoy an ad-free experience.'),
            ),
            const ListTile(
              leading: Icon(Icons.free_breakfast),
              title: Text('7-day free trial'),
              subtitle: Text('Try all premium features for free for 7 days.'),
            ),
            const SizedBox(height: 20),
            FutureBuilder(
              future: _products,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const CircularProgressIndicator();
                }

                Map<String, dynamic> subscriptionInfo = getSubscriptionInfo(
                  snapshot.data?[0],
                  "monthly",
                );

                if (subscriptionInfo.isEmpty) {
                  return const SizedBox.shrink();
                }

                return SubscriptionPeriodWidget(
                  title: "Monthly",
                  trialPrice: subscriptionInfo["trialPrice"],
                  trialPeriod: subscriptionInfo["trialPeriod"],
                  price: subscriptionInfo["fullPrice"],
                  currencySymbol: snapshot.data?[0].currency ?? "",
                  productId: snapshot.data?[0].productId ?? "",
                  offerTokenIndex: subscriptionInfo["offerTokenIndex"],
                );
              },
            ),
            FutureBuilder(
              future: _products,
              builder: (context, snapshot) {
                debugPrint("snapshot: $snapshot");
                if (snapshot.connectionState != ConnectionState.done) {
                  return const CircularProgressIndicator();
                }

                Map<String, dynamic> subscriptionInfo = getSubscriptionInfo(
                  snapshot.data?[0],
                  "yearly",
                );
                debugPrint("subscriptionInfo: $subscriptionInfo");

                if (subscriptionInfo.isEmpty) {
                  return const SizedBox.shrink();
                }

                return SubscriptionPeriodWidget(
                  title: "Yearly",
                  subtitle:
                      "${snapshot.data?[0].currency ?? ""} ${subscriptionInfo["fullPrice"].toStringAsFixed(2)} yearly",
                  trialPrice: subscriptionInfo["trialPrice"],
                  trialPeriod: subscriptionInfo["trialPeriod"],
                  price: subscriptionInfo["fullPrice"] / 12,
                  currencySymbol: snapshot.data?[0].currency ?? "",
                  productId: snapshot.data?[0].productId ?? "",
                  offerTokenIndex: subscriptionInfo["offerTokenIndex"],
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'You can cancel the subscription period at any time within the 7 days to avoid being charged. '
              'After the trial period, the subscription will automatically convert to a paid subscription.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: const InputDecoration(
                      hintText: 'Coupon code',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Consumer<TreeProvider>(
                  builder: (context, treeProvider, child) => ElevatedButton(
                    onPressed: () async {
                      final couponCode = _couponController.text;
                      // Use couponCode as needed
                      final url = AppConfig.reviewerVerificationUrl();
                      try {
                        final response = await http.post(
                          url,
                          body: couponCode,
                        );
                        if (response.statusCode == 200 &&
                            response.body == '1') {
                          treeProvider.setPro(true);
                          Fluttertoast.showToast(
                            msg: "Reviewer verified.",
                          );
                        } else {
                          Fluttertoast.showToast(
                            msg: "Invalid coupon code.",
                          );
                        }
                      } on HandshakeException catch (_) {
                        Fluttertoast.showToast(
                          msg: "Connection terminated. Please try again.",
                        );
                      }
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Center(child: BannerAdWidget()),
          ],
        ),
      ),
    );
  }
}
