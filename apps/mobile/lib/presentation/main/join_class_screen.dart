import 'package:flutter/material.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);
    // Akan diintegrasikan dengan JoinClassService di Step 1.9
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gabung Kelas')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Masukkan Kode Kelas',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kode kelas terdiri dari 6-12 karakter alfanumerik. Mahasiswa/Dosen otomatis aktif, sedangkan akun Umum berstatus pending.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Kode Kelas (misal: FARLEAN1)',
                    prefixIcon: Icon(Icons.pin_outlined, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Kode kelas wajib diisi';
                    }
                    final clean = v.trim().toUpperCase();
                    if (clean.length < 6 || clean.length > 12) {
                      return 'Panjang kode harus 6 - 12 karakter';
                    }
                    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(clean)) {
                      return 'Kode hanya boleh berupa huruf kapital dan angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Gabung Sekarang'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
