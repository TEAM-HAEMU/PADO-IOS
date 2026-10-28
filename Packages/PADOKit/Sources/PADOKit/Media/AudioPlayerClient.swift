@preconcurrency import AVFoundation
import Dependencies
import Foundation

/// 미리듣기 재생 — AVPlayer를 감싼 의존성. TCA 기능은 이 스트림만 보고 상태를 바꾼다.
public struct AudioPlayerClient: Sendable {
  public enum Event: Equatable, Sendable {
    /// 재생 위치(초)와 전체 길이(초)
    case progress(elapsed: Double, duration: Double)
    /// 앱 밖에서 멈추거나 다시 튼 경우 (전화·Siri·이어폰 빠짐·제어 센터)
    case playingChanged(Bool)
    case finished
    case failed
  }

  /// URL을 처음부터 재생하고, 끝나거나 취소될 때까지 이벤트를 보낸다
  public var play: @Sendable (_ url: URL) async -> AsyncStream<Event>
  public var pause: @Sendable () async -> Void
  public var resume: @Sendable () async -> Void
  public var stop: @Sendable () async -> Void

  public init(
    play: @escaping @Sendable (_ url: URL) async -> AsyncStream<Event>,
    pause: @escaping @Sendable () async -> Void,
    resume: @escaping @Sendable () async -> Void,
    stop: @escaping @Sendable () async -> Void
  ) {
    self.play = play
    self.pause = pause
    self.resume = resume
    self.stop = stop
  }
}

extension AudioPlayerClient: DependencyKey {
  public static var liveValue: AudioPlayerClient {
    AudioPlayerClient(
      play: { url in await LivePlayer.shared.play(url) },
      pause: { await LivePlayer.shared.pause() },
      resume: { await LivePlayer.shared.resume() },
      stop: { await LivePlayer.shared.stop() }
    )
  }

  public static let testValue = AudioPlayerClient(
    play: unimplemented("AudioPlayerClient.play", placeholder: .finished),
    pause: unimplemented("AudioPlayerClient.pause"),
    resume: unimplemented("AudioPlayerClient.resume"),
    stop: unimplemented("AudioPlayerClient.stop")
  )
}

public extension DependencyValues {
  var audioPlayer: AudioPlayerClient {
    get { self[AudioPlayerClient.self] }
    set { self[AudioPlayerClient.self] = newValue }
  }
}

/// AVPlayer는 메인 스레드에서만 다룬다
@MainActor
final class LivePlayer {
  static let shared = LivePlayer()

  private let player = AVPlayer()
  private var timeObserver: Any?
  private var endObserver: NSObjectProtocol?
  private var failObserver: NSObjectProtocol?
  private var kvo: [NSKeyValueObservation] = []
  private var continuation: AsyncStream<AudioPlayerClient.Event>.Continuation?
  /// 몇 번째 재생인지 — 앞 곡 스트림의 늦은 정리가 새 곡의 관찰자를 지우지 않게 한다
  private var generation = 0

  func play(_ url: URL) -> AsyncStream<AudioPlayerClient.Event> {
    finishCurrent()
    #if os(iOS)
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
    try? AVAudioSession.sharedInstance().setActive(true)
    #endif
    let item = AVPlayerItem(url: url)
    player.replaceCurrentItem(with: item)
    let (stream, continuation) = AsyncStream<AudioPlayerClient.Event>.makeStream()
    self.continuation = continuation
    generation += 1
    let current = generation
    timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main) { [weak item] time in
      let duration = item?.duration.seconds ?? .nan
      continuation.yield(.progress(elapsed: time.seconds, duration: duration.isFinite ? duration : 30))
    }
    endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in
      continuation.yield(.finished)
      continuation.finish()
    }
    // 주소가 만료됐거나(403) 네트워크가 끊긴 경우 — 알리지 않으면 화면이 '재생 중'에 멈춘다
    failObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main) { _ in
      continuation.yield(.failed)
      continuation.finish()
    }
    kvo = [
      item.observe(\.status, options: [.new]) { item, _ in
        guard item.status == .failed else { return }
        continuation.yield(.failed)
        continuation.finish()
      },
      player.observe(\.timeControlStatus, options: [.new]) { player, _ in
        switch player.timeControlStatus {
        case .playing: continuation.yield(.playingChanged(true))
        case .paused: continuation.yield(.playingChanged(false))
        case .waitingToPlayAtSpecifiedRate: break
        @unknown default: break
        }
      },
    ]
    continuation.onTermination = { [weak self] _ in
      Task { @MainActor in
        // 새 곡이 이미 시작됐으면 손대지 않는다. 아니면(취소·끝남·실패) 소리도 멈춘다
        guard let self, self.generation == current else { return }
        self.player.pause()
        self.removeObservers()
        self.deactivateSession()
      }
    }
    player.play()
    return stream
  }

  func pause() { player.pause() }
  func resume() { player.play() }

  func stop() {
    player.pause()
    player.replaceCurrentItem(with: nil)
    finishCurrent()
    deactivateSession()
  }

  /// 세션을 내려놓아 사용자가 듣던 다른 앱 음악이 다시 나오게 한다
  private func deactivateSession() {
    #if os(iOS)
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    #endif
  }

  private func finishCurrent() {
    continuation?.finish()
    continuation = nil
    removeObservers()
  }

  private func removeObservers() {
    if let timeObserver { player.removeTimeObserver(timeObserver) }
    if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    if let failObserver { NotificationCenter.default.removeObserver(failObserver) }
    kvo.forEach { $0.invalidate() }
    kvo = []
    timeObserver = nil
    endObserver = nil
    failObserver = nil
  }
}
