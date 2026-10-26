import SwiftUI

/// 드랍 종류 태그 — Figma: 핀 미리보기 상단 "♪ MUSIC" (높이 20, 좌우 8, 아이콘 12, 자간 6%)
public struct PADOTag: View {
  let kind: PADODropKind

  public init(_ kind: PADODropKind) { self.kind = kind }

  public var body: some View {
    HStack(spacing: 4) {
      PADOIconView(kind.icon, size: 12, color: T.Color.primary)
      Text(kind.tagTitle)
        .padoText(T.Typography.labelWide)
        .foregroundStyle(T.Color.primary)
    }
    .padding(.vertical, 3)
    .padding(.horizontal, 8)
    .background(T.Color.primarySoft, in: Capsule())
    .accessibilityElement(children: .combine)
    .accessibilityLabel(kind.tagTitle)
  }
}

/// 아이콘 + 짧은 정보 (주소, 거리 등) — Figma: "📍 부산 강서구 가락대로 1397번길"
public struct PADOMetaLabel: View {
  let icon: PADOIcon
  let text: String

  public init(_ icon: PADOIcon, _ text: String) {
    self.icon = icon
    self.text = text
  }

  public var body: some View {
    HStack(spacing: 4) {
      PADOIconView(icon, size: 12, color: T.Color.ink2)
      Text(text)
        .padoText(T.Typography.caption)
        .foregroundStyle(T.Color.ink2)
        .lineLimit(1)
    }
    .accessibilityElement(children: .combine)
  }
}

/// 곡 제목 + 아티스트 (가운데 정렬) — Figma: "난춘 / 새소년" (30/38 Bold, 15/22)
public struct PADOSongTitle: View {
  let title: String
  let artist: String

  public init(title: String, artist: String) {
    self.title = title
    self.artist = artist
  }

  public var body: some View {
    VStack(spacing: 2) {
      Text(title)
        .padoText(T.Typography.display)
        .foregroundStyle(T.Color.ink)
        .lineLimit(1)
      Text(artist)
        .padoText(T.Typography.body)
        .foregroundStyle(T.Color.ink2)
        .lineLimit(1)
    }
    .multilineTextAlignment(.center)
    .accessibilityElement(children: .combine)
  }
}

/// 드랍에 남긴 한마디 — Figma: Note (배경 card-2, 모서리 14, 여백 14/16)
public struct PADONoteCard: View {
  let author: String
  let time: String
  let text: String
  let avatar: Image?

  public init(author: String, time: String, text: String, avatar: Image? = nil) {
    self.author = author
    self.time = time
    self.text = text
    self.avatar = avatar
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        PADOAvatar(name: author, image: avatar, size: 22)
        Text(author)
          .padoText(T.Typography.captionStrong)
          .foregroundStyle(T.Color.ink)
        Text(time)
          .padoText(T.Typography.number)
          .foregroundStyle(T.Color.ink3)
      }
      Text(text)
        .padoText(T.Typography.body)
        .foregroundStyle(T.Color.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 14)
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(T.Color.card2, in: RoundedRectangle(cornerRadius: T.Radius.md))
    .accessibilityElement(children: .combine)
  }
}
