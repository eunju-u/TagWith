# TagWith App 🏷️

가계부와 태그 관리 기능을 제공하는 Flutter 애플리케이션입니다.

## 🚀 시작하기 전에 (환경 설정)

이 프로젝트는 보안상의 이유로 **`config.json`** 파일을 통해 중요 키값(API URL 등)을 관리합니다. 프로젝트를 처음 실행하려면 아래 설정을 완료해야 합니다.

### 1. `config.json` 설정
프로젝트 루트 디렉토리(최상단)에 `config.json` 파일을 생성하세요. `config.example.json`을 복사해서 사용하면 편리합니다.

```bash
cp config.example.json config.json
```

그 후, `config.json` 파일을 열어 실제 서버의 `BASE_URL` 값을 입력하세요.

```json
{
  "BASE_URL": "https://web-production-e1340.up.railway.app"
}
```

### 2. 프로젝트 실행
`config.json`을 사용하여 앱을 실행하려면 반드시 `--dart-define-from-file` 옵션을 붙여야 합니다.

**터미널에서 실행:**
```bash
flutter run --dart-define-from-file=config.json
```

**VS Code 디버깅 설정 (`.vscode/launch.json`):**
비주얼 스튜디오 코드를 사용하신다면 아래 설정을 `launch.json`에 추가하여 편하게 실행할 수 있습니다.

```json
{
  "configurations": [
    {
      "name": "TagWith (Config)",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define-from-file=config.json"]
    }
  ]
}
```

## 🛠️ 기술 스택
- **Flutter / Dart**
- **Dio**: HTTP 통신
- **Provider**: 상태 관리
- **Flutter Secure Storage**: 토큰 및 보안 데이터 저장
- **Google Fonts & Table Calendar**: UI 라이브러리