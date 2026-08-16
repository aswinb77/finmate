import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

// ── Chat mode ──────────────────────────────────────────────────────────────
enum _ChatMode { log, ask, search }

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _service = ExpenseService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  _ChatMode _mode = _ChatMode.log;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.checkAndClearExpiredChat();
    _service.addListener(_onDataChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _service.checkAndClearExpiredChat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.removeListener(_onDataChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    final pending = _service.pendingUncategorised;
    if (pending != null) _showEmojiPicker(pending);
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Mode-aware send ────────────────────────────────────────────────────
  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _service.addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _textController.clear();

    Future.delayed(const Duration(milliseconds: 400), () {
      switch (_mode) {
        case _ChatMode.log:
          // Force the log path regardless of text content
          _service.routeMessage(text, forceMode: 'log');
        case _ChatMode.ask:
          _service.routeMessage(text, forceMode: 'ask');
        case _ChatMode.search:
          _service.routeMessage(text, forceMode: 'search');
      }
    });
  }

  void _handleQuickChip(String text) {
    _service.addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    Future.delayed(const Duration(milliseconds: 400), () {
      _service.routeMessage(text); // chips always use auto-routing
    });
  }

  // ── Emoji picker ───────────────────────────────────────────────────────
  void _showEmojiPicker(Expense expense) {
    const emojiOptions = [
      '🎮', '🎵', '🎨', '📱', '💻', '🎁',
      '✂️', '🧴', '🪥', '🧹', '🔧', '📦',
      '🍛', '☕', '🍕', '🍔', '🍦', '🧁',
      '🚗', '🛺', '🚌', '✈️', '🚲', '⛽',
      '💰', '🛒', '🛍️', '💳', '🏠', '💡',
      '💊', '🏥', '💪', '⚽', '🧘', '🏋️',
      '🎬', '🎭', '🎪', '🎯', '🎲', '📚',
    ];
    const colorOptions = [
      Color(0xFFCCC0AE), Color(0xFFA8CCAC), Color(0xFF9BAFD6),
      Color(0xFFD4826A), Color(0xFFE8C84A), Color(0xFF7CB8A8),
      Color(0xFFB8A0D2), Color(0xFFF4A9A8),
    ];

    String selectedEmoji = '📦';
    Color selectedColor = const Color(0xFFCCC0AE);

    _service.addMessage(ChatMessage(
      text: 'Pick an emoji & color for "${expense.name}" 👇',
      isUser: false,
      timestamp: DateTime.now(),
    ));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5EFE0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4C4A8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Choose an emoji & color',
                    style: GoogleFonts.rubik(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: const Color(0xFF2A1F14))),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Choose an emoji',
                      style: GoogleFonts.rubik(fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C6A55))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: emojiOptions.map((emoji) {
                      final isSel = selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedEmoji = emoji),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF2A1F14) : const Color(0xFFF7F1E4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSel ? const Color(0xFF2A1F14) : const Color(0xFFE8DCCB)),
                          ),
                          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Pick a color',
                      style: GoogleFonts.rubik(fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C6A55))),
                  const SizedBox(height: 12),
                  Row(
                    children: colorOptions.map((color) {
                      final isSel = selectedColor == color;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedColor = color),
                          child: Container(
                            height: 36,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                              border: isSel
                                  ? Border.all(color: const Color(0xFF2A1F14), width: 2.5)
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _service.commitUncategorisedExpense(
                        expense.copyWith(emoji: selectedEmoji, color: selectedColor));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                        color: const Color(0xFF2A1F14),
                        borderRadius: BorderRadius.circular(18)),
                    child: Center(
                      child: Text(
                        'Add $selectedEmoji ${expense.name} — ₹${expense.amount}',
                        style: GoogleFonts.rubik(
                            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Just say it',
                  style: GoogleFonts.rubik(
                      fontSize: 30, fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A1F14))),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              itemCount: _service.messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_service.messages[index]),
            ),
          ),
          _buildQuickChips(),
          _buildModeToggle(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: const Color(0xFF2A1F14),
              borderRadius: BorderRadius.circular(12)),
          child: const Center(
            child: Text('◆', style: TextStyle(fontSize: 20, color: Color(0xFFE8C84A))),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.cleaning_services_rounded,
              color: Color(0xFF7C6A55), size: 24),
          tooltip: 'Clear Chat',
          onPressed: () {
            _service.clearChatMessages();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Chat messages cleared 🧹',
                  style: GoogleFonts.rubik(fontWeight: FontWeight.w500)),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF2A1F14),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          },
        ),
        const SizedBox(width: 8),
        Stack(children: [
          const Icon(Icons.notifications_rounded, color: Color(0xFFD4A853), size: 30),
          Positioned(
            top: 0, right: 0,
            child: Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFE07B54), shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF5EFE0), width: 1.5),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Message bubble dispatcher ───────────────────────────────────────────
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final bubble = Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF2A1F14) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 20),
        ),
        boxShadow: isUser
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: _buildBubbleContent(message),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        // top-align avatar with the bubble
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                  color: const Color(0xFF2A1F14),
                  borderRadius: BorderRadius.circular(8)),
              child: const Center(
                child: Text('◆',
                    style: TextStyle(fontSize: 12, color: Color(0xFFE8C84A))),
              ),
            ),
          ],
          // Swipeable only for log-confirmation bubbles with a linked expense
          if (!isUser && message.type == ChatMessageType.categoryChips &&
              message.loggedExpense != null)
            _SwipeToReveal(
              expense: message.loggedExpense!,
              onEdit: (expense) => _showEditSheet(expense),
              onDelete: (expense) => _confirmDelete(expense),
              child: bubble,
            )
          else
            Flexible(child: bubble),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(ChatMessage message) {
    switch (message.type) {
      case ChatMessageType.searchResults:
        return _buildSearchResultsBubble(message);
      case ChatMessageType.categoryChips:
        return _buildCategoryChipsBubble(message);
      case ChatMessageType.normal:
        return _buildTextBubble(message);
    }
  }

  Widget _buildTextBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Text(message.text,
          style: GoogleFonts.rubik(
              fontSize: 14, fontWeight: FontWeight.w400,
              color: message.isUser ? Colors.white : const Color(0xFF2A1F14),
              height: 1.45)),
    );
  }

  Widget _buildSearchResultsBubble(ChatMessage message) {
    final results = message.searchResults ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(message.text,
            style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600,
                color: const Color(0xFF7C6A55))),
        const SizedBox(height: 10),
        ...results.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Container(
            margin: EdgeInsets.only(bottom: i < results.length - 1 ? 6 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
                color: const Color(0xFFF7F1E4),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(row.name,
                      style: GoogleFonts.rubik(fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2A1F14))),
                  Text(row.date,
                      style: GoogleFonts.rubik(fontSize: 11,
                          color: const Color(0xFF9C8878))),
                ]),
              ),
              Text('₹${row.amount}',
                  style: GoogleFonts.rubik(fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A1F14))),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildCategoryChipsBubble(ChatMessage message) {
    final expense = message.loggedExpense;
    final allCats = [
      const CategoryInfo('Food', '🍛', Color(0xFFD4826A)),
      const CategoryInfo('Transit', '🛺', Color(0xFF9BAFD6)),
      const CategoryInfo('Fun', '🎬', Color(0xFFA8CCAC)),
      const CategoryInfo('Shopping', '🛍️', Color(0xFFE8C84A)),
      const CategoryInfo('Bills', '📄', Color(0xFFB8A898)),
      const CategoryInfo('Health', '💊', Color(0xFF7CB8A8)),
      const CategoryInfo('Other', '📦', Color(0xFFCCC0AE)),
    ];
    final chips = expense == null
        ? allCats
        : allCats.where((c) => c.name != expense.category).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(message.text,
            style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w400,
                color: const Color(0xFF2A1F14), height: 1.45)),
        if (expense != null && expense.isEdited)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('· edited',
                style: GoogleFonts.rubik(fontSize: 11,
                    color: const Color(0xFF9C8878))),
          ),
        if (expense != null) ...[
          const SizedBox(height: 10),
          Text('Wrong category?',
              style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w500,
                  color: const Color(0xFF9C8878))),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: chips.map((cat) => GestureDetector(
              onTap: () => _service.correctCategory(expense.id, cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cat.color.withValues(alpha: 0.5)),
                ),
                child: Text('${cat.emoji} ${cat.name}',
                    style: GoogleFonts.rubik(fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2A1F14))),
              ),
            )).toList(),
          ),
        ],
      ]),
    );
  }

  // ── Edit sheet ──────────────────────────────────────────────────────────
  void _showEditSheet(Expense expense) {
    final amountController =
        TextEditingController(text: expense.amount.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5EFE0),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFD4C4A8),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Text(expense.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(expense.name,
                    style: GoogleFonts.rubik(fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2A1F14))),
                Text(expense.category,
                    style: GoogleFonts.rubik(fontSize: 12,
                        color: const Color(0xFF7C6A55))),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DCCB)),
            ),
            child: Row(children: [
              Text('₹', style: GoogleFonts.rubik(
                  fontSize: 22, fontWeight: FontWeight.w600,
                  color: const Color(0xFF2A1F14))),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.rubik(fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2A1F14)),
                  decoration: InputDecoration(
                    hintText: 'New amount',
                    hintStyle: GoogleFonts.rubik(
                        fontSize: 22, color: const Color(0xFFB8A898)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                final newAmt = int.tryParse(amountController.text.trim());
                if (newAmt != null && newAmt > 0) {
                  Navigator.pop(ctx);
                  _service.editExpenseAmount(expense.id, newAmt);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                    color: const Color(0xFF2A1F14),
                    borderRadius: BorderRadius.circular(18)),
                child: Center(
                  child: Text('Save changes',
                      style: GoogleFonts.rubik(fontSize: 15,
                          fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  // ── Delete confirm ──────────────────────────────────────────────────────
  void _confirmDelete(Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5EFE0),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFD4C4A8),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Delete entry?',
              style: GoogleFonts.rubik(fontSize: 18,
                  fontWeight: FontWeight.w700, color: const Color(0xFF2A1F14))),
          const SizedBox(height: 8),
          Text(
            '${expense.emoji} ${expense.name} — ₹${expense.amount} will be removed permanently.',
            textAlign: TextAlign.center,
            style: GoogleFonts.rubik(fontSize: 14,
                color: const Color(0xFF7C6A55), height: 1.4),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE8DE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text('Cancel',
                        style: GoogleFonts.rubik(fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5C4A35))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _service.deleteExpense(expense.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4826A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text('Delete',
                        style: GoogleFonts.rubik(fontSize: 15,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Quick chips ─────────────────────────────────────────────────────────
  Widget _buildQuickChips() {
    final List<(String, String)> chips;
    final bool outlined;

    switch (_mode) {
      case _ChatMode.log:
        chips = _service.getSmartSuggestions(count: 5);
        outlined = false;
      case _ChatMode.ask:
        chips = const [
          ('🍛', 'how much on food this week?'),
          ('🛺', 'transit this week?'),
          ('😩', 'biggest regret?'),
          ('🎬', 'fun this week?'),
          ('📊', 'vs last month?'),
          ('💰', 'how much today?'),
        ];
        outlined = true;
      case _ChatMode.search:
        chips = const [
          ('🔍', 'find swiggy over 500'),
          ('🔍', 'find food over 200'),
          ('🔍', 'find auto'),
          ('🔍', 'find fun over 300'),
          ('🔍', 'show transit'),
        ];
        outlined = true;
    }

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
        itemCount: chips.length,
        itemBuilder: (_, i) {
          final chip = chips[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _handleQuickChip(chip.$2),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: outlined ? Colors.transparent : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: outlined
                      ? Border.all(color: const Color(0xFFD4C4A8), width: 1.2)
                      : null,
                ),
                child: Text(
                  '${chip.$1} ${chip.$2}',
                  style: GoogleFonts.rubik(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: outlined
                        ? const Color(0xFF5C4A35)
                        : const Color(0xFF2A1F14),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  // ── Mode toggle pill ────────────────────────────────────────────────────
  Widget _buildModeToggle() {
    const modes = [
      (_ChatMode.log,    '✏️', 'Log'),
      (_ChatMode.ask,    '💬', 'Ask'),
      (_ChatMode.search, '🔍', 'Search'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE8DE),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: modes.map((m) {
            final isActive = _mode == m.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_mode != m.$1) setState(() => _mode = m.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF2A1F14) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '${m.$2} ${m.$3}',
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? const Color(0xFFE8C84A)
                            : const Color(0xFF7C6A55),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Input bar ───────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    final hints = {
      _ChatMode.log: 'e.g. chai 20, auto 60...',
      _ChatMode.ask: 'How much on food this week?',
      _ChatMode.search: 'find swiggy over 300',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE0),
        border: Border(
            top: BorderSide(
                color: const Color(0xFFE8DCCB).withValues(alpha: 0.5),
                width: 1)),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE8DCCB)),
            ),
            child: TextField(
              controller: _textController,
              style: GoogleFonts.rubik(fontSize: 14, color: const Color(0xFF2A1F14)),
              decoration: InputDecoration(
                hintText: hints[_mode],
                hintStyle: GoogleFonts.rubik(fontSize: 14, color: const Color(0xFFB8A898)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _handleSend,
          child: Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(
                color: Color(0xFF2A1F14), shape: BoxShape.circle),
            child: const Center(
              child: Icon(Icons.send_rounded, color: Color(0xFFE8C84A), size: 22),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Swipe-to-reveal widget ──────────────────────────────────────────────────
class _SwipeToReveal extends StatefulWidget {
  final Widget child;
  final Expense expense;
  final void Function(Expense) onEdit;
  final void Function(Expense) onDelete;

  const _SwipeToReveal({
    required this.child,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SwipeToReveal> createState() => _SwipeToRevealState();
}

class _SwipeToRevealState extends State<_SwipeToReveal>
    with SingleTickerProviderStateMixin {
  static const _actionWidth = 116.0; // total width of the two action buttons
  late final AnimationController _ctrl;
  late final Animation<double> _slideAnim;

  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _slideAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_revealed) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _revealed = !_revealed);
  }

  void _close() {
    if (_revealed) {
      _ctrl.reverse();
      setState(() => _revealed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Swipe left to open, swipe right to close
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity != null) {
          if (d.primaryVelocity! < -200 && !_revealed) _toggle();
          if (d.primaryVelocity! > 200 && _revealed) _toggle();
        }
      },
      onTap: _close,
      child: ClipRect(
        child: Stack(
          children: [
            // Action buttons revealed on the right
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit button
                  GestureDetector(
                    onTap: () {
                      _close();
                      widget.onEdit(widget.expense);
                    },
                    child: Container(
                      width: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9BAFD6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('✏️', style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 2),
                          Text('Edit',
                              style: GoogleFonts.rubik(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Delete button
                  GestureDetector(
                    onTap: () {
                      _close();
                      widget.onDelete(widget.expense);
                    },
                    child: Container(
                      width: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4826A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🗑️', style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 2),
                          Text('Delete',
                              style: GoogleFonts.rubik(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The message bubble, slides left to reveal buttons
            AnimatedBuilder(
              animation: _slideAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(-_actionWidth * _slideAnim.value, 0),
                child: child,
              ),
              child: Flexible(child: widget.child),
            ),
          ],
        ),
      ),
    );
  }
}
