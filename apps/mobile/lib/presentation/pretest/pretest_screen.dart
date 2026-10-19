import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/content_status.dart';
import '../../models/pretest.dart';
import '../../models/question.dart';
import '../../models/test_attempt.dart';
import '../../repositories/attempt_repository.dart';
import '../../repositories/material_repository.dart';
import '../../repositories/meeting_repository.dart';
import '../../repositories/pretest_repository.dart';
import '../../services/auth_provider.dart';
import '../../services/grade_service.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

class PretestScreen extends StatefulWidget {
  final String pretestId;
  final String classId;
  final String meetingId;
  final PretestRepository? pretestRepository;
  final AttemptRepository? attemptRepository;
  final MaterialRepository? materialRepository;
  final DateTime Function()? nowProvider;

  const PretestScreen({
    super.key,
    required this.pretestId,
    this.classId = '',
    this.meetingId = '',
    this.pretestRepository,
    this.attemptRepository,
    this.materialRepository,
    this.nowProvider,
  });

  @override
  State<PretestScreen> createState() => _PretestScreenState();
}

class _PretestScreenState extends State<PretestScreen> {
  late final PretestRepository _pretestRepository;
  late final AttemptRepository _attemptRepository;
  late final MaterialRepository _materialRepository;

  Pretest? _pretest;
  List<Question> _questions = [];
  TestAttempt? _currentAttempt;
  final Map<String, dynamic> _answers = {};

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasOpenedMateri = false;
  String? _errorMessage;
  String? _errorKey;
  String? _errorParam;

  void _setError(String key, [String? param]) {
    setState(() {
      _errorKey = key;
      _errorParam = param;
      _isLoading = false;
    });
  }

  String _resolveErrorMessage(AppLocalizations l10n) {
    if (_errorKey != null) {
      switch (_errorKey) {
        case 'session_not_active':
          return l10n.quizSessionNotActive;
        case 'not_found':
          return l10n.quizNotFound;
        case 'draft_blocked':
          return l10n.quizDraftBlocked(_errorParam ?? '');
        case 'invalid_class_meeting':
          return l10n.quizInvalidClassMeeting;
        case 'no_questions':
          return l10n.quizNoQuestionsUploaded;
        case 'stale_session':
          return l10n.quizStaleSessionEnded;
        case 'max_attempts':
          return l10n.quizMaxAttemptsReached(_errorParam ?? '');
        case 'load_failed':
          return l10n.quizLoadFailedGeneric(_errorParam ?? '');
      }
    }
    return _errorMessage ?? l10n.quizPretestLoadFailed;
  }

