import 'brand_icon_source.dart';

/// Why a provider returned nothing, when it failed rather than simply not matching.
sealed class BrandIconError implements Exception {
  const BrandIconError();

  String get message;

  @override
  String toString() => message;
}

class NotFoundError extends BrandIconError {
  const NotFoundError();
  @override
  String get message => 'no match';
}

class UnreadableResponseError extends BrandIconError {
  const UnreadableResponseError();
  @override
  String get message => 'unreadable response';
}

class RateLimitedError extends BrandIconError {
  const RateLimitedError([this.retryAfterSeconds]);
  final double? retryAfterSeconds;
  @override
  String get message => retryAfterSeconds == null
      ? 'rate limited'
      : 'rate limited, retry in ${retryAfterSeconds!.toInt()}s';
}

class ProviderDisabledError extends BrandIconError {
  const ProviderDisabledError(this.source);
  final BrandIconSource source;
  @override
  String get message => '${source.id} is off';
}

class TransportError extends BrandIconError {
  const TransportError(this.detail);
  final String detail;
  @override
  String get message => detail;
}
