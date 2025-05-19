// Stub implementation for non-web platforms
// This file is only used as a fallback and should never be imported directly

// Mock HTML classes
class Blob {
  Blob(List<dynamic> contents);
}

class AnchorElement {
  AnchorElement({String? href});
  
  void setAttribute(String name, String value) {}
  
  void click() {}
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  
  static void revokeObjectUrl(String url) {}
}
