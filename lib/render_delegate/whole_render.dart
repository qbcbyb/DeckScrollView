import 'dart:math' as math;

import 'package:deck_scrollview/deck_render.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class RenderWholeDelegate extends DeckRenderDelegate {
  static const int maxVisibleItemCount = 8;
  static const double firstItemOffsetIndex = 7;
  static const double itemScaleMin = .95;

  RenderWholeDelegate(RenderDeckViewport viewport) : super(viewport);

  double get virtualItemExtent =>
      (viewport.size?.height ?? 0) / maxVisibleItemCount;

  @override
  int scrollOffsetToIndex(double scrollOffset) =>
      ((virtualItemExtent == 0 ? 0 : (scrollOffset / virtualItemExtent)) -
              firstItemOffsetIndex)
          .floor();

  @override
  double indexToRealScrollOffset(int index) => (index) * virtualItemExtent;
  @override
  double indexToScrollOffset(int index) =>
      (index + firstItemOffsetIndex) * virtualItemExtent;

  @override
  double get minEstimatedScrollExtent {
    assert(viewport.hasSize);
    if (viewport.childManager.childCount == null)
      return double.negativeInfinity;
    return 0.0;
  }

  @override
  double get maxEstimatedScrollExtent {
    assert(viewport.hasSize);
    if (viewport.childManager.childCount == null) return double.infinity;

    return math.max(
        0.0,
        (viewport.childManager.childCount + firstItemOffsetIndex) *
            virtualItemExtent);
  }

  @override
  Matrix4 getMatrixByUntransformedPaintingY(double paintingY,
      double visibleWidth, double visibleHeight, double parentHeight) {
    double fractionalY = paintingY / visibleHeight;
    if (fractionalY > 1) {
      fractionalY = 1;
    }
    if (fractionalY < 0.0) {
      fractionalY = 0.0;
    }
    var scale = (itemScaleMin + (1 - itemScaleMin) * fractionalY);
    return Matrix4.translationValues(visibleWidth / 2 * (1 - scale),
        math.pow(fractionalY, viewport.layoutPow).toDouble() * visibleHeight, 1)
      ..scale(scale, scale);
  }
}
