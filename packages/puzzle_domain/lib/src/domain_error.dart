/// Safe, structured rejection at a domain input boundary.
///
/// [path] is a schema path, not the submitted value. Messages never echo a
/// puzzle/replay payload. [offset], when present, is a decoded-text offset.
final class DomainException extends FormatException {
  const DomainException(this.code, this.path, String message, {int? offset})
    : super(message, null, offset);

  final String code;
  final String path;

  @override
  String toString() => 'DomainException($code at $path): $message';
}
