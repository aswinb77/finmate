import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/bug_report.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';

class BugReportModal extends StatefulWidget {
  const BugReportModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BugReportModal(),
    );
  }

  @override
  State<BugReportModal> createState() => _BugReportModalState();
}

class _BugReportModalState extends State<BugReportModal> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitBugReport() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    final user = AuthService().currentUser;
    final report = BugReport(
      userId: user?.uid ?? 'guest',
      userEmail: user?.email ?? 'anonymous@finmate.app',
      description: text,
      status: 'open',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      synced: false,
    );

    await LocalStorageService().saveBugReport(report);
    SyncService().refreshUnsyncedCount();
    if (SyncService().isOnline) {
      SyncService().triggerSync();
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bug report saved locally & queued for sync! 🐛',
            style: GoogleFonts.rubik(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF2A1F14),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardSpace),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4826A).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🐛', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Report a Bug',
                    style: GoogleFonts.rubik(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A1F14),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF8C7E72)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Found an issue? Describe what happened below. It will be saved locally immediately and synced to our team when online.',
            style: GoogleFonts.rubik(
              fontSize: 14,
              color: const Color(0xFF8C7E72),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            style: GoogleFonts.rubik(fontSize: 15, color: const Color(0xFF2A1F14)),
            decoration: InputDecoration(
              hintText: 'e.g. Spent amount was not updating on home screen after logging...',
              hintStyle: GoogleFonts.rubik(color: const Color(0xFFB5A99B)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE8DFD5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD4826A), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBugReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4826A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit Report',
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
