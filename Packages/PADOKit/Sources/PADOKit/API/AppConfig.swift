import Foundation

/// 빌드 설정 — Info.plist의 PADOAPIBaseURL, PADOUseMock (xcconfig에서 채움)
public struct AppConfig: Sendable {
  public var apiBaseURL: URL
  /// true면 서버 대신 내장 목 데이터 (RN 목 서버와 같은 시드)
  public var useMock: Bool

  public static let current: AppConfig = {
    let info = Bundle.main.infoDictionary ?? [:]
    let base = (info["PADOAPIBaseURL"] as? String).flatMap(URL.init(string:)) ?? URL(string: "https://api.paado.app/api/v1")!
    let mock = (info["PADOUseMock"] as? String).map { $0 == "YES" || $0 == "true" } ?? false
    return AppConfig(apiBaseURL: base, useMock: mock)
  }()
}
