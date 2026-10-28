import ComposableArchitecture
import Foundation
import PADOKit

/// 재생 중인 곡 (미리듣기를 찾는 데 필요한 정보만)
public struct Track: Equatable, Identifiable, Sendable {
  /// 곡 ID — 같은 곡인지 판단하는 기준
  public var id: String
  public var title: String
  public var artist: String
  public var artURL: URL?

  public init(id: String, title: String, artist: String, artURL: URL?) {
    self.id = id
    self.title = title
    self.artist = artist
    self.artURL = artURL
  }
}

/// 30초 미리듣기 재생기.
///
/// 지도(MapFeature)가 들고 있어서 핀 미리보기 시트를 닫아도 계속 재생된다.
/// 규칙: 같은 곡을 다시 누르면 일시정지/이어듣기, 다른 곡을 누르면 앞 곡을 멈추고 새로 튼다.
@Reducer
public struct PlayerFeature {
  @ObservableState
  public struct State: Equatable {
    public enum Status: Equatable, Sendable {
      case idle
      /// 미리듣기 주소를 찾는 중
      case loading
      case playing
      case paused
      /// iTunes에 미리듣기가 없는 곡
      case unavailable
    }

    public var track: Track?
    public var status: Status = .idle
    public var elapsed: Double = 0
    public var duration: Double = 30

    public init(track: Track? = nil, status: Status = .idle, elapsed: Double = 0, duration: Double = 30) {
      self.track = track
      self.status = status
      self.elapsed = elapsed
      self.duration = duration
    }

    public var progress: Double { duration > 0 ? min(elapsed / duration, 1) : 0 }
    public var isPlaying: Bool { status == .playing || status == .loading }

    /// 남은 시간 "0:26" (Figma 미리듣기 줄 표기)
    public var timeText: String {
      let left = max(0, Int((duration - elapsed).rounded(.up)))
      return "\(left / 60):" + String(format: "%02d", left % 60)
    }

    /// 이 곡이 지금 재생 상태인지 — 미리보기 카드의 재생 버튼 모양에 쓴다
    public func isPlaying(_ trackId: String?) -> Bool { trackId != nil && track?.id == trackId && isPlaying }
  }

  public enum Action: Sendable {
    /// 재생 버튼 — 같은 곡이면 일시정지/이어듣기, 다른 곡이면 새로 재생
    case toggle(Track)
    case stop
    case previewResolved(URL?)
    case playerEvent(AudioPlayerClient.Event)
  }

  @Dependency(\.previewClient) var previewClient
  @Dependency(\.audioPlayer) var audioPlayer

  enum CancelID { case playback }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .toggle(track):
        if state.track?.id == track.id {
          switch state.status {
          case .playing:
            state.status = .paused
            return .run { [audioPlayer] _ in await audioPlayer.pause() }
          case .paused:
            state.status = .playing
            return .run { [audioPlayer] _ in await audioPlayer.resume() }
          case .loading:
            return .none
          case .idle, .unavailable:
            break // 끝났거나 못 찾았던 곡 → 처음부터 다시 시도
          }
        }
        state.track = track
        state.status = .loading
        state.elapsed = 0
        return .run { [audioPlayer, previewClient] send in
          await audioPlayer.stop()
          await send(.previewResolved(await previewClient.previewURL(track.title, track.artist)))
        }
        .cancellable(id: CancelID.playback, cancelInFlight: true)

      case let .previewResolved(url):
        guard let url else {
          state.status = .unavailable
          return .none
        }
        state.status = .playing
        return .run { [audioPlayer] send in
          for await event in await audioPlayer.play(url) {
            await send(.playerEvent(event))
          }
        }
        .cancellable(id: CancelID.playback, cancelInFlight: true)

      case let .playerEvent(.progress(elapsed, duration)):
        state.elapsed = elapsed
        state.duration = duration
        return .none

      case let .playerEvent(.playingChanged(isPlaying)):
        // 끼어들기로 멈췄거나 이어폰·제어 센터로 다시 튼 경우만 반영 (로딩·끝난 상태는 그대로)
        guard state.status == .playing || state.status == .paused else { return .none }
        state.status = isPlaying ? .playing : .paused
        return .none

      case .playerEvent(.finished):
        state.status = .idle
        state.elapsed = 0
        return .none

      case .playerEvent(.failed):
        state.status = .unavailable
        return .none

      case .stop:
        state = State()
        return .merge(.cancel(id: CancelID.playback), .run { [audioPlayer] _ in await audioPlayer.stop() })
      }
    }
  }
}
