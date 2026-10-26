import Foundation

public struct Coordinate: Equatable, Hashable, Sendable, Codable {
  public var latitude: Double
  public var longitude: Double

  public init(latitude: Double, longitude: Double) {
    self.latitude = latitude
    self.longitude = longitude
  }

  /// 목 데이터·시뮬레이터 기준 위치 — 부산 강서구 가락대로 1397번길 교차점 남쪽 (봉림동)
  public static let home = Coordinate(latitude: 35.1889, longitude: 128.9038)

  /// 두 좌표 사이 거리(미터, 하버사인)
  public func distance(to other: Coordinate) -> Double {
    let r = 6_371_000.0
    let dLat = (other.latitude - latitude) * .pi / 180
    let dLon = (other.longitude - longitude) * .pi / 180
    let a = sin(dLat / 2) * sin(dLat / 2) + cos(latitude * .pi / 180) * cos(other.latitude * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
    return 2 * r * asin(sqrt(a))
  }
}

/// 주변 드랍 목록의 한 항목 — 서버 `GET /droppings` 응답 (RN `DropSummary`와 같은 모양)
public struct DropSummary: Equatable, Identifiable, Sendable {
  public enum Kind: Equatable, Sendable {
    case music(songId: String, title: String, artist: String)
    case vote(topic: String, optionIds: [String])
    case playlist(name: String, songIds: [String])
  }

  public var id: String
  public var userId: String
  public var kind: Kind
  public var content: String
  public var coordinate: Coordinate
  public var address: String
  public var imageURL: URL?
  public var isMine: Bool

  public init(id: String, userId: String, kind: Kind, content: String, coordinate: Coordinate, address: String, imageURL: URL?, isMine: Bool) {
    self.id = id
    self.userId = userId
    self.kind = kind
    self.content = content
    self.coordinate = coordinate
    self.address = address
    self.imageURL = imageURL
    self.isMine = isMine
  }

  /// 핀·목록에 보일 제목 (곡 제목, 투표 주제, 플리 이름)
  public var title: String {
    switch kind {
    case let .music(_, title, _): title
    case let .vote(topic, _): topic
    case let .playlist(name, _): name
    }
  }

  public var subtitle: String {
    switch kind {
    case let .music(_, _, artist): artist
    case let .vote(_, ids): "투표 · \(ids.count)곡"
    case let .playlist(_, ids): "플레이리스트 · \(ids.count)곡"
    }
  }
}

/// 음악 드랍 상세 — 서버 `GET /droppings/{id}` (음악 드랍일 때). 상세엔 type 필드가 없어 songId로 판별한다.
public struct MusicDropDetail: Equatable, Sendable, Decodable {
  public var droppingId: String
  public var songId: String
  public var userId: String
  public var username: String
  public var content: String
  public var createdAt: String
  public var albumImageUrl: URL?

  public init(droppingId: String, songId: String, userId: String, username: String, content: String, createdAt: String, albumImageUrl: URL?) {
    self.droppingId = droppingId
    self.songId = songId
    self.userId = userId
    self.username = username
    self.content = content
    self.createdAt = createdAt
    self.albumImageUrl = albumImageUrl
  }
}

/// 곡 — 서버 `GET /songs/{id}`
public struct Song: Equatable, Identifiable, Sendable, Decodable {
  public struct Links: Equatable, Sendable, Decodable {
    public var spotify: URL?
    public var youtubeMusic: URL?

    public init(spotify: URL? = nil, youtubeMusic: URL? = nil) {
      self.spotify = spotify
      self.youtubeMusic = youtubeMusic
    }
  }

  public var id: String
  public var title: String
  public var artist: String
  /// 초
  public var duration: Int
  public var albumImagePath: URL?
  public var links: Links

  public init(id: String, title: String, artist: String, duration: Int, albumImagePath: URL?, links: Links = .init()) {
    self.id = id
    self.title = title
    self.artist = artist
    self.duration = duration
    self.albumImagePath = albumImagePath
    self.links = links
  }
}

/// 드랍 반응 수 (좋아요·댓글) — 1단계는 상세 화면 표시용
public struct DropStats: Equatable, Sendable {
  public var likes: Int
  public var comments: Int

  public init(likes: Int, comments: Int) {
    self.likes = likes
    self.comments = comments
  }
}
