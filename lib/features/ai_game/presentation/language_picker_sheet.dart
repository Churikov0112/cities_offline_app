import 'package:cities_offline_app/features/languages/domain/models/available_language.dart';
import 'package:cities_offline_app/services/localization/language_utils.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:flutter/material.dart';

class LanguagePickerSheet extends StatefulWidget {
  final List<AvailableLanguage> languages;
  final ValueChanged<String?> onSelected;
  final String? selectedCode;
  final bool showAutoOption;
  final bool grouped;

  const LanguagePickerSheet({
    required this.languages,
    required this.onSelected,
    super.key,
    this.selectedCode,
    this.showAutoOption = true,
    this.grouped = false,
  });

  @override
  State<LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<LanguagePickerSheet> {
  late final TextEditingController _searchController;
  late List<AvailableLanguage> _filteredLanguages;
  late List<_GroupItem> _groupedItems;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredLanguages = widget.languages;
    _rebuildGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _rebuildGroups() {
    _groupedItems = _buildGroupItems(_filteredLanguages);
  }

  List<_GroupItem> _buildGroupItems(List<AvailableLanguage> langs) {
    if (!widget.grouped) {
      return langs.map((l) => _GroupItem(l.code, l.nativeName, false)).toList();
    }

    final result = <_GroupItem>[];
    final codeNames = {for (final l in langs) l.code: l.nativeName};

    // group by parent
    final groups = <String, List<String>>{};
    final added = <String>{};
    for (final l in langs) {
      final parent = parentLanguageCode(l.code);
      groups.putIfAbsent(parent, () => []);
      if (l.code != parent) {
        groups[parent]!.add(l.code);
      }
      added.add(l.code);
    }
    for (final l in langs) {
      if (!groups.containsKey(l.code)) {
        groups[l.code] = [];
      }
    }

    final sortedGroups = groups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sortedGroups) {
      final parentName = codeNames[entry.key] ?? entry.key;
      result.add(_GroupItem(entry.key, parentName, false));
      final variants = entry.value..sort();
      for (final v in variants) {
        result.add(_GroupItem(v, codeNames[v] ?? v, true));
      }
    }

    return result;
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
      _rebuildGroups();
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
                decoration: InputDecoration(
                  hintText: AppGlossary.searchLanguage.translate(),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _groupedItems.length + (widget.showAutoOption ? 1 : 0),
                itemBuilder: (context, index) {
                  if (widget.showAutoOption && index == 0) {
                    return ListTile(
                      selected: widget.selectedCode == null,
                      title: Translator(
                        termin: AppGlossary.auto,
                        builder: (text) => Text(text),
                      ),
                      onTap: () => widget.onSelected(null),
                    );
                  }
                  final itemIndex = index - (widget.showAutoOption ? 1 : 0);
                  final item = _groupedItems[itemIndex];
                  final parent = parentLanguageCode(item.code);
                  return ListTile(
                    selected: widget.selectedCode == parent,
                    contentPadding: EdgeInsets.lerp(
                      const EdgeInsets.symmetric(horizontal: 16),
                      const EdgeInsets.only(left: 48, right: 16),
                      item.isVariant ? 1.0 : 0.0,
                    )!,
                    title: Text(
                      item.isVariant
                          ? '${item.name} (${item.code})'
                          : item.name,
                    ),
                    onTap: () => widget.onSelected(parent),
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

class _GroupItem {
  final String code;
  final String name;
  final bool isVariant;

  const _GroupItem(this.code, this.name, this.isVariant);
}
