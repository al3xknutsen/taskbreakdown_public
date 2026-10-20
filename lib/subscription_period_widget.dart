import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'app_config.dart';

class SubscriptionPeriodWidget extends StatelessWidget {
  const SubscriptionPeriodWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.price,
    required this.currencySymbol,
    this.trialPrice,
    this.trialPeriod,
    required this.productId,
    required this.offerTokenIndex,
  });

  final String title;
  final String? subtitle;
  final double price;
  final String currencySymbol;
  final double? trialPrice;
  final String? trialPeriod;
  final String? productId;
  final int offerTokenIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        child: InkWell(
          onTap: AppConfig.demoMode
              ? null
              : () {
                  FlutterInappPurchase.instance.requestSubscription(
                    productId!,
                    prorationModeAndroid:
                        AndroidProrationMode.IMMEDIATE_WITH_TIME_PRORATION,
                    offerTokenIndex: offerTokenIndex,
                  );
                },
          child: SizedBox(
            height: 100,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      subtitle != null
                          ? Text(
                              subtitle!,
                              softWrap: true,
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, right: 3),
                        child: Text(
                          currencySymbol,
                        ),
                      ),
                      Text(
                        price.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text("/mo"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
