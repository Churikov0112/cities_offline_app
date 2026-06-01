import '../../../../core/framework/data_delivery/graphql/gql_variables.dart';

class {{name.pascalCase()}}GQLVariables extends GQLVariables {
  final String email;
  final String password;

  {{name.pascalCase()}}GQLVariables({
    required this.email,
    required this.password,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "password": password,
    };
  }
}
