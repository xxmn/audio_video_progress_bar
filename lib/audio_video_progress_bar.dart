import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'defines.dart';
import 'render_progress_bar.dart';

/// A progress bar widget to show or set the location of the currently
/// playing audio or video content.
///
/// This widget does not itself play audio or video content, but you can
/// use it in conjunction with an audio plugin. It is a more convenient
/// replacement for the Flutter Slider widget.
class ProgressBar extends LeafRenderObjectWidget {
  /// You must set the current audio or video duration [progress] and also
  /// the [total] duration. Optionally set the [buffered] content progress
  /// as well.
  ///
  /// When a user drags the thumb to a new location you can be notified
  /// by the [onSeek] callback so that you can update your audio/video player.
  const ProgressBar({
    Key? key,
    required this.progress,
    required this.total,
    this.buffered,
    this.onSeek,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.barHeight = 5.0,
    this.baseBarColor,
    this.progressBarColor,
    this.bufferedBarColor,
    this.barCapShape = BarCapShape.round,
    this.thumbRadius = 10.0,
    this.thumbColor,
    this.thumbGlowColor,
    this.thumbGlowRadius = 30.0,
    this.thumbCanPaintOutsideBar = true,
    this.timeLabelLocation,
    this.timeLabelType,
    this.timeLabelTextStyle,
    this.timeLabelTextStyle2,
    this.timeLabelPadding = 0.0,
  }) : super(key: key);

  /// The elapsed playing time of the media.
  ///
  /// This should not be greater than the [total] time.
  final Duration progress;

  /// The total duration of the media.
  final Duration total;

  /// The currently buffered content of the media.
  ///
  /// This is useful for streamed content. If you are playing a local file
  /// then you can leave this out.
  final List<List<Duration>>? buffered;

  /// A callback when user moves the thumb.
  ///
  /// When the user moved the thumb on the progress bar this callback will
  /// run. It will not run until after the user has finished the touch event.
  ///
  /// You will get the chosen duration to start playing at which you can pass
  /// on to your media player.
  ///
  /// If you want continuous duration updates as the user moves the thumb,
  /// see [onDragUpdate], where the provided [ThumbDragDetails] has a
  /// `timeStamp` with the seek duration on it.
  final ValueChanged<Duration>? onSeek;

  /// A callback when the user starts to move the thumb.
  ///
  /// This will be called only once when the drag begins. This provides you
  /// with the [ThumbDragDetails].
  ///
  /// This method is useful if you are planning to do something like add a time
  /// label and/or video preview over the thumb and you need to do some
  /// initialization.
  ///
  /// Use [onSeek] if you only want to seek to a new audio position when the
  /// drag event has finished.
  final ThumbDragStartCallback? onDragStart;

  /// A callback when the user is moving the thumb.
  ///
  /// This will be called repeatedly as the thumb position changes. This
  /// provides you with the [ThumbDragDetails], which notify you of the global
  /// and local positions of the drag event as well as the current thumb
  /// duration. The current thumb duration will not go beyond [total] or less
  /// that `Duration.zero` so you can use this information to clamp the drag
  /// position values.
  ///
  /// This method is useful if you are planning to do something like add a time
  /// label and/or video preview over the thumb and need to update the position
  /// to stay in sync with the thumb position.
  ///
  /// Use [onSeek] if you only want to seek to a new audio position when the
  /// drag event has finished.
  final ThumbDragUpdateCallback? onDragUpdate;

  /// A callback when the user is finished moving the thumb.
  ///
  /// This will be called only once when the drag ends.
  ///
  /// This method is useful if you are planning to do something like add a time
  /// label and/or video preview over the thumb and you need to dispose of
  /// something when the drag is finished.
  ///
  /// This method is called directly before [onSeek].
  final VoidCallback? onDragEnd;

  /// The vertical thickness of the progress bar.
  final double barHeight;

  /// The color of the progress bar before playback has started.
  ///
  /// By default it is a transparent version of your theme's primary color.
  final Color? baseBarColor;

  /// The color of the progress bar to the left of the current playing
  /// [progress].
  ///
  /// By default it is your theme's primary color.
  final Color? progressBarColor;

  /// The color of the progress bar between the [progress] location and the
  /// [buffered] location.
  ///
  /// By default it is a transparent version of your theme's primary color,
  /// a shade darker than [baseBarColor].
  final Color? bufferedBarColor;

  /// The shape of the bar at the left and right ends.
  ///
  /// This affects the base bar for the total time, the current progress bar,
  /// and the buffered progress bar. The default is [BarCapShape.round].
  final BarCapShape barCapShape;

  /// The radius of the circle for the moveable progress bar thumb.
  final double thumbRadius;

  /// The color of the circle for the moveable progress bar thumb.
  ///
  /// By default it is your theme's primary color.
  final Color? thumbColor;

  /// The color of the pressed-down effect of the moveable progress bar thumb.
  ///
  /// By default it is [thumbColor] with an alpha value of 80.
  final Color? thumbGlowColor;

  /// The radius of the circle for the pressed-down effect of the moveable
  /// progress bar thumb.
  ///
  /// By default it is 30.
  final double thumbGlowRadius;

  /// Whether the thumb radius will before the start of the bar when at the
  /// beginning or after the end of the bar when at the end.
  ///
  /// The default is `true` and this means that the thumb will be painted
  /// outside of the bounds of the widget if there are no side labels. You can
  /// wrap [ProgressBar] with a `Padding` widget if your layout needs to leave
  /// some extra room for the thumb.
  ///
  /// When set to `false` the thumb will be clamped within the width of the
  /// bar. This is nice for aligning the thumb with vertical labels at the start
  /// and end of playback. However, because of the clamping, the thumb won't
  /// move during audio/video playback when near the ends. Depending on the
  /// size of the thumb and the length of the song, this usually only lasts
  /// a few seconds. The progress label still indicates that playback
  /// is happening during this time, though.
  final bool thumbCanPaintOutsideBar;

