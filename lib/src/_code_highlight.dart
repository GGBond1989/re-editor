part of re_editor;

typedef HighlightBuilder = List<TextSpan> Function(String);

class _CodeHighlighter extends ValueNotifier<List<List<TextSpan>>> {

  final BuildContext _context;
  final _CodeParagraphProvider _provider;

  CodeLineEditingController _controller;
  HighlightBuilder? _builder;

  _CodeHighlighter({
    required BuildContext context,
    required CodeLineEditingController controller,
    HighlightBuilder? builder,
  }) : _context = context,
    _provider = _CodeParagraphProvider(),
    _controller = controller,
    _builder = builder,
    super(const []) {
    _controller.addListener(_onCodesChanged);
    _processHighlight();
  }

  set controller(CodeLineEditingController value) {
    if (_controller == value) {
      return;
    }
    _controller.removeListener(_onCodesChanged);
    _controller = value;
    _controller.addListener(_onCodesChanged);
    _processHighlight();
  }

  set builder(HighlightBuilder? value) {
    if (_builder == value) {
      return;
    }
    _builder = value;
    _processHighlight();
  }

  IParagraph build({
    required int index,
    required TextStyle style,
    required double maxWidth,
    int? maxLengthSingleLineRendering,
  }) {
    _provider.updateBaseStyle(style);
    _provider.updateMaxLengthSingleLineRendering(maxLengthSingleLineRendering);
    return _provider.build(_controller.buildTextSpan(
      context: _context,
      index: index,
      textSpan: _buildSpan(index, style),
      style: style
    ), maxWidth);
  }

  @override
  void dispose() {
    _controller.removeListener(_onCodesChanged);
    super.dispose();
  }

  TextSpan _buildSpan(int index, TextStyle style) {
    final String text = _controller.codeLines[index].text;
    if (index >= value.length) {
      return TextSpan( text: text, style: style );
    }
    return TextSpan(children: value[index], style: style);
  }

  void _onCodesChanged() {
    if (_controller.preValue?.codeLines == _controller.codeLines) {
      return;
    }
    _processHighlight();
  }

  void _processHighlight() {
    final builder = _builder;
    if (builder == null) {
      value = [];
      return;
    }
    final code = _controller.codeLines.asString(TextLineBreak.lf, false);
    value = splitSpansIntoLines(builder.call(code));
  }

  List<List<TextSpan>> splitSpansIntoLines(List<TextSpan> spans) {
    final result = [<TextSpan>[]];
    
    void addLine(String text, TextStyle? style, MouseCursor? cursor) {
      if (text.isEmpty) return;
      result.last.add(TextSpan(
        text: text,
        style: style,
        mouseCursor: cursor,
      ));
    }

    TextSpan cloneSpan(TextSpan span, TextStyle? style) {
      return TextSpan(
        text: span.text,
        children: span.children,
        style: style?.merge(span.style) ?? span.style,
        mouseCursor: span.mouseCursor,
      );
    }
    
    for (final span in spans) {
      if (span.text != null) {
        final lines = span.text!.split(TextLineBreak.lf.value);
        addLine(lines.first, span.style, span.mouseCursor);
        
        for (final line in lines.skip(1)) {
          result.add([]);
          addLine(line, span.style, span.mouseCursor);
        }
      }

      if ( span.children != null) {
        final children = span.children!
            .whereType<TextSpan>()
            .map((child) => cloneSpan(child, span.style))
            .toList();

        final childLines = splitSpansIntoLines(children);
        if (childLines.isNotEmpty) {
          result.last.addAll(childLines.first);
          result.addAll(childLines.skip(1));
        }
      }
    }
    return result;
  }
}