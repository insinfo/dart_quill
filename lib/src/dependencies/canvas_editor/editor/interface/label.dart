import './common.dart';

class ILabelStyle {
  String? color;
  String? backgroundColor;
  num? borderRadius;
  IPadding? padding;

  ILabelStyle({
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
  });
}

class ILabelOption {
  String? defaultColor;
  String? defaultBackgroundColor;
  num? defaultBorderRadius;
  IPadding? defaultPadding;

  ILabelOption({
    this.defaultColor,
    this.defaultBackgroundColor,
    this.defaultBorderRadius,
    this.defaultPadding,
  });
}