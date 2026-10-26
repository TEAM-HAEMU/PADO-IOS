import SwiftUI

/// 누를 때 살짝 옅어지는 기본 반응 (튕기는 애니메이션은 쓰지 않는다)
struct PADOPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.6 : 1)
      .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
  }
}

/// 넓은 버튼 — Figma: 로그인 화면 버튼 (높이 54, 모서리 20, 여백 16/20, 아이콘 간격 10)
public struct PADOButton: View {
  public enum Style: Sendable {
    /// 하늘빛 채움 + 흰 글자
    case primary
    /// card 채움 + line 테두리 + ink 글자 (예: 이메일로 계속하기)
    case secondary
    /// 카카오 노랑 (#FEE500, 글자 검정 85%) — 카카오 브랜드 규정 색이라 토큰이 아닌 고정값
    case kakao
  }

  let title: String
  let icon: PADOIcon?
  let style: Style
  let action: () -> Void

  public init(_ title: String, icon: PADOIcon? = nil, style: Style = .primary, action: @escaping () -> Void) {
    self.title = title
    self.icon = icon
    self.style = style
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        if let icon { PADOIconView(icon, size: 20, color: foreground) }
        Text(title).padoText(T.Typography.bodyStrong)
      }
      .foregroundStyle(foreground)
      .frame(maxWidth: .infinity, minHeight: 54)
      .padding(.horizontal, 20)
      .background(background, in: RoundedRectangle(cornerRadius: 20))
      .overlay {
        if style == .secondary { RoundedRectangle(cornerRadius: 20).strokeBorder(T.Color.line, lineWidth: 1) }
      }
      .contentShape(RoundedRectangle(cornerRadius: 20))
    }
    .buttonStyle(PADOPressStyle())
  }

  private var foreground: Color {
    switch style {
    case .primary: T.Color.onPrimary
    case .secondary: T.Color.ink
    case .kakao: .black.opacity(0.85)
    }
  }

  private var background: Color {
    switch style {
    case .primary: T.Color.primary
    case .secondary: T.Color.card
    case .kakao: Color(.sRGB, red: 254 / 255, green: 229 / 255, blue: 0, opacity: 1)
    }
  }
}

/// 아이콘 + 숫자 알약 (좋아요·댓글) — Figma: 높이 48, 여백 14/16/14/14, 간격 6
public struct PADOCountPill: View {
  let icon: PADOIcon
  let count: Int
  let label: String
  let action: () -> Void

  /// label: 보이스오버용 이름 (예: "좋아요")
  public init(_ icon: PADOIcon, count: Int, label: String, action: @escaping () -> Void) {
    self.icon = icon
    self.count = count
    self.label = label
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        PADOIconView(icon, size: 20, color: T.Color.ink)
        // Figma처럼 비례폭 숫자 (고정폭이면 "18"이 2pt 넓어진다 — FigmaSpecTests)
        Text("\(count)")
          .padoText(T.Typography.number)
          .foregroundStyle(T.Color.ink)
      }
      .padding(.vertical, 14)
      .padding(.leading, 14)
      .padding(.trailing, 16)
      .background(T.Color.card2, in: Capsule())
    }
    .buttonStyle(PADOPressStyle())
    .accessibilityLabel("\(label) \(count)")
  }
}

/// '전체 듣기' — 고른 음악 앱으로 넘어가는 버튼. Figma: CTA (높이 52, card-2 + line 테두리, 로고 20, ↗ 16)
public struct PADOListenButton: View {
  let service: PADOMusicService
  let title: String
  let action: () -> Void

  public init(service: PADOMusicService, title: String = "전체 듣기", action: @escaping () -> Void) {
    self.service = service
    self.title = title
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        PADOIconView(service.icon, size: 20)
        Text(title)
          .padoText(T.Typography.bodyStrong)
          .foregroundStyle(T.Color.ink)
        PADOIconView(.external, size: 16, color: T.Color.ink2)
      }
      .frame(maxWidth: .infinity, minHeight: 52)
      .background(T.Color.card2, in: Capsule())
      .overlay(Capsule().strokeBorder(T.Color.line, lineWidth: 1))
    }
    .buttonStyle(PADOPressStyle())
    .accessibilityLabel("\(service.name)에서 \(title)")
  }
}

/// 원형 재생 버튼 — Figma: 48, primary, 그림자(blur 18, 17%)
///
/// Figma 그림자 blur 값은 SwiftUI `shadow(radius:)`의 약 2배라 반으로 나눠 쓴다.
public struct PADOPlayButton: View {
  let isPlaying: Bool
  let size: CGFloat
  let action: () -> Void

  public init(isPlaying: Bool, size: CGFloat = 48, action: @escaping () -> Void) {
    self.isPlaying = isPlaying
    self.size = size
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      PADOIconView(isPlaying ? .pause : .play, size: size * 20 / 48, color: T.Color.onPrimary)
        .frame(width: size, height: size)
        .background(T.Color.primary, in: Circle())
        .shadow(color: T.Color.glow.opacity(0.17), radius: 9)
    }
    .buttonStyle(PADOPressStyle())
    .accessibilityLabel(isPlaying ? "일시정지" : "미리듣기 재생")
  }
}
