import 'dart:io';

class PangleAdsConfig {
  /// 官方测试id
  static String get appId => Platform.isIOS ? '8025677' : '8025677';
  static String get openId => Platform.isIOS ? '890000078' : '890000078';
  static String get interId => Platform.isIOS ? '980088188' : '980088188';
  static String get bannerId => Platform.isIOS ? '980088196' : '980088196';
  static String get nativeId => Platform.isIOS ? '980088216' : '980088216';
}

class GoogleAdConfig {
  /// 官方测试id
  static String get openId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/5575463023'
      : 'ca-app-pub-3940256099942544/9257395921';
  static String get interId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';
  static String get bannerId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/8388050270'
      : 'ca-app-pub-3940256099942544/9214589741';
  static String get nativeId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/2247696110'
      : 'ca-app-pub-3940256099942544/2247696110';
}

class VungleAdsConfig {
  /// 官方测试id
  static String get appId =>
      Platform.isIOS ? '695c8402c9bdaccfbb31f886' : '695c8402c9bdaccfbb31f886';
  static String get interId =>
      Platform.isIOS ? '91842-7041294' : '91842-7041294';
  static String get bannerId =>
      Platform.isIOS ? '__BANNER-9841140' : '__BANNER-9841140';
  static String get openId =>
      Platform.isIOS ? '22320-0538754' : '22320-0538754';
  static String get nativeId =>
      Platform.isIOS ? 'NATIVE-6582517' : 'NATIVE-6582517';
}
