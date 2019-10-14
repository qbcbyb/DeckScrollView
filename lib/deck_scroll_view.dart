// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:collection';

import 'package:deck_scrollview/deck_viewport.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter/widgets.dart';

/// A delegate that supplies children for [DeckScrollView].
///
/// [DeckScrollView] lazily constructs its children during layout to avoid
/// creating more children than are visible through the [Viewport]. This
/// delegate is responsible for providing children to [DeckScrollView]
/// during that stage.
///
/// See also:
///
///  * [DeckChildListDelegate], a delegate that supplies children using an
///    explicit list.
///  * [DeckChildLoopingListDelegate], a delegate that supplies infinite
///    children by looping an explicit list.
///  * [DeckChildBuilderDelegate], a delegate that supplies children using
///    a builder callback.
abstract class DeckChildDelegate {
  /// Return the child at the given index. If the child at the given
  /// index does not exist, return null.
  Widget build(BuildContext context, int index);

  /// Returns an estimate of the number of children this delegate will build.
  int get estimatedChildCount;

  /// Returns the true index for a child built at a given index. Defaults to
  /// the given index, however if the delegate is [DeckChildLoopingListDelegate],
  /// this value is the index of the true element that the delegate is looping to.
  ///
  ///
  /// Example: [DeckChildLoopingListDelegate] is built by looping a list of
  /// length 8. Then, trueIndexOf(10) = 2 and trueIndexOf(-5) = 3.
  int trueIndexOf(int index) => index;

  /// Called to check whether this and the old delegate are actually 'different',
  /// so that the caller can decide to rebuild or not.
  bool shouldRebuild(covariant DeckChildDelegate oldDelegate);
}

/// A delegate that supplies children for [DeckScrollView] using an
/// explicit list.
///
/// [DeckScrollView] lazily constructs its children to avoid creating more
/// children than are visible through the [Viewport]. This delegate provides
/// children using an explicit list, which is convenient but reduces the benefit
/// of building children lazily.
///
/// In general building all the widgets in advance is not efficient. It is
/// better to create a delegate that builds them on demand using
/// [DeckChildBuilderDelegate] or by subclassing [DeckChildDelegate]
/// directly.
///
/// This class is provided for the cases where either the list of children is
/// known well in advance (ideally the children are themselves compile-time
/// constants, for example), and therefore will not be built each time the
/// delegate itself is created, or the list is small, such that it's likely
/// always visible (and thus there is nothing to be gained by building it on
/// demand). For example, the body of a dialog box might fit both of these
/// conditions.
class DeckChildListDelegate extends DeckChildDelegate {
  /// Constructs the delegate from a concrete list of children.
  DeckChildListDelegate({@required this.children}) : assert(children != null);

  /// The list containing all children that can be supplied.
  final List<Widget> children;

  @override
  int get estimatedChildCount => children.length;

  @override
  Widget build(BuildContext context, int index) {
    if (index < 0 || index >= children.length) return null;
    return IndexedSemantics(child: children[index], index: index);
  }

  @override
  bool shouldRebuild(covariant DeckChildListDelegate oldDelegate) {
    return children != oldDelegate.children;
  }
}

/// A delegate that supplies infinite children for [DeckScrollView] by
/// looping an explicit list.
///
/// [DeckScrollView] lazily constructs its children to avoid creating more
/// children than are visible through the [Viewport]. This delegate provides
/// children using an explicit list, which is convenient but reduces the benefit
/// of building children lazily.
///
/// In general building all the widgets in advance is not efficient. It is
/// better to create a delegate that builds them on demand using
/// [DeckChildBuilderDelegate] or by subclassing [DeckChildDelegate]
/// directly.
///
/// This class is provided for the cases where either the list of children is
/// known well in advance (ideally the children are themselves compile-time
/// constants, for example), and therefore will not be built each time the
/// delegate itself is created, or the list is small, such that it's likely
/// always visible (and thus there is nothing to be gained by building it on
/// demand). For example, the body of a dialog box might fit both of these
/// conditions.
class DeckChildLoopingListDelegate extends DeckChildDelegate {
  /// Constructs the delegate from a concrete list of children.
  DeckChildLoopingListDelegate({@required this.children}) : assert(children != null);

