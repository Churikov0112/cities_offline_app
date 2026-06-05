import 'package:cities_offline_app/features/languages/domain/models/available_language.dart';
import 'package:flutter/material.dart';

class LanguagePickerSheet extends StatefulWidget {
  final List<AvailableLanguage> languages;
  final ValueChanged<String?> onSelected;
  final String? selectedCode;

  const LanguagePickerSheet({
    required this.languages,
    required this.onSelected,
    super.key,
    this.selectedCode,
  });

  @override
  State<LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<LanguagePickerSheet> {
  late final TextEditingController _searchController;
  late List<AvailableLanguage> _filteredLanguages;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredLanguages = widget.languages;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredLanguages = query.isEmpty
          ? widget.languages
          : widget.languages
                .where(
                  (l) =>
                      l.nativeName.toLowerCase().contains(query.toLowerCase()) ||
                      l.code.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
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
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Поиск языка',
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredLanguages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      selected: widget.selectedCode == null,
                      title: const Text('Авто (по вводу)'),
                      onTap: () => widget.onSelected(null),
                    );
                  }
                  final lang = _filteredLanguages[index - 1];
                  return ListTile(
                    selected: widget.selectedCode == lang.code,
                    title: Text('${lang.nativeName} (${lang.code})'),
                    onTap: () => widget.onSelected(lang.code),
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
