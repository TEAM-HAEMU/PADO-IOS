@preconcurrency import CoreLocation
import Dependencies
import Foundation

/// 현재 위치 — 주변 드랍을 찾을 때만 한 번 묻는다 (앱 사용 중 권한).
public struct LocationClient: Sendable {
  public enum Failure: Error, Equatable, Sendable {
    /// 권한 거부 — 설정에서 켜야 한다
    case denied
    /// 신호를 못 잡음 (실내·위치 서비스 꺼짐)
    case unavailable
  }

  public var currentLocation: @Sendable () async throws -> Coordinate
  /// 좌표의 동 이름 (예: "봉림동") — 지도 위쪽 제목. 못 찾으면 nil
  public var placeName: @Sendable (_ at: Coordinate) async -> String?

  public init(
    currentLocation: @escaping @Sendable () async throws -> Coordinate,
    placeName: @escaping @Sendable (_ at: Coordinate) async -> String?
  ) {
    self.currentLocation = currentLocation
    self.placeName = placeName
  }
}

extension LocationClient: DependencyKey {
  /// 목 모드 빌드면 기준 위치(봉림동)를 바로 돌려준다
  public static var liveValue: LocationClient {
    if AppConfig.current.useMock { return .fixed(.home, placeName: "봉림동") }
    return LocationClient(
      currentLocation: { try await LiveLocationProvider.shared.current() },
      placeName: { at in
        let marks = try? await CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: at.latitude, longitude: at.longitude), preferredLocale: Locale(identifier: "ko_KR"))
        return marks?.first.flatMap { $0.subLocality ?? $0.locality }
      }
    )
  }

  public static let testValue = LocationClient(
    currentLocation: unimplemented("LocationClient.currentLocation", placeholder: .home),
    placeName: unimplemented("LocationClient.placeName", placeholder: nil)
  )

  public static func fixed(_ coordinate: Coordinate, placeName: String? = nil) -> LocationClient {
    LocationClient(currentLocation: { coordinate }, placeName: { _ in placeName })
  }
}

public extension DependencyValues {
  var location: LocationClient {
    get { self[LocationClient.self] }
    set { self[LocationClient.self] = newValue }
  }
}

@MainActor
final class LiveLocationProvider: NSObject, CLLocationManagerDelegate {
  /// CLLocationManager는 메인 스레드에서 만들고 써야 해서, 처음 쓸 때 메인 액터에서 만들어지는 공유 인스턴스
  static let shared = LiveLocationProvider()

  private let manager = CLLocationManager()
  private var waiting: [CheckedContinuation<Coordinate, Error>] = []

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
  }

  func current() async throws -> Coordinate {
    switch manager.authorizationStatus {
    case .denied, .restricted: throw LocationClient.Failure.denied
    default: break
    }
    return try await withCheckedThrowingContinuation { c in
      waiting.append(c)
      if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() } else { manager.requestLocation() }
    }
  }

  private func resolve(_ result: Result<Coordinate, Error>) {
    let list = waiting
    waiting.removeAll()
    for c in list { c.resume(with: result) }
  }

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    Task { @MainActor in
      switch status {
      case .authorizedWhenInUse, .authorizedAlways: self.manager.requestLocation()
      case .denied, .restricted: self.resolve(.failure(LocationClient.Failure.denied))
      default: break
      }
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let last = locations.last else { return }
    let c = Coordinate(latitude: last.coordinate.latitude, longitude: last.coordinate.longitude)
    Task { @MainActor in self.resolve(.success(c)) }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    Task { @MainActor in self.resolve(.failure(LocationClient.Failure.unavailable)) }
  }
}
