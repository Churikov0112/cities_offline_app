import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/countries/presentation/bloc/countries_bloc.dart';
import 'package:cities_offline_app/services/localization/country_names.dart';
import 'package:cities_offline_app/services/localization/dictionary.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:flutter/material.dart';

class CountryPickerSheet extends StatefulWidget {
  final Set<String> selectedCodes;
  final ValueChanged<Set<String>> onChanged;

  const CountryPickerSheet({
    required this.selectedCodes,
    required this.onChanged,
    super.key,
  });

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<(String code, String name)> _allCountries = [];
  List<(String code, String name)> _filtered = [];
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedCodes);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = getIt<CountriesBloc>();
    if (bloc.state.status == CountriesStatus.loaded && _allCountries.isEmpty) {
      _allCountries = List.from(bloc.state.countries);
      _allCountries.sort((a, b) {
        final aName = countryNames[a.$1]?[Languages.english] ?? a.$2;
        final bName = countryNames[b.$1]?[Languages.english] ?? b.$2;
        return aName.compareTo(bName);
      });
      _filtered = List.from(_allCountries);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(_allCountries);
      } else {
        final q = query.toLowerCase();
        final currentLang = getIt<LanguageBloc>().state.language;
        _filtered = _allCountries.where((c) {
          final translated = countryNames[c.$1]?[currentLang] ?? c.$2;
          return translated.toLowerCase().contains(q) || c.$1.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).canvasColor,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                AppGlossary.countries.translate(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppGlossary.searchLanguage.translate(),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _allCountries.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final c = _filtered[index];
                        final currentLang = getIt<LanguageBloc>().state.language;
                        final translated = countryNames[c.$1]?[currentLang] ?? c.$2;
                        return CheckboxListTile(
                          value: _selected.contains(c.$1),
                          title: Text(translated),
                          subtitle: Text(c.$1, style: Theme.of(context).textTheme.bodySmall),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selected.add(c.$1);
                              } else {
                                _selected.remove(c.$1);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    widget.onChanged(_selected);
                    Navigator.of(context).pop();
                  },
                  child: Translator(
                    termin: AppGlossary.save,
                    builder: (text) => Text(text),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
