import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'eco_pulse_widgets.dart';
import 'atoms/eco_button.dart';
import 'mission_filter_widgets.dart';
import 'package:frontend/theme/app_theme.dart';

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

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData icon = Icons.notifications_active_outlined,
    String hintText = 'Type your message here...',
    required Future<void> Function(String) onSend,
    List<String>? quickMessages,
  }) {
    return showDialog(
      context: context,
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
    return EcoDialog(
      title: widget.title,
      subtitle: widget.subtitle,
      icon: Icon(widget.icon, color: AppTheme.violet, size: 24),
      actions: [
        EcoPulseButton(
          label: 'Cancel',
          variant: EcoButtonVariant.secondary,
          isSmall: true,
          onPressed: () => Navigator.pop(context),
        ),
        EcoPulseButton(
          label: 'Send',
          icon: Icons.send_rounded,
          isSmall: true,
          isLoading: _isSending,
          onPressed: () async {
            final text = _controller.text.trim();
            if (text.isEmpty) return;

            setState(() => _isSending = true);

            try {
              await widget.onSend(text);
              if (!context.mounted) return;
              Navigator.pop(context);
            } finally {
              if (mounted) {
                setState(() => _isSending = false);
              }
            }
          },
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EcoSectionHeader(title: 'Quick Presets'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.quickMessages
                  .map(
                    (msg) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: EcoFilterChip(
                        label: msg,
                        isSelected: _controller.text == msg,
                        onTap: () {
                          setState(() {
                            _controller.text = msg;
                          });
                        },
                        color: AppTheme.forest,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          EcoTextField(
            controller: _controller,
            label: 'Message Content',
            hintText: widget.hintText,
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}
