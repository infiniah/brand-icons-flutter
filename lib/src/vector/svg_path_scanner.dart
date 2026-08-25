/// Reads SVG path data one token at a time.
///
/// Path data is ASCII by grammar, so the text is held as code units. That matters: an icon path
/// runs to several thousand characters and is re-read whenever a cache misses.
class SVGPathScanner {
  SVGPathScanner(String text) : _units = text.codeUnits;

  final List<int> _units;
  int _index = 0;

  static const int _point = 0x2E;
  static const int _zero = 0x30;
  static const int _nine = 0x39;
  static const int _one = 0x31;
  static const int _lowerE = 0x65;
  static const int _upperE = 0x45;
  static const int _minus = 0x2D;
  static const int _plus = 0x2B;
  static const Set<int> _separators = {0x20, 0x09, 0x0A, 0x0D, 0x0C, 0x0B, 0x2C};

  static bool _isSeparator(int unit) => _separators.contains(unit);
  static bool _isDigit(int unit) => unit >= _zero && unit <= _nine;
  static bool _isSign(int unit) => unit == _minus || unit == _plus;
  static bool _isSignOrPoint(int unit) => _isSign(unit) || unit == _point;

  /// True once nothing but separators remains.
  bool get isAtEnd {
    var probe = _index;
    while (probe < _units.length && _isSeparator(_units[probe])) {
      probe++;
    }
    return probe >= _units.length;
  }

  /// True when the next token starts a number, so a command can be repeated implicitly.
  bool get hasNumber {
    var probe = _index;
    while (probe < _units.length && _isSeparator(_units[probe])) {
      probe++;
    }
    if (probe >= _units.length) return false;
    return _isDigit(_units[probe]) || _isSignOrPoint(_units[probe]);
  }

  void _skipSeparators() {
    while (_index < _units.length && _isSeparator(_units[_index])) {
      _index++;
    }
  }

  /// The next command letter, or null when the next token is not one.
  int? nextCommandUnit() {
    _skipSeparators();
    if (_index >= _units.length) return null;
    final unit = _units[_index];
    final letter = String.fromCharCode(unit).toLowerCase();
    if (!'mzlhvcsqta'.contains(letter)) return null;
    _index++;
    return unit;
  }

  double? nextNumber() {
    _skipSeparators();
    if (_index >= _units.length) return null;

    final start = _index;
    var sawDigit = false;
    var sawPoint = false;

    if (_isSign(_units[_index])) _index++;

    while (_index < _units.length) {
      final unit = _units[_index];
      if (_isDigit(unit)) {
        sawDigit = true;
        _index++;
      } else if (unit == _point && !sawPoint) {
        sawPoint = true;
        _index++;
      } else {
        break;
      }
    }

    if (!sawDigit) {
      _index = start;
      return null;
    }

    if (_index < _units.length &&
        (_units[_index] == _lowerE || _units[_index] == _upperE)) {
      final beforeExponent = _index;
      _index++;
      if (_index < _units.length && _isSign(_units[_index])) _index++;
      var sawExponentDigit = false;
      while (_index < _units.length && _isDigit(_units[_index])) {
        sawExponentDigit = true;
        _index++;
      }
      if (!sawExponentDigit) _index = beforeExponent;
    }

    final literal = String.fromCharCodes(_units.sublist(start, _index));
    final value = double.tryParse(literal);
    if (value == null || !value.isFinite) {
      _index = start;
      return null;
    }
    return value;
  }

  /// An arc flag, which the grammar defines as the single character `0` or `1`.
  bool? nextFlag() {
    _skipSeparators();
    if (_index >= _units.length) return null;
    final unit = _units[_index];
    if (unit != _zero && unit != _one) return null;
    _index++;
    return unit == _one;
  }
}
