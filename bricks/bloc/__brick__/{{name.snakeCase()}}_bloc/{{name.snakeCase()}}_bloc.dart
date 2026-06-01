import 'package:bloc/bloc.dart';
import 'package:graphql/client.dart';
import 'package:injectable/injectable.dart';

part '{{name.snakeCase()}}_bloc_event.dart';
part '{{name.snakeCase()}}_bloc_state.dart';

@singleton
class {{name.pascalCase()}}Bloc extends Bloc<{{name.pascalCase()}}Event, {{name.pascalCase()}}State> {
  {{name.pascalCase()}}Bloc() : super({{name.pascalCase()}}StateInitial()) {
    on<{{name.pascalCase()}}Event>(
      (event, emitter) => switch(event) {
         {{name.pascalCase()}}EventName() => _eventName(event, emitter),
      },
    );
  }

  Future<void> _eventName(
    {{name.pascalCase()}}EventName event,
    Emitter<{{name.pascalCase()}}State> emit,
  ) async {
      try {
      emit({{name.pascalCase()}}StatePending());
    
      emit({{name.pascalCase()}}StateLoadSucceeded([]));
    } on OperationException catch (exception) {
      emit({{name.pascalCase()}}StateFailed(exception.graphqlErrors.firstOrNull?.extensions?["message"] ?? exception.graphqlErrors.firstOrNull?.message ?? "Произошла ошибка"));
    } on Object catch (_) {
      emit({{name.pascalCase()}}StateFailed('Произошла ошибка'));
    }
  }
}


