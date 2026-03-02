/// Configuration for Vungle Ads SDK initialization
class VungleAdConfig {
  /// The Vungle App ID from your Vungle dashboard
  final String appId;

  /// Enable debug logging
  final bool debug;

  VungleAdConfig({required this.appId, this.debug = false});

  Map<String, dynamic> toJson() {
    return {'appId': appId, 'debug': debug};
  }
}