  /// The list containing all children that can be supplied.
  final List<Widget> children;

  @override
  int get estimatedChildCount => null;

  @override
  int trueIndexOf(int index) => index % children.length;

  @override
  Widget build(BuildContext context, int index) {
    if (children.isEmpty) return null;
    return IndexedSemantics(child: children[index % children.length], index: index);
  }

  @override
  bool shouldRebuild(covariant DeckChildLoopingListDelegate oldDelegate) {
    return children != oldDelegate.children;
  }
}

/// A delegate that supplies children for [DeckScrollView] using a builder
/// callback.
///
/// [DeckScrollView] lazily constructs its children to avoid creating more
/// children than are visible through the [Viewport]. This delegate provides
/// children using an [IndexedWidgetBuilder] callback, so that the children do
/// not have to be built until they are displayed.
class DeckChildBuilderDelegate extends DeckChildDelegate {
  /// Constructs the delegate from a builder callback.
  DeckChildBuilderDelegate({
    @required this.builder,
    this.childCount,
  }) : assert(builder != null);

  /// Called lazily to build children.
  final IndexedWidgetBuilder builder;

  /// {@template flutter.widgets.wheelList.childCount}
  /// If non-null, [childCount] is the maximum number of children that can be
  /// provided, and children are available from 0 to [childCount] - 1.
  ///
  /// If null, then the lower and upper limit are not known. However the [builder]
  /// must provide children for a contiguous segment. If the builder returns null
  /// at some index, the segment terminates there.
  /// {@endtemplate}
  final int childCount;

  @override
  int get estimatedChildCount => childCount;

  @override
  Widget build(BuildContext context, int index) {
    if (childCount == null) {
      final Widget child = builder(context, index);
      return child == null ? null : IndexedSemantics(child: child, index: index);
    }
    if (index < 0 || index >= childCount) return null;
    return IndexedSemantics(child: builder(context, index), index: index);
  }

  @override
  bool shouldRebuild(covariant DeckChildBuilderDelegate oldDelegate) {
    return builder != oldDelegate.builder || childCount != oldDelegate.childCount;
  }
}

/// A [Scrollable] which must be given its viewport children's item extent
/// size so it can pass it on ultimately to the [FixedExtentScrollController].
class _FixedExtentScrollable extends Scrollable {
  const _FixedExtentScrollable({
    Key key,
    AxisDirection axisDirection = AxisDirection.down,
    ScrollController controller,
    ScrollPhysics physics,
    @required this.itemExtent,
    @required ViewportBuilder viewportBuilder,
  }) : super(
          key: key,
          axisDirection: axisDirection,
          controller: controller,
          physics: physics,
          viewportBuilder: viewportBuilder,
        );

  final double itemExtent;

  @override
  _FixedExtentScrollableState createState() => _FixedExtentScrollableState();
}

/// This [ScrollContext] is used by [_FixedExtentScrollPosition] to read the
/// prescribed [itemExtent].
class _FixedExtentScrollableState extends ScrollableState {
  double get itemExtent {
    // Downcast because only _FixedExtentScrollable can make _FixedExtentScrollableState.
    final _FixedExtentScrollable actualWidget = widget;
    return actualWidget.itemExtent;
  }
}

