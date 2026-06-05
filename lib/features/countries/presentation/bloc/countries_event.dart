part of 'countries_bloc.dart';

sealed class CountriesEvent {
  const CountriesEvent();
}

class CountriesLoadRequested extends CountriesEvent {
  const CountriesLoadRequested();
}
