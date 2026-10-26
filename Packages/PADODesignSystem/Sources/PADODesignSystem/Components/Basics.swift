import SwiftUI

typealias T = PADOTokens

/// Figma 아이콘(24 그리드)을 원하는 크기·색으로. 서비스 로고는 원본 색을 유지한다.
public struct PADOIconView: View {
  let icon: PADOIcon
  let size: CGFloat
  let color: Color

  public init(_ icon: PADOIcon, size: CGFloat = 24, color: Color = PADOTokens.Color.ink) {
    self.icon = icon
    self.size = size
    self.color = color
  }

  public var body: some View {
    icon.image
      .resizable()
      .renderingMode(icon.isBrand ? .original : .template)
      .frame(width: size, height: size)
      .foregroundStyle(color)
      .accessibilityHidden(true)
  }
}

/// 드랍 종류 — 지도 핀 모양, 태그 글자, 아이콘이 여기서 정해진다.
public enum PADODropKind: String, CaseIterable, Sendable {
  case music, vote, playlist

  public var tagTitle: String {
    switch self {
    case .music: "MUSIC"
    case .vote: "VOTE"
    case .playlist: "PLAYLIST"
    }
  }

  public var icon: PADOIcon {
    switch self {
    case .music: .music
    case .vote: .vote
    case .playlist: .playlist
    }
  }
}

/// 음악 서비스 — '전체 듣기' 버튼의 로고
public enum PADOMusicService: String, CaseIterable, Sendable {
  case spotify, appleMusic, youtubeMusic

  public var icon: PADOIcon {
    switch self {
    case .spotify: .spotify
    case .appleMusic: .appleMusic
    case .youtubeMusic: .youtubeMusic
    }
  }

  public var name: String {
    switch self {
    case .spotify: "Spotify"
    case .appleMusic: "Apple Music"
    case .youtubeMusic: "YouTube Music"
    }
  }
}

/// 앨범 아트. 이미지가 없으면 하늘빛 바탕에 음표.
public struct PADOArt: View {
  let image: Image?
  let size: CGFloat

  public init(_ image: Image?, size: CGFloat) {
    self.image = image
    self.size = size
  }

  public var body: some View {
    Group {
      if let image {
        image.resizable().scaledToFill()
      } else {
        LinearGradient(colors: [T.Color.primarySoft, T.Color.card], startPoint: .topLeading, endPoint: .bottomTrailing)
          .overlay(PADOIconView(.music, size: size * 0.38, color: T.Color.ink3))
      }
    }
    .frame(width: size, height: size)
    .clipShape(Circle())
  }
}

/// 사람 프로필 — 사진이 없으면 이름 첫 글자
public struct PADOAvatar: View {
  let name: String
  let image: Image?
  let size: CGFloat

  public init(name: String, image: Image? = nil, size: CGFloat = 22) {
    self.name = name
    self.image = image
    self.size = size
  }

  public var body: some View {
    ZStack {
      Circle().fill(T.Color.page)
      if let image {
        image.resizable().scaledToFill().clipShape(Circle())
      } else {
        Text(String(name.prefix(1)))
          .font(.custom("Pretendard-SemiBold", size: size * 0.45))
          .foregroundStyle(T.Color.accent)
      }
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}