/// A box in which children on a wheel can be scrolled.
///
/// This widget is similar to a [ListView] but with the restriction that all
/// children must be the same size along the scrolling axis.
///
/// When the list is at the zero scroll offset, the first child is aligned with
/// the middle of the viewport. When the list is at the final scroll offset,
/// the last child is aligned with the middle of the viewport
///
/// The children are rendered as if rotating on a wheel instead of scrolling on
/// a plane.
class DeckScrollView extends StatefulWidget {
  /// Constructs a list in which children are scrolled a wheel. Its children
  /// are passed to a delegate and lazily built during layout.
  DeckScrollView({
    Key key,
    this.controller,
    bool primary,
    this.physics,
    this.layoutPow = 4,
    @required this.itemExtent,
    @required this.virtualItemExtent,
    this.clipToSize = true,
    this.renderChildrenOutsideViewport = false,
    @required List<Widget> children,
  })  : assert(children != null),
        assert(layoutPow != null),
        assert(layoutPow > 0),
        assert(itemExtent != null),
        assert(itemExtent > 0),
        assert(virtualItemExtent != null),
        assert(virtualItemExtent > 0),
        assert(clipToSize != null),
        assert(renderChildrenOutsideViewport != null),
        assert(
          !renderChildrenOutsideViewport || !clipToSize,
          RenderDeckViewport.clipToSizeAndRenderChildrenOutsideViewportConflict,
        ),
        assert(
            !(controller != null && primary == true),
            'Primary ScrollViews obtain their ScrollController via inheritance from a PrimaryScrollController widget. '
            'You cannot both set primary to true and pass an explicit controller.'),
        primary = primary ?? controller == null,
        childDelegate = DeckChildListDelegate(children: children),
        super(key: key);

  /// Constructs a list in which children are scrolled a wheel. Its children
  /// are managed by a delegate and are lazily built during layout.
  const DeckScrollView.useDelegate({
    Key key,
    this.controller,
    bool primary,
    this.physics,
    this.layoutPow = 4,
    @required this.itemExtent,
    this.virtualItemExtent,
    this.clipToSize = true,
    this.renderChildrenOutsideViewport = false,
    @required this.childDelegate,
  })  : assert(childDelegate != null),
        assert(layoutPow != null),
        assert(layoutPow > 0),
        assert(itemExtent != null),
        assert(itemExtent > 0),
        assert(clipToSize != null),
        assert(renderChildrenOutsideViewport != null),
        assert(
          !renderChildrenOutsideViewport || !clipToSize,
          RenderDeckViewport.clipToSizeAndRenderChildrenOutsideViewportConflict,
        ),
        assert(
            !(controller != null && primary == true),
            'Primary ScrollViews obtain their ScrollController via inheritance from a PrimaryScrollController widget. '
            'You cannot both set primary to true and pass an explicit controller.'),
        primary = primary ?? controller == null,
        super(key: key);

  final bool primary;

  /// Typically a [FixedExtentScrollController] used to control the current item.
  ///
  /// A [FixedExtentScrollController] can be used to read the currently
  /// selected/centered child item and can be used to change the current item.
  ///
  /// If none is provided, a new [FixedExtentScrollController] is implicitly
  /// created.
  ///
  /// If a [ScrollController] is used instead of [FixedExtentScrollController],
  /// [ScrollNotification.metrics] will no longer provide [FixedExtentMetrics]
  final ScrollController controller;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics physics;

  final double layoutPow;

  /// Size of each child in the main axis. Must not be null and must be
  /// positive.
  final double itemExtent;
  final double virtualItemExtent;

  /// {@macro flutter.rendering.wheelList.clipToSize}
  final bool clipToSize;

  /// {@macro flutter.rendering.wheelList.renderChildrenOutsideViewport}
  final bool renderChildrenOutsideViewport;

  /// A delegate that helps lazily instantiating child.
  final DeckChildDelegate childDelegate;

  @override
  _DeckScrollViewState createState() => _DeckScrollViewState();
}

class _DeckScrollViewState extends State<DeckScrollView> {
  int _lastReportedItemIndex = 0;
  ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    // scrollController = widget.controller ?? FixedExtentScrollController();

