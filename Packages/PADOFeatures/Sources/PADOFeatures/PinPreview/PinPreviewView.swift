import ComposableArchitecture
import PADODesignSystem
import PADOKit
import SwiftUI

/// 핀 미리보기 시트 화면. 재생 상태는 지도의 재생기(player)에서 받는다.
struct PinPreviewView: View {
  let store: StoreOf<PinPreviewFeature>
  let player: PlayerFeature.State

  var body: some View {
    let s = store.state
    RemoteArt(url: s.song?.albumImagePath ?? s.summary.imageURL) { art in
      PADOPinPreviewCard(
        model: .init(
          kind: .music,
          address: s.summary.address,
          title: s.track?.title ?? s.summary.title,
          artist: s.track?.artist ?? s.summary.subtitle,
          author: s.detail?.username ?? " ",
          time: s.detail.map { Self.timeLabel($0.createdAt) } ?? " ",
          note: s.detail?.content ?? s.summary.content,
          likes: s.stats?.likes ?? 0,
          comments: s.stats?.comments ?? 0,
          service: .spotify
        ),
        art: art,
        isPlaying: player.isPlaying(s.track?.id),
        progress: player.track?.id == s.track?.id ? player.progress : 0,
        timeText: player.track?.id == s.track?.id ? player.timeText : "0:30",
        actions: .init(
          togglePreview: { store.send(.playTapped) },
          like: {},          // 2단계: 로그인 후 좋아요
          openComments: {},  // 2단계: 댓글
          listen: { store.send(.listenTapped) },
          more: {}           // 2단계: 신고·차단
        )
      )
    }
    .task { await store.send(.task).finish() }
    .overlay {
      if let message = s.errorMessage {
        Text(message)
          .padoText(PADOTokens.Typography.captionStrong)
          .foregroundStyle(PADOTokens.Color.caution)
          .padding(12)
          .background(PADOTokens.Color.page, in: Capsule())
      }
    }
  }

  /// "2026-10-26T09:40:00Z" → "10월 26일 18:40" (기기 시간대)
  static func timeLabel(_ iso: String) -> String {
    let parser = ISO8601DateFormatter()
    guard let date = parser.date(from: iso) ?? parser.date(from: iso + "Z") else { return "" }
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.dateFormat = "M월 d일 HH:mm"
    return f.string(from: date)
  }
}
