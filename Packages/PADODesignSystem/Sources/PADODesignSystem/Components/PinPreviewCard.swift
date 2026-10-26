import SwiftUI

/// 핀 미리보기 시트 내용 — Figma: J 2.2 핀 미리보기의 Pin sheet (간격 16)
///
/// 상태를 갖지 않는 조립품이다. 재생 여부·진행률·누를 때 할 일은 화면(TCA 기능)이 넘겨준다.
public struct PADOPinPreviewCard: View {
  public struct Model: Equatable, Sendable {
    public var kind: PADODropKind
    public var address: String
    public var title: String
    public var artist: String
    public var author: String
    public var time: String
    public var note: String
    public var likes: Int
    public var comments: Int
    public var service: PADOMusicService

    public init(kind: PADODropKind, address: String, title: String, artist: String, author: String, time: String, note: String, likes: Int, comments: Int, service: PADOMusicService) {
      self.kind = kind
      self.address = address
      self.title = title
      self.artist = artist
      self.author = author
      self.time = time
      self.note = note
      self.likes = likes
      self.comments = comments
      self.service = service
    }
  }

  public struct Actions {
    public var togglePreview: () -> Void
    public var like: () -> Void
    public var openComments: () -> Void
    public var listen: () -> Void
    public var more: () -> Void

    public init(togglePreview: @escaping () -> Void = {}, like: @escaping () -> Void = {}, openComments: @escaping () -> Void = {}, listen: @escaping () -> Void = {}, more: @escaping () -> Void = {}) {
      self.togglePreview = togglePreview
      self.like = like
      self.openComments = openComments
      self.listen = listen
      self.more = more
    }
  }

  let model: Model
  let art: Image?
  let isPlaying: Bool
  let progress: Double
  let timeText: String
  let actions: Actions

  public init(model: Model, art: Image?, isPlaying: Bool, progress: Double, timeText: String, actions: Actions = .init()) {
    self.model = model
    self.art = art
    self.isPlaying = isPlaying
    self.progress = progress
    self.timeText = timeText
    self.actions = actions
  }

  public var body: some View {
    PADOSheet(topInset: 72) {
      VStack(spacing: 16) {
        HStack(spacing: 8) {
          PADOTag(model.kind)
          PADOMetaLabel(.pin, model.address)
        }
        PADOSongTitle(title: model.title, artist: model.artist)
        PADONoteCard(author: model.author, time: model.time, text: model.note)
        PADOPreviewBar(isPlaying: isPlaying, progress: progress, timeText: timeText, onToggle: actions.togglePreview)
        HStack(spacing: 10) {
          PADOCountPill(.heart, count: model.likes, label: "좋아요", action: actions.like)
          PADOCountPill(.comment, count: model.comments, label: "댓글", action: actions.openComments)
          PADOListenButton(service: model.service, action: actions.listen)
        }
      }
    }
    .overlay(alignment: .top) {
      PADODisc(art: art).offset(y: -56)
    }
    .overlay(alignment: .topTrailing) {
      Button(action: actions.more) { PADOIconView(.more, size: 20, color: T.Color.ink2).frame(width: 44, height: 44) }
        .buttonStyle(PADOPressStyle())
        .accessibilityLabel("더보기")
        .padding(.top, 4)
        .padding(.trailing, 6)
    }
  }
}

public extension PADOPinPreviewCard.Model {
  /// Figma 시안과 같은 예시 (미리보기·스냅샷 테스트용)
  static let sample = Self(kind: .music, address: "부산 강서구 가락대로 1397번길", title: "난춘", artist: "새소년", author: "하윤", time: "9월 21일 18:40", note: "퇴근길 버스 기다리면서 듣기 좋은 노래.\n강바람이랑 진짜 잘 어울려요.", likes: 18, comments: 4, service: .spotify)
}

#Preview("핀 미리보기") {
  ZStack(alignment: .bottom) {
    PADOTokens.Color.card2.ignoresSafeArea()
    PADOPinPreviewCard(model: .sample, art: nil, isPlaying: true, progress: 0.38, timeText: "0:26")
  }
}