  /// The location for the [progress] and [total] duration text labels.
  ///
  /// By default the labels appear under the progress bar but you can also
  /// put them above, on the sides, or remove them altogether.
  final TimeLabelLocation? timeLabelLocation;

  /// What to display for the time label on the right
  ///
  /// The right time label can show the total time or the remaining time as a
  /// negative number. The default is [TimeLabelType.totalTime].
  final TimeLabelType? timeLabelType;

  /// The [TextStyle] used by the time labels.
  ///
  /// By default it is [TextTheme.bodyText1].
  final TextStyle? timeLabelTextStyle;
  final TextStyle? timeLabelTextStyle2;

  /// The extra space between the time labels and the progress bar.
  ///
  /// The default is 0.0. A positive number will move the labels further from
  /// the progress bar and a negative number will move them closer.
  final double timeLabelPadding;

  @override
  RenderProgressBar createRenderObject(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textStyle = timeLabelTextStyle ?? theme.textTheme.bodyText1;
    final textStyle2 = timeLabelTextStyle2 ?? theme.textTheme.bodyText1;
    var p = RenderProgressBar(
      progress: progress,
      total: total,
      buffered: buffered ??
          [
            [Duration.zero, Duration.zero]
          ],
      onSeek: onSeek,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      barHeight: barHeight,
      baseBarColor: baseBarColor ?? primaryColor.withOpacity(0.24),
      progressBarColor: progressBarColor ?? primaryColor,
      bufferedBarColor: bufferedBarColor ?? primaryColor.withOpacity(0.24),
      barCapShape: barCapShape,
      thumbRadius: thumbRadius,
      thumbColor: thumbColor ?? primaryColor,
      thumbGlowColor: thumbGlowColor ?? (thumbColor ?? primaryColor).withAlpha(80),
      thumbGlowRadius: thumbGlowRadius,
      thumbCanPaintOutsideBar: thumbCanPaintOutsideBar,
      timeLabelLocation: timeLabelLocation ?? TimeLabelLocation.below,
      timeLabelType: timeLabelType ?? TimeLabelType.totalTime,
      timeLabelTextStyle: textStyle,
      timeLabelTextStyle2: textStyle2,
      timeLabelPadding: timeLabelPadding,
    );
    return p;
  }

  @override
  void updateRenderObject(BuildContext context, RenderProgressBar renderObject) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textStyle = timeLabelTextStyle ?? theme.textTheme.bodyText1;
    renderObject
      ..progress = progress
      ..total = total
      ..buffered = buffered ??
          [
            [Duration.zero, Duration.zero]
          ]
      ..onSeek = onSeek
      ..onDragStart = onDragStart
      ..onDragUpdate = onDragUpdate
      ..onDragEnd = onDragEnd
      ..barHeight = barHeight
      ..baseBarColor = baseBarColor ?? primaryColor.withOpacity(0.24)
      ..progressBarColor = progressBarColor ?? primaryColor
      ..bufferedBarColor = bufferedBarColor ?? primaryColor.withOpacity(0.24)
      ..barCapShape = barCapShape
      ..thumbRadius = thumbRadius
      ..thumbColor = thumbColor ?? primaryColor
      ..thumbGlowColor = thumbGlowColor ?? (thumbColor ?? primaryColor).withAlpha(80)
      ..thumbGlowRadius = thumbGlowRadius
      ..thumbCanPaintOutsideBar = thumbCanPaintOutsideBar
      ..timeLabelLocation = timeLabelLocation ?? TimeLabelLocation.below
      ..timeLabelType = timeLabelType ?? TimeLabelType.totalTime
      ..timeLabelTextStyle = textStyle
      ..timeLabelPadding = timeLabelPadding;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('progress', progress.toString()));
    properties.add(StringProperty('total', total.toString()));
    properties.add(StringProperty('buffered', buffered.toString()));
    properties
        .add(ObjectFlagProperty<ValueChanged<Duration>>('onSeek', onSeek, ifNull: 'unimplemented'));
    properties.add(ObjectFlagProperty<ThumbDragStartCallback>('onDragStart', onDragStart,
        ifNull: 'unimplemented'));
    properties.add(ObjectFlagProperty<ThumbDragUpdateCallback>('onDragUpdate', onDragUpdate,
        ifNull: 'unimplemented'));
    properties
        .add(ObjectFlagProperty<VoidCallback>('onDragEnd', onDragEnd, ifNull: 'unimplemented'));
    properties.add(DoubleProperty('barHeight', barHeight));
    properties.add(ColorProperty('baseBarColor', baseBarColor));
    properties.add(ColorProperty('progressBarColor', progressBarColor));
    properties.add(ColorProperty('bufferedBarColor', bufferedBarColor));
    properties.add(StringProperty('barCapShape', barCapShape.toString()));
    properties.add(DoubleProperty('thumbRadius', thumbRadius));
    properties.add(ColorProperty('thumbColor', thumbColor));
    properties.add(ColorProperty('thumbGlowColor', thumbGlowColor));
    properties.add(DoubleProperty('thumbGlowRadius', thumbGlowRadius));
    properties.add(FlagProperty('thumbCanPaintOutsideBar', value: thumbCanPaintOutsideBar));
    properties.add(StringProperty('timeLabelLocation', timeLabelLocation.toString()));
    properties.add(StringProperty('timeLabelType', timeLabelType.toString()));
    properties.add(DiagnosticsProperty('timeLabelTextStyle', timeLabelTextStyle));
    properties.add(DoubleProperty('timeLabelPadding', timeLabelPadding));
  }
}
