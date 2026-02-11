import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'eco_pulse_widgets.dart';
import 'mission_filter_widgets.dart';

class EcoNotifySheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String hintText;
  final Future<void> Function(String) onSend;
  final List<String> quickMessages;

  const EcoNotifySheet({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.notifications_active_outlined,
    this.hintText = 'Type your message here...',
    required this.onSend,
    this.quickMessages = const [
      'Starting soon!',
      'Check in now!',
      'Location updated.',
      'Mission completed.',
      'Thank you all!',
    ],
  });

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData icon = Icons.notifications_active_outlined,
    String hintText = 'Type your message here...',
    required Future<void> Function(String) onSend,
    List<String>? quickMessages,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EcoNotifySheet(
        title: title,
        subtitle: subtitle,
        icon: icon,
        hintText: hintText,
        onSend: onSend,
        quickMessages:
            quickMessages ??
            const [
              'Starting soon!',
              'Check in now!',
              'Location updated.',
              'Mission completed.',
              'Thank you all!',
            ],
      ),
    );
  }

  @override
  State<EcoNotifySheet> createState() => _EcoNotifySheetState();
}

class _EcoNotifySheetState extends State<EcoNotifySheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: EcoColors.clay,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: EcoColors.violet.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          color: EcoColors.violet,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.fraunces(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: EcoColors.ink,
                              ),
                            ),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                color: EcoColors.ink.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Standardized "Quick Message" UI (Filter Chips)
                  const EcoSectionHeader(title: 'Quick Presets'),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.quickMessages
                          .map(
                            (msg) => EcoFilterChip(
                              label: msg,
                              isSelected: false,
                              onTap: () {
                                setState(() {
                                  _controller.text = msg;
                                });
                              },
                              color: EcoColors.forest,
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 24),
                  EcoTextField(
                    controller: _controller,
                    label: 'Message Content',
                    hint: widget.hintText,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  EcoPulseButton(
                    label: 'Send Message',
                    icon: Icons.send_rounded,
                    width: double.infinity,
                    isLoading: _isSending,
                    backgroundColor: EcoColors.forest,
                    onPressed: () async {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;

                      setModalState(() => _isSending = true);

                      try {
                        await widget.onSend(text);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } finally {
                        if (context.mounted) {
                          setModalState(() => _isSending = false);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
