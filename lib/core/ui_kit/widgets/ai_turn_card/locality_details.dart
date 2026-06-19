import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/services/localization/country_names.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:cities_offline_app/services/navigation/navigation.dart';
import 'package:cities_offline_app/features/mediator/domain/models/locality.dart';

class LocalityDetails extends StatelessWidget {
  final Locality locality;

  const LocalityDetails({super.key, required this.locality});

  @override
  Widget build(BuildContext context) {
    final currentLang = getIt<LanguageBloc>().state.language;
    final countryName = countryNames[locality.countryCode.toLowerCase()]?[currentLang] ?? locality.country;
    final details = <Widget>[
      if (locality.population != null)
        _detailRow(AppGlossary.population.translate(), NumberFormat('#,##0', 'de').format(locality.population)),
      _detailRow(AppGlossary.type.translate(), translateCityType(locality.cityType)),
      _detailRow(AppGlossary.country.translate(), countryName),
      if (locality.lat != null && locality.lon != null)
        _detailRow(AppGlossary.coordinates.translate(), '${locality.lat!.toStringAsFixed(4)}, ${locality.lon!.toStringAsFixed(4)}'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...details,
          if (locality.lat != null && locality.lon != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.pushNamed(
                    RoutePaths.map.name,
                    queryParameters: {
                      'lat': locality.lat.toString(),
                      'lon': locality.lon.toString(),
                      'name': locality.matchedName,
                    },
                  );
                },
                icon: const Icon(Icons.map, size: 16),
                label: Translator(
                  termin: AppGlossary.onMap,
                  builder: (text) => Text(text, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }
}
