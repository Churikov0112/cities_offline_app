import 'package:flutter_project_template/src/features/auth/domain/models/session/session.dart';

import '../../../../graphql/graphql_api.dart' as gql;
import 'user_model_serializer.dart';

extension SessionModelSerializer on SessionModel {
  static SessionModel fromGql(gql.SessionFragmentMixin source) {
    return SessionModel(
      token: source.token,
      refreshToken: source.refreshToken,
      user: UserModelSerializer.fromGql(source.user),
    );
  }
}
