import 'package:flutter_project_template/src/core/framework/data_delivery/graphql/graphql.dart';

final {{name.camelCase()}}{{type}} = GqlQuery(
  innerFragments: [sessionFragment],
  body: '''
{{type.lowerCase()}} {{name.pascalCase()}}(\$email: String!,\$confirmationCode: String!) {
  {{name.camelCase()}}(email: \$email, confirmationCode: \$confirmationCode) {
  ...${sessionFragment.id}
  }
}
''',
);
