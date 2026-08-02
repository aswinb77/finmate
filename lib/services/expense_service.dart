import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../models/entry_record.dart';
import '../models/activity_log.dart';
import 'local_storage_service.dart';
import 'auth_service.dart';
import 'sync_service.dart';

// ── Category info ────────────────────────────────────────────────────────
class CategoryInfo {
  final String name;
  final String emoji;
  final Color color;
  const CategoryInfo(this.name, this.emoji, this.color);
}

// ── Fun fact template ────────────────────────────────────────────────────
class _FunFactTemplate {
  final String item;
  final int unitPrice;
  const _FunFactTemplate(this.item, this.unitPrice);
}

const _funFactTemplates = [
  _FunFactTemplate('cutting chais at Irani cafe ☕', 15),
  _FunFactTemplate('vada pavs in Mumbai 🌯', 20),
  _FunFactTemplate('samosas from the thela 🥟', 10),
  _FunFactTemplate('plates of pani puri 🥣', 30),
  _FunFactTemplate('idli plates at Saravana Bhavan 🥞', 40),
  _FunFactTemplate('dosas at a local joint 🥞', 60),
  _FunFactTemplate('filter coffees in Chennai ☕', 20),
  _FunFactTemplate('auto rides across town 🛺', 30),
  _FunFactTemplate('bus tickets on BMTC 🚌', 10),
  _FunFactTemplate('metro rides in Delhi 🚇', 25),
  _FunFactTemplate('Maggi packets 🍜', 12),
  _FunFactTemplate('lassi glasses in Jaipur 🥛', 40),
  _FunFactTemplate('coconut waters at the beach 🥥', 40),
  _FunFactTemplate('lime sodas at the juice shop 🍋', 20),
  _FunFactTemplate('sugarcane juice glasses 🧃', 20),
  _FunFactTemplate('egg rolls from the stall 🌯', 50),
  _FunFactTemplate('plates of momos 🥟', 60),
  _FunFactTemplate('bhel puri plates at Chowpatty 🏖️', 30),
  _FunFactTemplate('pav bhaji plates at Juhu 🍛', 80),
  _FunFactTemplate('chole bhature plates 🍛', 70),
  _FunFactTemplate('paratha meals at dhaba 🥞', 60),
  _FunFactTemplate('shawarma wraps at Al Bake 🌯', 120),
  _FunFactTemplate('burgers at local joint 🍔', 80),
  _FunFactTemplate('pizza slices 🍕', 100),
  _FunFactTemplate('ice cream cones 🍦', 30),
  _FunFactTemplate('kulfi sticks from the cart 🍦', 25),
  _FunFactTemplate('mango shakes at Haji Ali 🥭', 50),
  _FunFactTemplate('cold coffees ☕', 60),
  _FunFactTemplate('golgappa rounds 🥣', 20),
  _FunFactTemplate('aloo tikki plates 🥔', 15),
  _FunFactTemplate('jalebi plates 🍩', 40),
  _FunFactTemplate('gulab jamun pieces 🍩', 15),
  _FunFactTemplate('rasgulla pieces 🍮', 20),
  _FunFactTemplate('paan at the corner shop 🌿', 30),
  _FunFactTemplate('newspapers 📰', 5),
  _FunFactTemplate('Uber pool rides 🚕', 50),
  _FunFactTemplate('popcorn tubs at PVR 🍿', 250),
  _FunFactTemplate('single-screen movie tickets 🎬', 100),
  _FunFactTemplate('haircuts at local salon 💇', 100),
  _FunFactTemplate('chai-sutta combos 🚬', 30),
  _FunFactTemplate('books from the roadside 📚', 80),
  _FunFactTemplate('Rapido rides 🏍️', 50),
  _FunFactTemplate('parking hours 🅿️', 20),
  _FunFactTemplate('keema pav plates 🍖', 80),
  _FunFactTemplate('fresh OJ glasses 🍊', 40),
  _FunFactTemplate('local train tickets 🚂', 10),
  _FunFactTemplate('butter chicken plates 🍗', 200),
  _FunFactTemplate('craft beer pints 🍺', 300),
  _FunFactTemplate('potted plants from nursery 🪴', 150),
  _FunFactTemplate('gym day passes 💪', 200),
];

// ── Expense Service (singleton) ─────────────────────────────────────────
class ExpenseService extends ChangeNotifier {
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;
  ExpenseService._internal() {
    _auth.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    loadLocalData(forceReload: true);
  }

