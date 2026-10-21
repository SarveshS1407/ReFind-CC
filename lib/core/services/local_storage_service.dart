import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/item_model.dart';
import '../models/claim_model.dart';
import '../models/user_model.dart';
import '../models/sync_task.dart';

class LocalStorageService {
  static const String _keyItems = 'fk_cached_items_v1';
  static const String _keyClaims = 'fk_cached_claims_v1';
  static const String _keyDraft = 'fk_report_draft_v1';
  static const String _keyOutbox = 'fk_offline_outbox_v1';
  static const String _keyUser = 'fk_current_user_v1';
  static const String _keySimulateOffline = 'fk_simulate_offline_v1';
  static const String _keyThemeMode = 'fk_theme_mode_v1';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // --- Offline Simulation Toggle ---
  bool isSimulatedOffline() {
    return _prefs.getBool(_keySimulateOffline) ?? false;
  }

  Future<void> setSimulatedOffline(bool value) async {
    await _prefs.setBool(_keySimulateOffline, value);
  }

  // --- Theme Mode ---
  String? getThemeMode() {
    return _prefs.getString(_keyThemeMode);
  }

  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  // --- User Session ---
  AppUser? getUser() {
    final raw = _prefs.getString(_keyUser);
    if (raw == null) return null;
    try {
      return AppUser.fromMap(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(AppUser user) async {
    await _prefs.setString(_keyUser, jsonEncode(user.toMap()));
  }

  Future<void> clearUser() async {
    await _prefs.remove(_keyUser);
  }

  // --- Items Cache ---
  List<ItemModel> getItems() {
    final raw = _prefs.getStringList(_keyItems);
    if (raw == null) return [];
    try {
      return raw.map((str) => ItemModel.fromMap(jsonDecode(str))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveItems(List<ItemModel> items) async {
    final raw = items.map((item) => jsonEncode(item.toMap())).toList();
    await _prefs.setStringList(_keyItems, raw);
  }

  // --- Claims Cache ---
  List<ClaimModel> getClaims() {
    final raw = _prefs.getStringList(_keyClaims);
    if (raw == null) return [];
    try {
      return raw.map((str) => ClaimModel.fromMap(jsonDecode(str))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveClaims(List<ClaimModel> claims) async {
    final raw = claims.map((c) => jsonEncode(c.toMap())).toList();
    await _prefs.setStringList(_keyClaims, raw);
  }

  // --- Interrupted Report Draft Preservation ---
  Map<String, dynamic>? getReportDraft() {
    final raw = _prefs.getString(_keyDraft);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveReportDraft(Map<String, dynamic> draft) async {
    await _prefs.setString(_keyDraft, jsonEncode(draft));
  }

  Future<void> clearReportDraft() async {
    await _prefs.remove(_keyDraft);
  }

  // --- Offline Sync Outbox Queue ---
  List<OfflineSyncTask> getOutboxTasks() {
    final raw = _prefs.getStringList(_keyOutbox);
    if (raw == null) return [];
    try {
      return raw
          .map((str) => OfflineSyncTask.fromMap(jsonDecode(str)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOutboxTasks(List<OfflineSyncTask> tasks) async {
    final raw = tasks.map((t) => jsonEncode(t.toMap())).toList();
    await _prefs.setStringList(_keyOutbox, raw);
  }

  Future<void> addOutboxTask(OfflineSyncTask task) async {
    final tasks = getOutboxTasks();
    tasks.add(task);
    await saveOutboxTasks(tasks);
  }

  Future<void> removeOutboxTask(String taskId) async {
    final tasks = getOutboxTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await saveOutboxTasks(tasks);
  }
}
