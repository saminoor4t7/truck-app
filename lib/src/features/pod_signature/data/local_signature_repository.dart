import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SavedSignature {
  const SavedSignature({
    required this.id,
    required this.filePath,
    required this.signedBy,
    required this.savedAt,
  });

  final String id;
  final String filePath;
  final String signedBy;
  final DateTime savedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'filePath': filePath,
    'signedBy': signedBy,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedSignature.fromJson(Map<String, dynamic> json) => SavedSignature(
    id: json['id'] as String,
    filePath: json['filePath'] as String,
    signedBy: json['signedBy'] as String,
    savedAt: DateTime.parse(json['savedAt'] as String),
  );
}

class LocalSignatureRepository {
  static const _signaturesPreferenceKey = 'saved_driver_signatures';
  static const _driverNamePreferenceKey = 'driver_profile_name';
  static const _uuid = Uuid();

  Future<SavedSignature> save(String base64Png) async {
    final preferences = await SharedPreferences.getInstance();
    final id = _uuid.v4();
    final directory = await getApplicationSupportDirectory();
    final signaturesDirectory = Directory('${directory.path}/signatures');
    await signaturesDirectory.create(recursive: true);
    final file = File('${signaturesDirectory.path}/$id.png');
    await file.writeAsBytes(base64Decode(base64Png), flush: true);

    final signature = SavedSignature(
      id: id,
      filePath: file.path,
      signedBy: preferences.getString(_driverNamePreferenceKey) ?? 'Driver',
      savedAt: DateTime.now(),
    );
    final signatures = await all();
    await preferences.setString(
      _signaturesPreferenceKey,
      jsonEncode([signature, ...signatures].map((item) => item.toJson()).toList()),
    );
    return signature;
  }

  Future<List<SavedSignature>> all() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_signaturesPreferenceKey);
    if (encoded == null) return const [];

    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      throw const FormatException('Saved signatures must be a list.');
    }
    final signatures = decoded
        .map((item) {
          if (item is! Map) {
            throw const FormatException('Saved signature entry is invalid.');
          }
          return SavedSignature.fromJson(Map<String, dynamic>.from(item));
        })
        .toList();
    signatures.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return signatures;
  }
}
