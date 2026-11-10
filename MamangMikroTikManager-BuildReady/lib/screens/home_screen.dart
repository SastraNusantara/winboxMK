import 'package:flutter/material.dart';
import '../models/router_profile.dart';
import '../services/routeros_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _client = RouterOsClient();
  final _host = TextEditingController();
  final _port = TextEditingController(text: '8728');
  final _user = TextEditingController(text: 'admin');
  final _password = TextEditingController();
  String _status = 'Belum terhubung';
  String _routerName = 'Belum ada router';
  bool _busy = false;
  int _selected = 0;

  final _modules = const [
    ('Dashboard', Icons.dashboard_rounded),
    ('Hotspot', Icons.wifi_rounded),
    ('PPPoE', Icons.account_tree_rounded),
    ('Traffic', Icons.show_chart_rounded),
    ('Pelanggan & IP', Icons.people_alt_rounded),
    ('Simple Queue', Icons.speed_rounded),
    ('Firewall / NAT', Icons.shield_rounded),
    ('Terminal', Icons.terminal_rounded),
    ('Backup / Restore', Icons.backup_rounded),
  ];

  Future<void> _connect() async {
    if (_host.text.trim().isEmpty || _user.text.trim().isEmpty) {
      _message('Isi alamat router dan username terlebih dahulu.');
      return;
    }
    setState(() { _busy = true; _status = 'Menghubungkan...'; });
    try {
      await _client.connect(
        host: _host.text.trim(),
        port: int.tryParse(_port.text) ?? 8728,
        username: _user.text.trim(),
        password: _password.text,
      );
      final identity = await _client.command(['/system/identity/print']);
      final id = identity.expand((e) => e).firstWhere(
        (e) => e.startsWith('=name='),
        orElse: () => '=name=MikroTik',
      );
      setState(() { _status = 'Terhubung'; _routerName = id.substring(6); });
      _message('Koneksi berhasil.');
    } catch (e) {
      setState(() => _status = 'Gagal terhubung');
      _message('Koneksi gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _host.dispose(); _port.dispose(); _user.dispose(); _password.dispose();
    _client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 760;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mamang MikroTik Manager', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Chip(
              avatar: Icon(_client.isConnected ? Icons.circle : Icons.circle_outlined,
                size: 11, color: _client.isConnected ? Colors.greenAccent : Colors.orangeAccent),
              label: Text(_status, style: const TextStyle(fontSize: 12)),
            ),
          )
        ],
      ),
      drawer: isMobile ? Drawer(child: _navigation()) : null,
      body: Row(children: [
        if (!isMobile) SizedBox(width: 238, child: _navigation()),
        Expanded(child: _selected == 0 ? _dashboard() : _modulePage(_modules[_selected].$1)),
      ]),
    );
  }

  Widget _navigation() => Container(
    color: const Color(0xFF171D2B),
    child: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 16, 12, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.router_rounded, size: 34, color: Color(0xFFB9A5FF)),
            SizedBox(height: 10),
            Text('NETWORK CENTER', style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: Colors.white60)),
          ]),
        ),
        for (var i = 0; i < _modules.length; i++)
          ListTile(
            selected: _selected == i,
            selectedTileColor: const Color(0xFF35304F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(_modules[i].$2),
            title: Text(_modules[i].$1, style: const TextStyle(fontSize: 13)),
            onTap: () { setState(() => _selected = i); Navigator.maybePop(context); },
          ),
      ],
    ),
  );

  Widget _dashboard() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Text('Pusat kendali jaringan MikroTik', style: TextStyle(color: Colors.white.withOpacity(.6))),
      const SizedBox(height: 20),
      _connectionCard(),
      const SizedBox(height: 16),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _stat('CPU', '--', Icons.memory_rounded),
        _stat('RAM', '--', Icons.storage_rounded),
        _stat('Uptime', '--', Icons.timer_rounded),
        _stat('Traffic RX/TX', '--', Icons.swap_vert_rounded),
      ]),
      const SizedBox(height: 18),
      Card(child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Status Router', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 12),
          _info('Nama perangkat', _routerName),
          _info('Koneksi', _status),
          _info('Target kompatibilitas', 'RouterOS v6 dan v7'),
          _info('Metode akses', 'LAN / WiFi / VPN / remote'),
        ]),
      )),
      const SizedBox(height: 12),
      const Text('Catatan keamanan', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Gunakan akun RouterOS khusus dengan hak minimum yang diperlukan. Untuk akses jarak jauh, prioritaskan VPN dan jangan membuka port API ke internet publik.'),
    ]),
  );

  Widget _connectionCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Koneksi Router', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          SizedBox(width: 220, child: TextField(controller: _host, decoration: const InputDecoration(labelText: 'IP / Hostname'))),
          SizedBox(width: 100, child: TextField(controller: _port, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Port'))),
          SizedBox(width: 160, child: TextField(controller: _user, decoration: const InputDecoration(labelText: 'Username'))),
          SizedBox(width: 180, child: TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password'))),
          FilledButton.icon(onPressed: _busy ? null : _connect, icon: const Icon(Icons.link), label: Text(_busy ? 'Menghubungkan' : 'Hubungkan')),
          OutlinedButton.icon(onPressed: () async { await _client.disconnect(); setState(() => _status = 'Terputus'); }, icon: const Icon(Icons.link_off), label: const Text('Putuskan')),
        ]),
      ]),
    ),
  );

  Widget _stat(String title, String value, IconData icon) => SizedBox(
    width: 175,
    child: Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFFB9A5FF)),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ]),
    )),
  );

  Widget _info(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [Expanded(child: Text(k, style: const TextStyle(color: Colors.white60))), Text(v)]),
  );

  Widget _modulePage(String title) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.construction_rounded, size: 42, color: Color(0xFFB9A5FF)),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Modul ini sudah disiapkan dalam navigasi proyek dan akan diimplementasikan bertahap setelah koneksi API dasar diuji pada RouterOS v6 dan v7.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Chip(label: Text('Tahap pengembangan berikutnya')),
          ]),
        )),
      ),
    ),
  );
}
