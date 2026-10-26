import ComposableArchitecture
import Foundation
import PADOKit
import Testing
@testable import PADOFeatures

private let nanchun = Track(id: "song-1", title: "난춘", artist: "새소년", artURL: nil)
private let pado = Track(id: "song-5", title: "파도", artist: "새소년", artURL: nil)
private let previewURL = URL(string: "https://audio.example/nanchun.m4a")!

@MainActor
@Suite("재생기")
struct PlayerFeatureTests {
  @Test("재생: 미리듣기 주소를 찾고, 진행률을 받고, 끝나면 처음으로")
  func playToEnd() async {
    let (events, continuation) = AsyncStream<AudioPlayerClient.Event>.makeStream()
    let store = TestStore(initialState: PlayerFeature.State()) { PlayerFeature() } withDependencies: {
      $0.previewClient.previewURL = { _, _ in previewURL }
      $0.audioPlayer.stop = {}
      $0.audioPlayer.play = { url in
        #expect(url == previewURL)
        return events
      }
    }

    await store.send(.toggle(nanchun)) {
      $0.track = nanchun
      $0.status = .loading
    }
    await store.receive(\.previewResolved) { $0.status = .playing }
    continuation.yield(.progress(elapsed: 4, duration: 30))
    await store.receive(\.playerEvent) {
      $0.elapsed = 4
      #expect($0.timeText == "0:26") // 남은 시간 (Figma 표기)
    }
    continuation.yield(.finished)
    continuation.finish()
    await store.receive(\.playerEvent) {
      $0.status = .idle
      $0.elapsed = 0
    }
  }

  @Test("같은 곡을 다시 누르면 일시정지 → 이어듣기 (처음부터 다시 틀지 않음)")
  func pauseResume() async {
    let paused = LockIsolated(false), resumed = LockIsolated(false)
    let store = TestStore(initialState: PlayerFeature.State(track: nanchun, status: .playing, elapsed: 10)) { PlayerFeature() } withDependencies: {
      $0.audioPlayer.pause = { paused.setValue(true) }
      $0.audioPlayer.resume = { resumed.setValue(true) }
    }
    await store.send(.toggle(nanchun)) { $0.status = .paused }
    await store.send(.toggle(nanchun)) { $0.status = .playing }
    #expect(paused.value && resumed.value)
  }

  @Test("다른 곡을 누르면 앞 곡을 멈추고 새로 재생")
  func switchTrack() async {
    let stopped = LockIsolated(0)
    let store = TestStore(initialState: PlayerFeature.State(track: nanchun, status: .playing, elapsed: 10)) { PlayerFeature() } withDependencies: {
      $0.audioPlayer.stop = { stopped.withValue { $0 += 1 } }
      $0.previewClient.previewURL = { _, _ in nil }
    }
    await store.send(.toggle(pado)) {
      $0.track = pado
      $0.status = .loading
      $0.elapsed = 0
    }
    await store.receive(\.previewResolved) { $0.status = .unavailable } // 미리듣기 없는 곡
    #expect(stopped.value == 1)
  }
}

@MainActor
@Suite("지도")
struct MapFeatureTests {
  @Test("위치 → 동 이름·주변 드랍 → 음악 핀을 누르면 미리보기")
  func loadAndOpenPreview() async throws {
    let drops = try await APIClient.mock(latency: .zero).nearbyDrops(.home, 1)
    let store = TestStore(initialState: MapFeature.State()) { MapFeature() } withDependencies: {
      $0.location = .fixed(.home, placeName: "봉림동")
      $0.apiClient.nearbyDrops = { center, km in
        #expect(center == .home && km == 1)
        return drops
      }
    }

    await store.send(.task) { $0.loading = .loading }
    await store.receive(\.located.success) { $0.center = .home }
    await store.receive(\.dropsLoaded.success) {
      $0.drops = drops
      $0.loading = .loaded
    }
    await store.receive(\.placeNameResolved) { $0.placeName = "봉림동" }

    let music = drops.first { if case .music = $0.kind { true } else { false } }!
    await store.send(.pinTapped(id: music.id)) { $0.preview = PinPreviewFeature.State(summary: music) }

    let vote = drops.first { if case .vote = $0.kind { true } else { false } }!
    await store.send(.pinTapped(id: vote.id)) // 투표 드랍은 1단계에선 아무 일 없음
  }

