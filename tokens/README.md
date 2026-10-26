# 디자인 토큰

Figma 변수 한 곳에서 시작해 iOS(SwiftUI), Android(React Native), 웹 랜딩이 같은 값을 쓰게 하는 파이프라인입니다.

```
Figma "PADO Theme" 변수 + 텍스트 스타일
        │  tools/figma/export-variables.js  (Figma 플러그인/MCP에서 실행)
        ▼
tokens/figma-variables.json   ← 원본 그대로 (모드 10개 전부)
tokens/code-only.json         ← Figma에 아직 없는 토큰 (간격)
        │  npm run tokens  (tools/tokens/build.mjs)
        ▼
tokens/pado.tokens.json       ← 정리된 토큰 (선택한 모드 하나, W3C Design Tokens 형식)
 ├─ Packages/PADODesignSystem/…/PADOTokens.generated.swift   (SwiftUI)
 ├─ generated/react-native/tokens.ts                          (RN)
 └─ generated/web/tokens.css                                  (웹 CSS 변수)
```

## 쓰는 법

```bash
npm run tokens                         # 기본 모드 "J · 스카이 퓨어"
TOKENS_MODE="B · Deep" npm run tokens  # 다른 모드로
npm run test:tokens                    # 변환 규칙 테스트
npm run tokens:drift -- ../PADO-CLIENT/src/theme/tokens.ts   # 다른 코드의 색이 Figma와 다른지 확인
```

## 변환 규칙

| Figma | 코드 |
|---|---|
| `color/card-2` | `card2` (마지막 이름을 camelCase로) |
| 색 `#RRGGBB(AA)` | Swift `Color(.sRGB, …)`, TS 문자열, CSS 변수 |
| 자간 `-2%` | 글자 크기 기준 포인트 (22pt × -2% = -0.44pt) |
| 줄 높이 `Auto` | `nil` / `normal` (글꼴 기본값) |
| 글꼴 스타일 `SemiBold` | 굵기 600 → `Pretendard-SemiBold` |

생성 파일은 직접 고치지 않습니다. Figma를 고치고 다시 내보낸 뒤 `npm run tokens`를 실행하세요.
