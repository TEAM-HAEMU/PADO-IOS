import Dependencies
import Foundation

/// 30초 미리듣기 찾기 — Apple iTunes Search API (공개, 키 없음). RN `src/services/itunes.ts`와 같은 규칙.
///
/// - KR 스토어 검색이 비는 경우가 있어 US → KR 순서로 찾는다.
/// - 제목·가수가 모두 대충 맞는 곡만 고른다 (엉뚱한 곡을 틀지 않게).
/// - 결과는 앱 실행 중 기억해서 같은 곡을 다시 찾지 않는다 (iTunes는 IP당 분당 약 20회 제한).
public struct PreviewClient: Sendable {
  public var previewURL: @Sendable (_ title: String, _ artist: String) async -> URL?

  public init(previewURL: @escaping @Sendable (_ title: String, _ artist: String) async -> URL?) {
    self.previewURL = previewURL
  }
}

extension PreviewClient: DependencyKey {
  public static var liveValue: PreviewClient {
    let cache = PreviewCache()
    return PreviewClient { title, artist in
      let key = PreviewMatcher.normalize(title) + "|" + PreviewMatcher.normalize(artist)
      if let hit = await cache.get(key) { return hit }
      for country in ["US", "KR"] {
        var c = URLComponents(string: "https://itunes.apple.com/search")!
        c.queryItems = [.init(name: "term", value: "\(title) \(artist)"), .init(name: "entity", value: "song"), .init(name: "limit", value: "8"), .init(name: "country", value: country)]
        guard let (data, response) = try? await URLSession.shared.data(for: URLRequest(url: c.url!, timeoutInterval: 10)),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let result = try? JSONDecoder().decode(ITunesResult.self, from: data) else { continue }
        if let url = PreviewMatcher.pick(result.results, title: title, artist: artist)?.previewUrl.flatMap(URL.init(string:)) {
          await cache.set(key, url)
          return url
        }
      }
      return nil
    }
  }

  public static let testValue = PreviewClient(previewURL: unimplemented("PreviewClient.previewURL", placeholder: nil))
}

public extension DependencyValues {
  var previewClient: PreviewClient {
    get { self[PreviewClient.self] }
    set { self[PreviewClient.self] = newValue }
  }
}

actor PreviewCache {
  private var store: [String: URL] = [:]
  func get(_ key: String) -> URL? { store[key] }
  func set(_ key: String, _ url: URL) { store[key] = url }
}

struct ITunesResult: Decodable {
  struct Row: Decodable, Equatable {
    var trackName: String
    var artistName: String
    var previewUrl: String?
  }

  var results: [Row]
}

/// 검색 결과 중 맞는 곡 고르기 — 순수 함수라 따로 테스트한다
enum PreviewMatcher {
  /// 소문자 + 글자·숫자만 ("Pink + White" → "pinkwhite")
  static func normalize(_ s: String) -> String {
    s.lowercased().unicodeScalars.filter { CharacterSet.letters.contains($0) || CharacterSet.decimalDigits.contains($0) }.map(String.init).joined()
  }

  static func pick(_ rows: [ITunesResult.Row], title: String, artist: String) -> ITunesResult.Row? {
    let t = normalize(title)
    let mainArtist = artist.components(separatedBy: CharacterSet(charactersIn: ",&")).first ?? artist
    let a = normalize(mainArtist)
    func titleOK(_ r: ITunesResult.Row) -> Bool { let n = normalize(r.trackName); return !n.isEmpty && (n.contains(t) || t.contains(n)) }
    func artistOK(_ r: ITunesResult.Row) -> Bool { let n = normalize(r.artistName); return !a.isEmpty && (n.contains(a) || a.contains(n)) }
    return rows.first { titleOK($0) && artistOK($0) && $0.previewUrl != nil }
  }
}
