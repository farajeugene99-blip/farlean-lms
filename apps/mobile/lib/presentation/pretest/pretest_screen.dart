import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
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

  const PretestScreen({
    super.key,
    required this.pretestId,
    this.classId = '',
    this.meetingId = '',
    this.pretestRepository,
    this.attemptRepository,
    this.materialRepository,
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
    });

    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;
    if (uid == null) {
      setState(() {
        _errorMessage = 'Sesi Anda belum aktif.';
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Ambil metadata Pretest terlebih dahulu
      final pretest = await _pretestRepository.getPretest(widget.pretestId);
      if (pretest == null) {
        setState(() {
          _errorMessage = 'Kuis pretest tidak ditemukan.';
          _isLoading = false;
        });
        return;
      }
      _pretest = pretest;

      final effectiveClassId = widget.classId.isNotEmpty ? widget.classId : pretest.classId;
      final effectiveMeetingId = widget.meetingId.isNotEmpty ? widget.meetingId : pretest.meetingId;

      if (effectiveClassId.isEmpty || effectiveMeetingId.isEmpty) {
        setState(() {
          _errorMessage = 'Kuis tidak terhubung dengan kelas atau pertemuan yang valid.';
          _isLoading = false;
        });
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
        setState(() {
          _errorMessage = 'Soal kuis belum diunggah oleh pengajar.';
          _isLoading = false;
        });
        return;
      }

      // 4. Periksa sesi attempt: Recovery vs New Attempt
      final inProgressAttempt = await _attemptRepository.getInProgressAttempt(
        userId: uid,
        testId: widget.pretestId,
      );

      if (inProgressAttempt != null) {
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
          setState(() {
            _errorMessage = 'Anda telah mencapai batas maksimal percobaan (${pretest.maxAttempts}x).';
            _isLoading = false;
          });
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
        setState(() {
          _errorMessage = 'Gagal memuat sesi kuis: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _startServerTimer() {
    if (_pretest == null || _currentAttempt == null) return;

    final durationSeconds = _pretest!.duration * 60;
    final startedAt = _currentAttempt!.startedAt ?? DateTime.now();
    final elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Waktu pengerjaan telah habis. Jawaban Anda disimpan otomatis.'),
        backgroundColor: AppTheme.warning,
      ),
    );
    await _submitAttempt();
  }

  Future<void> _confirmSubmit() async {
    final unanswered = _questions.length - _answers.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kumpulkan Jawaban?'),
        content: Text(
          unanswered > 0
              ? 'Terdapat $unanswered soal yang belum Anda jawab. Jawaban yang sudah dikumpulkan tidak dapat diubah lagi.'
              : 'Seluruh soal telah dijawab. Apakah Anda yakin ingin mengumpulkan kuis sekarang?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Kumpulkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submitAttempt();
    }
  }

  Future<void> _submitAttempt() async {
    if (_isSubmitting || _currentAttempt == null) return;
    setState(() => _isSubmitting = true);

    try {
      // Simpan jawaban final sebelum pemanggilan grade
      await _attemptRepository.autosaveAnswers(
        attemptId: _currentAttempt!.id,
        answers: _answers,
      );

      // Panggil backend /api/grade untuk grading server-side yang idempoten
      GradeResult? gradeResult;
      try {
        final gradeService = GradeService();
        gradeResult = await gradeService.submitAndGrade(_currentAttempt!.id);
      } catch (e) {
        debugPrint('Catatan grading backend: $e');
      }

      // Pengerjaan disimpan, navigasi kembali dengan pesan
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.success),
              SizedBox(width: 8),
              Text('Kuis Selesai Dinilai'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (gradeResult != null) ...[
                Text(
                  'Skor Akhir: ${gradeResult.score}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Poin diperoleh: ${gradeResult.pointsEarned} dari ${gradeResult.totalPoints} poin',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'Jawaban Anda telah tersimpan dengan aman dan sesi kuis telah dikunci.',
                style: TextStyle(color: AppTheme.textSecondary),
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
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengumpulkan kuis: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator(message: 'Mempersiapkan kuis pretest...'));
    }

    if (_errorMessage != null || _pretest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pretest')),
        body: ErrorView(
          message: _errorMessage ?? 'Gagal memuat pretest.',
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
                  : AppTheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _remainingSeconds < 120 ? AppTheme.error : AppTheme.primary,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: _remainingSeconds < 120 ? AppTheme.error : AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  timerString,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _remainingSeconds < 120 ? AppTheme.error : AppTheme.primary,
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
            backgroundColor: AppTheme.border,
            color: AppTheme.primary,
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
                        'Soal ${_currentQuestionIndex + 1} dari ${_questions.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${question.points} Poin',
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
                    color: isSelected ? AppTheme.primary.withAlpha(15) : AppTheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
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
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _currentQuestionIndex--),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Sebelumnya'),
                  )
                else
                  const Spacer(),
                const Spacer(),
                if (_currentQuestionIndex < _questions.length - 1)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _currentQuestionIndex++),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Selanjutnya'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _confirmSubmit,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Kumpulkan'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Akses Pretest Terkunci')),
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
                'Materi Belum Dibuka',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sesuai ketentuan alur pembelajaran Farlean LMS, Anda harus membuka dan membaca materi pembelajaran pertemuan ini terlebih dahulu sebelum diperkenankan mengerjakan pretest.\n\nJika sebelumnya Anda sudah pernah membuka materi, ketuk tombol di bawah untuk membuka kembali materi agar progres kehadiran tersinkronisasi secara resmi ke server.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
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
                label: const Text('Buka Materi Pembelajaran'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
