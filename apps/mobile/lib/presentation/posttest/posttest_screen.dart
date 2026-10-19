import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/content_status.dart';
import '../../models/posttest.dart';
import '../../models/question.dart';
import '../../models/test_attempt.dart';
import '../../repositories/attempt_repository.dart';
import '../../repositories/posttest_repository.dart';
import '../../services/auth_provider.dart';
import '../../services/grade_service.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

class PosttestScreen extends StatefulWidget {
  final String posttestId;
  final String classId;
  final String meetingId;
  final PosttestRepository? posttestRepository;
  final AttemptRepository? attemptRepository;
  final DateTime Function()? nowProvider;

  const PosttestScreen({
    super.key,
    required this.posttestId,
    this.classId = '',
    this.meetingId = '',
    this.posttestRepository,
    this.attemptRepository,
    this.nowProvider,
  });

  @override
  State<PosttestScreen> createState() => _PosttestScreenState();
}

class _PosttestScreenState extends State<PosttestScreen> {
  late final PosttestRepository _posttestRepository;
  late final AttemptRepository _attemptRepository;

  Posttest? _posttest;
  List<Question> _questions = [];
  TestAttempt? _currentAttempt;
  final Map<String, dynamic> _answers = {};

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _errorKey;
  String? _errorParam1;
  String? _errorParam2;

  void _setError(String key, [String? param1, String? param2]) {
    setState(() {
      _errorKey = key;
      _errorParam1 = param1;
      _errorParam2 = param2;
      _isLoading = false;
    });
  }

  String _resolveErrorMessage(AppLocalizations l10n) {
    if (_errorKey != null) {
      switch (_errorKey) {
        case 'session_not_active':
          return l10n.quizSessionNotActive;
        case 'not_found':
          return l10n.quizPosttestNotFound;
        case 'draft_blocked':
          return l10n.quizDraftBlocked(_errorParam1 ?? '');
        case 'invalid_class':
          return l10n.quizInvalidClass;
        case 'no_questions_configured':
          return l10n.quizNoQuestionsConfigured;
        case 'max_attempts':
          return l10n.quizPosttestMaxAttemptsReached(_errorParam1 ?? '0', _errorParam2 ?? '1');
        case 'stale_session':
          return l10n.quizStaleSessionEnded;
        case 'load_failed':
          return l10n.quizPosttestLoadFailed(_errorParam1 ?? '');
      }
    }
    return _errorMessage ?? l10n.quizPosttestUnavailable;
  }

