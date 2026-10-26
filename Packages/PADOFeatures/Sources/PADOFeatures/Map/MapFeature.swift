import ComposableArchitecture
import Foundation
import PADOKit

/// 지도 홈 — 내 위치 → 주변 1km 드랍 → 핀을 누르면 미리보기 시트.
@Reducer
public struct MapFeature {
  /// 주변 드랍 검색 반경 (RN 앱과 같은 1km)
  public static let radiusKm = 1.0

  @ObservableState
  public struct State: Equatable {
    public enum Loading: Equatable, Sendable {
      case idle, loading, loaded
      case failed(String)
    }

    public var center: Coordinate?
    /// 지도 위쪽 제목 (동 이름)
    public var placeName: String?
    public var drops: [DropSummary] = []
    public var loading: Loading = .idle
    public var player = PlayerFeature.State()
    @Presents public var preview: PinPreviewFeature.State?

    public init() {}

    /// '가까운 드랍' 줄 — 가까운 순
    public var nearby: [DropSummary] {
      guard let center else { return drops }
      return drops.sorted { $0.coordinate.distance(to: center) < $1.coordinate.distance(to: center) }
    }

    public var selectedDropId: String? { preview?.summary.id }
  }

  public enum Action: Sendable {
    case task
    case retryTapped
    case located(Result<Coordinate, any Error>)
    case dropsLoaded(Result<[DropSummary], any Error>)
    case placeNameResolved(String?)
    case pinTapped(id: String)
    case miniDiscTapped
    case player(PlayerFeature.Action)
    case preview(PresentationAction<PinPreviewFeature.Action>)
  }

  @Dependency(\.location) var location
  @Dependency(\.apiClient) var api

  public init() {}

  public var body: some ReducerOf<Self> {
    Scope(state: \.player, action: \.player) { PlayerFeature() }
    Reduce { state, action in
      switch action {
      case .task, .retryTapped:
        guard state.loading != .loading else { return .none }
        state.loading = .loading
        return .run { send in
          await send(.located(await Result { try await location.currentLocation() }))
        }

      case let .located(.success(center)):
        state.center = center
        return .run { send in
          // 동 이름과 드랍을 동시에 찾되, 보내는 순서는 고정 (드랍 → 동 이름)
          async let name = location.placeName(center)
          await send(.dropsLoaded(await Result { try await api.nearbyDrops(center, Self.radiusKm) }))
          await send(.placeNameResolved(await name))
        }

      case let .placeNameResolved(name):
        state.placeName = name
        return .none

      case let .located(.failure(error)):
        state.loading = .failed(error as? LocationClient.Failure == .denied
          ? "위치 권한이 꺼져 있어요. 설정에서 켜면 주변 드랍이 보여요."
          : "위치를 찾지 못했어요. 잠시 뒤 다시 시도해 주세요.")
        return .none

      case let .dropsLoaded(.success(drops)):
        state.drops = drops
        state.loading = .loaded
        return .none

      case .dropsLoaded(.failure):
        state.loading = .failed("주변 드랍을 불러오지 못했어요.")
        return .none

      case let .pinTapped(id):
        guard let drop = state.drops.first(where: { $0.id == id }) else { return .none }
        // 1단계는 음악 드랍만 미리보기를 연다 (투표·플리 상세는 2단계)
        guard case .music = drop.kind else { return .none }
        state.preview = PinPreviewFeature.State(summary: drop)
        return .none

      case .miniDiscTapped:
        // 재생 중인 곡의 드랍을 다시 연다
        guard let trackId = state.player.track?.id,
              let drop = state.drops.first(where: { if case let .music(songId, _, _) = $0.kind { songId == trackId } else { false } }) else { return .none }
        state.preview = PinPreviewFeature.State(summary: drop)
        return .none

      case let .preview(.presented(.delegate(.togglePreview(track)))):
        return .send(.player(.toggle(track)))

      case .preview, .player:
        return .none
      }
    }
    .ifLet(\.$preview, action: \.preview) { PinPreviewFeature() }
  }
}
