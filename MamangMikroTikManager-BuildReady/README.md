# Mamang MikroTik Manager

Starter project Flutter untuk aplikasi manajemen MikroTik lintas platform:
- Windows desktop
- Android
- Target RouterOS v6 dan v7
- Koneksi LAN, Wi-Fi, VPN, dan remote melalui jaringan privat

## Status saat ini

Ini adalah **starter/prototype**, bukan aplikasi produksi dan bukan Winbox resmi.
Tampilan dashboard, navigasi modul, form koneksi, dan kerangka RouterOS API sudah disiapkan.
Modul Hotspot, PPPoE, traffic realtime, pelanggan/IP, Simple Queue, Firewall/NAT,
Terminal, Backup/Restore masih perlu implementasi dan pengujian.

## Prasyarat

- Flutter stable (Dart 3.3+)
- Android SDK untuk APK
- Visual Studio dengan workload **Desktop development with C++** untuk Windows

## Menjalankan

```bash
flutter create --platforms=android,windows .
flutter pub get
flutter run
```

## Build Android

```bash
flutter build apk --release
```

APK biasanya berada di:
`build/app/outputs/flutter-apk/app-release.apk`

## Build Windows

```bash
flutter config --enable-windows-desktop
flutter create --platforms=android,windows .
flutter build windows --release
```

Output biasanya berada di:
`build/windows/x64/runner/Release/`

## Pengaturan MikroTik

1. Buat user RouterOS khusus untuk aplikasi dengan hak akses minimum.
2. Aktifkan API hanya pada interface/jaringan tepercaya.
3. Default API: TCP 8728; API-SSL: TCP 8729.
4. Untuk akses remote, gunakan VPN (misalnya WireGuard) atau jaringan privat.
5. Jangan expose API atau Winbox langsung ke internet publik.

## Catatan teknis penting

`lib/services/routeros_client.dart` adalah kerangka awal protokol API dan belum siap produksi.
Penanganan stream terfragmentasi, autentikasi kompatibilitas RouterOS v6/v7,
timeout, reconnect, TLS certificate validation, serta pengujian integrasi harus
diselesaikan sebelum dipakai mengelola router sungguhan. Jangan gunakan untuk
perubahan konfigurasi produksi pada tahap ini.

## Rencana milestone

1. Stabilkan API client dan autentikasi v6/v7.
2. Router profiles, secure credential storage, multi-router.
3. Hotspot dan PPPoE.
4. Simple Queue dan traffic realtime.
5. Pelanggan/IP dan monitoring perangkat.
6. Firewall/NAT dengan konfirmasi tindakan berisiko.
7. Terminal dengan audit log dan allowlist/konfirmasi.
8. Backup/restore dengan validasi file dan konfirmasi.
9. Build dan uji APK + Windows installer.
