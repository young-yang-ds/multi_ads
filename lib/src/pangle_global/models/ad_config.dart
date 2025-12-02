class PangleAdConfig {
  final String appId;
  final bool useTextureView;
  final String? appName;
  final bool allowShowNotify;
  final bool allowShowPageWhenScreenLock;
  final bool debug;
  final List<String>? supportMultiProcess;
  final bool directDownloadNetworkType;

  PangleAdConfig({
    required this.appId,
    this.useTextureView = true,
    this.appName,
    this.allowShowNotify = true,
    this.allowShowPageWhenScreenLock = true,
    this.debug = false,
    this.supportMultiProcess,
    this.directDownloadNetworkType = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'useTextureView': useTextureView,
      'appName': appName,
      'allowShowNotify': allowShowNotify,
      'allowShowPageWhenScreenLock': allowShowPageWhenScreenLock,
      'debug': debug,
      'supportMultiProcess': supportMultiProcess,
      'directDownloadNetworkType': directDownloadNetworkType,
    };
  }
}
