import SwiftUI

/// 아래에서 올라오는 시트의 겉모양 — Figma: Pin sheet (card, 위 모서리 32, line 테두리, 여백 20/36)
///
/// topInset: 시트 위로 걸쳐 놓는 요소(예: 디스크)가 들어갈 공간. 핀 미리보기는 72.
/// 등장 애니메이션은 화면 쪽에서 정한다 (튕김 없이 ease-out).
public struct PADOSheet<Content: View>: View {
  let topInset: CGFloat
  let content: Content

  public init(topInset: CGFloat = 24, @ViewBuilder content: () -> Content) {
    self.topInset = topInset
    self.content = content()
  }

  public var body: some View {
    let shape = UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32)
    content
      .padding(.top, topInset)
      .padding(.horizontal, 20)
      .padding(.bottom, 36)
      .frame(maxWidth: .infinity)
      .background(T.Color.card, in: shape)
      .overlay(shape.stroke(T.Color.line, lineWidth: 1))
  }
}

/// 하단 탭 — Figma: B/Dock (370×68, 모서리 34, 가운데 드랍 버튼 52)
public struct PADODock: View {
  public enum Tab: String, CaseIterable, Sendable {
    case map, playlists, notifications, profile

    var icon: PADOIcon {
      switch self {
      case .map: .map
      case .playlists: .playlist
      case .notifications: .bell
      case .profile: .user
      }
    }

    var title: String {
      switch self {
      case .map: "지도"
      case .playlists: "플리"
      case .notifications: "알림"
      case .profile: "프로필"
      }
    }
  }

  let selection: Tab
  let hasUnread: Bool
  let onSelect: (Tab) -> Void
  let onDrop: () -> Void

  public init(selection: Tab, hasUnread: Bool = false, onSelect: @escaping (Tab) -> Void, onDrop: @escaping () -> Void) {
    self.selection = selection
    self.hasUnread = hasUnread
    self.onSelect = onSelect
    self.onDrop = onDrop
  }

  public var body: some View {
    HStack(spacing: 0) {
      item(.map)
      item(.playlists)
      Button(action: onDrop) {
        PADOIconView(.plus, size: 26, color: T.Color.onPrimary)
          .frame(width: 52, height: 52)
          .background(T.Color.primary, in: Circle())
          .shadow(color: T.Color.glow.opacity(0.19), radius: 10)
      }
      .buttonStyle(PADOPressStyle())
      .frame(maxWidth: .infinity)
      .accessibilityLabel("드랍하기")
      item(.notifications)
      item(.profile)
    }
    .padding(.horizontal, 8)
    .frame(height: 68)
    .background(.ultraThinMaterial, in: Capsule())
    .background(T.Color.card.opacity(0.85), in: Capsule())
    .overlay(Capsule().strokeBorder(T.Color.line, lineWidth: 1))
    .shadow(color: T.Color.glow.opacity(0.09), radius: 16, y: 12)
  }

  private func item(_ tab: Tab) -> some View {
    let on = tab == selection
    return Button { onSelect(tab) } label: {
      VStack(spacing: 4) {
        PADOIconView(tab.icon, size: 24, color: on ? T.Color.primary : T.Color.ink3)
          .overlay(alignment: .topTrailing) {
            if tab == .notifications && hasUnread {
              Circle().fill(T.Color.primary).overlay(Circle().stroke(T.Color.card, lineWidth: 1.5)).frame(width: 7, height: 7)
            }
          }
        Circle().fill(on ? T.Color.primary : .clear).frame(width: 4, height: 4)
      }
      .frame(maxWidth: .infinity, minHeight: 44)
    }
    .buttonStyle(PADOPressStyle())
    .accessibilityLabel(tab.title)
    .accessibilityAddTraits(on ? .isSelected : [])
  }
}
