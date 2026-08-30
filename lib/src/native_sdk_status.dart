/// Native platform represented by an [NativeSdkStatus].
enum NativePlatform { android, ios }

/// Linkage status of the official MSAL SDK on the current native platform.
final class NativeSdkStatus {
  const NativeSdkStatus({
    required this.platform,
    required this.linked,
    this.sdkVersion,
  });

  final NativePlatform platform;
  final bool linked;
  final String? sdkVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeSdkStatus &&
          platform == other.platform &&
          linked == other.linked &&
          sdkVersion == other.sdkVersion;

  @override
  int get hashCode => Object.hash(platform, linked, sdkVersion);

  @override
  String toString() =>
      'NativeSdkStatus(platform: $platform, linked: $linked, '
      'sdkVersion: $sdkVersion)';
}
