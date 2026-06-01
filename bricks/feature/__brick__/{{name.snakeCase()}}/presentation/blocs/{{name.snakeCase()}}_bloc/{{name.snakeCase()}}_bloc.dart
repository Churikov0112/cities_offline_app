import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part '{{name.snakeCase()}}_bloc.freezed.dart';
part '{{name.snakeCase()}}_bloc_event.dart';
part '{{name.snakeCase()}}_bloc_state.dart';

@singleton
class {{name.pascalCase()}}Bloc extends Bloc<{{name.pascalCase()}}Event, {{name.pascalCase()}}State> {
  {{name.pascalCase()}}Bloc() : super(const {{name.pascalCase()}}State.initial()) {
    on<{{name.pascalCase()}}Event>(
      (event, emitter) => event.map(
          eventName: (event) => _eventName(event, emitter),
      ),
    );
  }

  Future<void> _eventName(
    _{{name.pascalCase()}}EventEventName event,
    Emitter<{{name.pascalCase()}}State> emit,
  ) async {
    emit(const {{name.pascalCase()}}State.initial());
  }
}
