import Dependencies
import Foundation

/// PADO 서버 API — RN 앱(`src/api/endpoints.ts`)과 같은 명세. 1단계는 지도·핀 미리보기에 필요한 것만.
/// (매크로 없이 정의: 패키지를 매크로 신뢰 없이 빌드할 수 있게)
public struct APIClient: Sendable {
  /// 주변 드랍 — `GET /droppings?latitude&longitude&distance(km)`
  public var nearbyDrops: @Sendable (_ center: Coordinate, _ distanceKm: Double) async throws -> [DropSummary]
  /// 음악 드랍 상세 — `GET /droppings/{id}`
  public var musicDropDetail: @Sendable (_ id: String) async throws -> MusicDropDetail
  /// 곡 — `GET /songs/{id}`
  public var song: @Sendable (_ id: String) async throws -> Song
  /// 좋아요·댓글 수 — 로그인이 필요해 실패할 수 있다 (nil이면 화면에서 숨김)
  public var stats: @Sendable (_ dropId: String) async -> DropStats?

  public init(
    nearbyDrops: @escaping @Sendable (_ center: Coordinate, _ distanceKm: Double) async throws -> [DropSummary],
    musicDropDetail: @escaping @Sendable (_ id: String) async throws -> MusicDropDetail,
    song: @escaping @Sendable (_ id: String) async throws -> Song,
    stats: @escaping @Sendable (_ dropId: String) async -> DropStats?
  ) {
    self.nearbyDrops = nearbyDrops
    self.musicDropDetail = musicDropDetail
    self.song = song
    self.stats = stats
  }
}

public struct APIError: Error, Equatable, Sendable {
  public var status: Int
  public var code: String?

  public init(status: Int, code: String? = nil) {
    self.status = status
    self.code = code
  }
}

extension APIClient: DependencyKey {
  /// 목 모드 빌드(PADOUseMock=YES)면 내장 목 데이터, 아니면 실서버
  public static var liveValue: APIClient { AppConfig.current.useMock ? .mock() : .live(baseURL: AppConfig.current.apiBaseURL) }
  /// 테스트에서 덮어쓰지 않은 엔드포인트를 부르면 실패로 알려준다
  public static let testValue = APIClient(
    nearbyDrops: unimplemented("APIClient.nearbyDrops", placeholder: []),
    musicDropDetail: unimplemented("APIClient.musicDropDetail"),
    song: unimplemented("APIClient.song"),
    stats: unimplemented("APIClient.stats", placeholder: nil)
  )
  public static var previewValue: APIClient { .mock() }
}

public extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClient.self] }
    set { self[APIClient.self] = newValue }
  }
}

// MARK: - 실서버

extension APIClient {
  public static func live(baseURL: URL, session: URLSession = .shared) -> APIClient {
    @Sendable func get<T: Decodable & Sendable>(_ path: String, query: [String: String] = [:]) async throws -> T {
      var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
      if !query.isEmpty { components.queryItems = query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) } }
      var request = URLRequest(url: components.url!, timeoutInterval: 15)
      request.setValue("application/json", forHTTPHeaderField: "Accept")
      let (data, response) = try await session.data(for: request)
      let status = (response as? HTTPURLResponse)?.statusCode ?? 0
      guard (200..<300).contains(status) else {
        let code = (try? JSONDecoder().decode([String: String].self, from: data))?["code"]
        throw APIError(status: status, code: code)
      }
      return try JSONDecoder().decode(T.self, from: data)
    }

    return APIClient(
      nearbyDrops: { center, km in
        let res: NearbyResponse = try await get("droppings", query: ["latitude": "\(center.latitude)", "longitude": "\(center.longitude)", "distance": "\(km)"])
        return res.droppings.compactMap(\.summary)
      },
      musicDropDetail: { id in try await get("droppings/\(id)") },
      song: { id in try await get("songs/\(id)") },
      stats: { id in
        // 비로그인이면 401 — 숫자 없이 보여준다
        guard let likes: LikeCount = try? await get("likes/count/dropping/\(id)"),
              let comments: Int = try? await get("comments/count/\(id)") else { return nil }
        return DropStats(likes: likes.likeCount, comments: comments)
      }
    )
  }
}

/// 서버 응답 그대로의 모양 — type 필드로 갈라 앱 모델로 바꾼다
struct NearbyResponse: Decodable, Sendable {
  var droppings: [RawDrop]

  private enum CodingKeys: String, CodingKey { case droppings }
  /// 항목 하나가 깨져도(null 필드 등) 나머지는 보여준다
  private struct Lenient: Decodable { var drop: RawDrop?; init(from d: Decoder) { drop = try? RawDrop(from: d) } }

  init(from decoder: Decoder) throws {
    droppings = try decoder.container(keyedBy: CodingKeys.self).decode([Lenient].self, forKey: .droppings).compactMap(\.drop)
  }
}

struct LikeCount: Decodable, Sendable {
  var likeCount: Int
}

struct RawDrop: Decodable, Sendable {
  var type: String
  var droppingId: String
  var userId: String?
  var content: String?
  var latitude: Double
  var longitude: Double
  var address: String?
  var isMyDropping: Bool?
  var songId: String?
  var title: String?
  var artist: String?
  var albumImageUrl: String?
  var topic: String?
  var options: [String]?
  var playlistName: String?
  var songIds: [String]?
  var firstAlbumImageUrl: String?

  /// 알 수 없는 type이나 필수 필드가 빠진 항목은 버린다 (서버가 새 드랍 종류를 추가해도 앱이 죽지 않게)
  var summary: DropSummary? {
    let kind: DropSummary.Kind
    switch type {
    case "MUSIC":
      guard let songId, let title, let artist else { return nil }
      kind = .music(songId: songId, title: title, artist: artist)
    case "VOTE":
      guard let topic else { return nil }
      kind = .vote(topic: topic, optionIds: options ?? [])
    case "PLAYLIST":
      guard let playlistName else { return nil }
      kind = .playlist(name: playlistName, songIds: songIds ?? [])
    default:
      return nil
    }
    return DropSummary(
      id: droppingId, userId: userId ?? "", kind: kind, content: content ?? "",
      coordinate: Coordinate(latitude: latitude, longitude: longitude), address: address ?? "",
      imageURL: [albumImageUrl, firstAlbumImageUrl].compactMap { $0 }.first { !$0.isEmpty }.flatMap(URL.init(string:)), isMine: isMyDropping ?? false
    )
  }
}
