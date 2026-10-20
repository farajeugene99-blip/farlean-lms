import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/ai_service.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isWarning;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isWarning = false,
  });
}

class AiTutorScreen extends StatefulWidget {
  final AiService? aiService;

  const AiTutorScreen({super.key, this.aiService});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  late final AiService _aiService;
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  int? _remainingQuota;

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiService();
    // Guardrail 6: Tidak ada panggilan API di initState()
    // Pesan sambutan awal bersifat lokal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _messages.add(
            _ChatMessage(
              text: l10n.aiTutorWelcome,
              isUser: false,
              time: DateTime.now(),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? predefinedPrompt]) async {
    final text = (predefinedPrompt ?? _promptController.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _isLoading = true;
    });
    _promptController.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.askTutor(text);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _remainingQuota = response.remainingQuota;
        _messages.add(
          _ChatMessage(
            text: response.content,
            isUser: false,
            time: DateTime.now(),
            isWarning: response.isExamLocked,
          ),
        );
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(
          _ChatMessage(
            text: e.toString().replaceFirst('Exception: ', '').replaceFirst('StateError: ', ''),
            isUser: false,
            time: DateTime.now(),
            isWarning: true,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.aiTutorTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    _remainingQuota != null ? 'Sisa kuota: $_remainingQuota sesi' : l10n.aiTutorSubtitle,
                    style: TextStyle(fontSize: 10, color: context.textSecondaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingBubble();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Suggestion Chips (hanya jika pesan masih sedikit)
          if (_messages.length <= 2 && !_isLoading) _buildSuggestionChips(),

          // Bottom Input Composer
          _buildInputComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;
    final isWarning = message.isWarning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: isWarning ? AppTheme.warning.withAlpha(30) : AppTheme.primary.withAlpha(25),
              child: Icon(
                isWarning ? Icons.warning_amber_rounded : Icons.auto_awesome_rounded,
                size: 16,
                color: isWarning ? AppTheme.warning : AppTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primary
                    : (isWarning
                        ? AppTheme.warning.withAlpha(20)
                        : (context.isDarkMode ? AppTheme.surfaceVariantDark : context.cardColor)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: isWarning ? AppTheme.warning.withAlpha(80) : context.borderColor),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isUser
                      ? Colors.white
                      : (isWarning ? (context.isDarkMode ? Colors.amber[200] : Colors.amber[900]) : context.textPrimaryColor),
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primary.withAlpha(25),
            child: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.isDarkMode ? AppTheme.surfaceVariantDark : context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Sedang berpikir...',
                  style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      'Jelaskan konsep Polymorphism dalam OOP',
      'Bagaimana cara kerja Binary Search?',
      'Tips memahami State Management Flutter',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: suggestions.map((text) {
          return ActionChip(
            label: Text(text, style: const TextStyle(fontSize: 11)),
            onPressed: () => _sendMessage(text),
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputComposer() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.borderColor.withAlpha(120))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _promptController,
                decoration: InputDecoration(
                  hintText: l10n.aiTutorHint,
                  hintStyle: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                ),
                maxLines: 3,
                minLines: 1,
                onFieldSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isLoading ? null : () => _sendMessage(),
              icon: const Icon(Icons.arrow_upward_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
