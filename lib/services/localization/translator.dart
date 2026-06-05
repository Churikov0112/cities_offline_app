import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../di/di.dart';
import 'dictionary.dart';
import 'language_bloc/language_bloc.dart';

export 'dictionary.dart';
export 'language_bloc/language_bloc.dart';

class Translator extends StatelessWidget {
  final AppGlossary termin;
  final Widget Function(String value) builder;

  const Translator({required this.termin, required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      bloc: getIt.get(),
      builder: (context, state) {
        final word = dictionary[termin]![state.language]!;

        return builder(word);
      },
    );
  }
}

extension AppGlossaryExtension on AppGlossary {
  String translate() {
    final bloc = getIt.get<LanguageBloc>();
    return dictionary[this]![bloc.state.language]!;
  }
}

String translateCityType(String cityType) {
  switch (cityType) {
    case 'city':
      return AppGlossary.city.translate();
    case 'town':
      return AppGlossary.town.translate();
    case 'village':
      return AppGlossary.village.translate();
    case 'hamlet':
      return AppGlossary.hamlet.translate();
    default:
      return cityType;
  }
}

String translateDifficultyPreset(String name) {
  return switch (name) {
    'easy' => AppGlossary.easy.translate(),
    'medium' => AppGlossary.medium.translate(),
    'hard' => AppGlossary.hard.translate(),
    'custom' => AppGlossary.custom.translate(),
    _ => name,
  };
}
