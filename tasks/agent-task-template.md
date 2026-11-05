# Template pemberian task kepada agent

Ganti placeholder sebelum diberikan ke agent. Ambil satu task yang dependensinya sudah selesai; jangan menempelkan seluruh backlog jika konteks sempit cukup.

```text
Kerjakan task <Txxx — judul> untuk SIGNAL ZERO.

Baca:
1. tasks/plan.md (scope, prioritas, aturan eksekusi).
2. Kartu <Txxx> di tasks/phases/<file>.md.
3. Bagian PRD SIGNAL_ZERO_PRD_v2.2.md yang dirujuk kartu.
4. Output keputusan dan evidence dependensi: <daftar link/path>.
5. AGENTS.md/instruksi workspace yang berlaku dan kondisi file aktual.

Status dependensi: <ID: done + bukti>. Jika belum benar-benar done,
jelaskan blocker; jangan menganggap nomor lebih kecil berarti sudah selesai.

Tujuan: <salin tujuan kartu>.
Batas perubahan: <file/modul yang dimiliki agent>.
File yang sedang dimiliki agent lain: <daftar, atau tidak ada>.

Implementasikan hanya scope kartu, pertahankan guest/offline dan rules versi.
Path pada kartu adalah rencana: gunakan/perluas file nyata setelah inspeksi,
jangan membuat database/engine/audio service kedua untuk fungsi yang sama.
Jangan memutuskan mekanik, SDK, backend, atau formula actions yang masih
menunggu task keputusan. Jangan ubah PRD atau menurunkan acceptance criteria.

Selesaikan tiga acceptance criteria dan verifikasi spesifik pada kartu.
Jika scope melebihi lima file bermakna/satu sesi fokus, pecah child task
dengan kriteria tetap, dependensi dan handoff yang jelas sebelum coding luas.
Jangan menjalankan deploy/publish/transaksi berbiaya hanya dari deskripsi PRD;
ikuti otorisasi sesi dan batas lingkungan yang sebenarnya.

Setelah bekerja:
- Simpan bukti actual command/scenario, versi/seed/device dan hasil ke
  tasks/evidence/<Txxx>.md atau laporan yang ditentukan kartu.
- Perbarui status/owner/evidence di tasks/todo.md.
- Jangan centang done bila masih ada AC/test/platform wajib yang pending.
- Laporkan output, hasil verifikasi, batas pengujian, blocker, dan task siap
  berikutnya; jangan melaporkan hasil simulasi sebagai hasil perangkat nyata.
```

## Handoff minimum

```markdown
# Txxx — Handoff
Status: todo / in_progress / review / done / blocked
Owner: <agent/manusia>
Build/source reference: <commit jika repo sudah ada, atau versi artifact>
Rules/engine/schema: <versi yang relevan>

Output:
- <file dan perubahan konkret>

Acceptance criteria:
- AC1: PASS/FAIL/PENDING — <bukti>
- AC2: PASS/FAIL/PENDING — <bukti>
- AC3: PASS/FAIL/PENDING — <bukti>

Verifikasi:
- <command/scenario sebenarnya> → <hasil, seed/device/runtime bila relevan>

Keterbatasan/blocker:
- <belum diuji atau keputusan yang belum tersedia>

Task berikutnya yang siap:
- <ID dan alasan dependensinya sudah terpenuhi>
```

## Contoh batch pertama

- Agent A: T001, formalisasi mechanics; output spesifikasi dan contoh yang diperiksa, belum engine.
- Agent B: T003, toolchain/skeleton Flutter; terpisah dari file rules.
- Agent C: T008, verifikasi aturan jam dari sumber resmi pada saat task dieksekusi.

T002 belum siap sampai T001 selesai. T004 belum siap sampai T003 selesai. Tidak perlu membuat chat baru untuk setiap task; kartu dan evidence dapat menjadi konteks lanjutan pada sesi yang sama.
