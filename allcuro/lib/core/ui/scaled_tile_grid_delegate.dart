import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Fixed-column grid whose tiles keep the design's [childAspectRatio], but
/// grow tall enough for [minTileHeight] when the phone uses a large system
/// font or a narrow width — so icon + label tiles never overflow.
///
/// Use [labelTileHeight] to compute [minTileHeight] from the text scaler.
class ScaledTileGridDelegate extends SliverGridDelegate {
  const ScaledTileGridDelegate({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.minTileHeight,
    this.crossAxisSpacing = 0,
    this.mainAxisSpacing = 0,
  });

  final int crossAxisCount;
  final double childAspectRatio;
  final double minTileHeight;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final usable = constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final tileWidth = usable / crossAxisCount;
    final extent = math.max(tileWidth / childAspectRatio, minTileHeight);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      mainAxisExtent: extent,
    ).getLayout(constraints);
  }

  @override
  bool shouldRelayout(ScaledTileGridDelegate oldDelegate) =>
      oldDelegate.crossAxisCount != crossAxisCount ||
      oldDelegate.childAspectRatio != childAspectRatio ||
      oldDelegate.minTileHeight != minTileHeight ||
      oldDelegate.crossAxisSpacing != crossAxisSpacing ||
      oldDelegate.mainAxisSpacing != mainAxisSpacing;
}

/// Height of a tile made of a fixed-size part ([fixedHeight]: icon, gaps,
/// padding) plus [maxLines] lines of text at [fontSize] / [lineHeight],
/// scaled by the ambient system text scaler.
double labelTileHeight(
  BuildContext context, {
  required double fixedHeight,
  required double fontSize,
  required double lineHeight,
  int maxLines = 2,
}) {
  final scaled = MediaQuery.textScalerOf(context).scale(fontSize);
  // +2 absorbs sub-pixel rounding of the text layout.
  return fixedHeight + scaled * lineHeight * maxLines + 2;
}
