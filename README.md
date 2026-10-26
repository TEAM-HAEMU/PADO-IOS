# PADO iOS

PADO(파도)의 iOS 앱을 SwiftUI로 다시 만드는 저장소입니다. 지금 있는 장소에 노래를 남기고(드랍), 주변 1km 안에 남겨진 노래를 지도에서 찾아 듣는 앱이에요.

- Android는 React Native 앱([TEAM-HAEMU/PADO-CLIENT](https://github.com/TEAM-HAEMU/PADO-CLIENT))을 그대로 쓰고, iOS만 이 SwiftUI 앱으로 바꿔 같은 번들 ID의 업데이트로 출시합니다.
- 디자인 토큰은 Figma 변수 한 곳에서 시작해 SwiftUI·React Native·웹 랜딩이 같은 값을 씁니다.

## 구조

| 경로 | 내용 |
|---|---|
| `tokens/` | Figma 변수 원본 내보내기(`figma-variables.json`)와 정리된 토큰(`pado.tokens.json`) |
| `tools/` | 토큰 생성기, Figma 내보내기 스크립트 |
| `Packages/PADODesignSystem` | SwiftUI 디자인 시스템(SPM) — 토큰, 타이포, 컴포넌트, 미리보기 카탈로그 |
| `App/` | 앱 타깃 (TCA + Swift Concurrency) |

## 개발

- Xcode 26 이상, Swift 6
- 프로젝트 파일은 [XcodeGen](https://github.com/yonaskolb/XcodeGen)으로 생성합니다: `xcodegen`

## 브랜치 규칙

- 기능마다 `feat/…` 브랜치 → PR → 리뷰 후 머지
- 커밋 메시지: `type :: 설명` (예: `feat :: 지도 핀 미리보기 시트`)
