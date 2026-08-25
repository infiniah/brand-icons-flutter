import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/brand_icon_error.dart';

/// The only thing in the library that touches the network.
///
/// Kept behind an interface so every provider can be exercised without it. A non success code
/// comes back as null, because a provider not knowing a brand is an ordinary answer rather than an
/// error. `429` is the exception: being rate limited is something the caller may want to act on.
abstract class IconDownloader {
  Future<Uint8List?> bytes(String url, {String? referer, String? accept});

  Future<Map<String, dynamic>?> json(String url) async {
    final payload = await bytes(url, accept: 'application/json');
    if (payload == null) return null;
    try {
      return jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// The document head only, which is all any icon declaration lives in.
  Future<String?> headMarkup(String url);
}

class HttpIconDownloader extends IconDownloader {
  HttpIconDownloader({http.Client? client, this.timeout = const Duration(seconds: 8)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  static const _userAgent =
      'BrandIcons/1.0 (+https://github.com/infiniah/brand-icons-flutter)';

  /// Enough of a document to contain `<head>`, so a huge page is not downloaded whole.
  static const _markupLimit = 96 * 1024;

  @override
  Future<Uint8List?> bytes(String url, {String? referer, String? accept}) async {
    final response = await _get(url, referer: referer, accept: accept);
    return response?.bodyBytes;
  }

  @override
  Future<String?> headMarkup(String url) async {
    final response = await _get(url, accept: 'text/html');
    if (response == null) return null;
    final body = response.bodyBytes;
    final slice = body.length > _markupLimit ? body.sublist(0, _markupLimit) : body;
    return utf8.decode(slice, allowMalformed: true);
  }

  Future<http.Response?> _get(String url, {String? referer, String? accept}) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    try {
      final response = await _client.get(uri, headers: {
        'User-Agent': _userAgent,
        if (accept != null) 'Accept': accept,
        if (referer != null) 'Referer': referer,
      }).timeout(timeout);

      if (response.statusCode == 429) {
        throw RateLimitedError(double.tryParse(response.headers['retry-after'] ?? ''));
      }
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      return response;
    } on BrandIconError {
      rethrow;
    } catch (_) {
      return null;
    }
  }
}
