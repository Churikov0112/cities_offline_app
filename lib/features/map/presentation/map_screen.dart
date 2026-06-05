import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'utils/dpi.dart';

/// Бесплатные tile-серверы для MapLibre (векторные тайлы):
///
/// 1. CarTO Positron (светлая) — https://basemaps.cartocdn.com/gl/positron-gl-style/style.json
/// 2. CarTO Dark Matter (тёмная) — https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json
/// 3. CarTO Voyager (цветная) — https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json
/// 4. MapLibre Demo Tiles — https://demotiles.maplibre.org/style.json
/// 5. OpenFreeMap — https://tiles.openfreemap.org/styles/liberty
/// 6. Protomaps — https://api.protomaps.com/tiles/v3/light.json?key=YOUR_KEY (требуется ключ)

class MapScreen extends StatefulWidget {
  final double lat;
  final double lon;
  final String cityName;

  const MapScreen({
    required this.lat,
    required this.lon,
    required this.cityName,
    super.key,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _styleUrl = 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';
  MapLibreMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      calcDPI(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.cityName)),
      body: MapLibreMap(
        styleString: _styleUrl,
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.lat, widget.lon),
          zoom: 4,
        ),
        onMapCreated: (controller) async {
          _mapController = controller;
        },
        onStyleLoadedCallback: () async {
          final markerPng = await _buildMarkerImage();
          await _mapController?.addImage('location', markerPng);
          await _mapController?.addSymbol(
            SymbolOptions(
              geometry: LatLng(widget.lat, widget.lon),
              iconImage: 'location',
              iconSize: iconSizeBig,
              iconAnchor: "bottom",
            ),
          );
        },
      ),
    );
  }

  Future<Uint8List> _buildMarkerImage() async {
    final bytes = await rootBundle.load('assets/raster/location.png');
    return bytes.buffer.asUint8List();
  }
}
