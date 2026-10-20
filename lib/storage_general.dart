import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class Storage {
  Storage({required this.containerName}) {
    storageBox = GetStorage(containerName);
  }

  final String containerName;
  late final GetStorage storageBox;

  DateTime lastModified = DateTime.now();

  void writeToStorage(String key, dynamic data) {
    storageBox.write(key, data);
  }

  void writeToStorageThrottled(String key, dynamic data) {
    DateTime now = DateTime.now();
    if (now.difference(lastModified).inSeconds < 1) {
      return;
    } else {
      lastModified = now;
      writeToStorage(key, data);
    }
  }

  void writeListToStorage(String key, List<dynamic> data) {
    writeToStorage(
      key,
      jsonEncode(data.map((e) => e.toJson()).toList()),
    );
  }

  void writeMapToStorage(String key, Map<String, dynamic> data) {
    writeToStorage(key, jsonEncode(data));
  }

  dynamic readFromStorage(String key, dynamic defaultValue) {
    return storageBox.read(key) ?? defaultValue;
  }

  List<dynamic> readListFromStorage(String key) {
    return jsonDecode(readFromStorage(key, jsonEncode([]))) ?? [];
  }

  Map<String, dynamic> readMapFromStorage(String key) {
    return jsonDecode(readFromStorage(key, jsonEncode({}))) ?? {};
  }

  static dynamic tryLoadingJson(Function action, dynamic defaultValue) {
    try {
      return action();
    } catch (_) {
      return defaultValue;
    }
  }
}
