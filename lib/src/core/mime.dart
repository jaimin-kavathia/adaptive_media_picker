/// Best-effort MIME type lookup from a file path's extension.
///
/// Returns null when the path has no recognised extension (e.g. web blob
/// URLs), so callers should prefer a MIME type reported by the platform.
String? mimeTypeFromPath(String path) {
  final int dot = path.lastIndexOf('.');
  final int separator = path.lastIndexOf(RegExp(r'[/\\]'));
  if (dot < 0 || dot < separator) return null;
  return _mimeTypes[path.substring(dot + 1).toLowerCase()];
}

const Map<String, String> _mimeTypes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'bmp': 'image/bmp',
  'heic': 'image/heic',
  'heif': 'image/heif',
  'tif': 'image/tiff',
  'tiff': 'image/tiff',
  'mp4': 'video/mp4',
  'm4v': 'video/x-m4v',
  'mov': 'video/quicktime',
  'webm': 'video/webm',
  'mkv': 'video/x-matroska',
  'avi': 'video/x-msvideo',
  '3gp': 'video/3gpp',
};

/// Image MIME type detected from the file signature of [bytes], or null.
String? mimeTypeFromBytes(List<int> bytes) {
  bool startsWith(List<int> signature, [int offset = 0]) {
    if (bytes.length < offset + signature.length) return false;
    for (int i = 0; i < signature.length; i++) {
      if (bytes[offset + i] != signature[i]) return false;
    }
    return true;
  }

  if (startsWith(const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (startsWith(const [0x89, 0x50, 0x4E, 0x47])) return 'image/png';
  if (startsWith(const [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
  if (startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
      startsWith(const [0x57, 0x45, 0x42, 0x50], 8)) {
    return 'image/webp';
  }
  return null;
}

/// Whether [mimeType] matches [pattern], which may be exact
/// (`image/png`), a wildcard subtype (`image/*`) or `*/*`.
bool mimeTypeMatches(String pattern, String mimeType) {
  final String p = pattern.trim().toLowerCase();
  final String m = mimeType.toLowerCase();
  if (p == '*/*' || p == '*') return true;
  if (p.endsWith('/*')) return m.startsWith(p.substring(0, p.length - 1));
  return p == m;
}
