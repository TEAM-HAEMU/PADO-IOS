import Testing
@testable import PADODesignSystem

@Suite("디자인 토큰")
struct TokenTests {
  @Test("Figma J 모드 값이 생성 코드에 그대로 들어간다")
  func generatedValues() {
    #expect(PADOTokens.colorNames.count == 21) // Figma 20 + 코드 전용 glow
    #expect(PADOTokens.colorNames.contains { $0 == ("primary", "#4F97F2") })
    #expect(PADOTokens.Radius.lg == 22)
    #expect(PADOTokens.Typography.title.size == 22)
    #expect(PADOTokens.Typography.title.lineHeight == 30)
    #expect(PADOTokens.Typography.title.letterSpacing == -0.44)
    #expect(PADOTokens.Typography.displayStrong.lineHeight == nil)
  }

  @Test("굵기에 맞는 Pretendard 이름", arguments: [(400, "Pretendard-Regular"), (500, "Pretendard-Medium"), (600, "Pretendard-SemiBold"), (700, "Pretendard-Bold")])
  func postScriptName(weight: Int, expected: String) {
    let style = PADOTextStyle(name: "t", family: "Pretendard", weight: weight, size: 16, lineHeight: nil, letterSpacing: 0)
    #expect(style.postScriptName == expected)
  }
}
