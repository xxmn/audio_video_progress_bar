import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'defines.dart';

class RenderProgressBar extends RenderBox {
  RenderProgressBar({
    required Duration progress,
    required Duration total,
    required List<List<Duration>> buffered,
    ValueChanged<Duration>? onSeek,
    ThumbDragStartCallback? onDragStart,
    ThumbDragUpdateCallback? onDragUpdate,
    VoidCallback? onDragEnd,
    required double barHeight,
    required Color baseBarColor,
    required Color progressBarColor,
    required Color bufferedBarColor,
    required BarCapShape barCapShape,
    double thumbRadius = 20.0,
    required Color thumbColor,
    required Color thumbGlowColor,
    double thumbGlowRadius = 30.0,
    bool thumbCanPaintOutsideBar = true,
    required TimeLabelLocation timeLabelLocation,
    required TimeLabelType timeLabelType,
    TextStyle? timeLabelTextStyle,
    TextStyle? timeLabelTextStyle2,
    double timeLabelPadding = 0.0,
  })  : _progress = progress,
        _total = total,
        _buffered = buffered,
        _onSeek = onSeek,
        _onDragStartUserCallback = onDragStart,
        _onDragUpdateUserCallback = onDragUpdate,
        _onDragEndUserCallback = onDragEnd,
        _barHeight = barHeight,
        _baseBarColor = baseBarColor,
        _progressBarColor = progressBarColor,
        _bufferedBarColor = bufferedBarColor,
        _barCapShape = barCapShape,
        _thumbRadius = thumbRadius,
        _thumbColor = thumbColor,
        _thumbGlowColor = thumbGlowColor,
        _thumbGlowRadius = thumbGlowRadius,
        _thumbCanPaintOutsideBar = thumbCanPaintOutsideBar,
        _timeLabelLocation = timeLabelLocation,
        _timeLabelType = timeLabelType,
        _timeLabelTextStyle = timeLabelTextStyle,
        _timeLabelTextStyle2 = timeLabelTextStyle2,
        _timeLabelPadding = timeLabelPadding {
    _drag = HorizontalDragGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onEnd = _onDragEnd
      ..onCancel = _finishDrag;
    _thumbValue = _proportionOfTotal(_progress);
  }

  // This is the gesture recognizer used to move the thumb.
  HorizontalDragGestureRecognizer? _drag;

  // This is a value between 0.0 and 1.0 used to indicate the position on
  // the bar.
  late double _thumbValue;

  // The thumb can move for two reasons. One is that the [progress] changed.
  // The other is that the user is dragging the thumb. This variable keeps
  // track of that so that while the user is dragging the thumb at the same
  // time as a [progress] update there won't be a conflict.
  bool _userIsDraggingThumb = false;

  // This padding is always used between the time labels and the progress bar
  // when the time labels are on the sides. Any user defined [timeLabelPadding]
  // is in addition to this.
  double get _defaultSidePadding {
    const minPadding = 5.0;
    return (_thumbCanPaintOutsideBar) ? thumbRadius + minPadding : minPadding;
  }

  void _onDragStart(DragStartDetails details) {
    _userIsDraggingThumb = true;
    _updateThumbPosition(details.localPosition);
    onDragStart?.call(ThumbDragDetails(
      timeStamp: _currentThumbDuration(),
      globalPosition: details.globalPosition,
      localPosition: details.localPosition,
    ));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _updateThumbPosition(details.localPosition);
    onDragUpdate?.call(ThumbDragDetails(
      timeStamp: _currentThumbDuration(),
      globalPosition: details.globalPosition,
      localPosition: details.localPosition,
    ));
  }

  void _onDragEnd(DragEndDetails details) {
    onDragEnd?.call();
    onSeek?.call(_currentThumbDuration());
    _finishDrag();
  }

  void _finishDrag() {
    _userIsDraggingThumb = false;
    markNeedsPaint();
  }

  Duration _currentThumbDuration() {
    final thumbMiliseconds = _thumbValue * total.inMilliseconds;
    return Duration(milliseconds: thumbMiliseconds.round());
  }

