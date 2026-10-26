import SwiftUI

/// 물방울 핀 모양 — Figma B/Drop Pin 벡터(48×61.44)를 그대로 옮긴 경로
public struct PADODropShape: Shape {
  public init() {}

  public func path(in rect: CGRect) -> Path {
    let sx = rect.width / 48, sy = rect.height / 61.44
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy) }
    var path = Path()
    path.move(to: p(24, 61.44))
    path.addCurve(to: p(0, 24), control1: p(18.24, 51.84), control2: p(0, 41.28))
    path.addCurve(to: p(7.0294, 7.0294), control1: p(0, 17.6348), control2: p(2.5286, 11.5303))
    path.addCurve(to: p(24, 0), control1: p(11.5303, 2.5286), control2: p(17.6348, 0))
    path.addCurve(to: p(40.9706, 7.0294), control1: p(30.3652, 0), control2: p(36.4697, 2.5286))
    path.addCurve(to: p(48, 24), control1: p(45.4714, 11.5303), control2: p(48, 17.6348))
    path.addCurve(to: p(24, 61.44), control1: p(48, 41.28), control2: p(29.76, 51.84))
    path.closeSubpath()
    return path
  }
}

/// 지도 핀 — Figma: B/Drop Pin/Music · Vote · Playlist · Far, Music Active
public struct PADODropPin: View {
  public enum Content {
    case music(art: Image?)
    case vote
    case playlist(arts: [Image?], count: Int)
  }

  let content: Content
  let isActive: Bool
  let title: String?
  let subtitle: String?

  /// isActive면 핀이 커지고 옆에 제목 칩이 붙는다 (지금 재생/선택 중인 드랍)
  public init(_ content: Content, isActive: Bool = false, title: String? = nil, subtitle: String? = nil) {
    self.content = content
    self.isActive = isActive
    self.title = title
    self.subtitle = subtitle
  }

  private var dropWidth: CGFloat { isActive ? 60 : (isVote ? 40 : 48) }
  private var isVote: Bool { if case .vote = content { true } else { false } }

  public var body: some View {
    HStack(alignment: .top, spacing: 6) {
      pin
      if isActive, let title {
        VStack(alignment: .leading, spacing: 1) {
          Text(title).padoText(T.Typography.captionStrong).foregroundStyle(T.Color.ink)
          if let subtitle { Text(subtitle).padoText(T.Typography.label).foregroundStyle(T.Color.ink3) }
        }
        .padding(EdgeInsets(top: 7, leading: 12, bottom: 8, trailing: 14))
        .background(T.Color.page, in: RoundedRectangle(cornerRadius: T.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: T.Radius.md).strokeBorder(T.Color.line, lineWidth: 1))
        .padding(.top, 10)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private var pin: some View {
    let w = dropWidth, h = w * 61.44 / 48
    return VStack(spacing: -h * 0.12) {
      ZStack(alignment: .top) {
        PADODropShape()
          .fill(T.Color.page)
          .overlay(PADODropShape().stroke(T.Color.primary, lineWidth: isActive ? 2 : 1.6))
          .frame(width: w, height: h)
          .shadow(color: T.Color.glow.opacity(isActive ? 0.3 : 0.2), radius: isActive ? 11 : 7)
        inner(w)
          .padding(.top, w / 12)
        if case let .playlist(_, count) = content {
          Text("\(count)곡")
            .padoText(T.Typography.label)
            .foregroundStyle(T.Color.onPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(T.Color.primary, in: Capsule())
            .offset(x: w * 0.55, y: -4)
        }
      }
      ripples(w)
    }
  }

  @ViewBuilder private func inner(_ w: CGFloat) -> some View {
    switch content {
    case let .music(art):
      PADOArt(art, size: w * 40 / 48)
    case .vote:
      PADOIconView(.vote, size: 18, color: T.Color.primary).padding(.top, 6)
    case let .playlist(arts, _):
      let cell = w * 20 / 48
      VStack(spacing: 0) {
        ForEach(0..<2, id: \.self) { r in
          HStack(spacing: 0) {
            ForEach(0..<2, id: \.self) { c in
              let i = r * 2 + c
              Group {
                if i < arts.count, let art = arts[i] { art.resizable().scaledToFill() } else { T.Color.primarySoft }
              }
              .frame(width: cell, height: cell)
              .clipped()
            }
          }
        }
      }
      .clipShape(Circle())
    }
  }

  private func ripples(_ w: CGFloat) -> some View {
    ZStack {
      Ellipse().stroke(T.Color.primary.opacity(0.5), lineWidth: 1.2).frame(width: w * 44 / 48, height: w * 15 / 48)
      Ellipse().stroke(T.Color.primary.opacity(0.7), lineWidth: 1.2).frame(width: w * 24 / 48, height: w * 8.2 / 48)
      Ellipse().fill(T.Color.primary).frame(width: w * 12 / 48, height: w * 4 / 48)
    }
  }
}

/// 멀리 있는 드랍 — 작은 점과 물결. Figma: B/Drop Pin/Far (24×16)
public struct PADOFarPin: View {
  public init() {}

  public var body: some View {
    ZStack {
      Ellipse().stroke(T.Color.primary.opacity(0.6), lineWidth: 1.2).frame(width: 22, height: 7.5)
      Circle().fill(T.Color.primary).frame(width: 8, height: 8).shadow(color: T.Color.primary.opacity(0.8), radius: 4)
    }
    .frame(width: 24, height: 16)
    .accessibilityHidden(true)
  }
}

/// 내 위치 — Figma: B/Me (18 점, 4 테두리)
public struct PADOMeMarker: View {
  public init() {}

  public var body: some View {
    Circle()
      .fill(T.Color.ink)
      .overlay(Circle().strokeBorder(T.Color.page, lineWidth: 4))
      .frame(width: 22, height: 22)
      .shadow(color: T.Color.glow.opacity(0.4), radius: 8)
      .accessibilityLabel("내 위치")
  }
}

/// '가까운 드랍' 줄의 한 칸 — Figma: Nearby row item (아트 50, 고리 60, 폭 66)
public struct PADONearbyItem: View {
  let title: String
  let artist: String
  let art: Image?
  let isNear: Bool

  /// isNear가 false면 1km 밖이라 흐리게 (Figma: 고리 line, 제목 ink-3)
  public init(title: String, artist: String, art: Image?, isNear: Bool = true) {
    self.title = title
    self.artist = artist
    self.art = art
    self.isNear = isNear
  }

  public var body: some View {
    VStack(spacing: 6) {
      PADOArt(art, size: 50)
        .frame(width: 60, height: 60)
        .overlay(Circle().strokeBorder(isNear ? T.Color.accent2 : T.Color.line, lineWidth: isNear ? 2 : 1.5))
        .shadow(color: T.Color.glow.opacity(isNear ? 0.21 : 0), radius: 7)
      Text(title).padoText(T.Typography.captionStrong).foregroundStyle(isNear ? T.Color.ink : T.Color.ink3).lineLimit(1)
      Text(artist).padoText(T.Typography.label).foregroundStyle(T.Color.ink3).lineLimit(1)
    }
    .frame(width: 66)
    .accessibilityElement(children: .combine)
  }
}