  // Timer State
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  Timer? _autosaveDebounce;

  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _pretestRepository = widget.pretestRepository ?? PretestRepository();
    _attemptRepository = widget.attemptRepository ?? AttemptRepository();
    _materialRepository = widget.materialRepository ?? MaterialRepository();
    _initializePretestSession();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autosaveDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initializePretestSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorKey = null;
      _errorParam = null;
    });

    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;
    if (uid == null) {
      _setError('session_not_active');
      return;
    }

    try {
      // 1. Ambil metadata Pretest terlebih dahulu
      final pretest = await _pretestRepository.getPretest(widget.pretestId);
      if (pretest == null) {
        _setError('not_found');
        return;
      }
      _pretest = pretest;

      // Enforce status Published di sisi klien (Client Published Gate)
      if (pretest.status != ContentStatus.published) {
        _setError('draft_blocked', pretest.status.value);
        return;
      }

      final effectiveClassId = widget.classId.isNotEmpty ? widget.classId : pretest.classId;
      final effectiveMeetingId = widget.meetingId.isNotEmpty ? widget.meetingId : pretest.meetingId;

      if (effectiveClassId.isEmpty || effectiveMeetingId.isEmpty) {
        _setError('invalid_class_meeting');
        return;
      }

      // 2. Cek Gate: Materi harus pernah dibuka
      _hasOpenedMateri = await _materialRepository.hasOpenedMateri(
        classId: effectiveClassId,
        meetingId: effectiveMeetingId,
        uid: uid,
      );

      if (!_hasOpenedMateri) {
        setState(() => _isLoading = false);
        return;
      }

      // 3. Ambil daftar soal
      final questionsList = await _pretestRepository.getQuestions(widget.pretestId);
      if (questionsList.isEmpty) {
        _setError('no_questions');
        return;
      }

      // 4. Periksa sesi attempt: Recovery vs New Attempt
      final inProgressAttempt = await _attemptRepository.getInProgressAttempt(
        userId: uid,
        testId: widget.pretestId,
      );

      if (inProgressAttempt != null) {
        // Cek apakah attempt recovery ini sudah kadaluarsa (expired)
        final now = (widget.nowProvider ?? DateTime.now)();
        final durationSeconds = pretest.duration * 60;
        final startedAt = inProgressAttempt.startedAt ?? now;
        final elapsedSeconds = now.difference(startedAt).inSeconds;
        final remaining = durationSeconds - elapsedSeconds;

        if (remaining <= 0) {
          // Attempt basi. Jika tidak ada jawaban sama sekali, tandai sesi berakhir tanpa auto-submit 0
          if (inProgressAttempt.answers.isEmpty) {
            _setError('stale_session');
            return;
          }
        }

        // RECOVERY SESSION
        _currentAttempt = inProgressAttempt;
        _answers.addAll(inProgressAttempt.answers);

        // Rekonstruksi urutan soal berdasarkan question_order yang tersimpan
        final Map<String, Question> qMap = {for (var q in questionsList) q.id: q};
        _questions = inProgressAttempt.questionOrder
            .map((qid) => qMap[qid])
            .whereType<Question>()
            .toList();
        if (_questions.isEmpty) _questions = questionsList;
      } else {
        // Cek kuota max_attempts
        final count = await _attemptRepository.getAttemptCount(
          userId: uid,
          testId: widget.pretestId,
        );
        if (count >= pretest.maxAttempts) {
          _setError('max_attempts', pretest.maxAttempts.toString());
          return;
        }

        // Buat attempt baru dengan urutan acak tersimpan
        final shuffledList = List<Question>.from(questionsList)..shuffle();
        _questions = shuffledList;
        final questionOrder = _questions.map((q) => q.id).toList();

        final newAttempt = await _attemptRepository.startAttempt(
          userId: uid,
          testId: widget.pretestId,
          classId: effectiveClassId,
          attemptNo: count + 1,
          questionOrder: questionOrder,
        );
        _currentAttempt = newAttempt;
      }

      // 5. Hitung Sisa Waktu berdasarkan started_at waktu server
      _startServerTimer();

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        _setError('load_failed', e.toString());
      }
    }
  }

  void _startServerTimer() {
    if (_pretest == null || _currentAttempt == null) return;

    final now = (widget.nowProvider ?? DateTime.now)();
    final durationSeconds = _pretest!.duration * 60;
    final startedAt = _currentAttempt!.startedAt ?? now;
    final elapsedSeconds = now.difference(startedAt).inSeconds;

    _remainingSeconds = durationSeconds - elapsedSeconds;
    if (_remainingSeconds <= 0) {
      _remainingSeconds = 0;
      _autoSubmitOnTimeUp();
      return;
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _autoSubmitOnTimeUp();
        }
      });
    });
  }

  void _onAnswerSelected(String questionId, dynamic answerValue) {
    setState(() {
      _answers[questionId] = answerValue;
    });

    // Debounced autosave (1 detik)
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(const Duration(seconds: 1), () {
      if (_currentAttempt != null) {
        _attemptRepository.autosaveAnswers(
          attemptId: _currentAttempt!.id,
          answers: _answers,
        );
      }
    });
  }

  Future<void> _autoSubmitOnTimeUp() async {
    if (_isSubmitting) return;
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.quizTimeUpAutosaved),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
    await _submitAttempt(autoSubmit: true, reason: 'timeout');
  }

  Future<void> _confirmSubmit() async {
    final l10n = AppLocalizations.of(context);
    final unanswered = _questions.length - _answers.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.quizConfirmSubmitTitle),
        content: Text(
          unanswered > 0
              ? l10n.quizConfirmUnansweredBody(unanswered)
              : l10n.quizConfirmSubmitBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.btnCancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: Text(l10n.quizBtnSubmit),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submitAttempt(autoSubmit: false, reason: 'manual');
    }
  }

  Future<void> _submitAttempt({bool autoSubmit = false, String? reason}) async {
    if (_isSubmitting || _currentAttempt == null) return;
    setState(() => _isSubmitting = true);

    _countdownTimer?.cancel();
    _autosaveDebounce?.cancel();

    try {
      // Simpan jawaban final sebelum pemanggilan grade
      await _attemptRepository.autosaveAnswers(
        attemptId: _currentAttempt!.id,
        answers: _answers,
      );

      // Panggil backend /api/grade untuk grading server-side yang idempoten
      final gradeService = GradeService();
      final gradeResult = await gradeService.submitAndGrade(
        _currentAttempt!.id,
        autoSubmit: autoSubmit,
        reason: reason,
      );

      // Pengerjaan disimpan dan berhasil dinilai
      if (!mounted) return;
      await _showResultDialog(gradeResult);
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
        SnackBar(content: Text(l10n.quizSubmitFailed(e.toString())), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _handleUncertainSubmitResult() async {
    TestAttempt? freshAttempt;
    try {
      freshAttempt = await _attemptRepository.getAttempt(_currentAttempt!.id);
    } catch (_) {}

    if (!mounted) return;

    // Cabang A (Graded): Transaksi server ternyata selesai tepat waktu sebelum koneksi terputus
    if (freshAttempt != null && freshAttempt.status == AttemptStatus.graded) {
      await _showResultDialog(
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

    // Cabang B (In-Progress): Server belum memproses, kuis masih aktif
    if (freshAttempt != null && freshAttempt.status == AttemptStatus.inProgress) {
      final l10n = AppLocalizations.of(context);
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

    // Cabang C (Tidak Dapat Memastikan): Status tidak dapat dipastikan
    final l10n = AppLocalizations.of(context);
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

  Future<void> _showResultDialog(GradeResult gradeResult) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
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
              l10n.quizFinalScore(gradeResult.score.toString()),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.quizPointsEarned(gradeResult.pointsEarned.toString(), gradeResult.totalPoints.toString()),
              style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.quizPretestAnswersLocked,
              style: TextStyle(color: context.textSecondaryColor),
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
      return Scaffold(body: LoadingIndicator(message: l10n.quizPretestLoading));
    }

    if (_errorMessage != null || _errorKey != null || _pretest == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.meetingModulePretest)),
        body: ErrorView(
          message: _resolveErrorMessage(l10n),
          onRetry: _initializePretestSession,
        ),
      );
    }

    if (!_hasOpenedMateri) {
      return _buildMateriGateScreen();
    }

    final question = _questions[_currentQuestionIndex];
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timerString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_pretest!.title),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _remainingSeconds < 120
                  ? AppTheme.error.withAlpha(20)
                  : context.primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _remainingSeconds < 120 ? AppTheme.error : context.primaryColor,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: _remainingSeconds < 120 ? AppTheme.error : context.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  timerString,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _remainingSeconds < 120 ? AppTheme.error : context.primaryColor,
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
            color: context.primaryColor,
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.quizQuestionOf(_currentQuestionIndex + 1, _questions.length),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.quizPoints(question.points),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Question Text
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Text(
                      question.text,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Options List
                ...List.generate(question.options.length, (optIndex) {
                  final optionText = question.options[optIndex];
                  final isSelected = _answers[question.id] == optIndex;

                  return Card(
                    color: isSelected ? context.primaryColor.withAlpha(25) : context.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? context.primaryColor : context.borderColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    // ignore: deprecated_member_use
                    child: RadioListTile<int>(
                      title: Text(optionText, style: const TextStyle(fontSize: 14)),
                      value: optIndex,
                      // ignore: deprecated_member_use
                      groupValue: _answers[question.id] as int?,
                      // ignore: deprecated_member_use
                      onChanged: _isSubmitting
                          ? null
                          : (val) {
                              if (val != null) {
                                _onAnswerSelected(question.id, val);
                              }
                            },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Bottom Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _currentQuestionIndex--),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(l10n.quizBtnPrev),
                  )
                else
                  const Spacer(),
                const Spacer(),
                if (_currentQuestionIndex < _questions.length - 1)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _currentQuestionIndex++),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(l10n.quizBtnNext),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _confirmSubmit,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(l10n.quizBtnSubmit),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMateriGateScreen() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.quizGateLockedTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock_rounded, size: 56, color: AppTheme.warning),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.quizGateMateriNotOpened,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.quizGateLockedDesc,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondaryColor, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final effectiveMeetingId = widget.meetingId.isNotEmpty
                      ? widget.meetingId
                      : (_pretest?.meetingId ?? '');
                  final effectiveClassId = widget.classId.isNotEmpty
                      ? widget.classId
                      : (_pretest?.classId ?? '');

                  if (effectiveMeetingId.isNotEmpty) {
                    try {
                      final meeting = await MeetingRepository().getMeeting(effectiveMeetingId);
                      if (meeting != null && meeting.materiId != null && meeting.materiId!.isNotEmpty) {
                        if (!mounted) return;
                        await context.push(
                          '/materials/${meeting.materiId}?classId=$effectiveClassId&meetingId=$effectiveMeetingId',
                        );
                        if (mounted) {
                          _initializePretestSession();
                        }
                        return;
                      }
                    } catch (_) {}
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.menu_book_rounded, size: 20),
                label: Text(l10n.quizGateOpenMaterialBtn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
