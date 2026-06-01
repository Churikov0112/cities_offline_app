import 'package:flutter_project_template/src/data_delivery/clients/artemis/artemis_client.dart';
import 'package:flutter_project_template/src/features/auth/domain/models/session/session.dart';

import '../../../../graphql/graphql_api.dart' as gql;
import '../serializers/session_model_serializer.dart';

class BackendQueryArguments {
  final String email;
  final String password;

  const BackendQueryArguments({
    required this.email,
    required this.password,
  });
}

class BackendQuery {
  Future<SessionModel> resolve({
    required ArtemisBackendDataClient client,
    required BackendQueryArguments arguments,
  }) async {
    final payload = await client.commonClient.execute(
      gql.SessionCreateMutation(
        variables: gql.SessionCreateArguments(
          email: '',
          password: '',
        ),
      ),
    );

    return SessionModelSerializer.fromGql(payload.data!.sessionCreate!);
  }
}
