import 'package:flutter/widgets.dart';

import '../../../../../core/constants/app_constants.dart';
import 'segment_marker.dart';

/// Контроллер поля-сплиттера: хранит «сырой» текст с символами
/// [kSegmentDelimiter] (ровно то, что уйдёт на сервер). Сам разделитель в тексте
/// невидим — метку поверх поля рисует игла, — поэтому «|» лишь занимает место.
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

/// Режет текст на спаны: обычные куски и подсвеченные метки. Каждый [kSegmentDelimiter]
/// — отдельный спан из одного символа, поэтому смещения курсора и выделения
/// не сдвигаются (в отличие от `WidgetSpan`). Та же разбивка кормит зеркальный
/// `TextPainter` при хит-тесте перетаскивания.
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