  // Timer State
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  Timer? _autosaveDebounce;

  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _posttestRepository = widget.posttestRepository ?? PosttestRepository();
    _attemptRepository = widget.attemptRepository ?? AttemptRepository();
    _loadPosttestSession();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autosaveDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPosttestSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorKey = null;
      _errorParam1 = null;
      _errorParam2 = null;
    });

    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;

    if (uid == null) {
      _setError('session_not_active');
      return;
    }

    try {
      final posttest = await _posttestRepository.getPosttest(widget.posttestId);
      if (posttest == null) {
        _setError('not_found');
        return;
      }
      _posttest = posttest;

      // Enforce status Published di sisi klien
      if (posttest.status != ContentStatus.published) {
        _setError('draft_blocked', posttest.status.value);
        return;
      }

      final effectiveClassId = widget.classId.isNotEmpty ? widget.classId : posttest.classId;
      if (effectiveClassId.isEmpty) {
        _setError('invalid_class');
        return;
      }

      final rawQuestions = await _posttestRepository.getQuestions(widget.posttestId);
      if (rawQuestions.isEmpty) {
        _setError('no_questions_configured');
        return;
      }

      // 1. Cek attempt in_progress yang sedang berjalan
      TestAttempt? attempt = await _attemptRepository.getInProgressAttempt(
        userId: uid,
        testId: widget.posttestId,
      );

      if (attempt == null) {
        // Cek apakah kuota attempt masih tersedia
        final attemptCount = await _attemptRepository.getAttemptCount(
          userId: uid,
          testId: widget.posttestId,
        );

        if (attemptCount >= posttest.maxAttempts) {
          _setError('max_attempts', '$attemptCount', '${posttest.maxAttempts}');
          return;
        }

        // Acak soal dan mulai attempt baru
        final shuffled = List<Question>.from(rawQuestions)..shuffle();
        final questionOrder = shuffled.map((q) => q.id).toList();

        attempt = await _attemptRepository.startAttempt(
          userId: uid,
          testId: widget.posttestId,
          classId: effectiveClassId,
          attemptNo: attemptCount + 1,
          questionOrder: questionOrder,
          kind: 'posttest',
        );

        _questions = shuffled;
      } else {
        // Cek apakah attempt recovery ini sudah kadaluarsa (expired)
        final now = (widget.nowProvider ?? DateTime.now)();
        final durationSeconds = posttest.duration * 60;
        final startedAt = attempt.startedAt ?? now;
        final elapsedSeconds = now.difference(startedAt).inSeconds;
        final remaining = durationSeconds - elapsedSeconds;

        if (remaining <= 0) {
          if (attempt.answers.isEmpty) {
            _setError('stale_session');
            return;
          }
        }

        // Pulihkan urutan soal dari attempt sebelumnya
        final questionMap = {for (final q in rawQuestions) q.id: q};
        _questions = attempt.questionOrder
            .map((id) => questionMap[id])
            .whereType<Question>()
            .toList();

        if (_questions.isEmpty) {
          _questions = rawQuestions;
        }

        // Pulihkan jawaban yang tersimpan
        _answers.addAll(attempt.answers);
      }

      _currentAttempt = attempt;

      // 2. Hitung Sisa Waktu dari started_at
      _startTimer(posttest, attempt);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        _setError('load_failed', e.toString());
      }
    }
  }

  void _startTimer(Posttest posttest, TestAttempt attempt) {
    _countdownTimer?.cancel();
    final now = (widget.nowProvider ?? DateTime.now)();
    final startTime = attempt.startedAt ?? now;
    final elapsedSec = now.difference(startTime).inSeconds;
    final totalAllowedSec = posttest.duration * 60;
    final left = totalAllowedSec - elapsedSec;

    if (left <= 0) {
      _remainingSeconds = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSubmitOnTimeUp();
      });
      return;
    }

    _remainingSeconds = left;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        _autoSubmitOnTimeUp();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _onAnswerSelected(String questionId, int optionIndex) {
    setState(() {
      _answers[questionId] = optionIndex;
    });

    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(const Duration(milliseconds: 800), () {
      final attempt = _currentAttempt;
      if (attempt != null && attempt.status.isInProgress) {
        _attemptRepository.autosaveAnswers(
          attemptId: attempt.id,
          answers: _answers,
        );
      }
    });
  }

  Future<void> _submitAttempt({bool autoSubmit = false, String? reason}) async {
    final attempt = _currentAttempt;
    if (attempt == null || _isSubmitting) return;

    if (!autoSubmit) {
      final l10n = AppLocalizations.of(context);
      final unansweredCount = _questions.length - _answers.length;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.quizConfirmSubmitTitle),
          content: Text(
            unansweredCount > 0
                ? l10n.quizConfirmUnansweredBody(unansweredCount)
                : l10n.quizConfirmSubmitBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.btnCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              child: Text(l10n.quizBtnSubmit),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);
    _countdownTimer?.cancel();
    _autosaveDebounce?.cancel();

    try {
      // Simpan jawaban terakhir sebelum submit
      await _attemptRepository.autosaveAnswers(
        attemptId: attempt.id,
        answers: _answers,
      );

      final gradeService = GradeService();
      final gradeResult = await gradeService.submitAndGrade(
        attempt.id,
        autoSubmit: autoSubmit,
        reason: reason ?? (autoSubmit ? 'timeout' : 'manual'),
      );

      if (!mounted) return;
      _showResultDialog(gradeResult);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (e is GradeException && e.code == 'DEADLINE_PASSED') {
        _showDeadlineExpiredDialog();
        return;
      }

      if (e is GradeException && e.isUncertainResult) {
        await _handleUncertainSubmitResult();
        return;
      }

      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.quizSubmitFailed(e.toString())),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _handleUncertainSubmitResult() async {
    TestAttempt? freshAttempt;
    try {
      freshAttempt = await _attemptRepository.getAttempt(_currentAttempt!.id);
    } catch (_) {}

    if (!mounted) return;

    if (freshAttempt != null && freshAttempt.status == AttemptStatus.graded) {
      _showResultDialog(
        GradeResult(
          success: true,
          attemptId: freshAttempt.id,
          score: freshAttempt.score ?? 0.0,
          pointsEarned: 0,
          totalPoints: 0,
          status: 'graded',
          message: 'Hasil kuis telah dinilai oleh server.',
          isIdempotent: true,
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context);
    if (freshAttempt != null && freshAttempt.status == AttemptStatus.inProgress) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.wifi_tethering_error_rounded, color: AppTheme.warning),
              const SizedBox(width: 8),
              Text(l10n.quizPendingEvaluationTitle),
            ],
          ),
          content: Text(l10n.quizPendingEvaluationBody),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.quizUnderstand),
            ),
          ],
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppTheme.error),
            const SizedBox(width: 8),
            Text(l10n.quizConnErrorTitle),
          ],
        ),
        content: Text(l10n.quizConnErrorBody),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.quizUnderstand),
          ),
        ],
      ),
    );
  }

  void _showDeadlineExpiredDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.timer_off_rounded, color: AppTheme.error),
            const SizedBox(width: 8),
            Text(l10n.quizDeadlineExpiredTitle),
          ],
        ),
        content: Text(l10n.quizDeadlineExpiredBody),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(l10n.quizGateBackToMeetingBtn),
          ),
        ],
      ),
    );
  }

  void _autoSubmitOnTimeUp() {
    if (_isSubmitting || !mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.quizTimeUpAutosubmitted),
        backgroundColor: AppTheme.warning,
      ),
    );
    _submitAttempt(autoSubmit: true, reason: 'timeout');
  }

  void _showResultDialog(GradeResult result) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.success),
            const SizedBox(width: 8),
            Text(l10n.quizSubmitSuccessTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.quizFinalScore(result.score.toStringAsFixed(1)),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.quizPointsEarned(result.pointsEarned.toString(), result.totalPoints.toString()),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.quizPosttestAnswersLocked,
              style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(l10n.quizGateBackToMeetingBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        body: LoadingIndicator(message: l10n.quizPosttestLoading),
      );
    }

    if (_errorMessage != null || _errorKey != null || _posttest == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.meetingModulePosttest)),
        body: ErrorView(
          message: _resolveErrorMessage(l10n),
          onRetry: _loadPosttestSession,
        ),
      );
    }

    final posttest = _posttest!;
    final currentQ = _questions[_currentQuestionIndex];
    final selectedOption = _answers[currentQ.id];
    final isDark = context.isDarkMode;
    final accentColor = isDark ? const Color(0xFFC084FC) : Colors.deepPurple;

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timerText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(posttest.title),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _remainingSeconds < 180 ? AppTheme.error.withAlpha(20) : context.primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: _remainingSeconds < 180 ? AppTheme.error : context.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  timerText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _remainingSeconds < 180 ? AppTheme.error : context.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Question Progress Indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: context.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Text(
                      l10n.quizQuestionOf(_currentQuestionIndex + 1, _questions.length),
                      style: TextStyle(fontWeight: FontWeight.bold, color: context.textSecondaryColor),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.quizPoints(currentQ.points),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Question Text
                Text(
                  currentQ.text,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),

                // Options List
                ...List.generate(currentQ.options.length, (idx) {
                  final isSelected = selectedOption == idx;
                  final optionChar = String.fromCharCode(65 + idx); // A, B, C...
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: _isSubmitting ? null : () => _onAnswerSelected(currentQ.id, idx),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor.withAlpha(25) : context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? accentColor : context.borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: isSelected ? accentColor : context.backgroundColor,
                              child: Text(
                                optionChar,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : context.textPrimaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                currentQ.options[idx],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Bottom Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _currentQuestionIndex--);
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(l10n.quizBtnPrev),
                  ),
                const Spacer(),
                if (_currentQuestionIndex < _questions.length - 1)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _currentQuestionIndex++);
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(l10n.quizBtnNext),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _submitAttempt(autoSubmit: false),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    icon: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(l10n.quizBtnSubmit),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
