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

  // ── Undo / Edit state (single-step) ─────────────────────────────────────
  Expense? _lastLoggedExpense;    // the most recently *logged* expense
  int? _lastLoggedBotMsgIdx;      // index of the bot confirmation bubble to update

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

  /// Permanently delete an expense by id. Also removes the corresponding
  /// chat confirmation bubble from the message list.
  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    // Remove the associated bot confirmation bubble
    _messages.removeWhere(
      (m) => m.type == ChatMessageType.categoryChips && m.loggedExpense?.id == id,
    );
    // Clear undo state if the deleted item was the last logged one
    if (_lastLoggedExpense?.id == id) {
      _lastLoggedExpense = null;
      _lastLoggedBotMsgIdx = null;
    }
    notifyListeners();
    await _storage.deleteEntry(id);
    await _logActivity('delete_expense');
  }

  /// Edit an existing expense amount in-place (marks it as edited).
  Future<void> editExpenseAmount(String id, int newAmount) async {
    final idx = _expenses.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final updated = _expenses[idx].copyWith(amount: newAmount, isEdited: true);
    _expenses[idx] = updated;
    if (_lastLoggedExpense?.id == id) _lastLoggedExpense = updated;
    notifyListeners();
    await _persistExpense(updated);
    await _logActivity('edit_expense');
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

  // ── routeMessage — single entry point for every user message ────────────
  /// Checks intent in this order and stops at the first match:
  /// undo → edit → search → question → log
  /// Routes a user message to the correct handler.
  ///
  /// [forceMode] bypasses pattern matching when the mode toggle is active:
  /// - `'log'`    → always treat as a new expense entry
  /// - `'ask'`    → always treat as a question (even without '?')
  /// - `'search'` → always treat as a search query
  Future<void> routeMessage(String input, {String? forceMode}) async {
    final text = input.trim().toLowerCase();

    // Mode toggle takes priority over pattern matching
    if (forceMode == 'log') {
      await _handleLog(input);
      return;
    }
    if (forceMode == 'ask') {
      await _handleQuestion(text);
      return;
    }
    if (forceMode == 'search') {
      await _handleSearch(text);
      return;
    }

    // Auto-routing (no mode forced — chips and free-text)
    if (text.startsWith('undo')) {
      await _handleUndo();
    } else if (text.startsWith('change last to') ||
        text.startsWith('make that')) {
      await _handleEdit(text);
    } else if (text.startsWith('find') ||
        text.startsWith('search') ||
        text.startsWith('show')) {
      await _handleSearch(text);
    } else if (text.contains('?') ||
        text.startsWith('how much') ||
        text.startsWith('did i') ||
        text.startsWith('was i') ||
        text.startsWith('vs')) {
      await _handleQuestion(text);
    } else {
      await _handleLog(input);
    }
  }

  // ── Handler: undo ────────────────────────────────────────────────────────
  Future<void> _handleUndo() async {
    if (_lastLoggedExpense == null) {
      await addMessage(ChatMessage(
        text: 'Nothing to undo yet this session.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      return;
    }

    final removed = _lastLoggedExpense!;
    // Remove from expense list
    _expenses.removeWhere((e) => e.id == removed.id);
    // Remove the bot confirmation bubble that accompanied the log
    if (_lastLoggedBotMsgIdx != null &&
        _lastLoggedBotMsgIdx! < _messages.length) {
      _messages.removeAt(_lastLoggedBotMsgIdx!);
    }
    _lastLoggedExpense = null;
    _lastLoggedBotMsgIdx = null;
    notifyListeners();

    await addMessage(ChatMessage(
      text: 'Undone — removed ₹${removed.amount} from ${removed.category} 🗑️',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  // ── Handler: edit ────────────────────────────────────────────────────────
  Future<void> _handleEdit(String text) async {
    if (_lastLoggedExpense == null) {
      await addMessage(ChatMessage(
        text: 'Nothing logged yet to edit.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      return;
    }

    final numberMatch = RegExp(r'\d+').firstMatch(text);
    if (numberMatch == null) {
      await addMessage(ChatMessage(
        text: 'Hmm, couldn\'t find a new amount. Try "change last to 380".',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      return;
    }

    final newAmount = int.tryParse(numberMatch.group(0)!);
    if (newAmount == null || newAmount <= 0) {
      await addMessage(ChatMessage(
        text: 'That amount doesn\'t look right. Try "change last to 380".',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      return;
    }

    final old = _lastLoggedExpense!;
    final updated = old.copyWith(amount: newAmount, isEdited: true);

    final idx = _expenses.indexWhere((e) => e.id == old.id);
    if (idx != -1) {
      _expenses[idx] = updated;
    }
    _lastLoggedExpense = updated;
    notifyListeners();

    await _persistExpense(updated);
    await addMessage(ChatMessage(
      text: 'Updated! ${updated.emoji} ${updated.name} is now ₹$newAmount · edited',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  // ── Handler: search (real data only) ─────────────────────────────────────
  Future<void> _handleSearch(String text) async {
    final overMatch = RegExp(r'over\s*(\d+)').firstMatch(text);
    final threshold = overMatch != null
        ? int.tryParse(overMatch.group(1)!) ?? 0
        : 0;

    final keyword = text
        .replaceAll(RegExp(r'^(find|search|show)\s*'), '')
        .replaceAll(RegExp(r'over\s*\d+'), '')
        .trim();

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final matches = _expenses.where((e) {
      final nameMatch = keyword.isEmpty ||
          e.name.toLowerCase().contains(keyword) ||
          e.category.toLowerCase().contains(keyword) ||
          e.emoji.contains(keyword);
      return nameMatch && e.amount > threshold;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (matches.isEmpty) {
      final msg = _expenses.isEmpty
          ? 'No expenses logged yet. Start by typing something like "chai 20".'
          : keyword.isEmpty
              ? 'No expenses found over ₹$threshold.'
              : 'No matches for "$keyword"${threshold > 0 ? ' over ₹$threshold' : ''}.';
      await addMessage(ChatMessage(
        text: msg,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      return;
    }

    final results = matches.take(6).map((e) {
      final d = e.timestamp;
      return SearchResultRow(
        name: '${e.emoji} ${e.name}',
        date: '${d.day} ${months[d.month]}',
        amount: e.amount,
      );
    }).toList();

    await addMessage(ChatMessage(
      text: 'Found ${results.length} match${results.length == 1 ? '' : 'es'}:',
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.searchResults,
      searchResults: results,
    ));
  }


  // ── Handler: question ────────────────────────────────────────────────────
  Future<void> _handleQuestion(String text) async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final lastMonth = DateTime.now().subtract(const Duration(days: 30));

    String response;

    if (text.contains('food') || text.contains('swiggy') ||
        text.contains('zomato') || text.contains('eat')) {
      final total = _expenses
          .where((e) =>
              e.category == 'Food' && e.timestamp.isAfter(weekAgo))
          .fold(0, (s, e) => s + e.amount);
      final monthTotal = _expenses
          .where((e) =>
              e.category == 'Food' && e.timestamp.isAfter(lastMonth))
          .fold(0, (s, e) => s + e.amount);
      if (total > 0) {
        response =
            '🍛 ₹$total on Food this week — about ${((total / (monthTotal > 0 ? monthTotal : total)) * 100).round()}% of everything you spent. A bit above your usual.';
      } else {
        response = '🍛 Nothing logged under Food this week yet!';
      }
    } else if (text.contains('transit') ||
        text.contains('auto') ||
        text.contains('uber') ||
        text.contains('travel')) {
      final total = _expenses
          .where((e) =>
              e.category == 'Transit' && e.timestamp.isAfter(weekAgo))
          .fold(0, (s, e) => s + e.amount);
      response = total > 0
          ? '🛺 ₹$total on Transit this week. That\'s ${(total / 7).round()} a day on average.'
          : '🛺 No transit expenses logged this week.';
    } else if (text.contains('fun') ||
        text.contains('entertainment') ||
        text.contains('movie')) {
      final total = _expenses
          .where((e) =>
              e.category == 'Fun' && e.timestamp.isAfter(weekAgo))
          .fold(0, (s, e) => s + e.amount);
      response = total > 0
          ? '🎬 ₹$total on Fun this week. Worth it? 😄'
          : '🎬 Nothing on Fun this week — saving up?';
    } else if (text.contains('regret') || text.contains('worst')) {
      final regrets = weeklyRegrets;
      if (regrets.isEmpty) {
        response = '😩 No regrets logged this week! You\'re doing great.';
      } else {
        final top = regrets.first;
        response =
            '😩 Biggest regret this week: ${top.emoji} ${top.name} — ₹${top.amount}. Ouch.';
      }
    } else if (text.contains('vs') ||
        text.contains('last month') ||
        text.contains('compare')) {
      final now = DateTime.now();
      final thisMonth =
          monthlyTotalFor(now.year, now.month);
      final prevMonth = now.month == 1
          ? monthlyTotalFor(now.year - 1, 12)
          : monthlyTotalFor(now.year, now.month - 1);
      if (thisMonth == 0 && prevMonth == 0) {
        response = '📊 Not enough data to compare yet — keep logging!';
      } else if (prevMonth == 0) {
        response = '📊 This month: ₹$thisMonth. No data from last month to compare.';
      } else {
        final diff = thisMonth - prevMonth;
        final sign = diff >= 0 ? '+' : '';
        final pct = ((diff.abs() / prevMonth) * 100).round();
        response =
            '📊 This month: ₹$thisMonth vs ₹$prevMonth last month — $sign$diff ($sign$pct%). ${diff > 0 ? 'Spending up a bit.' : 'Nice, spending down!'}';
      }
    } else if (text.contains('total') || text.contains('today')) {
      response = '💰 Today\'s total: ₹$todayTotal across ${todayExpenses.length} expenses.';
    } else {
      response =
          'Hmm, I\'m not sure about that one 🤔 Try asking about food, transit, fun, or vs last month.';
    }

    await addMessage(ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  // ── Handler: log (fallback) ──────────────────────────────────────────────
  Future<void> _handleLog(String input) async {
    final expense = parseExpense(input);

    if (expense == null) {
      await addMessage(ChatMessage(
        text:
            'Hmm, I couldn\'t get that 🤔\nTry something like "chai 30 rupees" or "auto 80"',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      return;
    }

    if (expense.category == 'Other') {
      // Signal to the UI that we need the emoji picker (return expense via callback)
      _pendingUncategorised = expense;
      notifyListeners();
      return;
    }

    await _commitLoggedExpense(expense);
  }

  /// Called by the UI after the emoji-picker resolves an "Other" category expense.
  Future<void> commitUncategorisedExpense(Expense expense) async {
    _pendingUncategorised = null;
    await _commitLoggedExpense(expense);
  }

  /// Shared finalisation path for both normal logs and emoji-picker resolutions.
  Future<void> _commitLoggedExpense(Expense expense) async {
    await addExpense(expense);
    _lastLoggedExpense = expense;

    final botMsg = ChatMessage(
      text: getBotResponse(expense),
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.categoryChips,
      loggedExpense: expense,
    );
    await addMessage(botMsg);
    _lastLoggedBotMsgIdx = _messages.length - 1;
  }

  // Holds an uncategorised expense waiting for emoji-picker resolution
  Expense? _pendingUncategorised;
  Expense? get pendingUncategorised => _pendingUncategorised;

  /// Correct the category of the last logged expense (via category chips).
  Future<void> correctCategory(String expenseId, CategoryInfo newCat) async {
    final idx = _expenses.indexWhere((e) => e.id == expenseId);
    if (idx == -1) return;
    final updated = _expenses[idx].copyWith(
      category: newCat.name,
      emoji: newCat.emoji,
      color: newCat.color,
    );
    _expenses[idx] = updated;
    if (_lastLoggedExpense?.id == expenseId) {
      _lastLoggedExpense = updated;
    }
    notifyListeners();
    await _persistExpense(updated);
    await addMessage(ChatMessage(
      text: 'Got it — moved to ${newCat.name} ${newCat.emoji}',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

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
      emoji: _detectEmoji(name.toLowerCase(), cat.emoji),
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

  /// Returns a specific emoji for well-known items, falling back to [fallback].
  String _detectEmoji(String lower, String fallback) {
    // ── Drinks & beverages ──
    if (lower.contains('lassi'))        return '🥛';
    if (lower.contains('chai') || lower.contains('tea')) return '☕';
    if (lower.contains('coffee'))       return '☕';
    if (lower.contains('juice'))        return '🧃';
    if (lower.contains('shake') || lower.contains('milkshake')) return '🥤';
    if (lower.contains('water'))        return '💧';
    if (lower.contains('beer'))         return '🍺';
    if (lower.contains('wine'))         return '🍷';
    if (lower.contains('drink') || lower.contains('alcohol')) return '🍹';
    // ── Street food & snacks ──
    if (lower.contains('samosa'))       return '🥟';
    if (lower.contains('momos') || lower.contains('momo')) return '🥟';
    if (lower.contains('burger'))       return '🍔';
    if (lower.contains('pizza'))        return '🍕';
    if (lower.contains('sandwich'))     return '🥪';
    if (lower.contains('roll') || lower.contains('wrap')) return '🌯';
    if (lower.contains('shawarma'))     return '🌯';
    if (lower.contains('pav') || lower.contains('bhaji')) return '🫓';
    if (lower.contains('vada'))         return '🫓';
    if (lower.contains('dosa') || lower.contains('idli')) return '🫓';
    if (lower.contains('paratha') || lower.contains('roti') || lower.contains('naan')) return '🫓';
    if (lower.contains('bhel') || lower.contains('chaat')) return '🥗';
    if (lower.contains('chips') || lower.contains('biscuit')) return '🍪';
    if (lower.contains('cake') || lower.contains('pastry')) return '🎂';
    if (lower.contains('ice cream') || lower.contains('kulfi')) return '🍦';
    if (lower.contains('jalebi') || lower.contains('sweet')) return '🍬';
    if (lower.contains('bread') || lower.contains('toast')) return '🍞';
    if (lower.contains('egg'))          return '🍳';
    if (lower.contains('maggi') || lower.contains('noodle')) return '🍜';
    // ── Meals ──
    if (lower.contains('biryani') || lower.contains('biriyani')) return '🍛';
    if (lower.contains('thali'))        return '🍱';
    if (lower.contains('rice') || lower.contains('dal')) return '🍚';
    if (lower.contains('paneer'))       return '🧀';
    if (lower.contains('chicken'))      return '🍗';
    if (lower.contains('mutton') || lower.contains('kebab') || lower.contains('tikka')) return '🍖';
    if (lower.contains('fish'))         return '🐟';
    if (lower.contains('manchurian') || lower.contains('soup')) return '🍲';
    if (lower.contains('salad'))        return '🥗';
    if (lower.contains('fruit'))        return '🍎';
    if (lower.contains('lunch'))        return '🍱';
    if (lower.contains('dinner'))       return '🍽️';
    if (lower.contains('breakfast') || lower.contains('snack')) return '🥞';
    // ── Transit ──
    if (lower.contains('auto'))         return '🛺';
    if (lower.contains('uber') || lower.contains('ola') || lower.contains('cab') || lower.contains('taxi')) return '🚕';
    if (lower.contains('bus'))          return '🚌';
    if (lower.contains('metro'))        return '🚇';
    if (lower.contains('train'))        return '🚆';
    if (lower.contains('rapido'))       return '🏍️';
    if (lower.contains('flight'))       return '✈️';
    if (lower.contains('fuel') || lower.contains('petrol') || lower.contains('diesel')) return '⛽';
    if (lower.contains('parking'))      return '🅿️';
    // ── Fun & entertainment ──
    if (lower.contains('movie') || lower.contains('cinema') || lower.contains('pvr') || lower.contains('inox')) return '🎬';
    if (lower.contains('game'))         return '🎮';
    if (lower.contains('concert'))      return '🎵';
    if (lower.contains('bowling'))      return '🎳';
    if (lower.contains('bar') || lower.contains('pub')) return '🍻';
    if (lower.contains('party') || lower.contains('outing')) return '🥳';
    // ── Shopping ──
    if (lower.contains('phone') || lower.contains('mobile')) return '📱';
    if (lower.contains('headphone') || lower.contains('earphone')) return '🎧';
    if (lower.contains('shirt') || lower.contains('tshirt') || lower.contains('clothes')) return '👕';
    if (lower.contains('shoes') || lower.contains('sneaker')) return '👟';
    if (lower.contains('watch'))        return '⌚';
    if (lower.contains('bag') || lower.contains('purse')) return '👜';
    if (lower.contains('amazon') || lower.contains('flipkart') || lower.contains('myntra')) return '📦';
    // ── Bills ──
    if (lower.contains('netflix') || lower.contains('prime') || lower.contains('hotstar')) return '📺';
    if (lower.contains('spotify'))      return '🎵';
    if (lower.contains('electricity'))  return '⚡';
    if (lower.contains('wifi') || lower.contains('internet')) return '📶';
    if (lower.contains('recharge'))     return '📲';
    if (lower.contains('rent'))         return '🏠';
    // ── Health ──
    if (lower.contains('gym') || lower.contains('fitness')) return '🏋️';
    if (lower.contains('yoga'))         return '🧘';
    if (lower.contains('medicine') || lower.contains('pharmacy')) return '💊';
    if (lower.contains('doctor') || lower.contains('hospital')) return '🏥';
    if (lower.contains('dental'))       return '🦷';
    return fallback;
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
