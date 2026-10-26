# PADODesignSystem

PADO iOS의 SwiftUI 디자인 시스템 패키지(SPM)입니다. 값은 전부 Figma에서 나온 토큰(`PADOTokens`)을 쓰고, 컴포넌트는 Figma 화면 실측 치수를 따릅니다.

## 구성

| 폴더 | 내용 |
|---|---|
| `Tokens/` | `PADOTokens.generated.swift`(생성), `PADOTextStyle` |
| `Typography/` | Pretendard 등록, `.padoText(_:)` (Figma 줄 높이·자간 적용) |
| `Icons/` | `PADOIcon.generated.swift` — Figma 아이콘 22개 (SVG 벡터 에셋) |
| `Components/` | 버튼, 태그, 한마디 카드, 미리듣기 줄, 디스크, 지도 핀, 시트, 하단 탭, 핀 미리보기 카드 |
| `Catalog/` | `PADOCatalog` — 토큰·컴포넌트 전체를 한 화면에서 보는 미리보기 |

## 쓰는 법

```swift
import PADODesignSystem

PADOFonts.register()   // 앱 시작 시 한 번

Text("난춘").padoText(PADOTokens.Typography.display).foregroundStyle(PADOTokens.Color.ink)
PADOPreviewBar(isPlaying: true, progress: 0.4, timeText: "0:26") { /* 재생/정지 */ }
```

## 규칙

- 컴포넌트는 상태를 갖지 않습니다. 재생 여부, 진행률, 누를 때 할 일은 바깥(TCA 기능)에서 넘겨줍니다.
- 색·간격·반경은 토큰만 씁니다. 예외는 브랜드 규정 색(카카오 노랑)뿐이고 코드에 이유를 적어 둡니다.
- 애니메이션은 튕기지 않는 ease-out만 씁니다.

## 테스트

```bash
xcodebuild -scheme PADODesignSystem -destination 'platform=iOS Simulator,name=iPhone 17' test
```

- `FigmaSpecTests`: 컴포넌트를 배치한 크기가 Figma 프레임 크기와 같은지 (예: 한마디 카드 360×104)
- `ComponentSnapshotTests`: 모양 회귀 테스트. 기준 이미지는 `__Snapshots__/`. 의도한 변경이면 기준 이미지를 지우고 다시 실행하면 새로 찍힙니다.
- `TokenTests`: 생성된 토큰 값
