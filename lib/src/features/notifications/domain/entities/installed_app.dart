import 'dart:typed_data';

class InstalledApp {
  const InstalledApp({
    required this.name,
    required this.packageName,
    required this.isIgnored,
    this.iconBytes,
  });

  final String name;
  final String packageName;
  final Uint8List? iconBytes;
  final bool isIgnored;

  InstalledApp copyWith({
    String? name,
    String? packageName,
    Uint8List? iconBytes,
    bool? isIgnored,
    bool clearIcon = false,
  }) {
    return InstalledApp(
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      iconBytes: clearIcon ? null : iconBytes ?? this.iconBytes,
      isIgnored: isIgnored ?? this.isIgnored,
    );
  }
}
