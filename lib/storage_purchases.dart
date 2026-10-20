import 'package:flutter/material.dart';
import 'package:taskbreakdown/storage_general.dart';

class StoragePurchases extends Storage {
  static const key = "purchases";
  StoragePurchases() : super(containerName: key);

  List<String> readInvalidSubscriptions() {
    return List<String>.from(readFromStorage(key, []));
  }

  void writeInvalidSubscriptions(List<String> purchaseTokens) {
    writeToStorage(key, purchaseTokens);
  }

  void addInvalidSubscription(String purchaseToken) {
    List<String> invalidSubscriptions = readInvalidSubscriptions();
    invalidSubscriptions.add(purchaseToken);
    debugPrint(invalidSubscriptions.toString());
    writeInvalidSubscriptions(invalidSubscriptions);
  }
}