  // This needs to stay in sync with the layout. This could be a potential
  // source of bugs if there is a layout change but we forget to update this.
  // It might be a good idea to redesign the architecture so that there is
  // only one place to make changes.
  void _updateThumbPosition(Offset localPosition) {
    final dx = localPosition.dx;
    double lengthBefore = 0.0;
    double lengthAfter = 0.0;
    if (_timeLabelLocation == TimeLabelLocation.sides) {
      lengthBefore = _leftLabelSize.width + _defaultSidePadding + _timeLabelPadding;
      lengthAfter = _rightLabelSize.width + _defaultSidePadding + _timeLabelPadding;
    }
    // The paint used to draw the bar line draws half of the cap before the
    // start of the line (and after the end of the line). The cap radius is
    // equal to half of the line width, which in this case is the bar height.
    final barCapRadius = _barHeight / 2;
    double barStart = lengthBefore + barCapRadius;
    double barEnd = size.width - lengthAfter - barCapRadius;
    final barWidth = barEnd - barStart;
    final position = (dx - barStart).clamp(0.0, barWidth);
    _thumbValue = (position / barWidth);
    markNeedsPaint();
  }

  /// The play location of the media.
  ///
  /// This is used to update the thumb value and the left time label.
  Duration get progress => _progress;
  Duration _progress;
  set progress(Duration value) {
    if (_progress == value) {
      return;
    }
    if (_progress.inHours != value.inHours) {
      _clearLabelCache();
    }
    _progress = value;
    if (!_userIsDraggingThumb) {
      _thumbValue = _proportionOfTotal(value);
    }
    markNeedsPaint();
  }

  Size get timeLabelSize {
    var h1 = max(_leftLabelSize.height, _slashSize.height);
    var h = max(h1, _rightLabelSize.height);
    var w = _leftLabelSize.width + _slashSize.width + _rightLabelSize.width;
    return Size(w, h);
  }

  TextPainter? _cachedLeftLabel;
  Size get _leftLabelSize {
    _cachedLeftLabel ??= _leftTimeLabel();
    return _cachedLeftLabel!.size;
  }

  TextPainter? _cachedSlash;
  Size get _slashSize {
    _cachedSlash ??= _slash();
    return _cachedSlash!.size;
  }

  TextPainter? _cachedRightLabel;
  Size get _rightLabelSize {
    _cachedRightLabel ??= _rightTimeLabel();
    return _cachedRightLabel!.size;
  }

  void _clearLabelCache() {
    _cachedLeftLabel = null;
    _cachedRightLabel = null;
  }

  TextPainter _leftTimeLabel() {
    final progressText = _getTimeString(progress);
    return _layoutText("$progressText");
  }

  TextPainter _slash() {
    return _layoutText2(" / ");
  }

  TextPainter _rightTimeLabel() {
    switch (timeLabelType) {
      case TimeLabelType.totalTime:
        final text = _getTimeString(total);
        return _layoutText2(text);
      case TimeLabelType.remainingTime:
        final remaining = total - progress;
        final text = '-${_getTimeString(remaining)}';
        return _layoutText2(text);
    }
  }

  TextPainter _layoutText(String text) {
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: _timeLabelTextStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter;
  }

