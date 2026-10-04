import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
import '../../models/manual_book.dart';
import '../../repositories/manual_book_repository.dart';
import '../../services/auth_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

class ManualBookListScreen extends StatefulWidget {
  final String classId;
  final ManualBookRepository? manualBookRepository;

  const ManualBookListScreen({
    super.key,
    this.classId = 'default_class',
    this.manualBookRepository,
  });

  @override
  State<ManualBookListScreen> createState() => _ManualBookListScreenState();
}

class _ManualBookListScreenState extends State<ManualBookListScreen> {
  late final ManualBookRepository _manualBookRepository;
  List<ManualBook> _books = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _manualBookRepository = widget.manualBookRepository ?? ManualBookRepository();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _manualBookRepository.getManualBooksByClass(widget.classId);
      if (mounted) {
        setState(() {
          _books = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat manual book: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openPdf(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka tautan PDF.'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error membuka berkas: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _showAddBookDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final urlController = TextEditingController();
    final fileNameController = TextEditingController(text: 'panduan.pdf');
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Manual Book'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul Panduan'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi Singkat'),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL Berkas Cloudinary (PDF)',
                    prefixIcon: Icon(Icons.link_rounded, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'URL berkas wajib diisi';
                    if (!v.startsWith('http://') && !v.startsWith('https://')) {
                      return 'URL harus diawali http:// atau https://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: fileNameController,
                  decoration: const InputDecoration(labelText: 'Nama Berkas (.pdf)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final book = ManualBook(
                  id: '',
                  classId: widget.classId,
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  fileUrl: urlController.text.trim(),
                  fileName: fileNameController.text.trim(),
                  fileSize: 1024 * 1024, // Estimasi 1 MB
                  createdAt: DateTime.now(),
                );
                await _manualBookRepository.createManualBook(book);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (created == true) {
      _loadBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buku Panduan (Manual Book)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: _loadBooks,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              onPressed: _showAddBookDialog,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Tambah Manual Book'),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Memuat buku panduan...');
    }

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadBooks);
    }

    if (_books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 56,
                color: AppTheme.textSecondary.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Buku Panduan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pengajar belum menambahkan buku panduan (Manual Book) PDF untuk kelas ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _books.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final book = _books[index];
          return _buildBookCard(book);
        },
      ),
    );
  }

  Widget _buildBookCard(ManualBook book) {
    final sizeKb = (book.fileSize / 1024).round();
    final sizeStr = sizeKb > 1024
        ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
        : '$sizeKb KB';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.description.isNotEmpty ? book.description : 'Tidak ada deskripsi',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            book.fileName,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  $sizeStr',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openPdf(book.fileUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Buka Dokumen PDF'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(140, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
