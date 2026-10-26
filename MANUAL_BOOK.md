# Buku Panduan Pengguna (Manual Book) — Farlean LMS

Selamat datang di **Farlean LMS** (Learning Management System). Dokumen panduan ini dirancang untuk membantu mahasiswa, dosen/pengajar, dan administrator dalam menggunakan seluruh fitur aplikasi pembelajaran Farlean LMS secara optimal, aman, dan efisien.

---

## Daftar Isi
1. [Tentang Akun, Peran (Role), dan Tipe Akun](#1-tentang-akun-peran-role-dan-tipe-akun)
2. [Alur Autentikasi dan Masuk ke Aplikasi](#2-alur-autentikasi-dan-masuk-ke-aplikasi)
   - 2.1 [Masuk dengan Akun Terdaftar (Login)](#21-masuk-dengan-akun-terdaftar-login)
   - 2.2 [Pendaftaran Akun Baru (Registrasi)](#22-pendaftaran-akun-baru-registrasi)
   - 2.3 [Verifikasi Alamat Email](#23-verifikasi-alamat-email)
   - 2.4 [Masuk Cepat Menggunakan Google (Google Sign-In)](#24-masuk-cepat-menggunakan-google-google-sign-in)
   - 2.5 [Penyelesaian Profil Pengguna (Onboarding Profil)](#25-penyelesaian-profil-pengguna-onboarding-profil)
   - 2.6 [Pemulihan Kata Sandi (Lupa Password)](#26-pemulihan-kata-sandi-lupa-password)
3. [Manajemen Kelas Pembelajaran di Beranda](#3-manajemen-kelas-pembelajaran-di-beranda)
   - 3.1 [Navigasi Menu Utama](#31-navigasi-menu-utama)
   - 3.2 [Bergabung ke Kelas Menggunakan Kode Kelas](#32-bergabung-ke-kelas-menggunakan-kode-kelas)
   - 3.3 [Memahami Status Keanggotaan Kelas (Aktif vs Menunggu Persetujuan)](#33-memahami-status-keanggotaan-kelas-aktif-vs-menunggu-persetujuan)
   - 3.4 [Membuat dan Mengarsipkan Kelas (Khusus Dosen / Staf)](#34-membuat-dan-mengarsipkan-kelas-khusus-dosen--staf)
4. [Alur Pengumpulan Tugas Pembelajaran (Mahasiswa)](#4-alur-pengumpulan-tugas-pembelajaran-mahasiswa)
   - 4.1 [Membuka Kelas, Pertemuan, dan Rincian Tugas](#41-membuka-kelas-pertemuan-dan-rincian-tugas)
   - 4.2 [Perbedaan Lampiran Petunjuk Dosen dan Berkas Pengumpulan](#42-perbedaan-lampiran-petunjuk-dosen-dan-berkas-pengumpulan)
   - 4.3 [Langkah demi Langkah Memilih dan Mengunggah Berkas Tugas](#43-langkah-demi-langkah-memilih-dan-mengunggah-berkas-tugas)
   - 4.4 [Memeriksa Hasil dan Status Pengumpulan (Terkumpul / Terlambat)](#44-memeriksa-hasil-dan-status-pengumpulan-terkumpul--terlambat)
   - 4.5 [Mengganti atau Mengumpulkan Ulang Tugas (Kumpulkan Ulang)](#45-mengganti-atau-mengumpulkan-ulang-tugas-kumpulkan-ulang)
   - 4.6 [Aturan Tugas Kelompok vs Tugas Individu](#46-aturan-tugas-kelompok-vs-tugas-individu)
   - 4.7 [Tanya Jawab & Penanganan Masalah Pengumpulan Tugas](#47-tanya-jawab--penanganan-masalah-pengumpulan-tugas)
5. [Aktivitas Pembelajaran Lainnya](#5-aktivitas-pembelajaran-lainnya)
   - 5.1 [Mengakses Materi Perkuliahan & Lampiran Dokumen](#51-mengakses-materi-perkuliahan--lampiran-dokumen)
   - 5.2 [Menonton Video Pembelajaran](#52-menonton-video-pembelajaran)
   - 5.3 [Pengerjaan Pretest dan Posttest Terjadwal](#53-pengerjaan-pretest-dan-posttest-terjadwal)
   - 5.4 [Forum Diskusi Interaktif](#54-forum-diskusi-interaktif)
   - 5.5 [Buku Panduan Sistem Global (Manual Book In-App)](#55-buku-panduan-sistem-global-manual-book-in-app)

---

## 1. Tentang Akun, Peran (Role), dan Tipe Akun

Farlean LMS memisahkan hak akses sistem menjadi dua dimensi yang berbeda dan saling melengkapi:

### A. Peran Sistem (`Role`)
1. **USER (Mahasiswa/Umum)**: Mengakses kelas yang diikuti, materi, video, forum diskusi, tes, serta mengumpulkan tugas.
2. **GURU (Pengajar/Dosen)**: Membuat kelas, menjadwalkan pertemuan, mengunggah materi & video, membuat kuis & tugas, menilai tugas mahasiswa, serta mengelola kelompok belajar.
3. **ADMIN (Administrator)**: Mengelola seluruh sistem, menerbitkan buku panduan sistem global, dan mengatur konfigurasi aplikasi tingkat lanjut.

### B. Tipe Akun (`Account Type`)
- **MAHASISWA**: Akun terafiliasi dengan domain mahasiswa universitas (misal: `@farlean.edu`, `@mhs.unesa.ac.id`). Memperoleh akses langsung (status `active`) saat bergabung ke kelas pembelajaran.
- **DOSEN**: Akun terafiliasi dengan domain dosen universitas (misal: `@dosen.farlean.edu`, `@unesa.ac.id`).
- **UMUM**: Pengguna dengan email publik (seperti Gmail atau Yahoo). Saat memasukkan kode kelas, status keanggotaan akan berada pada tahap menunggu persetujuan (`pending`) dari dosen pemilik kelas.

---

## 2. Alur Autentikasi dan Masuk ke Aplikasi

### 2.1 Masuk dengan Akun Terdaftar (Login)
Jika Anda **sudah memiliki akun** yang telah diverifikasi:
1. Buka aplikasi Farlean LMS. Layar **Masuk** akan tampil secara otomatis.
2. Masukkan alamat email terdaftar pada kolom **Alamat Email**.
3. Masukkan kata sandi akun Anda pada kolom **Kata Sandi**. Anda dapat menekan ikon mata untuk memastikan kata sandi yang diketik sudah benar.
4. Tekan tombol **Masuk**.
5. Jika data login cocok, Anda langsung diarahkan ke menu **Beranda**.
6. **Jika Muncul Notifikasi Kesalahan**:
   - Apabila email atau kata sandi tidak cocok, aplikasi menampilkan pesan ramah: *"Email belum terdaftar atau kata sandi salah"*.
   - Jika Anda belum memiliki akun, silakan tekan tautan **Daftar di sini** pada notifikasi atau tombol **Daftar Sekarang** di bawah form.

### 2.2 Pendaftaran Akun Baru (Registrasi)
Jika Anda **belum memiliki akun**:
1. Pada layar Masuk, tekan tombol **Daftar Sekarang** di bagian bawah.
2. Isi formulir pendaftaran:
   - **Nama Lengkap**: Nama asli Anda sesuai identitas akademik.
   - **Alamat Email**: Gunakan email institusi (kampus) untuk mendapatkan status Mahasiswa/Dosen secara otomatis, atau email pribadi aktif.
   - **Kata Sandi**: Minimal 6 karakter.
   - **Konfirmasi Kata Sandi**: Ulangi kata sandi yang sama.
3. Tekan tombol **Daftar Akun Baru**.
4. Sistem akan membuat akun baru dan secara otomatis mengirimkan email berisi tautan verifikasi. Anda akan langsung diarahkan ke layar **Verifikasi Email**.

### 2.3 Verifikasi Alamat Email
Aplikasi mewajibkan verifikasi email demi keamanan data akademik dan mencegah akun palsu:
1. Buka kotak masuk (inbox) atau folder spam pada email yang Anda daftarkan.
2. Cari email masuk dari Farlean LMS / Firebase dan klik tautan verifikasi yang tercantum di dalamnya.
3. Setelah halaman browser menyatakan verifikasi berhasil, kembali ke aplikasi Farlean LMS.
4. Pada layar Verifikasi Email di aplikasi, tekan tombol **Saya Sudah Verifikasi**.
5. Aplikasi akan menyegarkan token autentikasi Anda secara aman dan melanjutkan ke langkah berikutnya.
6. **Kirim Ulang Email Verifikasi**:
   - Jika email verifikasi belum masuk, tekan tombol **Kirim Ulang Email**.
   - Untuk mencegah pengiriman email beruntun yang tidak sengaja, tombol ini dilengkapi hitung mundur (cooldown) selama 60 detik. Tunggu waktu hitung mundur selesai sebelum menekan kembali jika diperlukan.
   - Jika ingin berganti ke akun lain, tekan tombol **Ganti Akun**.

### 2.4 Masuk Cepat Menggunakan Google (Google Sign-In)
1. Pada layar Masuk atau Daftar, tekan tombol **Masuk dengan Google**.
2. Pilih akun Google yang terpasang pada perangkat Anda.
3. Karena akun Google telah terverifikasi oleh Google, Anda tidak perlu melakukan verifikasi email secara manual.
4. Jika ini adalah pertama kalinya Anda masuk, sistem akan mengarahkan Anda ke layar **Lengkapi Profil**.

### 2.5 Penyelesaian Profil Pengguna (Onboarding Profil)
Bagi pengguna baru (khususnya via Google Sign-In):
1. Periksa nama lengkap Anda pada kolom **Nama Lengkap**.
2. Masukkan **NIM** (untuk Mahasiswa) atau **NIP** (untuk Dosen). Bagi mahasiswa UNESA, sistem mengenali format NIM secara otomatis dari email resmi.
3. Beri centang pada persetujuan syarat dan ketentuan layanan.
4. Tekan tombol **Simpan & Lanjutkan**. Anda siap menggunakan seluruh fitur Farlean LMS.

### 2.6 Pemulihan Kata Sandi (Lupa Password)
1. Pada layar Masuk, tekan tautan **Lupa Kata Sandi?**.
2. Masukkan alamat email Anda, lalu tekan **Kirim Tautan Reset**.
3. Buka email Anda dan ikuti petunjuk untuk membuat kata sandi baru.

---

## 3. Manajemen Kelas Pembelajaran di Beranda

### 3.1 Navigasi Menu Utama
Aplikasi Farlean LMS memiliki 5 menu utama pada bilah navigasi bawah:
1. **Beranda**: Menampilkan ringkasan kelas yang Anda ikuti atau kelola, kartu selamat datang, dan akses buku panduan.
2. **Materi**: Menampilkan daftar pertemuan terstruktur, silabus, dan modul perkuliahan dari kelas yang sedang aktif dipilih.
3. **AI Tutor**: Asisten belajar cerdas berbasis AI untuk bertanya seputar materi kuliah.
4. **Diskusi**: Forum tanya jawab dan diskusi kelas bersama rekan dan pengajar.
5. **Profil**: Informasi akun, pengaturan tema (Gelap/Terang), ganti kata sandi, dan tombol Keluar.

### 3.2 Bergabung ke Kelas Menggunakan Kode Kelas
1. Pada menu **Beranda**, tekan ikon kunci atau tombol **Gabung Kelas** / **Masukkan Kode Kelas**.
2. Masukkan kode unik kelas (panjang 6 hingga 12 karakter alfanumerik huruf kapital, contoh: `FARLEAN1` atau `QATEST123`).
3. Tekan tombol **Gabung Kelas**.
4. Dialog konfirmasi akan muncul menampilkan nama kelas dan status pendaftaran Anda:
   - **Mahasiswa**: Langsung berstatus **Aktif** (`active`). Tekan tombol **Buka Kelas** untuk langsung mulai belajar.
   - **Pengguna Umum**: Berstatus **Menunggu Persetujuan** (`pending`). Anda akan diarahkan kembali ke Beranda.

### 3.3 Memahami Status Keanggotaan Kelas (Aktif vs Menunggu Persetujuan)
Pada menu Beranda, kartu kelas yang Anda ikuti menampilkan status yang jujur dan akurat:
- **Kelas Aktif**: Menampilkan lencana warna hijau `Active`. Anda dapat langsung menekan tombol **Buka Kelas** untuk melihat seluruh pertemuan, materi, dan tugas.
- **Menunggu Persetujuan**: Menampilkan lencana warna oranye `Menunggu Persetujuan` dan tombol bertuliskan `Menunggu`.
  - Jika Anda menekan kartu ini, aplikasi akan menampilkan pesan pemberitahuan bahwa kelas masih menunggu persetujuan dari dosen pengajar.
  - Ini melindungi Anda agar tidak mengalami kendala penolakan izin saat membuka kelas.
- **Gagal Memuat Kelas**: Jika koneksi jaringan Anda terputus saat memuat kelas di Beranda, aplikasi menampilkan tampilan error informatif dilengkapi tombol **Coba Lagi** (tidak disamarkan sebagai kondisi belum punya kelas).

### 3.4 Membuat dan Mengarsipkan Kelas (Khusus Dosen / Staf)
- **Membuat Kelas**: Tekan ikon tambah kelas di AppBar Beranda, isi nama kelas, deskripsi, dan kode kelas khusus (opsional), lalu tekan Simpan.
- **Mengarsipkan Kelas**: Kelas yang telah selesai semester dapat diarsipkan dari menu opsi kelas agar tidak menerima pendaftaran baru.

---

## 4. Alur Pengumpulan Tugas Pembelajaran (Mahasiswa)

Farlean LMS menerapkan metode pengumpulan tugas modern dan praktis melalui **Unggah Berkas Langsung dari Perangkat**. Anda **tidak perlu** mengetikkan link URL panjang atau menuliskan nama file secara manual.

### 4.1 Membuka Kelas, Pertemuan, dan Rincian Tugas
1. Dari menu **Beranda**, tekan tombol **Buka Kelas** pada kelas yang ingin Anda ikuti.
2. Pada tab **Pertemuan & Silabus**, pilih pertemuan terkait (misalnya: *Pertemuan 3 — Analisis & Desain Sistem*).
3. Pada halaman rincian pertemuan, temukan bagian **Tugas Pembelajaran**.
4. Tekan kartu tugas untuk membuka halaman **Detail Tugas**.

### 4.2 Perbedaan Lampiran Petunjuk Dosen dan Berkas Pengumpulan
Penting untuk memahami perbedaan antara dua jenis berkas pada halaman tugas:
- **Lampiran Petunjuk Soal (Dari Dosen)**: Berkas dokumen (PDF/DOCX) yang disiapkan oleh Dosen pengajar berisi soal, panduan, atau rubrik pengerjaan tugas. Tekan tombol **Buka Berkas Soal** untuk membaca instruksi.
  > ⚠️ *Mengunduh atau membaca lampiran petunjuk dosen BUKAN berarti mengumpulkan tugas.*
- **Berkas Hasil Pekerjaan (Dari Mahasiswa)**: Berkas tugas Anda sendiri (jawaban laporan, makalah, presentasi, atau source code berkas ZIP) yang Anda unggah dari memori ponsel atau laptop.

### 4.3 Langkah demi Langkah Memilih dan Mengunggah Berkas Tugas
1. Pada halaman Detail Tugas, baca batas waktu pengumpulan (**Deadline**) dan deskripsi tugas.
2. Tekan tombol **Kumpulkan Tugas** di bagian bawah layar.
3. Dialog pop-up pengumpulan akan muncul.
4. Tekan tombol **Pilih Berkas dari Perangkat**.
5. Sistem akan membuka pengelola berkas (File Picker) bawaan perangkat Anda.
6. Cari dan pilih file hasil pekerjaan Anda:
   - Format yang didukung: **PDF, DOC, DOCX, atau ZIP**.
   - Batas ukuran file: Maksimal **10 MB** (atau sesuai batasan yang ditentukan dosen).
7. Setelah file dipilih, dialog akan menampilkan:
   - Nama berkas asli (misal: `Tugas1_Farlean_25050974183.pdf`).
   - Ukuran berkas (misal: `2.4 MB`).
   - Tombol **Ganti Berkas** (ikon panah bolak-balik) jika Anda salah memilih file.
   - Tombol **Hapus Berkas** (ikon silang merah) untuk membatalkan pemilihan.
8. Masukkan catatan singkat untuk pengajar pada kolom **Catatan untuk Dosen** (opsional).
9. Tekan tombol **Kumpulkan Tugas**.
10. Tunggu indikator putaran loading selesai. Berkas Anda akan diunggah ke server penyimpanan Cloudinary secara aman dan status pengumpulan akan diperbarui di sistem.
11. Notifikasi hijau *"Tugas berhasil dikumpulkan!"* akan muncul.

### 4.4 Memeriksa Hasil dan Status Pengumpulan (Terkumpul / Terlambat)
Setelah berhasil dikumpulkan, halaman Detail Tugas akan langsung menampilkan informasi pengumpulan Anda:
- **Status Pengumpulan**:
  - `TERKUMPUL`: Dikumpulkan tepat waktu sebelum deadline berakhir.
  - `TERLAMBAT`: Dikumpulkan setelah deadline berakhir (jika dosen mengaktifkan izin pengumpulan terlambat).
  - `DINILAI`: Tugas telah diperiksa oleh dosen pengajar. Nilai angka (0–100) dan umpan balik ulasan dosen akan tampil jelas.
- **Nama Berkas & Ukuran**: Nama berkas pekerjaan yang Anda serahkan.
- **Tombol Buka Berkas Tugas**: Tekan tombol ini untuk melihat/mengunduh kembali berkas yang telah Anda kirimkan guna memastikan isinya tidak salah.

### 4.5 Mengganti atau Mengumpulkan Ulang Tugas (Kumpulkan Ulang)
Jika Anda menemukan kesalahan pada tugas yang telah dikumpulkan dan batas waktu deadline masih berlaku:
1. Tekan tombol **Kumpulkan Ulang** pada halaman Detail Tugas.
2. Dialog akan menampilkan berkas yang sebelumnya sudah Anda kumpulkan.
3. Anda dapat:
   - Menekan tombol **Ganti Berkas** untuk memilih berkas versi baru dari perangkat Anda.
   - Mengubah catatan untuk dosen jika diperlukan.
4. Tekan tombol **Kumpulkan Ulang**. Berkas baru akan menggantikan berkas lama Anda.

### 4.6 Aturan Tugas Kelompok vs Tugas Individu
- **Tugas Individu**: Setiap mahasiswa mengunggah berkas masing-masing.
- **Tugas Kelompok**: Cukup **satu orang perwakilan kelompok** yang mengunggah berkas tugas. Seluruh anggota kelompok yang terdaftar akan otomatis memiliki status tugas terkumpul yang sama dan menerima nilai yang sama dari dosen pengajar.

### 4.7 Tanya Jawab & Penanganan Masalah Pengumpulan Tugas
- **Pertanyaan: Mengapa muncul pesan "Ukuran berkas melebihi batas maksimal 10 MB"?**
  - *Solusi*: Kompres dokumen PDF atau arsipkan gambar di dalam dokumen sebelum memilih file, lalu pilih kembali file tersebut.
- **Pertanyaan: Mengapa tombol Kumpulkan Tugas tidak bisa ditekan?**
  - *Solusi*: Pastikan Anda sudah memilih berkas dokumen terlebih dahulu hingga nama dan ukuran file muncul pada kotak hijau/abu-abu.
- **Pertanyaan: Apa yang terjadi jika internet terputus saat proses upload berlangsung?**
  - *Solusi*: Aplikasi akan membatalkan status upload secara aman dan menampilkan pesan error merah. Tugas Anda tidak akan ditandai terkumpul sebelum berkas benar-benar berhasil disimpan. Periksa koneksi internet Anda dan tekan Kumpulkan Tugas kembali.

---

## 5. Aktivitas Pembelajaran Lainnya

### 5.1 Mengakses Materi Perkuliahan & Lampiran Dokumen
Buka menu **Materi**, pilih pertemuan, lalu pilih materi yang diinginkan. Anda dapat membaca modul teks kaya (rich-text) yang dilengkapi gambar dan membuka berkas dokumen pendukung yang disisipkan oleh pengajar.

### 5.2 Menonton Video Pembelajaran
Setiap pertemuan dapat dilengkapi tautan video pembelajaran YouTube atau rekaman kuliah. Pemutar video terintegrasi memungkinkan Anda menonton langsung di dalam aplikasi tanpa terganggu iklan.

### 5.3 Pengerjaan Pretest dan Posttest Terjadwal
- **Pretest**: Dilaksanakan sebelum membuka materi untuk menguji pemahaman awal Anda.
- **Posttest**: Dilaksanakan setelah menyelesaikan materi dan pertemuan untuk mengukur pencapaian belajar.
- Tes dilengkapi batas waktu pengerjaan otomatis dan deteksi integritas tes.

### 5.4 Forum Diskusi Interaktif
Gunakan menu **Diskusi** untuk membuat utas pertanyaan baru atau membalas diskusi dosen dan teman sekelas. Anda dapat menyebutkan referensi video perkuliahan atau melampirkan berkas ringkasan diskusi.

### 5.5 Buku Panduan Sistem Global (Manual Book In-App)
Pada AppBar pojok kanan atas menu Beranda, terdapat ikon buku terbuka (**Buku Panduan**). Tekan ikon tersebut untuk melihat daftar dokumen PDF panduan resmi yang dipublikasikan oleh Administrator kampus. Dokumen dapat langsung dibuka melalui aplikasi penampil PDF perangkat Anda.

---

*Hak Cipta © 2026 Tim Pengembang Farlean LMS. Seluruh Hak Dilindungi Undang-Undang.*
