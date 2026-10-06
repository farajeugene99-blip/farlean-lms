import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
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

  const PosttestScreen({
    super.key,
    required this.posttestId,
    this.classId = '',
    this.meetingId = '',
    this.posttestRepository,
    this.attemptRepository,
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
    });

    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;

    if (uid == null) {
      setState(() {
        _errorMessage = 'Sesi login tidak valid. Silakan masuk kembali.';
        _isLoading = false;
      });
      return;
    }

    try {
      final posttest = await _posttestRepository.getPosttest(widget.posttestId);
      if (posttest == null) {
        setState(() {
          _errorMessage = 'Kuis post test tidak ditemukan.';
          _isLoading = false;
        });
        return;
      }

      final rawQuestions = await _posttestRepository.getQuestions(widget.posttestId);
      if (rawQuestions.isEmpty) {
        setState(() {
          _errorMessage = 'Belum ada soal yang dikonfigurasi untuk post test ini.';
          _isLoading = false;
        });
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
          setState(() {
            _errorMessage = 'Anda telah mencapai batas maksimal percobaan ($attemptCount/${posttest.maxAttempts}).';
            _isLoading = false;
          });
          return;
        }

        // Acak soal dan mulai attempt baru
        final shuffled = List<Question>.from(rawQuestions)..shuffle();
        final questionOrder = shuffled.map((q) => q.id).toList();

        attempt = await _attemptRepository.startAttempt(
          userId: uid,
          testId: widget.posttestId,
          classId: widget.classId,
          attemptNo: attemptCount + 1,
          questionOrder: questionOrder,
          kind: 'posttest',
        );

        _questions = shuffled;
      } else {
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

      // 2. Hitung Sisa Waktu dari started_at
      _startTimer(posttest, attempt);

      setState(() {
        _posttest = posttest;
        _currentAttempt = attempt;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat kuis post test: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _startTimer(Posttest posttest, TestAttempt attempt) {
    _countdownTimer?.cancel();
    final now = DateTime.now();
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

  Future<void> _submitAttempt({bool autoSubmit = false}) async {
    final attempt = _currentAttempt;
    if (attempt == null || _isSubmitting) return;

    if (!autoSubmit) {
      final unansweredCount = _questions.length - _answers.length;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kumpulkan Post Test?'),
          content: Text(
            unansweredCount > 0
                ? 'Masih ada $unansweredCount soal yang belum dijawab. Yakin ingin mengumpulkan sekarang?'
                : 'Semua soal telah dijawab. Jawaban akan dikunci dan dinilai oleh server.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Periksa Kembali'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kumpulkan'),
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
      final gradeResult = await gradeService.submitAndGrade(attempt.id);

      if (!mounted) return;
      _showResultDialog(gradeResult);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim penilaian: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _autoSubmitOnTimeUp() {
    if (_isSubmitting || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Waktu pengerjaan telah habis. Jawaban dikumpulkan otomatis.'),
        backgroundColor: AppTheme.warning,
      ),
    );
    _submitAttempt(autoSubmit: true);
  }

  void _showResultDialog(GradeResult result) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.success),
            SizedBox(width: 8),
            Text('Hasil Post Test'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skor Akhir: ${result.score.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Poin Diperoleh: ${result.pointsEarned} dari ${result.totalPoints}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Jawaban Anda telah dikunci dan skor evaluasi pembelajaran telah tercatat di server.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Kembali ke Pertemuan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Mempersiapkan sesi post test...'),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post Test')),
        body: ErrorView(
          message: _errorMessage!,
          onRetry: _loadPosttestSession,
        ),
      );
    }

    final posttest = _posttest!;
    final currentQ = _questions[_currentQuestionIndex];
    final selectedOption = _answers[currentQ.id];

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
              color: _remainingSeconds < 180 ? AppTheme.error.withAlpha(20) : AppTheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: _remainingSeconds < 180 ? AppTheme.error : AppTheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  timerText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _remainingSeconds < 180 ? AppTheme.error : AppTheme.primary,
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
            backgroundColor: AppTheme.background,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Text(
                      'Soal ${_currentQuestionIndex + 1} dari ${_questions.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${currentQ.points} Poin',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple),
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
                          color: isSelected ? Colors.deepPurple.withAlpha(20) : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.deepPurple : AppTheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: isSelected ? Colors.deepPurple : AppTheme.background,
                              child: Text(
                                optionChar,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
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
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _currentQuestionIndex--);
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Sebelumnya'),
                  ),
                const Spacer(),
                if (_currentQuestionIndex < _questions.length - 1)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _currentQuestionIndex++);
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Selanjutnya'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _submitAttempt(autoSubmit: false),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    icon: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Selesai & Kumpulkan'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
