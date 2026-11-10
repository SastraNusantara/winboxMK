import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Minimal RouterOS API sentence client.
/// Default ports: 8728 (API), 8729 (API-SSL).
/// Use a VPN or trusted LAN; do not expose API ports publicly.
class RouterOsClient {
  Socket? _socket;
  StreamIterator<List<int>>? _iterator;
  bool get isConnected => _socket != null;

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
    bool useTls = false,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    await disconnect();
    if (useTls) {
      _socket = await SecureSocket.connect(host, port, timeout: timeout);
    } else {
      _socket = await Socket.connect(host, port, timeout: timeout);
    }
    _iterator = StreamIterator<List<int>>(_socket!);
    try {
      final challenge = await _readSentence().timeout(timeout);
      if (challenge.isNotEmpty && challenge.first == '!done') {
        await _writeSentence(['/login', '=name=$username', '=password=$password']);
      } else {
        await _writeSentence(['/login', '=name=$username', '=password=$password']);
      }
      final reply = await _readReply().timeout(timeout);
      if (reply.any((s) => s.first == '!trap')) {
        throw Exception(_extractMessage(reply));
      }
    } catch (_) {
      await disconnect();
      rethrow;
    }
  }

  Future<List<List<String>>> command(List<String> words) async {
    if (_socket == null) throw StateError('Belum terhubung ke router');
    await _writeSentence(words);
    return _readReply();
  }

  Future<List<List<String>>> _readReply() async {
    final result = <List<String>>[];
    while (true) {
      final sentence = await _readSentence();
      if (sentence.isEmpty) continue;
      result.add(sentence);
      if (sentence.first == '!done') return result;
      if (sentence.first == '!trap') {
        // Continue until !done so the stream remains aligned.
      }
    }
  }

  String _extractMessage(List<List<String>> reply) {
    for (final sentence in reply) {
      for (final word in sentence) {
        if (word.startsWith('=message=')) return word.substring(9);
      }
    }
    return 'Autentikasi gagal atau router menolak perintah.';
  }

  Future<void> _writeSentence(List<String> words) async {
    final socket = _socket;
    if (socket == null) throw StateError('Socket tidak tersedia');
    for (final word in words) {
      final bytes = utf8.encode(word);
      socket.add(_encodeLength(bytes.length));
      socket.add(bytes);
    }
    socket.add(const [0]);
    await socket.flush();
  }

  Future<List<String>> _readSentence() async {
    final words = <String>[];
    while (true) {
      final length = await _readLength();
      if (length == 0) return words;
      final bytes = await _readExact(length);
      words.add(utf8.decode(bytes, allowMalformed: true));
    }
  }

  Future<int> _readLength() async {
    final first = (await _readExact(1))[0];
    if ((first & 0x80) == 0) return first;
    if ((first & 0xC0) == 0x80) {
      return ((first & 0x3F) << 8) | (await _readExact(1))[0];
    }
    if ((first & 0xE0) == 0xC0) {
      final b = await _readExact(3);
      return ((first & 0x1F) << 24) | (b[0] << 16) | (b[1] << 8) | b[2];
    }
    if ((first & 0xF0) == 0xE0) {
      final b = await _readExact(4);
      return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
    }
    throw const FormatException('Panjang paket API tidak valid');
  }

  Future<List<int>> _readExact(int count) async {
    final iterator = _iterator;
    if (iterator == null) throw StateError('Koneksi terputus');
    final out = <int>[];
    while (out.length < count) {
      if (!await iterator.moveNext()) throw const SocketException('Koneksi ditutup router');
      final chunk = iterator.current;
      final remaining = count - out.length;
      if (chunk.length <= remaining) {
        out.addAll(chunk);
      } else {
        out.addAll(chunk.take(remaining));
        // StreamIterator does not support putting the unused tail back.
        // This client therefore reads exact-sized chunks through a buffered socket
        // implementation in the next development milestone.
        throw const FormatException('Fragmentasi stream tidak didukung pada prototipe awal');
      }
    }
    return out;
  }

  List<int> _encodeLength(int length) {
    if (length < 0x80) return [length];
    if (length < 0x4000) return [((length >> 8) | 0x80), length & 0xFF];
    if (length < 0x200000) return [((length >> 16) | 0xC0), (length >> 8) & 0xFF, length & 0xFF];
    if (length < 0x10000000) {
      return [((length >> 24) | 0xE0), (length >> 16) & 0xFF, (length >> 8) & 0xFF, length & 0xFF];
    }
    return [0xF0, (length >> 24) & 0xFF, (length >> 16) & 0xFF, (length >> 8) & 0xFF, length & 0xFF];
  }

  Future<void> disconnect() async {
    await _iterator?.cancel();
    _iterator = null;
    _socket?.destroy();
    _socket = null;
  }
}
