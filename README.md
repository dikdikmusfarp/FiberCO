# FiberCo - Data Analyst Technical Assessment

Analisis performa infrastruktur, Servco, dan monetisasi media FiberCo untuk periode Januari sampai Desember 2025.

Isi folder:

- Query lengkap ada di `sql/`. Penomoran file saya buat mengikuti urutan pertanyaan di tiap section biar gampang dicocokkan.
- Executive summary (PDF) saya taruh terpisah di folder ini.
- Engine yang saya pakai DuckDB. Semua query bisa dijalankan ulang di atas lima tabel sumber: homepass, subscription_snapshot, servco, media_package, dan region_master.

## Dashboard Tableau Public

Dashboard dipisah per section:

- Infrastructure Overview: https://public.tableau.com/app/profile/dikdik.musfar/viz/InfrastructureOverview_17850846923050/InfrastructureOverview
- Servco & Competition: https://public.tableau.com/app/profile/dikdik.musfar/viz/ServcoCompetition/ServcoCompetition
- Media Monetization: https://public.tableau.com/app/profile/dikdik.musfar/viz/MediaMonetization/MediaMonetization
- Six Month Strategy: https://public.tableau.com/app/profile/dikdik.musfar/viz/SixMonthStrategy/SixMonthStrategy

README ini isinya jawaban bagian yang butuh penjelasan teks, plus asumsi yang saya ambil.

## Asumsi

Ada beberapa hal yang saya putuskan di awal dan perlu dijelaskan:

- Penetration saya hitung sebagai Active CA dibagi Total Homepass di periode yang sama.
- Revenue per homepass pakai total lease revenue bulan berjalan dibagi jumlah homepass bulan itu, bukan rata-rata setahun.
- Periode exclusive di data ini jalan dari Januari sampai Juni 2025. Performa selama masa exclusive saya pisahkan dari performa sesudahnya (Juli sampai Desember) supaya perbandingannya adil.
- Attach rate media dihitung dari snapshot Desember 2025 saja. Tabel media tidak punya kolom tanggal, jadi tren bulanan memang tidak bisa dibuat.
- Di area multi-ISP, satu homepass bisa punya lebih dari satu Active CA. Karena itu saya pisahkan penetration berbasis homepass aktif dan penetration berbasis jumlah CA.
- Semua angka kolom `_pct` di CSV hasil disimpan dalam skala 0-100 (misal `75.10`), bukan 0-1.

## Section 1: Infrastructure & Utilization

Untuk pola strukturalnya (Task 4), utilisasi memang naik di hampir semua grup sepanjang 2025, tapi sebarannya tidak merata.

- Area open access lebih baik dibanding area yang dulunya exclusive. Di Desember 2025 open access mencapai 82.67% penetration dan Rp108.5K revenue/homepass, sementara area bekas exclusive cuma 59.60% dan Rp79.5K.
- HFC menghasilkan revenue/homepass lebih tinggi dari FTTH, Rp107.1K vs Rp99.0K di Desember. Total revenue FTTH memang lebih besar, tapi jumlah homepass-nya juga lebih banyak, jadi revenue/homepass lebih adil buat membandingkan keduanya.
- Utilisasi rendah menumpuk di lima fibernode yang selalu ada di kuartil penetration terbawah sepanjang 12 periode: F708541, F951618, F737809, F125728, dan F926002. Ini masalah yang menetap, bukan penurunan sesaat.

Jadi menurut saya utilisasi node lemah ini yang harus dibereskan dulu sebelum ekspansi jaringan besar-besaran. Perbandingan exclusive vs open access juga sebaiknya dibaca dengan konteks periode kontrak, bukan cuma angka akhirnya.

Query terkait: `01_monthly_penetration.sql`, `02a_high_capex_low_utilization.sql`, `02b_underperforming_fibernode.sql`, `03_monetization_trend.sql`.

## Section 2: Servco Performance & Competition

- XLS (Servco 101) jadi kontributor terbesar, 175 Active CA dan 24.19% kontribusi lease revenue di Desember.
- Dibanding minimum guarantee 25%, XLS jauh di atas. Penetration Desember 65.06%, atau selisih 40.06 poin persen di atas guarantee. Sepanjang 12 bulan statusnya selalu memenuhi guarantee.
- Exclusive vs post-exclusive: di 250 homepass yang dulu exclusive, homepass penetration naik dari 24.00% (Juni) ke 56.40% (Desember) setelah masa exclusive habis.
- Single vs multi-ISP: area multi-ISP mencapai 73.33% homepass penetration dan Rp128.8K revenue/homepass, di atas single-ISP yang 68.00% dan Rp89.4K.

