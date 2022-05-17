import 'dart:ui';
import 'package:flutter/foundation.dart';

/// This is where the current time and total time labels should appear in
/// relation to the progress bar.
enum TimeLabelLocation {
  ///  The time is displayed above the progress bar.
  ///
  ///  | 01:23              05:00 |
  ///  | -------O---------------- |
  above,

  ///  The time is displayed below the progress bar.
  ///
  ///  | -------O---------------- |
  ///  | 01:23              05:00 |
  below,

  ///  The time is displayed on the sides of the progress bar.
  ///
  ///  | 01:23 -------O---------------- 05:00 |
  sides,

  ///  The time is not displayed.
  ///
  ///  | -------O---------------- |
  none,
}

/// The time label on the right hand side can be shown as the [totalTime] or as
/// the [remainingTime]. If the choice is [remainingTime] then this will be
/// shown as a negative number.
///
///
enum TimeLabelType {
  /// The time label on the right shows the total time.
  ///
  /// | -------O---------------- |
  /// | 01:23              05:00 |
  totalTime,

  /// The time label on the right shows the remaining time as a
  /// negative number.
  ///
  /// | -------O---------------- |
  /// | 01:23             -03:37 |
  remainingTime,
}

/// The shape of the progress bar at the left and right ends.
enum BarCapShape {
  /// The left and right ends of the bar are round.
  round,

  /// The left and right ends of the bar are square.
  square,
}

/// The callback signature for when the thumb begins a horizontal drag.
typedef ThumbDragStartCallback = void Function(ThumbDragDetails details);

/// The callback signature for when the thumb is moving on horizontally and has
/// new data.
typedef ThumbDragUpdateCallback = void Function(ThumbDragDetails details);

/// Data to pass back on drag callback events
class ThumbDragDetails {
  const ThumbDragDetails({
    this.timeStamp = Duration.zero,
    this.globalPosition = Offset.zero,
    this.localPosition = Offset.zero,
  });

  /// The duration position of the thumb on the progress bar
  final Duration timeStamp;

  /// The global position of the drag event moving the thumb on the progress bar.
  final Offset globalPosition;

  /// The local position of the drag event moving the thumb on the progress bar.
  final Offset localPosition;

  @override
  String toString() => '${objectRuntimeType(this, 'ThumbDragDetails')}('
      'time: $timeStamp, '
      'global: $globalPosition, '
      'local: $localPosition)';
}
