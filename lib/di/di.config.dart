// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../features/ai_game/domain/services/ai_move_service.dart' as _i30;
import '../features/ai_game/presentation/bloc/ai_game_bloc.dart' as _i320;
import '../features/countries/presentation/bloc/countries_bloc.dart' as _i311;
import '../features/game/domain/services/hint_service.dart' as _i551;
import '../features/game/domain/services/turn_validator.dart' as _i770;
import '../features/game/presentation/bloc/game_bloc.dart' as _i744;
import '../features/languages/presentation/bloc/languages_bloc.dart' as _i664;
import '../features/mediator/domain/repos/cities_repository.dart' as _i34;
import '../features/mediator/domain/services/villages_db_service.dart' as _i674;
import '../features/mediator/presentation/bloc/mediator_bloc.dart' as _i661;
import '../features/villages/presentation/bloc/villages_cubit.dart' as _i523;
import '../services/localization/language_bloc/language_bloc.dart' as _i381;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  gh.singleton<_i674.VillagesDbService>(() => _i674.VillagesDbService());
  gh.singleton<_i523.VillagesCubit>(() => _i523.VillagesCubit());
  gh.singleton<_i381.LanguageBloc>(() => _i381.LanguageBloc());
  gh.singleton<_i34.CitiesRepository>(
    () =>
        _i34.CitiesRepository(villagesDbService: gh<_i674.VillagesDbService>()),
    dispose: (i) => i.closeVillagesDatabase(),
  );
  gh.singleton<_i30.AiMoveService>(
    () => _i30.AiMoveService(citiesRepository: gh<_i34.CitiesRepository>()),
  );
  gh.singleton<_i311.CountriesBloc>(
    () => _i311.CountriesBloc(citiesRepository: gh<_i34.CitiesRepository>()),
  );
  gh.singleton<_i551.HintService>(
    () => _i551.HintService(citiesRepository: gh<_i34.CitiesRepository>()),
  );
  gh.singleton<_i770.TurnValidator>(
    () => _i770.TurnValidator(citiesRepository: gh<_i34.CitiesRepository>()),
  );
  gh.singleton<_i664.LanguagesBloc>(
    () => _i664.LanguagesBloc(citiesRepository: gh<_i34.CitiesRepository>()),
  );
  gh.singleton<_i661.MediatorBloc>(
    () => _i661.MediatorBloc(citiesRepository: gh<_i34.CitiesRepository>()),
  );
  gh.singleton<_i320.AiGameBloc>(
    () => _i320.AiGameBloc(
      citiesRepository: gh<_i34.CitiesRepository>(),
      aiMoveService: gh<_i30.AiMoveService>(),
    ),
  );
  gh.singleton<_i744.GameBloc>(
    () => _i744.GameBloc(
      turnValidator: gh<_i770.TurnValidator>(),
      hintService: gh<_i551.HintService>(),
      aiMoveService: gh<_i30.AiMoveService>(),
    ),
  );
  return getIt;
}