  @Test("위치 권한 거부 → 설정 안내 문구")
  func locationDenied() async {
    let store = TestStore(initialState: MapFeature.State()) { MapFeature() } withDependencies: {
      $0.location.currentLocation = { throw LocationClient.Failure.denied }
    }
    await store.send(.task) { $0.loading = .loading }
    await store.receive(\.located.failure) { $0.loading = .failed("위치 권한이 꺼져 있어요. 설정에서 켜면 주변 드랍이 보여요.") }
  }

  @Test("시트의 재생 버튼은 지도의 재생기로 위임된다 (시트를 닫아도 계속 재생)")
  func previewDelegatesPlayback() async throws {
    let drop = try await APIClient.mock(latency: .zero).nearbyDrops(.home, 1).first!
    var state = MapFeature.State()
    state.drops = [drop]
    state.preview = PinPreviewFeature.State(summary: drop)
    let store = TestStore(initialState: state) { MapFeature() } withDependencies: {
      $0.audioPlayer.stop = {}
      $0.previewClient.previewURL = { _, _ in nil }
    }
    store.exhaustivity = .off(showSkippedAssertions: false)

    await store.send(\.preview.presented.playTapped)
    await store.receive(\.preview.presented.delegate.togglePreview)
    await store.receive(\.player.toggle) { $0.player.status = .loading }

    await store.send(.preview(.dismiss)) { $0.preview = nil }
    #expect(store.state.player.track != nil) // 시트가 닫혀도 재생기는 그대로
  }
}

@MainActor
@Suite("핀 미리보기")
struct PinPreviewFeatureTests {
  @Test("상세 → 곡을 순서대로, 반응 수는 같이 불러온다")
  func load() async throws {
    let api = APIClient.mock(latency: .zero)
    let drop = try await api.nearbyDrops(.home, 1).first!
    let store = TestStore(initialState: PinPreviewFeature.State(summary: drop)) { PinPreviewFeature() } withDependencies: {
      $0.apiClient = api
    }
    await store.send(.task) { $0.isLoading = true }
    let detail = try await api.musicDropDetail(drop.id)
    let song = try await api.song(detail.songId)
    await store.receive(\.loaded.success) {
      $0.isLoading = false
      $0.detail = detail
      $0.song = song
      $0.stats = DropStats(likes: 18, comments: 4)
    }
  }

  @Test("사라진 드랍(404)은 안내 문구")
  func notFound() async throws {
    let drop = try await APIClient.mock(latency: .zero).nearbyDrops(.home, 1).first!
    let store = TestStore(initialState: PinPreviewFeature.State(summary: drop)) { PinPreviewFeature() } withDependencies: {
      $0.apiClient.musicDropDetail = { _ in throw APIError(status: 404, code: "D2") }
      $0.apiClient.stats = { _ in nil }
    }
    await store.send(.task) { $0.isLoading = true }
    await store.receive(\.loaded.failure) {
      $0.isLoading = false
      $0.errorMessage = "이미 사라진 드랍이에요."
    }
  }

  @Test("전체 듣기는 곡의 Spotify 링크를 연다")
  func listen() async throws {
    let api = APIClient.mock(latency: .zero)
    let drop = try await api.nearbyDrops(.home, 1).first!
    var state = PinPreviewFeature.State(summary: drop)
    state.song = try await api.song(MockData.songs[0].id)
    let opened = LockIsolated<URL?>(nil)
    let store = TestStore(initialState: state) { PinPreviewFeature() } withDependencies: {
      $0.openURL = OpenURLEffect { url in opened.setValue(url); return true }
    }
    await store.send(.listenTapped)
    #expect(opened.value == state.song?.links.spotify)
  }
}
