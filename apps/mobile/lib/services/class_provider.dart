import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/classroom.dart';
import '../repositories/class_repository.dart';

class ClassProvider extends ChangeNotifier {
  final ClassRepository _classRepository;
  static const String _prefSelectedClassKey = 'farlean_selected_class_id';

  List<Classroom> _ownedClasses = [];
  List<Classroom> _joinedClasses = [];
  String? _selectedClassId;
  bool _isLoading = false;
  String? _errorMessage;

  ClassProvider({ClassRepository? classRepository})
      : _classRepository = classRepository ?? ClassRepository();

  List<Classroom> get ownedClasses => List.unmodifiable(_ownedClasses);
  List<Classroom> get joinedClasses => List.unmodifiable(_joinedClasses);
  List<Classroom> get activeJoinedClasses =>
      List.unmodifiable(_joinedClasses.where((c) => c.isMembershipActive));
  List<Classroom> get pendingJoinedClasses =>
      List.unmodifiable(_joinedClasses.where((c) => c.isMembershipPending));
  List<Classroom> get allClasses => [..._ownedClasses, ..._joinedClasses];

  String? get selectedClassId => _selectedClassId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Classroom? get selectedClass {
    if (_selectedClassId == null) return null;
    try {
      return allClasses.firstWhere((c) => c.id == _selectedClassId);
    } catch (_) {
      return null;
    }
  }

  bool get hasSingleClass => allClasses.length == 1;
  String? get singleClassId => allClasses.length == 1 ? allClasses.first.id : null;

  /// Memuat daftar kelas dan memulihkan kelas yang sebelumnya dipilih
  Future<void> loadClasses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _classRepository.getMyClasses();
      _ownedClasses = res['owned'] ?? [];
      _joinedClasses = res['joined'] ?? [];

      // Pulihkan selectedClassId dari penyimpanan lokal
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefSelectedClassKey);

      if (_selectedClassId == null && savedId != null) {
        _selectedClassId = savedId;
      }

      // Validasi keberadaan kelas yang tersimpan (hanya kelas aktif non-arsip dan membership aktif)
      final exists = allClasses.any((c) => c.id == _selectedClassId && !c.isArchived && c.isMembershipActive);
      if (!exists) {
        _selectedClassId = null;
        await prefs.remove(_prefSelectedClassKey);
      }

      // Smart Tab/Selector: Jika user hanya punya 1 kelas aktif yang dapat diakses, pilih otomatis
      final activeList = [..._ownedClasses, ...activeJoinedClasses].where((c) => !c.isArchived).toList();
      if (_selectedClassId == null && activeList.length == 1) {
        _selectedClassId = activeList.first.id;
        await prefs.setString(_prefSelectedClassKey, _selectedClassId!);
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat kelas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memilih kelas aktif untuk navigasi sesi pembelajaran
  Future<void> selectClass(String? classId) async {
    _selectedClassId = classId;
    final prefs = await SharedPreferences.getInstance();
    if (classId != null && classId.isNotEmpty) {
      await prefs.setString(_prefSelectedClassKey, classId);
    } else {
      await prefs.remove(_prefSelectedClassKey);
    }
    notifyListeners();
  }

  /// Membuat kelas baru (khusus Dosen / Staff)
  Future<Classroom> createClass({
    required String name,
    String description = '',
    String? customCode,
  }) async {
    final newClass = await _classRepository.createClass(
      name: name,
      description: description,
      customCode: customCode,
    );

    _ownedClasses.insert(0, newClass);
    await selectClass(newClass.id);
    notifyListeners();
    return newClass;
  }

  /// Mengarsipkan kelas
  Future<void> archiveClass(String classId) async {
    await _classRepository.archiveClass(classId);

    _ownedClasses = _ownedClasses.map((c) {
      if (c.id == classId) return c.copyWith(status: 'Archived');
      return c;
    }).toList();

    if (_selectedClassId == classId) {
      await selectClass(null);
    } else {
      notifyListeners();
    }
  }

  /// Mengaktifkan kembali kelas yang berstatus Archived
  Future<void> reactivateClass(String classId) async {
    await _classRepository.reactivateClass(classId);

    _ownedClasses = _ownedClasses.map((c) {
      if (c.id == classId) return c.copyWith(status: 'Active');
      return c;
    }).toList();

    notifyListeners();
  }

  /// Membersihkan seluruh state kelas saat logout
  Future<void> clear() async {
    _ownedClasses = [];
    _joinedClasses = [];
    _selectedClassId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefSelectedClassKey);
    } catch (_) {}
    notifyListeners();
  }
}
