import 'package:flutter/material.dart';
import 'package:frontend/widgets/eco_pulse_widgets.dart';
import 'package:provider/provider.dart';
import '../../../../models/mission_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/collaboration_provider.dart';
import '../../../../theme/app_theme.dart';

class CollaborationTab extends StatefulWidget {
  final Mission mission;

  const CollaborationTab({super.key, required this.mission});

  @override
  State<CollaborationTab> createState() => _CollaborationTabState();
}

class _CollaborationTabState extends State<CollaborationTab> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _checklistController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final PageController _pageController = PageController();
  final FocusNode _commentFocusNode = FocusNode();
  final FocusNode _checklistFocusNode = FocusNode();
  
  int _selectedTab = 0;
  bool _isInitialized = false;
  String? _initError;

  // Loading States
  bool _isSendingComment = false;
  bool _isAddingTask = false;

  @override
  void initState() {
    super.initState();
    _initializeCollaboration();
  }

  Future<void> _initializeCollaboration() async {
    try {
      final provider = context.read<CollaborationProvider>();
      await provider.initBoard(widget.mission.id);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _initError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _initError = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _checklistController.dispose();
    _chatScrollController.dispose();
    _pageController.dispose();
    _commentFocusNode.dispose();
    _checklistFocusNode.dispose();

    context.read<CollaborationProvider>().leaveBoard();

    super.dispose();
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        0, // Newest is at index 0 in reverse mode
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendComment(CollaborationProvider provider) async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSendingComment) return;

    setState(() => _isSendingComment = true);
    try {
      await provider.sendComment(text);
      _commentController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  Future<void> _addChecklistItem(CollaborationProvider provider) async {
    final text = _checklistController.text.trim();
    if (text.isEmpty || _isAddingTask) return;

    setState(() => _isAddingTask = true);
    try {
      await provider.addChecklistItem(text);
      _checklistController.clear();
      _checklistFocusNode.requestFocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingTask = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingOrError();
    }

    final provider = context.watch<CollaborationProvider>();
    final authProvider = context.read<AuthProvider>();
    
    return Column(
      children: [
        _buildPresenceHeader(provider.activeUsers),
        const Divider(height: 1, color: Color(0x1F000000)),
        _buildTabSelector(),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _selectedTab = index);
            },
            children: [
              _buildChatSection(provider, authProvider),
              _buildChecklistSection(provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOrError() {
    if (_initError != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: EcoColors.terracotta),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load collaboration',
                    style: EcoText.bodySM(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _initError!,
                    style: TextStyle(
                      fontSize: 13,
                      color: EcoColors.ink.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _initializeCollaboration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EcoColors.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
      );
    }

    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(EcoColors.forest),
      ),
    );
  }

  Widget _buildPresenceHeader(List<dynamic> users) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: EcoColors.clay,
      child: Row(
        children: [
          // Active indicator with semantic pulse
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: users.isNotEmpty ? EcoColors.violet : EcoColors.ink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: users.isNotEmpty ? [
                BoxShadow(
                  color: EcoColors.violet.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ] : null,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'ACTIVE SQUAD',
            style: EcoText.monoSM(context).copyWith(
              color: EcoColors.forest,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          _buildActiveUserAvatars(users),
        ],
      ),
    );
  }

  Widget _buildActiveUserAvatars(List<dynamic> users) {
    const maxVisible = 4;
    final visibleUsers = users.take(maxVisible).toList();
    final remainingCount = users.length - maxVisible;

    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...visibleUsers.map((user) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _buildUserAvatar(user),
          )),
          if (remainingCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                '+$remainingCount',
                style: EcoText.monoSM(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: EcoColors.ink.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(dynamic user) {
    final userName = user['name'] as String?;
    final initial = userName?.isNotEmpty == true 
        ? userName![0].toUpperCase() 
        : '?';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: EcoColors.violet, width: 2),
        boxShadow: [
          BoxShadow(
            color: EcoColors.ink.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: EcoColors.clay,
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: EcoColors.forest,
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: EcoColors.clay,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - 8) / 2; // -8 for 4px inner padding on each side
          
          return Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                // Sliding Selector Pill
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: _selectedTab * tabWidth,
                  width: tabWidth,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: EcoColors.forest,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: EcoColors.forest.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tab Labels
                Row(
                  children: [
                    _buildTabButton(
                      label: 'CHAT',
                      index: 0,
                      onTap: () {
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                    ),
                    _buildTabButton(
                      label: 'CHECKLIST',
                      index: 1,
                      onTap: () {
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedTab == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: EcoText.monoSM(context).copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: isSelected ? Colors.white : EcoColors.ink.withValues(alpha: 0.4),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildChatSection(CollaborationProvider provider, AuthProvider authProvider) {
    final pinnedComments = provider.comments.where((c) => c.isPinned).toList();
    final otherComments = provider.comments.where((c) => !c.isPinned).toList();

    return Container(
      color: EcoColors.clay,
      child: Column(
        children: [
          if (pinnedComments.isNotEmpty) _buildPinnedSection(provider, pinnedComments),
          Expanded(
            child: otherComments.isEmpty && pinnedComments.isEmpty
                ? _buildEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No messages yet',
                    subtitle: 'Start the conversation with your team',
                  )
                : ListView.builder(
                    controller: _chatScrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(20),
                    itemCount: otherComments.length,
                    itemBuilder: (context, index) {
                      return _buildChatBubble(provider, authProvider, otherComments[index]);
                    },
                  ),
          ),
          _buildChatInput(provider),
        ],
      ),
    );
  }

  Widget _buildPinnedSection(CollaborationProvider provider, List<MissionComment> pinned) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.violet.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoColors.violet.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin_rounded, size: 16, color: EcoColors.violet),
              const SizedBox(width: 8),
              Text(
                'PINNED UPDATES',
                style: EcoText.monoSM(context).copyWith(
                  color: EcoColors.violet,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pinned.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    c.content,
                    style: TextStyle(
                      fontWeight: FontWeight.w700, 
                      fontSize: 13, 
                      height: 1.4,
                      color: EcoColors.ink.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => provider.togglePin(c.id, false),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: EcoColors.violet.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 12, color: EcoColors.violet),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildChatBubble(CollaborationProvider provider, AuthProvider authProvider, dynamic comment) {
    final currentUserId = authProvider.user?.id;
    final isMine = comment.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                comment.userName ?? 'Unknown',
                style: EcoText.monoSM(context).copyWith(
                  fontSize: 9,
                  color: EcoColors.ink.withValues(alpha: 0.5),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMine) _buildPinAction(provider, comment, isMine),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMine ? EcoColors.forest : EcoColors.terracotta,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: EcoColors.ink.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    comment.content ?? '',
                    style: TextStyle(
                      color: isMine ? Colors.white : Colors.white,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: isMine ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (!isMine) _buildPinAction(provider, comment, isMine),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinAction(CollaborationProvider provider, dynamic comment, bool isMine) {
    return Padding(
      padding: EdgeInsets.only(left: isMine ? 0 : 8, right: isMine ? 8 : 0),
      child: InkWell(
        onTap: () => provider.togglePin(comment.id, true),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.push_pin_outlined, 
            size: 14, 
            color: EcoColors.forest.withValues(alpha: 0.2)
          ),
        ),
      ),
    );
  }

  Widget _buildChatInput(CollaborationProvider provider) {
    return Container(
      // 1. Match the background color and padding to the input's intended look
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
      decoration: BoxDecoration(
        color: EcoColors.clay, // The background now fills the whole bottom area
        border: Border(
          top: BorderSide(
            color: EcoColors.ink.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                // 2. We keep the white background ONLY for the text field area
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  // Optional: add a subtle border to define the input better
                  border: Border.all(color: EcoColors.ink.withValues(alpha: 0.05)),
                ),
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Message team...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Colors.black38,
                      fontSize: 14,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _sendComment(provider),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 3. The Send Button now sits cleanly next to the input
            IconButton.filled(
              icon: _isSendingComment 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Icon(Icons.send_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: EcoColors.forest,
                foregroundColor: Colors.white,
                // Match height of the single-line input
                minimumSize: const Size(48, 48), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: _isSendingComment ? null : () => _sendComment(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistSection(CollaborationProvider provider) {
    return Container(
      color: EcoColors.clay, // Consistent background with chat
      child: Column(
        children: [
          Expanded(
            child: provider.checklist.isEmpty
                ? _buildEmptyState(
                    icon: Icons.checklist_rounded,
                    title: 'No tasks yet',
                    subtitle: 'Add tasks to track progress together',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: provider.checklist.length,
                    itemBuilder: (context, index) {
                      final item = provider.checklist[index];
                      return _buildChecklistItem(provider, item);
                    },
                  ),
          ),
          _buildChecklistInput(provider), // Now matches Chat Input
        ],
      ),
    );
  }

  Widget _buildChecklistItem(CollaborationProvider provider, dynamic item) {
    final bool isDone = item.isCompleted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDone ? Colors.white.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? Colors.transparent : EcoColors.forest.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: EcoColors.ink.withValues(alpha: isDone ? 0.01 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CheckboxListTile(
          title: Text(
            item.content ?? '',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isDone ? FontWeight.w500 : FontWeight.w600,
              decoration: isDone ? TextDecoration.lineThrough : null,
              color: isDone ? EcoColors.ink.withValues(alpha: 0.4) : EcoColors.ink,
              height: 1.4,
            ),
          ),
          value: isDone,
          onChanged: (value) => provider.toggleChecklistItem(item.id, value ?? false),
          activeColor: EcoColors.forest,
          checkColor: Colors.white,
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }

  Widget _buildChecklistInput(CollaborationProvider provider) {
    return Container(
      // Match the Chat Input Container
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: EcoColors.clay,
        border: Border(
          top: BorderSide(
            color: EcoColors.ink.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24), // Capsule style
                  border: Border.all(color: EcoColors.ink.withValues(alpha: 0.05)),
                ),
                child: TextField(
                  controller: _checklistController,
                  focusNode: _checklistFocusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Add a new task...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Colors.black38,
                      fontSize: 14,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (_) => _addChecklistItem(provider),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Circular "Add" button matching the "Send" button
            IconButton.filled(
              icon: _isAddingTask
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: EcoColors.forest,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
                shape: const CircleBorder(), // Perfect circle to match chat
              ),
              onPressed: _isAddingTask ? null : () => _addChecklistItem(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: Colors.black.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: EcoColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}