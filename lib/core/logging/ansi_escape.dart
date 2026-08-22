final RegExp _ansiOperatingSystemCommand = RegExp(
  r'\x1B\][^\x07\x1B]*(?:\x07|\x1B\\)',
);

final RegExp _ansiControlSequence = RegExp(r'(?:\x1B\[|\x9B)[0-?]*[ -/]*[@-~]');

/// Removes terminal control sequences from text rendered by Flutter widgets.
String stripAnsiEscapeSequences(String text) {
  return text
      .replaceAll(_ansiOperatingSystemCommand, '')
      .replaceAll(_ansiControlSequence, '');
}
