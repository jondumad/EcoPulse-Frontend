import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/collaboration_provider.dart';
import '../../theme/app_theme.dart';
import '../../components/grain_overlay.dart';
import '../../widgets/eco_pulse_widgets.dart';

class CollaborationBoardScreen extends StatefulWidget {
  final int missionId;
  final String missionTitle;

  const CollaborationBoardScreen({
    super.key,
    required this.missionId,
    required this.missionTitle,
  });

  @override
  State<CollaborationBoardScreen> createState() =>
      _CollaborationBoardScreenState();
}

class _CollaborationBoardScreenState extends State<CollaborationBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();
  CollaborationProvider? _provider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider == null) {
      _provider = Provider.of<CollaborationProvider>(context, listen: false);
      _provider!.initBoard(widget.missionId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    _provider?.leaveBoard();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clay,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.missionTitle, style: const TextStyle(fontSize: 16)),
            const Text(
              'Collaboration Board',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppTheme.forest,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              _PresenceHeader(),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Chat & Updates'),
                  Tab(text: 'Checklist'),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: AppTheme.violet,
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: GrainOverlay()),
          TabBarView(
            controller: _tabController,
            children: [
              _ChatTab(commentController: _commentController),
              _ChecklistTab(),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresenceHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activeUsers = context.watch<CollaborationProvider>().activeUsers;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'Active:',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: activeUsers.length,
              itemBuilder: (context, index) {
                final user = activeUsers[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Tooltip(
                    message: user['name'],
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.violet,
                      child: Text(
                        user['name'][0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.forest,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  final TextEditingController commentController;

  const _ChatTab({required this.commentController});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollaborationProvider>();
    final pinnedComments = provider.comments.where((c) => c.isPinned).toList();
    final otherComments = provider.comments.where((c) => !c.isPinned).toList();

    debugPrint(
      'CollaborationBoardScreen: Rendering ChatTab with ${provider.comments.length} total comments',
    );

    return Column(
      children: [
        if (pinnedComments.isNotEmpty)
          _PinnedSection(pinnedComments: pinnedComments),
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: otherComments.length,
            itemBuilder: (context, index) {
              final comment = otherComments[index];
              return _CommentBubble(comment: comment);
            },
          ),
        ),
        _MessageInput(commentController: commentController),
      ],
    );
  }
}

class _PinnedSection extends StatelessWidget {
  final List<MissionComment> pinnedComments;

  const _PinnedSection({required this.pinnedComments});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.forest.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.forest.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin, size: 16, color: AppTheme.terracotta),
              const SizedBox(width: 8),
              Text(
                'PINNED UPDATES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.ink.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...pinnedComments.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                c.content,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final MissionComment comment;

  const _CommentBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${comment.createdAt.hour}:${comment.createdAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.ink.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  comment.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 16,
                ),
                onPressed: () => context
                    .read<CollaborationProvider>()
                    .togglePin(comment.id, !comment.isPinned),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(comment.content),
          ),
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController commentController;

  const _MessageInput({required this.commentController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: 'Share an update...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.clay.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: AppTheme.forest,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                if (commentController.text.isNotEmpty) {
                  context.read<CollaborationProvider>().sendComment(
                    commentController.text,
                  );
                  commentController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollaborationProvider>();
    final checklist = provider.checklist;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: checklist.length,
            itemBuilder: (context, index) {
              final item = checklist[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  title: Text(
                    item.content,
                    style: TextStyle(
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isCompleted
                          ? AppTheme.ink.withValues(alpha: 0.5)
                          : AppTheme.ink,
                    ),
                  ),
                  value: item.isCompleted,
                  onChanged: (val) =>
                      provider.toggleChecklistItem(item.id, val ?? false),
                  activeColor: AppTheme.forest,
                ),
              );
            },
          ),
        ),
        _AddChecklistItemInput(),
      ],
    );
  }
}

class _AddChecklistItemInput extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Add task...'),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: AppTheme.forest,
              size: 32,
            ),
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                context.read<CollaborationProvider>().addChecklistItem(
                  _controller.text,
                );
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
