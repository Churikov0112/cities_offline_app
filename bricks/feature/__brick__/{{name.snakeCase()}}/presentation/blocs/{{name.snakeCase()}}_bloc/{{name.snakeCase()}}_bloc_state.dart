part of '{{name.snakeCase()}}_bloc.dart';

@freezed
class {{name.pascalCase()}}State with _${{name.pascalCase()}}State {
  const {{name.pascalCase()}}State._();

  const factory {{name.pascalCase()}}State.initial() = _{{name.pascalCase()}}InitialState;



  {{name.pascalCase()}}StateIsTypeHelpers get isType {
    return {{name.pascalCase()}}StateIsTypeHelpers._(this);
  }
}

class {{name.pascalCase()}}StateIsTypeHelpers {
  final {{name.pascalCase()}}State _s;

  {{name.pascalCase()}}StateIsTypeHelpers._(this._s);

  bool get initial => _s is _{{name.pascalCase()}}InitialState;
}
