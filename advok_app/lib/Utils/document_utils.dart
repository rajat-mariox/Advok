import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../Services/api_service.dart';

/// Max case-document size, matching the backend's 10MB cap.
const int maxDocumentBytes = 10 * 1024 * 1024;

/// File types accepted for case documents.
const List<String> documentExtensions = [
  'pdf',
  'jpg',
  'jpeg',
  'png',
  'doc',
  'docx',
  'txt',
];

/// Content type for a file, from its extension.
String mimeForFileName(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  return switch (ext) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'txt' => 'text/plain',
    _ => 'application/octet-stream',
  };
}

/// A file picked for upload, ready to send as a base64 data URL.
class PickedDocument {
  const PickedDocument({required this.name, required this.dataUrl});

  final String name;
  final String dataUrl;
}

/// Opens the system picker for a case document. Returns null when the user
/// cancels; throws [ApiException] when the file is over the size cap, so
/// callers surface it like any other request error.
Future<PickedDocument?> pickCaseDocument() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: documentExtensions,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null) return null;
  if (file.size > maxDocumentBytes) {
    throw ApiException('File too large. Max size is 10MB.');
  }
  return PickedDocument(
    name: file.name,
    dataUrl: 'data:${mimeForFileName(file.name)};base64,${base64Encode(bytes)}',
  );
}

/// The document's bytes, whether the backend stored it inline (a data URL)
/// or on S3 (an https URL).
Future<Uint8List> documentBytes(String url) async {
  if (url.startsWith('data:')) {
    final comma = url.indexOf(',');
    if (comma == -1) throw ApiException('This document could not be read.');
    return base64Decode(url.substring(comma + 1));
  }
  try {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode >= 400) {
      throw ApiException('This document could not be downloaded.');
    }
    return response.bodyBytes;
  } on ApiException {
    rethrow;
  } catch (_) {
    throw ApiException('This document could not be downloaded.');
  }
}

/// Saves the file through the system save dialog (Downloads on mobile).
/// Returns the saved path, or null when the user cancelled.
Future<String?> saveDocumentToDevice({
  required String name,
  required Uint8List bytes,
}) {
  return FilePicker.saveFile(fileName: name, bytes: bytes);
}
