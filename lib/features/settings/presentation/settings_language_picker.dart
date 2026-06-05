import 'package:cities_offline_app/services/localization/dictionary.dart';
import 'package:flutter/material.dart';

const _languageNames = <Languages, String>{
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

const _languageFlags = <Languages, String>{
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

class SettingsLanguagePickerSheet extends StatefulWidget {
  final Languages current;
  final ValueChanged<Languages> onSelected;

  const SettingsLanguagePickerSheet({
    required this.current,
    required this.onSelected,
    super.key,
  });

  @override
  State<SettingsLanguagePickerSheet> createState() => _SettingsLanguagePickerSheetState();
}

class _SettingsLanguagePickerSheetState extends State<SettingsLanguagePickerSheet> {
  late final TextEditingController _searchController;
  late List<Languages> _filtered;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = Languages.values.toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = Languages.values.toList();
      } else {
        final q = query.toLowerCase();
        _filtered = Languages.values.where((l) {
          final native = _languageNames[l]!.toLowerCase();
          final code = l.code.toLowerCase();
          return native.contains(q) || code.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search language',
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final lang = _filtered[index];
                  final isSelected = lang == widget.current;
                  return ListTile(
                    selected: isSelected,
                    leading: Text(_languageFlags[lang]!, style: const TextStyle(fontSize: 24)),
                    title: Text(_languageNames[lang]!),
                    trailing: isSelected ? const Icon(Icons.check) : null,
                    onTap: () {
                      widget.onSelected(lang);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
