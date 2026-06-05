import 'package:flutter/widgets.dart';

/// Переменная нужна, чтобы рассчитывать размер маркера относительно разрешения экрана смартфона.
/// Применяется как для Maplibre, так и для FwdMap
double _kDPI = 1;

const double _kMarkerIconScale = 0.91;
const double _kSelectedMarkerIconScale = 1.2;

double iconSize = _kMarkerIconScale / _kDPI;
double iconSizeBig = _kSelectedMarkerIconScale / _kDPI;

/// Вычисляет значение переменной _kDPI, использующейся, чтобы задавать размеры маркера
void calcDPI(BuildContext context) {
  final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
  _kDPI = 2.0 / devicePixelRatio;
  iconSize = _kMarkerIconScale / _kDPI;
  iconSizeBig = _kSelectedMarkerIconScale / _kDPI;
}