  TextPainter _layoutText2(String text) {
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: _timeLabelTextStyle2),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter;
  }

  /// The total time length of the media.
  Duration get total => _total;
  Duration _total;
  set total(Duration value) {
    if (_total == value) {
      return;
    }
    if (_total.inHours != value.inHours) {
      _clearLabelCache();
    }
    _total = value;
    if (!_userIsDraggingThumb) {
      _thumbValue = _proportionOfTotal(progress);
    }
    markNeedsPaint();
  }

  /// The buffered length of the media when streaming.
  List<List<Duration>> get buffered => _buffered;
  List<List<Duration>> _buffered;
  set buffered(List<List<Duration>> value) {
    if (_buffered == value) {
      return;
    }
    _buffered = value;
    markNeedsPaint();
  }

  /// A callback for the audio duration position to where the thumb was moved.
  ValueChanged<Duration>? get onSeek => _onSeek;
  ValueChanged<Duration>? _onSeek;
  set onSeek(ValueChanged<Duration>? value) {
    if (value == _onSeek) {
      return;
    }
    _onSeek = value;
  }

  /// A callback when the thumb starts being dragged.
  ThumbDragStartCallback? get onDragStart => _onDragStartUserCallback;
  ThumbDragStartCallback? _onDragStartUserCallback;
  set onDragStart(ThumbDragStartCallback? value) {
    if (value == _onDragStartUserCallback) {
      return;
    }
    _onDragStartUserCallback = value;
  }

  /// A callback when the thumb is being dragged.
  ThumbDragUpdateCallback? get onDragUpdate => _onDragUpdateUserCallback;
  ThumbDragUpdateCallback? _onDragUpdateUserCallback;
  set onDragUpdate(ThumbDragUpdateCallback? value) {
    if (value == _onDragUpdateUserCallback) {
      return;
    }
    _onDragUpdateUserCallback = value;
  }

  /// A callback when the thumb drag is finished.
  VoidCallback? get onDragEnd => _onDragEndUserCallback;
  VoidCallback? _onDragEndUserCallback;
  set onDragEnd(VoidCallback? value) {
    if (value == _onDragEndUserCallback) {
      return;
    }
    _onDragEndUserCallback = value;
  }

  /// The vertical thickness of the bar that the thumb moves along.
  double get barHeight => _barHeight;
  double _barHeight;
  set barHeight(double value) {
    if (_barHeight == value) return;
    _barHeight = value;
    markNeedsPaint();
  }

  /// The color of the progress bar before any playing or buffering.
  Color get baseBarColor => _baseBarColor;
  Color _baseBarColor;
  set baseBarColor(Color value) {
    if (_baseBarColor == value) return;
    _baseBarColor = value;
    markNeedsPaint();
  }

  /// The color of the played portion of the progress bar.
  Color get progressBarColor => _progressBarColor;
  Color _progressBarColor;
  set progressBarColor(Color value) {
    if (_progressBarColor == value) return;
    _progressBarColor = value;
    markNeedsPaint();
  }

  /// The color of the visible buffered portion of the progress bar.
  Color get bufferedBarColor => _bufferedBarColor;
  Color _bufferedBarColor;
  set bufferedBarColor(Color value) {
    if (_bufferedBarColor == value) return;
    _bufferedBarColor = value;
    markNeedsPaint();
  }

  BarCapShape get barCapShape => _barCapShape;
  BarCapShape _barCapShape;
  set barCapShape(BarCapShape value) {
    if (_barCapShape == value) return;
    _barCapShape = value;
    markNeedsPaint();
  }

  /// The color of the moveable thumb.
  Color get thumbColor => _thumbColor;
  Color _thumbColor;
  set thumbColor(Color value) {
    if (_thumbColor == value) return;
    _thumbColor = value;
    markNeedsPaint();
  }

  /// The length of the radius for the circular thumb.
  double get thumbRadius => _thumbRadius;
  double _thumbRadius;
  set thumbRadius(double value) {
    if (_thumbRadius == value) return;
    _thumbRadius = value;
    markNeedsLayout();
  }

  /// The color of the pressed-down effect of the moveable thumb.
  Color get thumbGlowColor => _thumbGlowColor;
  Color _thumbGlowColor;
  set thumbGlowColor(Color value) {
    if (_thumbGlowColor == value) return;
    _thumbGlowColor = value;
    if (_userIsDraggingThumb) markNeedsPaint();
  }

  /// The length of the radius of the pressed-down effect of the moveable thumb.
  double get thumbGlowRadius => _thumbGlowRadius;
  double _thumbGlowRadius;
  set thumbGlowRadius(double value) {
    if (_thumbGlowRadius == value) return;
    _thumbGlowRadius = value;
    markNeedsLayout();
  }

  /// Whether the thumb will paint before the start or after the end of the bar.
  bool get thumbCanPaintOutsideBar => _thumbCanPaintOutsideBar;
  bool _thumbCanPaintOutsideBar;
  set thumbCanPaintOutsideBar(bool value) {
    if (_thumbCanPaintOutsideBar == value) return;
    _thumbCanPaintOutsideBar = value;
    markNeedsPaint();
  }

  /// The position of the duration text labels for the progress and total time.
  TimeLabelLocation get timeLabelLocation => _timeLabelLocation;
  TimeLabelLocation _timeLabelLocation;
  set timeLabelLocation(TimeLabelLocation value) {
    if (_timeLabelLocation == value) return;
    _timeLabelLocation = value;
    markNeedsLayout();
  }

  /// What to display for the time label on the right
  ///
  /// The right time label can show the total time or the remaining time as a
  /// negative number. The default is [TimeLabelType.totalTime].
  TimeLabelType get timeLabelType => _timeLabelType;
  TimeLabelType _timeLabelType;
  set timeLabelType(TimeLabelType value) {
    if (_timeLabelType == value) return;
    _timeLabelType = value;
    _clearLabelCache();
    markNeedsLayout();
  }

  /// The text style for the duration text labels. By default this style is
  /// taken from the theme's [textStyle.bodyText1].
  TextStyle? get timeLabelTextStyle => _timeLabelTextStyle;
  TextStyle? _timeLabelTextStyle;
  set timeLabelTextStyle(TextStyle? value) {
    if (_timeLabelTextStyle == value) return;
    _timeLabelTextStyle = value;
    _clearLabelCache();
    markNeedsLayout();
  }

  /// The text style for the duration text labels. By default this style is
  /// taken from the theme's [textStyle.bodyText1].
  TextStyle? get timeLabelTextStyle2 => _timeLabelTextStyle2;
  TextStyle? _timeLabelTextStyle2;
  set timeLabelTextStyle2(TextStyle? value) {
    if (_timeLabelTextStyle2 == value) return;
    _timeLabelTextStyle2 = value;
    _clearLabelCache();
    markNeedsLayout();
  }

  /// The length of the radius for the circular thumb.
  double get timeLabelPadding => _timeLabelPadding;
  double _timeLabelPadding;
  set timeLabelPadding(double value) {
    if (_timeLabelPadding == value) return;
    _timeLabelPadding = value;
    markNeedsLayout();
  }

  // The smallest that this widget would ever want to be.
  static const _minDesiredWidth = 100.0;

  @override
  double computeMinIntrinsicWidth(double height) => _minDesiredWidth;

  @override
  double computeMaxIntrinsicWidth(double height) => _minDesiredWidth;

  @override
  double computeMinIntrinsicHeight(double width) => _calculateDesiredHeight();

  @override
  double computeMaxIntrinsicHeight(double width) => _calculateDesiredHeight();

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      _drag?.addPointer(event);
    }
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final desiredWidth = constraints.maxWidth;
    final desiredHeight = _calculateDesiredHeight();
    final desiredSize = Size(desiredWidth, desiredHeight);
    return constraints.constrain(desiredSize);
  }

  // When changing these remember to keep the gesture recognizer for the
  // thumb in sync.
  double _calculateDesiredHeight() {
    switch (_timeLabelLocation) {
      case TimeLabelLocation.below:
      case TimeLabelLocation.above:
        return _heightWhenLabelsAboveOrBelow();
      case TimeLabelLocation.sides:
        return _heightWhenLabelsOnSides();
      default:
        return _heightWhenNoLabels();
    }
  }

  double _heightWhenLabelsAboveOrBelow() {
    return _heightWhenNoLabels() + _textHeight() + _timeLabelPadding;
  }

  double _heightWhenLabelsOnSides() {
    return max(_heightWhenNoLabels(), _textHeight());
  }

  double _heightWhenNoLabels() {
    return max(2 * _thumbRadius, _barHeight);
  }

  double _textHeight() {
    return _leftLabelSize.height;
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    switch (_timeLabelLocation) {
      case TimeLabelLocation.above:
      case TimeLabelLocation.below:
        _drawProgressBarWithLabelsAboveOrBelow(canvas);
        break;
      case TimeLabelLocation.sides:
        _drawProgressBarWithLabelsOnSides(canvas);
        break;
      default:
        _drawProgressBarWithoutLabels(canvas);
    }

    canvas.restore();
  }

  ///  Draw the progress bar and labels vertically aligned:
  ///
  ///  | -------O---------------- |
  ///  | 01:23              05:00 |
  ///
  /// Or like this:
  ///
  ///  | 01:23              05:00 |
  ///  | -------O---------------- |
  void _drawProgressBarWithLabelsAboveOrBelow(Canvas canvas) {
    // calculate sizes
    final barWidth = size.width;
    final barHeight = _heightWhenNoLabels();

    // whether to paint the labels below the progress bar or above it
    final isLabelBelow = _timeLabelLocation == TimeLabelLocation.below;

    // current time label
    final labelDy = (isLabelBelow) ? barHeight + _timeLabelPadding : 0.0;
    final leftLabelOffset = Offset(0, labelDy);
    _leftTimeLabel().paint(canvas, leftLabelOffset);

    // total or remaining time label
    // final rightLabelDx = size.width - _rightLabelSize.width;

    final slashDx = _leftLabelSize.width;
    final slashOffset = Offset(slashDx, labelDy);
    _slash().paint(canvas, slashOffset);

    final rightLabelDx = _leftLabelSize.width + _slashSize.width;
    final rightLabelOffset = Offset(rightLabelDx, labelDy);
    _rightTimeLabel().paint(canvas, rightLabelOffset);

    // progress bar
    final barDy = (isLabelBelow) ? 0.0 : _leftLabelSize.height + _timeLabelPadding;
    _drawProgressBar(canvas, Offset(0, barDy), Size(barWidth, barHeight));
  }

  ///  Draw the progress bar and labels horizontally aligned:
  ///
  ///  | 01:23 -------O---------------- 05:00 |
  ///
  void _drawProgressBarWithLabelsOnSides(Canvas canvas) {
    // left time label
    final leftLabelSize = _leftLabelSize;
    final verticalOffset = size.height / 2 - leftLabelSize.height / 2;
    final leftLabelOffset = Offset(0, verticalOffset);
    _leftTimeLabel().paint(canvas, leftLabelOffset);

    // right time label
    final rightLabelSize = _rightLabelSize;
    final rightLabelWidth = rightLabelSize.width;
    final totalLabelDx = size.width - rightLabelWidth;
    final totalLabelOffset = Offset(totalLabelDx, verticalOffset);
    _rightTimeLabel().paint(canvas, totalLabelOffset);

    // progress bar
    final leftLabelWidth = leftLabelSize.width;
    final barHeight = _heightWhenNoLabels();
    final barWidth = size.width -
        2 * _defaultSidePadding -
        2 * _timeLabelPadding -
        leftLabelWidth -
        rightLabelWidth;
    final barDy = size.height / 2 - barHeight / 2;
    final barDx = leftLabelWidth + _defaultSidePadding + _timeLabelPadding;
    _drawProgressBar(canvas, Offset(barDx, barDy), Size(barWidth, barHeight));
  }

  /// Draw the progress bar without labels like this:
  ///
  /// | -------O---------------- |
  ///
  void _drawProgressBarWithoutLabels(Canvas canvas) {
    final barWidth = size.width - 2 * _thumbRadius;
    final barHeight = 2 * _thumbRadius;

    _drawProgressBar(canvas, Offset(_thumbRadius, 0), Size(barWidth, barHeight));
  }

  void _drawProgressBar(Canvas canvas, Offset offset, Size localSize) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _drawBaseBar(canvas, localSize);
    _drawBufferedBar(canvas, localSize);
    _drawCurrentProgressBar(canvas, localSize);
    _drawThumb(canvas, localSize);
    canvas.restore();
  }

  void _drawBaseBar(Canvas canvas, Size localSize) {
    _drawBar(
      canvas: canvas,
      availableSize: localSize,
      widthProportion: 1.0,
      color: baseBarColor,
    );
  }

  void _drawBufferedBar(Canvas canvas, Size localSize) {
    _drawRangeBar(
      canvas: canvas,
      availableSize: localSize,
      widthRangeList: _proportionOfBuffered(_buffered),
      color: bufferedBarColor,
    );
  }

  void _drawCurrentProgressBar(Canvas canvas, Size localSize) {
    _drawBar(
      canvas: canvas,
      availableSize: localSize,
      widthProportion: _proportionOfTotal(_progress),
      color: progressBarColor,
    );
  }

  void _drawRangeBar({
    required Canvas canvas,
    required Size availableSize,
    required List<List<double>> widthRangeList,
    required Color color,
  }) {
    final strokeCap = (_barCapShape == BarCapShape.round) ? StrokeCap.round : StrokeCap.square;
    final baseBarPaint = Paint()
      ..color = color
      ..strokeCap = strokeCap
      ..strokeWidth = _barHeight;
    final capRadius = _barHeight / 2;
    final adjustedWidth = availableSize.width - barHeight;

    for (var widthRange in widthRangeList) {
      var dx1 = widthRange[0] * adjustedWidth + capRadius;
      var dx2 = widthRange[1] * adjustedWidth + capRadius;
      var dy = availableSize.height / 2;
      var startPoint = Offset(dx1, dy);
      var endPoint = Offset(dx2, dy);
      canvas.drawLine(startPoint, endPoint, baseBarPaint);
    }
  }

  void _drawBar({
    required Canvas canvas,
    required Size availableSize,
    required double widthProportion,
    required Color color,
  }) {
    final strokeCap = (_barCapShape == BarCapShape.round) ? StrokeCap.round : StrokeCap.square;
    final baseBarPaint = Paint()
      ..color = color
      ..strokeCap = strokeCap
      ..strokeWidth = _barHeight;
    final capRadius = _barHeight / 2;
    final adjustedWidth = availableSize.width - barHeight;
    final dx = widthProportion * adjustedWidth + capRadius;
    final startPoint = Offset(capRadius, availableSize.height / 2);
    var endPoint = Offset(dx, availableSize.height / 2);
    canvas.drawLine(startPoint, endPoint, baseBarPaint);
  }

  void _drawThumb(Canvas canvas, Size localSize) {
    final thumbPaint = Paint()..color = thumbColor;
    final barCapRadius = _barHeight / 2;
    final availableWidth = localSize.width - _barHeight;
    var thumbDx = _thumbValue * availableWidth + barCapRadius;
    if (!_thumbCanPaintOutsideBar) {
      thumbDx = thumbDx.clamp(_thumbRadius, localSize.width - _thumbRadius);
    }
    final center = Offset(thumbDx, localSize.height / 2);
    if (_userIsDraggingThumb) {
      final thumbGlowPaint = Paint()..color = thumbGlowColor;
      canvas.drawCircle(center, thumbGlowRadius, thumbGlowPaint);
    }
    canvas.drawCircle(center, thumbRadius, thumbPaint);
  }

  List<List<double>> _proportionOfBuffered(List<List<Duration>> durationRangeList) {
    return durationRangeList
        .map(
          (durationRange) => durationRange
              .map(
                (duration) => _proportionOfTotal(duration),
              )
              .toList(),
        )
        .toList();
  }

  double _proportionOfTotal(Duration duration) {
    if (total.inMilliseconds == 0) {
      return 0.0;
    }
    return duration.inMilliseconds / total.inMilliseconds;
  }

  String _getTimeString(Duration time) {
    final minutes = time.inMinutes.remainder(Duration.minutesPerHour).toString();
    final seconds = time.inSeconds.remainder(Duration.secondsPerMinute).toString().padLeft(2, '0');
    return time.inHours > 0
        ? "${time.inHours}:${minutes.padLeft(2, "0")}:$seconds"
        : "$minutes:$seconds";
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    // description
    config.textDirection = TextDirection.ltr;
    config.label = 'Progress bar';
    config.value = '${(_thumbValue * 100).round()}%';

    // increase action
    config.onIncrease = increaseAction;
    final increased = _thumbValue + _semanticActionUnit;
    config.increasedValue = '${((increased).clamp(0.0, 1.0) * 100).round()}%';

    // descrease action
    config.onDecrease = decreaseAction;
    final decreased = _thumbValue - _semanticActionUnit;
    config.decreasedValue = '${((decreased).clamp(0.0, 1.0) * 100).round()}%';
  }

  // This is how much to move the thumb if the move is triggered by a
  // semantic action rather than a touch event.
  static const double _semanticActionUnit = 0.05;

  void increaseAction() {
    final newValue = _thumbValue + _semanticActionUnit;
    _thumbValue = (newValue).clamp(0.0, 1.0);
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void decreaseAction() {
    final newValue = _thumbValue - _semanticActionUnit;
    _thumbValue = (newValue).clamp(0.0, 1.0);
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }
}