  final LocalStorageService _storage = LocalStorageService();
  final AuthService _auth = AuthService();
  final SyncService _sync = SyncService();

  final List<Expense> _expenses = [];
  final List<ChatMessage> _messages = [];
  bool _loadedFromDb = false;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoaded => _loadedFromDb;

  Future<void> loadLocalData({bool forceReload = false}) async {
    if (_loadedFromDb && !forceReload) return;
    try {
      final userId = _auth.currentUser?.uid ?? 'guest_user';
      final records = await _storage.getEntriesForUser(userId);
      _expenses.clear();
      _messages.clear();

      for (final r in records) {
        if (r.type == 'expense') {
          _expenses.add(Expense.fromMap(r.payload));
        }
      }

      // Initialize fresh chat session greeting (chat is session-based & resets on app launch)
      clearChatMessages();
    } catch (e) {
      debugPrint('Error loading local entries: $e');
    } finally {
      _loadedFromDb = true;
      notifyListeners();
    }
  }

  void clearChatMessages() {
    _messages.clear();
    final initialMsg = ChatMessage(
      text:
          'Hey! Tell me what you spent, like "chai 15 rupees" or tap a quick chip below.',
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(initialMsg);
    notifyListeners();
  }

  /// Check if chat session has expired (older than 15 minutes) and clear if needed
  void checkAndClearExpiredChat() {
    if (_messages.length > 1) {
      final lastMsgTime = _messages.last.timestamp;
      if (DateTime.now().difference(lastMsgTime).inMinutes >= 15) {
        clearChatMessages();
      }
    }
  }

  // ── Getters ───────────────────────────────────────────────────────────
  List<Expense> get todayExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.timestamp.year == now.year &&
            e.timestamp.month == now.month &&
            e.timestamp.day == now.day)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  int get todayTotal => todayExpenses.fold(0, (sum, e) => sum + e.amount);

  int get monthTotal {
    final now = DateTime.now();
    return _expenses
        .where(
            (e) => e.timestamp.year == now.year && e.timestamp.month == now.month)
        .fold(0, (sum, e) => sum + e.amount);
  }

