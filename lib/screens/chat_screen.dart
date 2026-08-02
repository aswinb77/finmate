import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _service = ExpenseService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

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
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
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

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    _service.addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _textController.clear();

    // Parse expense
    final expense = _service.parseExpense(text);

    // Delayed bot response
    Future.delayed(const Duration(milliseconds: 400), () {
      if (expense != null) {
        if (expense.category == 'Other') {
          // Show emoji picker for uncategorized expenses
          _showEmojiPicker(expense);
        } else {
          _service.addExpense(expense);
          _service.addMessage(ChatMessage(
            text: _service.getBotResponse(expense),
            isUser: false,
            timestamp: DateTime.now(),
          ));
        }
      } else {
        _service.addMessage(ChatMessage(
          text:
              'Hmm, I couldn\'t get that 🤔\nTry something like "chai 30 rupees" or "auto 80"',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    });
  }

  void _showEmojiPicker(Expense expense) {
    // Common emojis organized by style
    const emojiOptions = [
      // Objects & Activities
      '🎮', '🎵', '🎨', '📱', '💻', '🎁',
      '✂️', '🧴', '🪥', '🧹', '🔧', '📦',
      // Food & Drink
      '🍛', '☕', '🍕', '🍔', '🍦', '🧁',
      // Transport
      '🚗', '🛺', '🚌', '✈️', '🚲', '⛽',
      // Money & Shopping
      '💰', '🛒', '🛍️', '💳', '🏠', '💡',
      // Health & Sports
      '💊', '🏥', '💪', '⚽', '🧘', '🏋️',
      // Fun
      '🎬', '🎭', '🎪', '🎯', '🎲', '📚',
    ];

    const colorOptions = [
      Color(0xFFCCC0AE), // default Other
      Color(0xFFA8CCAC), // green
      Color(0xFF9BAFD6), // blue
      Color(0xFFD4826A), // coral
      Color(0xFFE8C84A), // gold
      Color(0xFF7CB8A8), // teal
      Color(0xFFB8A0D2), // purple
      Color(0xFFF4A9A8), // pink
    ];

    String selectedEmoji = '📦';
    Color selectedColor = const Color(0xFFCCC0AE);

    // Show bot message asking to pick
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
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar & Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4C4A8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Choose an emoji & color',
                          style: GoogleFonts.rubik(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2A1F14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Emoji Grid + Color Picker
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose an emoji',
                            style: GoogleFonts.rubik(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7C6A55),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: emojiOptions.map((emoji) {
                              final isSelected = selectedEmoji == emoji;
                              return GestureDetector(
                                onTap: () =>
                                    setModalState(() => selectedEmoji = emoji),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF2A1F14)
                                        : const Color(0xFFF7F1E4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF2A1F14)
                                          : const Color(0xFFE8DCCB),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(emoji,
                                        style: const TextStyle(fontSize: 22)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Pick a color',
                            style: GoogleFonts.rubik(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7C6A55),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: colorOptions.map((color) {
                              final isSelected = selectedColor == color;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setModalState(() => selectedColor = color),
                                  child: Container(
                                    height: 36,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(10),
                                      border: isSelected
                                          ? Border.all(
                                              color: const Color(0xFF2A1F14),
                                              width: 2.5)
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Fixed Confirm Button at Bottom
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          final updated = expense.copyWith(
                            emoji: selectedEmoji,
                            color: selectedColor,
                          );
                          _service.addExpense(updated);
                          _service.addMessage(ChatMessage(
                            text: _service.getBotResponse(updated),
                            isUser: false,
                            timestamp: DateTime.now(),
                          ));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A1F14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Text(
                              'Add $selectedEmoji ${expense.name} — ₹${expense.amount}',
                              style: GoogleFonts.rubik(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleQuickChip(String text) {
    _textController.text = text;
    _handleSend();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _service.messages;

    return SafeArea(
      child: Column(
        children: [
          // ── Top bar ───────────────────────────────────────────────────
          _buildTopBar(),

          // ── Title ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Just say it',
                style: GoogleFonts.rubik(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2A1F14),
                ),
              ),
            ),
          ),

          // ── Messages ──────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(messages[index]),
            ),
          ),

          // ── Quick chips ───────────────────────────────────────────────
          _buildQuickChips(),

          // ── Input bar ─────────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2A1F14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('◆',
                  style: TextStyle(fontSize: 20, color: Color(0xFFE8C84A))),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded,
                color: Color(0xFF7C6A55), size: 24),
            tooltip: 'Clear Chat',
            onPressed: () {
              _service.clearChatMessages();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Chat messages cleared 🧹',
                    style: GoogleFonts.rubik(fontWeight: FontWeight.w500),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF2A1F14),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              const Icon(Icons.notifications_rounded,
                  color: Color(0xFFD4A853), size: 30),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE07B54),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFF5EFE0), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Chat bubble ─────────────────────────────────────────────────────────
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF2A1F14)
                  : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 20),
              ),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.rubik(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isUser ? Colors.white : const Color(0xFF2A1F14),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick chips (smart suggestions) ──────────────────────────────────────
  Widget _buildQuickChips() {
    final chips = _service.getSmartSuggestions(count: 4);

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 0, 14, 10),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final chip = chips[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => _handleQuickChip(chip.$2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE8DCCB),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${chip.$1} ${chip.$2}',
                  style: GoogleFonts.rubik(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5C4A35),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Input bar ───────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE0),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE8DCCB).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F1E4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE8DCCB),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  color: const Color(0xFF2A1F14),
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. taxi 120 rupees',
                  hintStyle: GoogleFonts.rubik(
                    fontSize: 14,
                    color: const Color(0xFFB8A898),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF2A1F14),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.send_rounded,
                    color: Color(0xFFE8C84A), size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
