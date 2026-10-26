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
      var fuzzy: URL?
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
        // 정확히 맞는 곡이 두 스토어 모두 없을 때만 쓰는 후보 (한글 제목 → 영문 음역 대비)
        if fuzzy == nil { fuzzy = PreviewMatcher.fuzzyPick(result.results, title: title, artist: artist)?.previewUrl.flatMap(URL.init(string:)) }
      }
      return fuzzy
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

  /// 한글 제목·가수는 iTunes에 영문 음역으로 올라간 경우가 많다 (난춘 → "Nan Chun", 새소년 → "SE SO NEON").
  /// iTunes 검색이 음역을 고려하므로, 한글이 섞였으면 검색 1순위(미리듣기 있는 첫 곡)를 믿는다. RN 앱과 같은 규칙.
  static func fuzzyPick(_ rows: [ITunesResult.Row], title: String, artist: String) -> ITunesResult.Row? {
    let hasHangul = (title + artist).unicodeScalars.contains { (0xAC00...0xD7A3).contains($0.value) || (0x3131...0x318E).contains($0.value) }
    return hasHangul ? rows.first { $0.previewUrl != nil } : nil
  }
}
