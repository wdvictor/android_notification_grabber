import 'dart:typed_data';

import '../../domain/entities/installed_app.dart';

class InstalledAppModel {
  const InstalledAppModel({
    required this.name,
    required this.packageName,
    this.iconBytes,
  });

  factory InstalledAppModel.fromMap(Map<Object?, Object?> map) {
    final rawName = map['name'] as String?;
    final rawPackageName = map['packageName'] as String?;

    return InstalledAppModel(
      name: rawName == null || rawName.trim().isEmpty
          ? (rawPackageName ?? '').trim()
          : rawName.trim(),
      packageName: (rawPackageName ?? '').trim(),
      iconBytes: _readIconBytes(map['icon']),
    );
  }

  final String name;
  final String packageName;
  final Uint8List? iconBytes;

  InstalledApp toEntity({required bool isIgnored}) {
    return InstalledApp(
      name: name,
      packageName: packageName,
      iconBytes: iconBytes,
      isIgnored: isIgnored,
    );
  }

  static Uint8List? _readIconBytes(Object? value) {
    if (value is Uint8List) {
      return value;
    }

    if (value is List<int>) {
      return Uint8List.fromList(value);
    }

    return null;
  }
}
