class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://web-production-e1340.up.railway.app',
  );

  static const String naverClientId = String.fromEnvironment(
    'NAVER_CLIENT_ID',
    defaultValue: '8zKcP6_dylvz_hceMUkx', // 보안상 실제 키는 .json에만 적고 여기에 적지 않는 편이 좋습니다.
  );

  static const String naverClientSecret = String.fromEnvironment(
    'NAVER_CLIENT_SECRET',
    defaultValue: 'DEJZPkNHsk',
  );

  static const String naverMapClientId = String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID',
    defaultValue: 'jd2c1ntprd',
  );
}
