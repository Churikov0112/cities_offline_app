import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:cities_offline_app/services/navigation/bottom_sheet_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_language_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Translator(
          termin: AppGlossary.settings,
          builder: (text) => Text(text),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Translator(
            termin: AppGlossary.language,
            builder: (text) => Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          BlocBuilder<LanguageBloc, LanguageState>(
            bloc: getIt(),
            builder: (context, state) {
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                leading: Text(_flagFor(state.language), style: const TextStyle(fontSize: 24)),
                title: Text(_nativeNameFor(state.language)),
                trailing: const Icon(Icons.keyboard_arrow_down),
                onTap: () {
                  BottomSheetController.showBottomSheet(
                    context,
                    (_) => SettingsLanguagePickerSheet(
                      current: state.language,
                      onSelected: (lang) {
                        getIt<LanguageBloc>().add(LanguageBlocEventSet(language: lang));
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

const _nativeNames = <Languages, String>{
  Languages.english: 'English',
  Languages.russian: 'Русский',
  Languages.spanish: 'Español',
  Languages.portuguese: 'Português',
  Languages.turkish: 'Türkçe',
  Languages.french: 'Français',
  Languages.chinese: '中文',
  Languages.arabic: 'العربية',
  Languages.japanese: '日本語',
  Languages.hindi: 'हिन्दी',
  Languages.bengal: 'বাংলা',
  Languages.german: 'Deutsch',
  Languages.korean: '한국어',
  Languages.italian: 'Italiano',
  Languages.vietnamese: 'Tiếng Việt',
};

const _flags = <Languages, String>{
  Languages.english: '\u{1F1EC}\u{1F1E7}',
  Languages.russian: '\u{1F1F7}\u{1F1FA}',
  Languages.spanish: '\u{1F1EA}\u{1F1F8}',
  Languages.portuguese: '\u{1F1F5}\u{1F1F9}',
  Languages.turkish: '\u{1F1F9}\u{1F1F7}',
  Languages.french: '\u{1F1EB}\u{1F1F7}',
  Languages.chinese: '\u{1F1E8}\u{1F1F3}',
  Languages.arabic: '\u{1F1F8}\u{1F1E6}',
  Languages.japanese: '\u{1F1EF}\u{1F1F5}',
  Languages.hindi: '\u{1F1EE}\u{1F1F3}',
  Languages.bengal: '\u{1F1E7}\u{1F1E9}',
  Languages.german: '\u{1F1E9}\u{1F1EA}',
  Languages.korean: '\u{1F1F0}\u{1F1F7}',
  Languages.italian: '\u{1F1EE}\u{1F1F9}',
  Languages.vietnamese: '\u{1F1FB}\u{1F1F3}',
};

String _nativeNameFor(Languages lang) => _nativeNames[lang]!;
String _flagFor(Languages lang) => _flags[lang]!;
