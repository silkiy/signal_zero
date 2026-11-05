# SIGNAL ZERO — Verifikasi Game Off 2026

**Task:** T008. **Diperiksa:** 5 November 2026, 23:04–23:08 WIB (Asia/Jakarta). **Status:** riset aturan selesai; build dan submission belum dinyatakan patuh/selesai.

Dokumen ini melengkapi status “belum diverifikasi” pada PRD v2.2 §19–20 dengan bukti saat ini. PRD asli tidak diubah. Periksa ulang sumber pada T096 sebelum mengirim game karena aturan dapat diperbarui.

## Sumber primer

- [Halaman resmi Game Off 2026](https://itch.io/jam/game-off-2026), hosted by GitHub dan Lee Reilly.
- [Pengumuman resmi GitHub: Game Off 2026, the theme is SHIFT](https://github.blog/open-source/gaming/game-off-2026-the-theme-is-shift/), Lee Reilly, 1 November 2026.
- [FAQ resmi oleh Lee Reilly, Jam Host](https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq), topik sticky bertanggal 1 November 2026.

Tidak memakai aturan Game Off 2025 atau jam lain sebagai aturan 2026.

## Fakta yang terverifikasi

| Aspek | Hasil pemeriksaan | Bukti |
|---|---|---|
| Tema | **SHIFT**; interpretasi peserta fleksibel. | [Overview resmi](https://itch.io/jam/game-off-2026), [pengumuman GitHub](https://github.blog/open-source/gaming/game-off-2026-the-theme-is-shift/) |
| Mulai | 1 November 2026, 13:37 PST menurut FAQ. | [FAQ: Important dates](https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq) |
| Deadline | **1 Desember 2026, 13:37 PST** untuk source push dan submission itch.io. | [GitHub: How to participate](https://github.blog/open-source/gaming/game-off-2026-the-theme-is-shift/) |
| AI | Bantuan AI, termasuk coding, ide, gambar, dan audio, diizinkan; penggunaan AI diminta untuk diungkap saat submission. | [FAQ: rules dan AI](https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq) |
| Source | Repository GitHub harus publik. Lisensi bebas dipilih; lisensi open source dianjurkan, tidak diwajibkan. | [GitHub: participation dan light rules](https://github.blog/open-source/gaming/game-off-2026-the-theme-is-shift/) |
| Hasil yang dikirim | Game playable di itch.io dan URL repository GitHub. Push source saja belum menjadi submission jam. | [FAQ: Submissions](https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq) |
| Platform/akses | Semua platform diterima, termasuk mobile/browser; sediakan akses bermain dan instruksi jelas. Tidak ada kewajiban build web/Windows pada FAQ. | [FAQ: platforms](https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq) |
| Waktu pengerjaan | Mayoritas pengembangan harus berlangsung selama jam; template, starter, dan pustaka sebelumnya diperbolehkan. | [GitHub: Light rules](https://github.blog/open-source/gaming/game-off-2026-the-theme-is-shift/) |
| Hak/kredit | Ikuti lisensi dan attribution yang berlaku untuk code/aset pihak ketiga. | [FAQ: assets dan copyright](https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq) |
| Penilaian | Peserta/teammate dengan submission memenuhi syarat dapat menilai; kategori: overall, gameplay, graphics, audio, innovation, theme interpretation. | [FAQ: Voting](https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq), [overview](https://itch.io/jam/game-off-2026) |
| Akhir voting | 1 Januari 2027, 13:37 PST. | [Overview resmi](https://itch.io/jam/game-off-2026) |

Penyelenggara merekomendasikan akses gratis agar peserta mudah bermain dan menilai; FAQ tidak menyatakannya sebagai kewajiban harga. [FAQ: free to play](https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq)

## Jadwal yang dipakai proyek

Konversi berikut dihitung dari timezone **PST = UTC−08:00** yang disebut sumber, dengan **WIB = UTC+07:00**. Jangan membaca 13:37 PST sebagai 13:37 WIB.

| Event | Waktu sumber PST | UTC | WIB / Asia/Jakarta |
|---|---|---|---|
| Jam mulai, presisi menit FAQ | 1 Nov 2026 13:37 | 1 Nov 2026 21:37 | 2 Nov 2026 04:37 |
| Deadline source dan submission | **1 Des 2026 13:37** | **1 Des 2026 21:37** | **2 Des 2026 04:37** |
| Voting berakhir | 1 Jan 2027 13:37 | 1 Jan 2027 21:37 | 2 Jan 2027 04:37 |

Overview menampilkan awal submission dengan detik `21:37:27`, sementara FAQ memberi waktu mulai hingga menit. Deadline overview tampil `2026-12-01 21:37:00` dan konsisten dengan konversi deadline PST di atas. Presisi mulai ini tidak mengubah deadline proyek. [Overview resmi](https://itch.io/jam/game-off-2026), [FAQ tanggal](https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq)

## Dampak terhadap PRD dan backlog

Bagian ini adalah penilaian penerapan untuk SIGNAL ZERO, bukan aturan tambahan penyelenggara.

| Dampak / tindakan | Pemetaan | Status saat T008 |
|---|---|---|
| Global SHIFT yang mengubah routing memberi hubungan langsung dengan tema; jelaskan interpretasinya pada halaman game. Tidak perlu menambah mekanik baru hanya untuk tema. | PRD §3, §19; T001, T029, T096 | Sesuai konsep secara analitis; kualitas interpretasi dinilai lewat game yang nanti dimainkan. |
| Flutter/Flame dapat dipertahankan. Web tetap prioritas akses dalam PRD, dengan fallback playable bila kompatibilitas gagal. | PRD §1, §10, §14; T004, T093, T094 | Pilihan platform baseline tidak berubah; bukti artifact menunggu task terkait. |
| Siapkan URL repo publik dan source final. Gameplay inti guest/offline tanpa wallet tetap menjadi jalur mudah bagi penilai. | PRD §1, §8, §19; T028, T093, T094, T096 | Publikasi repo/build belum dilakukan oleh T008. |
| Catat penggunaan AI aktual sejak awal, lalu isi disclosure submission dan kredit/README yang relevan. | PRD §19; T096 | AI digunakan dalam breakdown dan riset dokumen; jangan menyalin ini sebagai daftar final bila penggunaan bertambah. T008 tidak membuat aset gambar/audio. |
| Tentukan lisensi code, aturan kredit dependency, dan hak distribusi sebelum paket dibagikan. Visual/audio procedural tetap keputusan PRD. | PRD §9, §19; T096 | Owner memilih lisensi dan URL repo; T008 tidak menetapkan lisensi atau membuat repo eksternal. |
| Gunakan deadline WIB yang telah dikonversi untuk perencanaan; uji artifact bersih dan lengkapi submission sebelum batas tersebut. | T096, T097 | Tidak menetapkan estimasi pengerjaan atau menjanjikan seluruh P1 selesai sebelum deadline. |
| Pastikan halaman game benar-benar terdaftar pada jam; source push dan upload game harus sama-sama siap. | PRD §19; T096, T097 | Paket/checklist adalah pekerjaan backlog; pengiriman eksternal belum dilakukan. |

Tidak ada perubahan FR, prioritas, atau scope gameplay yang diperlukan berdasarkan temuan T008. Konsekuensi rilis di atas dipetakan ke task yang sudah ada. Jika owner menginginkan perubahan platform, scope, atau persyaratan lain, catat keputusan dan dampak task sebelum implementasinya.

## Hal yang masih perlu ditutup saat rilis

- [ ] Owner menetapkan lisensi code/aset serta lokasi repository publik; verifikasi URL dapat dibuka tanpa akses khusus.
- [ ] T093/T094 membuktikan paket playable dan instruksi akses pada platform yang benar-benar dikirim. Detail packaging/ukuran file itch.io diuji di sana; jam tidak menetapkan satu format archive wajib pada sumber yang diperiksa.
- [ ] T096 mengecek ulang aturan, melengkapi disclosure AI aktual, kredit, checksum/version, known issues, dan GitHub URL.
- [ ] T097 menilai kesiapan paket; submission eksternal harus dilakukan dalam konteks otorisasi pengiriman yang sesuai.

Temuan tema, deadline, AI policy, platform, dan source/submission sudah terkonfirmasi; tidak ada blocker riset T008 yang tersisa. Checklist rilis belum ditandai selesai dan dokumen ini bukan klaim bahwa game sudah dikirim atau telah diterima penyelenggara.
