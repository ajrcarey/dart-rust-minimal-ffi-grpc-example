part of app;

class Option<T> {
  Option.some(final T value) : _value = value {
    if (value == null) {
      throw _e;
    }
  }

  Option.none() : _value = null;

  factory Option.maybe(
          final T // TODO: T? once Flutter supports dart 2.8
              value) =>
      value == null ? new Option<T>.none() : new Option<T>.some(value);

  final T _value;

  bool get isEmpty => _value == null;

  bool get isNotEmpty => _value != null;

  bool contains(final T that) => isNotEmpty && _value == that;

  Iterable<T> toIterable() => isNotEmpty ? [_value] : [];

  void ifMissing(void f()) {
    if (isEmpty) {
      f();
    }
  }

  void ifPresent(void f(final T t)) {
    if (isNotEmpty) {
      f(_value);
    }
  }

  void ifContains(final T that, void f()) {
    if (contains(that)) {
      f();
    }
  }

  void match(void ifPresent(final T v), void ifMissing()) =>
      isNotEmpty ? ifPresent(_value) : ifMissing();

  R cond<R>(R ifPresent(final T t), R ifMissing()) =>
      isEmpty ? ifMissing() : ifPresent(_value);

  bool filter(bool predicate(final T v)) => isEmpty ? false : predicate(_value);

  Option<R> map<R>(R mapping(final T v)) =>
      isEmpty ? new Option<R>.none() : new Option<R>.maybe(mapping(_value));

  Option<R> flatMap<R>(Option<R> mapping(final T v)) =>
      isEmpty ? new Option<R>.none() : mapping(_value);

  T orElse(final T sentinel) => isEmpty ? sentinel : _value;

  T orElseGet(T supplier()) => isEmpty ? supplier() : _value;

  Option<T> orElsePass(covariant Option<T> supplier()) =>
      isEmpty ? supplier() : this;

  T orElseThrow(final Exception e) => isEmpty ? throw e : _value;

  T orElsePanic() => orElseThrow(_e);

  static final NullArgumentException _e = new NullArgumentException();

  @override
  bool operator ==(Object other) {
    if (!(other is Option)) {
      return false;
    } else {
      return _value == (other as Option)._value;
    }
  }

  @override
  String toString() => isNotEmpty ? 'Some<$T = $_value>' : 'None<$T>';
}

class NullArgumentException implements Exception {}

// ignore: non_constant_identifier_names
Option<T> Some<T>(final T value) => Option<T>.some(value);

// ignore: non_constant_identifier_names
Option<T> None<T>() => Option<T>.none();

// ignore: non_constant_identifier_names
Option<T> Maybe<T>(
        final T // TODO: T? once Flutter supports dart 2.8
            value) =>
    Option<T>.maybe(value);