  List<Expense> expensesForDate(DateTime date) {
    return _expenses
        .where((e) =>
            e.timestamp.year == date.year &&
            e.timestamp.month == date.month &&
            e.timestamp.day == date.day)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  int monthlyTotalFor(int year, int month) {
    return _expenses
        .where((e) => e.timestamp.year == year && e.timestamp.month == month)
        .fold(0, (sum, e) => sum + e.amount);
  }

  // ── Mutations ─────────────────────────────────────────────────────────
  Future<void> addExpense(Expense expense) async {
    // Ensure expense has UUID
    final finalExpense = expense.id.length > 20
        ? expense
        : expense.copyWith(id: const Uuid().v4());

    _expenses.add(finalExpense);
    notifyListeners();

    await _persistExpense(finalExpense);
    await _logActivity('add_expense');
  }

  Future<void> addMessage(ChatMessage message) async {
    _messages.add(message);
    notifyListeners();
  }

  Future<void> setMood(String expenseId, int mood) async {
    final idx = _expenses.indexWhere((e) => e.id == expenseId);
    if (idx != -1) {
      final updated = _expenses[idx].copyWith(mood: mood);
      _expenses[idx] = updated;
      notifyListeners();

      await _persistExpense(updated);
      await _logActivity('rate_expense_mood');
    }
  }

  Expense? get latestUnratedExpense {
    for (int i = _expenses.length - 1; i >= 0; i--) {
      if (!_expenses[i].hasMood) return _expenses[i];
    }
    return null;
  }

  // ── Persistence Helpers ──────────────────────────────────────────────
  Future<void> _persistExpense(Expense expense) async {
    final userId = _auth.currentUser?.uid ?? 'guest';
    final entry = EntryRecord(
      id: expense.id,
      userId: userId,
      type: 'expense',
      payload: expense.toMap(),
      createdAt: expense.timestamp,
      updatedAt: DateTime.now(),
      synced: false,
    );

    await _storage.saveEntry(entry);
    if (!_auth.isGuest) {
      _sync.refreshUnsyncedCount();
      if (_sync.isOnline) {
        _sync.triggerSync();
      }
    }
  }

  Future<void> _logActivity(String action) async {
    final userId = _auth.currentUser?.uid ?? 'guest';
    final log = ActivityLog(
      userId: userId,
      action: action,
      createdAt: DateTime.now(),
      synced: false,
    );
    await _storage.saveActivityLog(log);
  }

  // ── Vibes aggregation ─────────────────────────────────────────────────
  Map<String, double> get categoryMoodScores {
    final groups = <String, List<int>>{};
    for (final e in _expenses) {
      if (e.hasMood) {
        groups.putIfAbsent(e.category, () => []).add(e.mood!);
      }
    }
    return groups.map((cat, moods) =>
        MapEntry(cat, moods.reduce((a, b) => a + b) / moods.length));
  }

  List<Expense> get weeklyRegrets {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _expenses
        .where((e) => e.mood == 2 && e.timestamp.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<Expense> get weeklyLoved {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _expenses
        .where((e) => e.mood == 0 && e.timestamp.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  int get ratedCount => _expenses.where((e) => e.hasMood).length;

  // ── Natural-language parser ───────────────────────────────────────────
  Expense? parseExpense(String input) {
    final text = input.trim().toLowerCase();
    final cleaned = text
        .replaceAll('rupees', '')
        .replaceAll('rs.', '')
        .replaceAll('rs', '')
        .replaceAll('₹', '')
        .trim();

    final numberMatch = RegExp(r'\d+').firstMatch(cleaned);
    if (numberMatch == null) return null;

    final amount = int.tryParse(numberMatch.group(0)!);
    if (amount == null || amount <= 0) return null;

    var name = cleaned
        .replaceAll(RegExp(r'\d+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (name.isEmpty) return null;

    final cat = _detectCategory(name);
    name = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');

    return Expense(
      id: const Uuid().v4(),
      name: name,
      amount: amount,
      category: cat.name,
      emoji: cat.emoji,
      color: cat.color,
    );
  }

  CategoryInfo _detectCategory(String name) {
    final lower = name.toLowerCase();

    if (_matchesAny(lower, [
      'chai', 'tea', 'coffee', 'thali', 'biryani', 'biriyani',
      'lunch', 'dinner', 'breakfast', 'snack', 'food', 'pizza',
      'burger', 'dosa', 'idli', 'pav', 'bhaji', 'momos', 'momo',
      'roll', 'shawarma', 'swiggy', 'zomato', 'samosa', 'puri',
      'bhel', 'chaat', 'lassi', 'juice', 'shake', 'ice cream',
      'kulfi', 'jalebi', 'sweet', 'cake', 'bread', 'egg', 'paratha',
      'naan', 'roti', 'maggi', 'noodle', 'rice', 'dal', 'paneer',
      'chicken', 'mutton', 'fish', 'kebab', 'tikka', 'manchurian',
      'soup', 'salad', 'fruit', 'biscuit', 'chips',
    ])) {
      return const CategoryInfo('Food', '🍛', Color(0xFFD4826A));
    }

    if (_matchesAny(lower, [
      'auto', 'uber', 'ola', 'taxi', 'cab', 'bus', 'metro',
      'train', 'rapido', 'fuel', 'petrol', 'diesel', 'gas',
      'parking', 'toll', 'ride', 'travel', 'flight',
    ])) {
      return const CategoryInfo('Transit', '🛺', Color(0xFF9BAFD6));
    }

    if (_matchesAny(lower, [
      'movie', 'cinema', 'pvr', 'inox', 'game', 'bowling',
      'concert', 'party', 'outing', 'trip', 'holiday', 'club',
      'bar', 'beer', 'drink', 'alcohol', 'wine', 'pub',
    ])) {
      return const CategoryInfo('Fun', '🎬', Color(0xFFA8CCAC));
    }

    if (_matchesAny(lower, [
      'shopping', 'clothes', 'shirt', 'tshirt', 'shoes', 'amazon',
      'flipkart', 'myntra', 'ajio', 'phone', 'gadget', 'electronics',
      'charger', 'headphone', 'watch', 'bag', 'purse',
    ])) {
      return const CategoryInfo('Shopping', '🛍️', Color(0xFFE8C84A));
    }

    if (_matchesAny(lower, [
      'bill', 'recharge', 'electricity', 'water', 'rent', 'emi',
      'subscription', 'netflix', 'spotify', 'wifi', 'internet',
      'insurance', 'tax',
    ])) {
      return const CategoryInfo('Bills', '📄', Color(0xFFB8A898));
    }

    if (_matchesAny(lower, [
      'doctor', 'medicine', 'medical', 'hospital', 'pharmacy',
      'gym', 'yoga', 'health', 'dental',
    ])) {
      return const CategoryInfo('Health', '💊', Color(0xFF7CB8A8));
    }

    return const CategoryInfo('Other', '📦', Color(0xFFCCC0AE));
  }

  bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  String getBotResponse(Expense expense) {
    final responses = [
      'Got it — logged ₹${expense.amount} under ${expense.category} ${expense.emoji}',
      'Noted! ₹${expense.amount} for ${expense.name} ${expense.emoji}',
      'Done! Added ₹${expense.amount} to ${expense.category} ${expense.emoji}',
      'Logged ₹${expense.amount} — ${expense.name} ${expense.emoji}',
    ];

    final base = responses[Random().nextInt(responses.length)];

    final todayCount = todayExpenses.length;
    if (todayCount > 0 && todayCount % 5 == 0) {
      return '$base\nThat\'s $todayCount expenses today! 📊';
    }
    final foodCount =
        todayExpenses.where((e) => e.category == 'Food').length;
    if (expense.category == 'Food' && foodCount > 2) {
      return '$base\nYou\'re eating well today! 😋';
    }
    return base;
  }

  String getRandomFunFact(int amount) {
    if (amount == 0) return 'Add expenses in Chat to see fun facts! 💬';

    final template =
        _funFactTemplates[Random().nextInt(_funFactTemplates.length)];
    final count = amount ~/ template.unitPrice;
    if (count == 0) return '< 1 ${template.item}';
    return '= $count ${template.item}';
  }

  static String formatTime(DateTime dt) {
    final hour = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  List<(String, String)> getSmartSuggestions({int count = 4}) {
    if (_expenses.isEmpty) {
      return _getRandomDefaults(count);
    }
    return _getPersonalizedSuggestions(count);
  }

  List<(String, String)> _getRandomDefaults(int count) {
    const defaults = [
      ('☕', 'chai 15'),
      ('🛺', 'auto 60'),
      ('🍿', 'snack 30'),
      ('🍛', 'lunch 100'),
      ('🚌', 'bus 15'),
      ('☕', 'coffee 40'),
      ('🍕', 'pizza 200'),
      ('🥟', 'samosa 10'),
      ('🍜', 'maggi 20'),
      ('🥛', 'lassi 40'),
      ('🌯', 'shawarma 120'),
      ('🥣', 'pani puri 30'),
      ('🍦', 'ice cream 50'),
      ('🚇', 'metro 30'),
      ('🍔', 'burger 100'),
    ];

    final shuffled = List.of(defaults)..shuffle(Random());
    return shuffled.take(count).toList();
  }

  List<(String, String)> _getPersonalizedSuggestions(int count) {
    final nameGroups = <String, List<Expense>>{};
    for (final e in _expenses) {
      final key = e.name.toLowerCase();
      nameGroups.putIfAbsent(key, () => []).add(e);
    }

    final sorted = nameGroups.entries.toList()
      ..sort((a, b) {
        final freqCompare = b.value.length.compareTo(a.value.length);
        if (freqCompare != 0) return freqCompare;
        return b.value.last.timestamp.compareTo(a.value.last.timestamp);
      });

    final suggestions = <(String, String)>[];
    final usedCategories = <String>{};

    for (final entry in sorted) {
      if (suggestions.length >= count) break;

      final expenseList = entry.value;
      final representative = expenseList.last;
      final avgAmount =
          (expenseList.fold(0, (sum, e) => sum + e.amount) / expenseList.length)
              .round();

      if (usedCategories.length >= 2 &&
          !usedCategories.contains(representative.category) &&
          suggestions.length >= count - 1) {
        continue;
      }

      suggestions.add((
        representative.emoji,
        '${representative.name.toLowerCase()} $avgAmount',
      ));
      usedCategories.add(representative.category);
    }

    if (suggestions.length < count) {
      final existingNames =
          suggestions.map((s) => s.$2.split(' ').first).toSet();
      final padding = _getRandomDefaults(count * 2)
          .where((d) => !existingNames.contains(d.$2.split(' ').first))
          .take(count - suggestions.length);
      suggestions.addAll(padding);
    }

    return suggestions.take(count).toList();
  }
}
