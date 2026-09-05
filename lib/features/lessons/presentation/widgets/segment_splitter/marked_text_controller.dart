import 'package:flutter/widgets.dart';

import '../../../../../core/constants/app_constants.dart';
import 'segment_marker.dart';

/// Splitter field controller; it stores text with invisible
/// [kSegmentDelimiter].
class MarkedTextController extends TextEditingController {
  MarkedTextController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return buildSegmentSpans(
      text: text,
      base: style,
      marker: markerTextStyle(style),
    );
  }
}

/// Splits text into spans: plain chunks and one-character marker spans.
TextSpan buildSegmentSpans({
  required String text,
  required TextStyle? base,
  required TextStyle marker,
}) {
  final children = <InlineSpan>[];
  var index = 0;
  final length = text.length;
  while (index < length) {
    final next = text.indexOf(kSegmentDelimiter, index);
    if (next == -1) {
      children.add(TextSpan(text: text.substring(index)));
      break;
    }
    if (next > index) {
      children.add(TextSpan(text: text.substring(index, next)));
    }
    children.add(TextSpan(text: kSegmentDelimiter, style: marker));
    index = next + 1;
  }
  return TextSpan(style: base, children: children);
}