    // if (widget.controller is FixedExtentScrollController) {
    //   final FixedExtentScrollController controller = widget.controller;
    //   _lastReportedItemIndex = controller.initialItem;
    // }
  }

  @override
  void didUpdateWidget(DeckScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != scrollController) {
      final ScrollController oldScrollController = scrollController;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        oldScrollController.dispose();
      });
      scrollController = widget.controller;
    }
  }

  @override
  Widget build(BuildContext context) {
    scrollController = widget.primary ? PrimaryScrollController.of(context) : widget.controller;
    return _FixedExtentScrollable(
      controller: scrollController,
      physics: widget.physics,
      itemExtent: widget.itemExtent,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        return DeckViewport(
          layoutPow: widget.layoutPow,
          itemExtent: widget.itemExtent,
          virtualItemExtent: widget.virtualItemExtent,
          clipToSize: widget.clipToSize,
          renderChildrenOutsideViewport: widget.renderChildrenOutsideViewport,
          offset: offset,
          childDelegate: widget.childDelegate,
        );
      },
    );
  }
}

/// Element that supports building children lazily for [DeckViewport].
class DeckElement extends RenderObjectElement implements DeckChildManager {
  /// Creates an element that lazily builds children for the given widget.
  DeckElement(DeckViewport widget) : super(widget);

  @override
  DeckViewport get widget => super.widget;

  @override
  RenderDeckViewport get renderObject => super.renderObject;

  // We inflate widgets at two different times:
  //  1. When we ourselves are told to rebuild (see performRebuild).
  //  2. When our render object needs a new child (see createChild).
  // In both cases, we cache the results of calling into our delegate to get the
  // widget, so that if we do case 2 later, we don't call the builder again.
  // Any time we do case 1, though, we reset the cache.

  /// A cache of widgets so that we don't have to rebuild every time.
  final Map<int, Widget> _childWidgets = HashMap<int, Widget>();

  /// The map containing all active child elements. SplayTreeMap is used so that
  /// we have all elements ordered and iterable by their keys.
  final SplayTreeMap<int, Element> _childElements = SplayTreeMap<int, Element>();

