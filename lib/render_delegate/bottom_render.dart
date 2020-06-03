import 'dart:math' as math;

import 'package:deck_scrollview/deck_render.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class RenderBottomDelegate extends DeckRenderDelegate {
  static const double deckOffsetRange = 30;
  static const int maxVisibleCountInDeckRange = 4;
  static const double itemScaleMin = .95;

  RenderBottomDelegate(RenderDeckViewport viewport) : super(viewport);

  @override
  bool get reversePaint => true;

  @override
  int scrollOffsetToIndex(double scrollOffset) =>
      ((viewport.itemExtent == 0 ? 0 : ((scrollOffset) / viewport.itemExtent)))
          .floor();

  @override
  double indexToRealScrollOffset(int index) => (index) * viewport.itemExtent;
  @override
  double indexToScrollOffset(int index) => index * viewport.itemExtent;

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
        (viewport.childManager.childCount + maxVisibleCountInDeckRange) *
                viewport.itemExtent +
            (viewport.size?.height ?? 0));
  }

  double computedViewportHeight(double parentHeight) =>
      parentHeight + viewport.itemExtent * maxVisibleCountInDeckRange;

  @override
  Matrix4 getMatrixByUntransformedPaintingY(double paintingY,
      double visibleWidth, double visibleHeight, double parentHeight) {
    if ((paintingY + viewport.itemExtent + deckOffsetRange) > visibleHeight) {
      var fractionalYInDeckRange = 1 -
          ((paintingY + viewport.itemExtent) - visibleHeight) /
              (maxVisibleCountInDeckRange * viewport.itemExtent);
      var scale = (itemScaleMin + (1 - itemScaleMin) * fractionalYInDeckRange);
      return Matrix4.translationValues(
          visibleWidth / 2 * (1 - scale),
          parentHeight -
              viewport.itemExtent * scale -
              math
                      .pow(fractionalYInDeckRange.clamp(0, 1),
                          viewport.layoutPow)
                      .toDouble() *
                  deckOffsetRange,
          1)
        ..scale(scale, scale);
    }
    return Matrix4.translationValues(
        0,
        ((paintingY) / (parentHeight)).clamp(-1, 1).toDouble() * parentHeight,
        1);
  }
}
