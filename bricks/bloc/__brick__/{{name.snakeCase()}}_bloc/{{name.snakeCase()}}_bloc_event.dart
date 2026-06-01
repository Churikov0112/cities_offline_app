part of '{{name.snakeCase()}}_bloc.dart';

sealed class {{name.pascalCase()}}Event {}

final class {{name.pascalCase()}}EventName extends {{name.pascalCase()}}Event {
  {{name.pascalCase()}}EventName();
}
