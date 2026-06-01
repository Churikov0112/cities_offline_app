import 'package:injectable/injectable.dart';
import 'package:flutter_project_template/src/data_delivery/clients/artemis/artemis_client.dart';

import '../../domain/repositories/{{name.snakeCase()}}_repository_interface/{{name.snakeCase()}}_repository_interface.dart';
import '../queries/{{name.snakeCase()}}_backend_query.dart';


@Singleton(as: {{name.pascalCase()}}RepositoryInterface)
class {{name.pascalCase()}}RepositoryImpl extends {{name.pascalCase()}}RepositoryInterface {
  final ArtemisBackendDataClient _client;

   {{name.pascalCase()}}RepositoryImpl(this._client);

  @override
  Future<void> foo() async {
    final query = BackendQuery();
    final result = await query.resolve(
      client: _client,
      arguments: BackendQueryArguments(
        email: '',
        password: '',
      ),
    );
  }
}