Satu catatan penting, angka-angka ini menunjukkan hubungan, bukan bukti sebab-akibat. Kenaikan sesudah exclusive berakhir belum tentu murni karena kompetisi.

Query terkait: `05_servco_performance.sql`, `06_xls_minimum_guarantee.sql`, `07a_exclusivity_phase.sql`, `07b_isp_competition.sql`.

## Section 3: Media Monetization & Profitability

- Attach rate tertinggi per Servco ada di MMA (51.85%), per region ada di Jakarta Pusat (53.52%).
- Produk dengan total margin tertinggi Catchplay (Rp2.37M), sementara margin rate tertinggi Sport Pack (45.31%).
- Region dengan potensi terbesar adalah Jakarta Utara (potensi tambahan 18 media CA) dan Jakarta Barat (11), totalnya 29 CA kalau attach rate-nya dikejar sampai benchmark 53.52%.

Apakah media benar-benar mengangkat ARPU (Task 4)? Iya. Berbasis pelanggan aktif Desember 2025 (360 pakai media, 409 tanpa media), pelanggan tanpa media punya combined ARPU Rp131.7K, sedangkan yang pakai media Rp274.6K. Uplift-nya 108.57% dibanding lease ARPU pelanggan media, atau kira-kira dua kali lipat ARPU pelanggan tanpa media.

Tapi ada batasnya. Ini kenaikan revenue, bukan net profit. Data cuma menyediakan wholesale cost add-on dan tidak ada biaya paket CATV dasar, jadi dampak penuh ke laba belum bisa dihitung.

Query terkait: `08_media_attach_rate.sql`, `09_media_revenue_margin.sql`, `10a_product_profitability.sql`, `10b_servco_upsell.sql`, `10c_region_potential.sql`, `11_media_arpu_impact.sql`.

## Section 4: Strategic Recommendations

Tiga prioritas buat enam bulan ke depan:

1. Bereskan utilisasi lima node lemah. Kelimanya punya 250 homepass dan 149 Active CA (59.60%). Kalau mau target 70% dalam enam bulan, butuh 175 Active CA, artinya tambahan 26 CA. Fokuskan akuisisi dan evaluasi kualitas layanan di sini dulu.
2. Uji perluasan multi-ISP secara terkontrol dan buat exclusivity berbasis performa. Selisih revenue/homepass multi vs single-ISP sampai Rp39.4K. Sebaiknya lewat pilot dulu karena datanya belum membuktikan kausalitas.
3. Dorong media upsell di region yang gap-nya paling besar. Prioritas Jakarta Utara dan Jakarta Barat (total 29 media CA), pakai pendekatan MMA sebagai acuan dan Catchplay sebagai produk andalan.

Jawaban untuk pertanyaan kebijakan:

- Ekspansi FTTH agresif? Belum perlu. FTTH masih di bawah HFC baik di penetration, revenue/homepass, maupun capex per Active CA. Cukup ekspansi selektif di area yang demand-nya sudah terbukti, dan dahulukan perbaikan utilisasi aset yang sudah ada.
- Lanjutkan exclusivity? Tidak sebagai kebijakan standar. Kalau tetap dipakai, batasi periodenya, kasih target penetration yang jelas, dan sertakan opsi membuka akses kalau targetnya meleset.
- Dorong multi-ISP? Iya, tapi bertahap. Pilot dulu di node utilisasi rendah sebelum diterapkan ke seluruh jaringan.
- Ubah strategi media bundling? Iya, perluas tapi terarah. Yang dipantau bukan cuma revenue, tapi juga attach rate, media ARPU, add-on margin, dan retention.

Benang merahnya, maksimalkan dulu return dari aset dan pelanggan yang sudah ada sebelum ekspansi infrastruktur skala besar.

Query pendukung: `13a_technology_evidence.sql` sampai `13g_product_margin_evidence.sql`.

## Struktur folder

```
submission/
├── README.md
├── executive_summary.pdf   (menyusul, termasuk link Tableau Public)
└── sql/                     (semua query, dinomori sesuai urutan pertanyaan)
```
