import ComposableArchitecture
import Foundation
import PADOKit

/// 핀 미리보기 시트 — 드랍 상세·곡·반응 수를 불러와 보여준다.
///
/// 재생은 직접 하지 않고 지도에 `delegate(.togglePreview)`로 맡긴다 (시트를 닫아도 재생이 이어지게).
@Reducer
public struct PinPreviewFeature {
  @ObservableState
  public struct State: Equatable {
    public var summary: DropSummary
    public var detail: MusicDropDetail?
    public var song: Song?
    public var stats: DropStats?
    public var isLoading = false
    public var errorMessage: String?

    public init(summary: DropSummary) {
      self.summary = summary
    }

    /// 재생에 쓸 곡 정보 — 상세를 불러오기 전에도 목록 정보로 바로 틀 수 있다
    public var track: Track? {
      guard case let .music(songId, title, artist) = summary.kind else { return nil }
      return Track(id: songId, title: song?.title ?? title, artist: song?.artist ?? artist, artURL: song?.albumImagePath ?? summary.imageURL)
    }
  }

  public enum Action: Sendable {
    case task
    case loaded(Result<Loaded, any Error>)
    case playTapped
    case listenTapped
    case closeTapped
    case delegate(Delegate)

    @CasePathable
    public enum Delegate: Equatable, Sendable {
      case togglePreview(Track)
    }
  }

  public struct Loaded: Equatable, Sendable {
    public var detail: MusicDropDetail
    public var song: Song
    public var stats: DropStats?
  }

  @Dependency(\.apiClient) var api
  @Dependency(\.openURL) var openURL
  @Dependency(\.dismiss) var dismiss

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        guard state.detail == nil else { return .none }
        state.isLoading = true
        let id = state.summary.id
        return .run { [api] send in
          await send(.loaded(await Result {
            // 상세 → 곡 순서는 지켜야 하고(songId가 상세에 있음), 반응 수는 동시에
            async let stats = api.stats(id)
            let detail = try await api.musicDropDetail(id)
            let song = try await api.song(detail.songId)
            return Loaded(detail: detail, song: song, stats: await stats)
          }))
        }

      case let .loaded(.success(loaded)):
        state.isLoading = false
        state.detail = loaded.detail
        state.song = loaded.song
        state.stats = loaded.stats
        return .none

      case let .loaded(.failure(error)):
        state.isLoading = false
        state.errorMessage = (error as? APIError)?.status == 404 ? "이미 사라진 드랍이에요." : "드랍을 불러오지 못했어요."
        return .none

      case .playTapped:
        guard let track = state.track else { return .none }
        return .send(.delegate(.togglePreview(track)))

      case .listenTapped:
        guard let url = state.song?.links.spotify else { return .none }
        return .run { [openURL] _ in await openURL(url) }

      case .closeTapped:
        return .run { [dismiss] _ in await dismiss() }

      case .delegate:
        return .none
      }
    }
  }
}
