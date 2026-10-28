import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/ai_service.dart';
import '../common/hutao_avatar.dart';

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
  final String? classId;
  final String? meetingId;
  final String? materiId;
  final String? materiTitle;
  final String? initialPrompt;

  const AiTutorScreen({
    super.key,
    this.aiService,
    this.classId,
    this.meetingId,
    this.materiId,
    this.materiTitle,
    this.initialPrompt,
  });

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
  int? _remainingBurst;
  int? _remainingDaily;
  bool _contextDismissed = false;

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiService();
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      _promptController.text = widget.initialPrompt!.trim();
    }
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
      final response = await _aiService.askTutor(
        text,
        classId: _contextDismissed ? null : widget.classId,
        meetingId: _contextDismissed ? null : widget.meetingId,
        materiId: _contextDismissed ? null : widget.materiId,
      );
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _remainingQuota = response.remainingQuota;
        _remainingBurst = response.remainingBurst;
        _remainingDaily = response.remainingDaily;
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
      if (e is AiException && e.statusCode == 429) {
        _remainingQuota = 0;
      }
      final displayMsg = e.toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('StateError: ', '')
          .replaceFirst('Bad state: ', '')
          .trim();
      setState(() {
        _isLoading = false;
        _messages.add(
          _ChatMessage(
            text: displayMsg.isNotEmpty ? displayMsg : 'Gagal memproses pertanyaan Anda.',
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
            const HutaoAvatar(size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.aiTutorTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    _remainingQuota != null && _remainingBurst != null && _remainingDaily != null
                        ? l10n.aiTutorQuotaSubtitle(_remainingQuota!, _remainingBurst!, _remainingDaily!)
                        : (_remainingQuota != null ? 'Sisa kuota: $_remainingQuota' : l10n.aiTutorSubtitle),
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
          if (!_contextDismissed && (widget.materiTitle != null || widget.materiId != null))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primary.withAlpha(15),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Konteks: ${widget.materiTitle ?? "Materi Terpilih"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _contextDismissed = true),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
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

  MarkdownStyleSheet _buildMarkdownStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;
    final borderColor = context.borderColor;

    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: TextStyle(
        fontSize: 13,
        height: 1.45,
        color: textPrimary,
      ),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      em: TextStyle(
        fontStyle: FontStyle.italic,
        color: textPrimary,
      ),
      h1: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        height: 1.4,
        color: textPrimary,
      ),
      h2: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        height: 1.35,
        color: textPrimary,
      ),
      h3: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        height: 1.3,
        color: textPrimary,
      ),
      h4: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.bold,
        height: 1.3,
        color: textPrimary,
      ),
      listBullet: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
      listBulletPadding: const EdgeInsets.only(right: 6),
      // Inline code (TextStyle murni tanpa borderRadius/padding)
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        backgroundColor: isDark ? Colors.black26 : const Color(0xFFE2E8F0),
        color: isDark ? const Color(0xFF4FD1C5) : const Color(0xFF0F766E),
      ),
      // Multiline codeblock (BoxDecoration dengan borderRadius 8 dan padding 10)
      codeblockDecoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      codeblockPadding: const EdgeInsets.all(10),
      codeblockAlign: WrapAlignment.start,
      // Blockquote
      blockquote: TextStyle(
        fontSize: 13,
        height: 1.45,
        fontStyle: FontStyle.italic,
        color: textSecondary,
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
        border: const Border(
          left: BorderSide(color: AppTheme.primary, width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      // Table
      tableHead: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: textPrimary,
      ),
      tableBody: TextStyle(
        fontSize: 12,
        color: textPrimary,
      ),
      tableBorder: TableBorder.all(color: borderColor, width: 1),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 1,
            color: borderColor,
          ),
        ),
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
            HutaoAvatar(size: 28, isWarning: isWarning),
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
              child: isUser
                  ? Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.white,
                      ),
                    )
                  : (isWarning
                      ? Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: context.isDarkMode ? Colors.amber[200] : Colors.amber[900],
                          ),
                        )
                      : SelectionArea(
                          child: MarkdownBody(
                            data: message.text,
                            selectable: false,
                            shrinkWrap: true,
                            onTapLink: (text, href, title) async {
                              if (href != null) {
                                final uri = Uri.tryParse(href);
                                if (uri != null && await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              }
                            },
                            styleSheet: _buildMarkdownStyle(context),
                          ),
                        )),
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
          const HutaoAvatar(size: 28),
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
