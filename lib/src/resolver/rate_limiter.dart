import 'dart:math' as math;

/// A token bucket, in requests per minute, that callers await before touching the network.
///
/// Callers arriving with the bucket empty are queued rather than spun on: each takes its token
/// immediately, driving the balance negative, then waits exactly as long as it takes the bucket to
/// refill that far.
class RateLimiter {
  RateLimiter({required int requestsPerMinute, int? burst})
      : _capacity = math.max(1, burst ?? math.max(1, requestsPerMinute)).toDouble(),
        _refillPerSecond = math.max(1, requestsPerMinute) / 60 {
    _tokens = _capacity;
    _lastRefill = DateTime.now();
  }

  final double _capacity;
  final double _refillPerSecond;
  late double _tokens;
  late DateTime _lastRefill;

  /// Returns once this caller is allowed to proceed.
  Future<void> acquire() async {
    final wait = _claim();
    if (wait > 0) {
      await Future<void>.delayed(Duration(milliseconds: (wait * 1000).round()));
    }
  }

  /// Tokens currently spendable without waiting.
  int availableTokens() {
    _refill();
    return math.max(0, _tokens.floor());
  }

  void reset() {
    _tokens = _capacity;
    _lastRefill = DateTime.now();
  }

  double _claim() {
    _refill();
    _tokens -= 1;
    return _tokens < 0 ? -_tokens / _refillPerSecond : 0;
  }

  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill).inMicroseconds / 1e6;
    _lastRefill = now;
    if (elapsed <= 0) return;
    _tokens = math.min(_capacity, _tokens + elapsed * _refillPerSecond);
  }
}
