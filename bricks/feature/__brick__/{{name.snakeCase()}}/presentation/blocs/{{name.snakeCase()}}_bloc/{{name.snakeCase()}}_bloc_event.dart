part of '{{name.snakeCase()}}_bloc.dart';

@freezed
class {{name.pascalCase()}}Event with _${{name.pascalCase()}}Event {
  const {{name.pascalCase()}}Event._();

  const factory {{name.pascalCase()}}Event.eventName() = _{{name.pascalCase()}}EventEventName;
}
