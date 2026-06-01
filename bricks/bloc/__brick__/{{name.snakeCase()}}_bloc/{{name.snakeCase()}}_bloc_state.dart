part of '{{name.snakeCase()}}_bloc.dart';

sealed class {{name.pascalCase()}}State {

  List<String>? get result {
    return switch (this) {
      {{name.pascalCase()}}StateLoadSucceeded() => (this as  {{name.pascalCase()}}StateLoadSucceeded)._result,
      _ => null,
    };
  }
}

final class {{name.pascalCase()}}StateInitial extends {{name.pascalCase()}}State {
  {{name.pascalCase()}}StateInitial();
}

final class {{name.pascalCase()}}StatePending extends {{name.pascalCase()}}State {
  {{name.pascalCase()}}StatePending();
}

final class {{name.pascalCase()}}StateLoadSucceeded extends {{name.pascalCase()}}State {
  final List<String> _result;
  {{name.pascalCase()}}StateLoadSucceeded(this._result);
}

final class {{name.pascalCase()}}StateFailed extends {{name.pascalCase()}}State {
  final String reason;
  {{name.pascalCase()}}StateFailed(this.reason);
}


