import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

/// Hive box names
const String kCustomersBox = 'customers';
const String kTransactionsBox = 'transactions';
const String kSettingsBox = 'settings';
const String kPendingMutationsBox = 'pending_mutations';

/// Hive local storage service for offline support
class LocalStorage {
  static late Box _customersBox;
  static late Box _transactionsBox;
  static late Box _settingsBox;
  static late Box _pendingMutationsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _customersBox = await Hive.openBox(kCustomersBox);
    _transactionsBox = await Hive.openBox(kTransactionsBox);
    _settingsBox = await Hive.openBox(kSettingsBox);
    _pendingMutationsBox = await Hive.openBox(kPendingMutationsBox);
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  static T? getSetting<T>(String key) => _settingsBox.get(key) as T?;
  static Future<void> setSetting(String key, dynamic value) =>
      _settingsBox.put(key, value);

  // ── Customers ─────────────────────────────────────────────────────────────
  static List<Map> getCachedCustomers() {
    return _customersBox.values
        .whereType<String>()
        .map((s) => json.decode(s) as Map)
        .toList();
  }

  static Future<void> cacheCustomers(List<Map<String, dynamic>> customers) async {
    await _customersBox.clear();
    for (final c in customers) {
      await _customersBox.put(c['id'], json.encode(c));
    }
  }

  static Future<void> updateCachedCustomer(Map<String, dynamic> customer) async {
    await _customersBox.put(customer['id'], json.encode(customer));
  }

  static Future<void> deleteCachedCustomer(String id) async {
    await _customersBox.delete(id);
  }

  // ── Transactions ──────────────────────────────────────────────────────────
  static List<Map> getCachedTransactions() {
    return _transactionsBox.values
        .whereType<String>()
        .map((s) => json.decode(s) as Map)
        .toList();
  }

  static Future<void> cacheTransactions(List<Map<String, dynamic>> txns) async {
    for (final t in txns) {
      await _transactionsBox.put(t['id'], json.encode(t));
    }
  }

  // ── Pending Mutations (Offline Queue) ─────────────────────────────────────
  static Future<void> queueMutation(Map<String, dynamic> mutation) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _pendingMutationsBox.put(id, json.encode(mutation));
  }

  static List<Map<String, dynamic>> getPendingMutations() {
    return _pendingMutationsBox.values
        .whereType<String>()
        .map((s) => json.decode(s) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> clearPendingMutations() async {
    await _pendingMutationsBox.clear();
  }

  static Future<void> clearAll() async {
    await _customersBox.clear();
    await _transactionsBox.clear();
    await _settingsBox.clear();
    await _pendingMutationsBox.clear();
  }
}

/// Local Storage Provider
final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());
