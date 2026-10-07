import { VercelRequest, VercelResponse } from '@vercel/node';

/**
 * Daftar origin yang diizinkan untuk keperluan development lokal.
 * Flutter Web secara default menggunakan port tetap 5000 sesuai konfigurasi.
 */
const DEFAULT_DEV_ORIGINS = [
  'http://localhost:5000',
  'http://127.0.0.1:5000',
];

/**
 * Mengambil daftar origin yang diizinkan dari environment variable CORS_ALLOWED_ORIGINS
 * atau fallback ke default development origin jika di lingkungan non-produksi.
 */
export function getAllowedOrigins(): string[] {
  const envOrigins = process.env.CORS_ALLOWED_ORIGINS;
  const configured = envOrigins
    ? envOrigins
        .split(',')
        .map((o) => o.trim())
        .filter(Boolean)
    : [];

  const isProduction = process.env.NODE_ENV === 'production' || process.env.VERCEL_ENV === 'production';

  if (isProduction) {
    // Di lingkungan produksi, HANYA izinkan origin yang terdaftar secara eksplisit
    return configured;
  }

  // Di lingkungan development/test, gabungkan konfigurasi env dengan default port dev
  const combined = new Set([...configured, ...DEFAULT_DEV_ORIGINS]);
  return Array.from(combined);
}

/**
 * Memeriksa apakah origin request termasuk dalam daftar yang diizinkan.
 */
export function isOriginAllowed(origin: string | undefined): boolean {
  if (!origin) return false;

  const isProduction = process.env.NODE_ENV === 'production' || process.env.VERCEL_ENV === 'production';
  if (!isProduction) {
    // Di lingkungan development, izinkan localhost dan 127.0.0.1 pada sembarang port (Flutter Web dinamis)
    if (/^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) {
      return true;
    }
  }

  const allowed = getAllowedOrigins();
  return allowed.includes(origin);
}

/**
 * Helper CORS terpusat.
 * 
 * Aturan:
 * - Tidak menggunakan wildcard (*) bersamaan dengan credentials.
 * - Aplikasi menggunakan header Authorization: Bearer, bukan cookie, sehingga Allow-Credentials tidak digunakan.
 * - Menambahkan 'Vary: Origin' saat meng-echo origin yang cocok.
 * - Mengizinkan OPTIONS preflight request langsung selesai (204 No Content) tanpa auth/rate limit.
 * - Jika origin tidak cocok, TIDAK mengirimkan header Access-Control-Allow-Origin (tidak fallback ke *).
 * 
 * @returns true jika request adalah preflight OPTIONS dan telah ditangani (respon berakhir).
 */
export function applyCors(req: VercelRequest, res: VercelResponse): boolean {
  const origin = req.headers.origin as string | undefined;

  if (origin && isOriginAllowed(origin)) {
    if (typeof res.setHeader === 'function') {
      res.setHeader('Access-Control-Allow-Origin', origin);
      res.setHeader('Vary', 'Origin');
      res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
      res.setHeader(
        'Access-Control-Allow-Headers',
        'Authorization, Content-Type, X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Date, X-Api-Version'
      );
      res.setHeader('Access-Control-Max-Age', '86400');
    }
  }

  if (req.method === 'OPTIONS') {
    res.status(204);
    if (typeof res.end === 'function') {
      res.end();
    } else if (typeof res.json === 'function') {
      res.json({});
    }
    return true;
  }

  return false;
}
