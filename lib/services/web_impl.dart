// Web implementation
import 'dart:html' as html;

// Export html for use in other files
export 'dart:html' show Blob, AnchorElement, Url;

// Create a File class that mimics dart:io File for web
class File {
  final String path;
  
  File(this.path);
  
  Future<String> readAsString() async {
    throw UnsupportedError('Reading files directly is not supported on web');
  }
  
  Future<void> writeAsString(String contents) async {
    final bytes = List<int>.from(contents.codeUnits);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', path.split('/').last)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
  
  Future<void> writeAsBytes(List<int> bytes) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', path.split('/').last)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

// Mock Directory class for web
class Directory {
  final String path;
  
  Directory(this.path);
  
  static Future<Directory> get temporary async {
    return Directory('/temp');
  }
}

// Note: We're not defining getApplicationDocumentsDirectory or getTemporaryDirectory here
// to avoid conflicts with path_provider package
