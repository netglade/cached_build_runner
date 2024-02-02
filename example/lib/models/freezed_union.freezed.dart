// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'freezed_union.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$FreezedUnion {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() home,
    required TResult Function(User user) user,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? home,
    TResult? Function(User user)? user,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? home,
    TResult Function(User user)? user,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Home value) home,
    required TResult Function(UserUnion value) user,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Home value)? home,
    TResult? Function(UserUnion value)? user,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Home value)? home,
    TResult Function(UserUnion value)? user,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FreezedUnionCopyWith<$Res> {
  factory $FreezedUnionCopyWith(
          FreezedUnion value, $Res Function(FreezedUnion) then) =
      _$FreezedUnionCopyWithImpl<$Res, FreezedUnion>;
}

/// @nodoc
class _$FreezedUnionCopyWithImpl<$Res, $Val extends FreezedUnion>
    implements $FreezedUnionCopyWith<$Res> {
  _$FreezedUnionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$HomeImplCopyWith<$Res> {
  factory _$$HomeImplCopyWith(
          _$HomeImpl value, $Res Function(_$HomeImpl) then) =
      __$$HomeImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$HomeImplCopyWithImpl<$Res>
    extends _$FreezedUnionCopyWithImpl<$Res, _$HomeImpl>
    implements _$$HomeImplCopyWith<$Res> {
  __$$HomeImplCopyWithImpl(_$HomeImpl _value, $Res Function(_$HomeImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$HomeImpl implements Home {
  const _$HomeImpl();

  @override
  String toString() {
    return 'FreezedUnion.home()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$HomeImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() home,
    required TResult Function(User user) user,
  }) {
    return home();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? home,
    TResult? Function(User user)? user,
  }) {
    return home?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? home,
    TResult Function(User user)? user,
    required TResult orElse(),
  }) {
    if (home != null) {
      return home();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Home value) home,
    required TResult Function(UserUnion value) user,
  }) {
    return home(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Home value)? home,
    TResult? Function(UserUnion value)? user,
  }) {
    return home?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Home value)? home,
    TResult Function(UserUnion value)? user,
    required TResult orElse(),
  }) {
    if (home != null) {
      return home(this);
    }
    return orElse();
  }
}

abstract class Home implements FreezedUnion {
  const factory Home() = _$HomeImpl;
}

/// @nodoc
abstract class _$$UserUnionImplCopyWith<$Res> {
  factory _$$UserUnionImplCopyWith(
          _$UserUnionImpl value, $Res Function(_$UserUnionImpl) then) =
      __$$UserUnionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({User user});
}

/// @nodoc
class __$$UserUnionImplCopyWithImpl<$Res>
    extends _$FreezedUnionCopyWithImpl<$Res, _$UserUnionImpl>
    implements _$$UserUnionImplCopyWith<$Res> {
  __$$UserUnionImplCopyWithImpl(
      _$UserUnionImpl _value, $Res Function(_$UserUnionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
  }) {
    return _then(_$UserUnionImpl(
      null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as User,
    ));
  }
}

/// @nodoc

class _$UserUnionImpl implements UserUnion {
  const _$UserUnionImpl(this.user);

  @override
  final User user;

  @override
  String toString() {
    return 'FreezedUnion.user(user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserUnionImpl &&
            (identical(other.user, user) || other.user == user));
  }

  @override
  int get hashCode => Object.hash(runtimeType, user);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserUnionImplCopyWith<_$UserUnionImpl> get copyWith =>
      __$$UserUnionImplCopyWithImpl<_$UserUnionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() home,
    required TResult Function(User user) user,
  }) {
    return user(this.user);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? home,
    TResult? Function(User user)? user,
  }) {
    return user?.call(this.user);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? home,
    TResult Function(User user)? user,
    required TResult orElse(),
  }) {
    if (user != null) {
      return user(this.user);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Home value) home,
    required TResult Function(UserUnion value) user,
  }) {
    return user(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Home value)? home,
    TResult? Function(UserUnion value)? user,
  }) {
    return user?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Home value)? home,
    TResult Function(UserUnion value)? user,
    required TResult orElse(),
  }) {
    if (user != null) {
      return user(this);
    }
    return orElse();
  }
}

abstract class UserUnion implements FreezedUnion {
  const factory UserUnion(final User user) = _$UserUnionImpl;

  User get user;
  @JsonKey(ignore: true)
  _$$UserUnionImplCopyWith<_$UserUnionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
