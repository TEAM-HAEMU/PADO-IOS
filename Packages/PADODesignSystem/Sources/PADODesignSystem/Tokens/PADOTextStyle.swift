import SwiftUI

/// Figma 텍스트 스타일 하나 (예: text/Title = Pretendard Bold 22/30, 자간 -2%).
/// 값은 `PADOTokens.generated.swift`에서 만들어지고, 화면에서는 `.padoText(_:)`로 적용한다.
public struct PADOTextStyle: Sendable, Hashable, Identifiable {
  public let name: String
  public let family: String
  /// CSS 굵기 (400 Regular, 500 Medium, 600 SemiBold, 700 Bold)
  public let weight: Int
  public let size: CGFloat
  /// nil이면 글꼴 기본 줄 높이 (Figma "Auto")
  public let lineHeight: CGFloat?
  /// 포인트 단위 (Figma 퍼센트 값을 글자 크기 기준으로 바꾼 값)
  public let letterSpacing: CGFloat

  public var id: String { name }

  public init(name: String, family: String, weight: Int, size: CGFloat, lineHeight: CGFloat?, letterSpacing: CGFloat) {
    self.name = name
    self.family = family
    self.weight = weight
    self.size = size
    self.lineHeight = lineHeight
    self.letterSpacing = letterSpacing
  }

  /// 번들된 Pretendard의 PostScript 이름 (예: "Pretendard-SemiBold")
  public var postScriptName: String {
    let suffix: String
    switch weight {
    case ..<450: suffix = "Regular"
    case ..<550: suffix = "Medium"
    case ..<650: suffix = "SemiBold"
    default: suffix = "Bold"
    }
    return "\(family)-\(suffix)"
  }
}