  @override
  void update(DeckViewport newWidget) {
    final DeckViewport oldWidget = widget;
    super.update(newWidget);
    final DeckChildDelegate newDelegate = newWidget.childDelegate;
    final DeckChildDelegate oldDelegate = oldWidget.childDelegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRebuild(oldDelegate)))
      performRebuild();
  }

  @override
  int get childCount => widget.childDelegate.estimatedChildCount;

  @override
  void performRebuild() {
    _childWidgets.clear();
    super.performRebuild();
    if (_childElements.isEmpty) return;

    final int firstIndex = _childElements.firstKey();
    final int lastIndex = _childElements.lastKey();

    for (int index = firstIndex; index <= lastIndex; ++index) {
      final Element newChild = updateChild(_childElements[index], retrieveWidget(index), index);
      if (newChild != null) {
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    }
  }

  /// Asks the underlying delegate for a widget at the given index.
  ///
  /// Normally the builder is only called once for each index and the result
  /// will be cached. However when the element is rebuilt, the cache will be
  /// cleared.
  Widget retrieveWidget(int index) {
    return _childWidgets.putIfAbsent(index, () => widget.childDelegate.build(this, index));
  }

  @override
  bool childExistsAt(int index) => retrieveWidget(index) != null;

  @override
  void createChild(int index, {@required RenderBox after}) {
    owner.buildScope(this, () {
      final bool insertFirst = after == null;
      assert(insertFirst || _childElements[index - 1] != null);
      final Element newChild = updateChild(_childElements[index], retrieveWidget(index), index);
      if (newChild != null) {
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    });
  }

  @override
  void removeChild(RenderBox child) {
    final int index = renderObject.indexOf(child);
    owner.buildScope(this, () {
      assert(_childElements.containsKey(index));
      final Element result = updateChild(_childElements[index], null, index);
      assert(result == null);
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  @override
  Element updateChild(Element child, Widget newWidget, dynamic newSlot) {
    final DeckParentData oldParentData = child?.renderObject?.parentData;
    final Element newChild = super.updateChild(child, newWidget, newSlot);
    final DeckParentData newParentData = newChild?.renderObject?.parentData;
    if (newParentData != null) {
      newParentData.index = newSlot;
      if (oldParentData != null) newParentData.offset = oldParentData.offset;
    }

    return newChild;
  }

  @override
  void insertChildRenderObject(RenderObject child, int slot) {
    final RenderDeckViewport renderObject = this.renderObject;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child, after: _childElements[slot - 1]?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    const String moveChildRenderObjectErrorMessage =
        'Currently we maintain the list in contiguous increasing order, so '
        'moving children around is not allowed.';
    assert(false, moveChildRenderObjectErrorMessage);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(child.parent == renderObject);
    renderObject.remove(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    _childElements.forEach((int key, Element child) {
      visitor(child);
    });
  }

  @override
  void forgetChild(Element child) {
    _childElements.remove(child.slot);
  }
}

/// A viewport showing a subset of children on a wheel.
///
/// Typically used with [DeckScrollView], this viewport is similar to
/// [Viewport] in that it shows a subset of children in a scrollable based
/// on the scrolling offset and the children's dimensions. But uses
/// [RenderDeckViewport] to display the children on a wheel.
///
/// See also:
///
///  * [DeckScrollView], widget that combines this viewport with a scrollable.
///  * [RenderDeckViewport], the render object that renders the children
///    on a wheel.
class DeckViewport extends RenderObjectWidget {
  /// Creates a viewport where children are rendered onto a wheel.
  ///
  /// The [itemExtent] argument in pixels must be provided and must be positive.
  ///
  /// The [clipToSize] argument defaults to true and must not be null.
  ///
  /// The [renderChildrenOutsideViewport] argument defaults to false and must
  /// not be null.
  ///
  /// The [offset] argument must be provided and must not be null.
  const DeckViewport({
    Key key,
    @required this.layoutPow,
    @required this.itemExtent,
    this.virtualItemExtent,
    this.clipToSize = true,
    this.renderChildrenOutsideViewport = false,
    @required this.offset,
    @required this.childDelegate,
  })  : assert(childDelegate != null),
        assert(offset != null),
        assert(layoutPow != null),
        assert(layoutPow > 0),
        assert(itemExtent != null),
        assert(itemExtent > 0),
        assert(clipToSize != null),
        assert(renderChildrenOutsideViewport != null),
        assert(
          !renderChildrenOutsideViewport || !clipToSize,
          RenderDeckViewport.clipToSizeAndRenderChildrenOutsideViewportConflict,
        ),
        super(key: key);

  final double layoutPow;

  /// {@macro flutter.rendering.wheelList.itemExtent}
  final double itemExtent;
  final double virtualItemExtent;

  /// {@macro flutter.rendering.wheelList.clipToSize}
  final bool clipToSize;

  /// {@macro flutter.rendering.wheelList.renderChildrenOutsideViewport}
  final bool renderChildrenOutsideViewport;

  /// [ViewportOffset] object describing the content that should be visible
  /// in the viewport.
  final ViewportOffset offset;

  /// A delegate that lazily instantiates children.
  final DeckChildDelegate childDelegate;

  @override
  DeckElement createElement() => DeckElement(this);

  @override
  RenderDeckViewport createRenderObject(BuildContext context) {
    final DeckElement childManager = context;
    return RenderDeckViewport(
      childManager: childManager,
      offset: offset,
      itemExtent: itemExtent,
      virtualItemExtent: virtualItemExtent,
      layoutPow: layoutPow,
      clipToSize: clipToSize,
      renderChildrenOutsideViewport: renderChildrenOutsideViewport,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderDeckViewport renderObject) {
    renderObject
      ..offset = offset
      ..layoutPow = layoutPow
      ..itemExtent = itemExtent
      ..virtualItemExtent = virtualItemExtent
      ..clipToSize = clipToSize
      ..renderChildrenOutsideViewport = renderChildrenOutsideViewport;
  }
}
