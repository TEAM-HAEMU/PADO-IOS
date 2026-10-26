import SwiftUI

/// Figma 글자 명세(크기·굵기·줄 높이·자간)를 그대로 적용한다.
///
/// SwiftUI에는 "줄 높이" 속성이 없어서, 글꼴 기본 줄 높이와 Figma 줄 높이의 차이를
/// 줄 사이 간격(lineSpacing) + 위아래 여백으로 나눠 채운다. 한 줄일 때 박스 높이가 Figma와 같아진다.
struct PADOTextModifier: ViewModifier {
  let style: PADOTextStyle

  func body(content: Content) -> some View {
    let natural = PADOFonts.naturalLineHeight(style)
    let extra = max(0, (style.lineHeight ?? natural) - natural)
    content
      .font(PADOFonts.font(style))
      .tracking(style.letterSpacing)
      .lineSpacing(extra)
      .padding(.vertical, extra / 2)
  }
}

public extension View {
  /// 예: `Text("난춘").padoText(PADOTokens.Typography.display)`
  func padoText(_ style: PADOTextStyle) -> some View {
    modifier(PADOTextModifier(style: style))
  }
}
