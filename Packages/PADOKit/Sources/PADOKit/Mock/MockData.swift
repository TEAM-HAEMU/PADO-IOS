import Foundation

/// 목 데이터 — RN 앱 `src/api/mock/server.ts`·`data.ts`와 같은 시드 (봉림동 주변 드랍 8개).
/// 앨범 아트는 직접 만든 가상 커버(Resources/MockCovers)라 스크린샷·데모에 써도 된다.
public enum MockData {
  static func cover(_ index: Int) -> URL? {
    Bundle.module.url(forResource: String(format: "cover%02d", index % 14 + 1), withExtension: "jpg")
  }

  public static let songs: [Song] = [
    ("난춘", "새소년", 229), ("사건의 지평선", "윤하", 301), ("Everything", "검정치마", 293), ("긴 꿈", "새소년", 258),
    ("파도", "새소년", 282), ("자유", "새소년", 236), ("Bubble Gum", "NewJeans", 200), ("TOMBOY", "HYUKOH", 242),
    ("주저하는 연인들을 위해", "잔나비", 265), ("Let It Happen", "Tame Impala", 467), ("Pink + White", "Frank Ocean", 185),
    ("밤편지", "아이유", 253), ("Robbers", "The 1975", 255), ("Square", "백예린", 262),
  ].enumerated().map { i, s in
    Song(id: String(format: "0199a5e0-2222-7abc-8def-%012d", i + 1), title: s.0, artist: s.1, duration: s.2, albumImagePath: cover(i),
         links: .init(spotify: URL(string: "https://open.spotify.com/search/\(s.0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")")))
  }

  static func song(_ title: String) -> Song { songs.first { $0.title == title }! }

  /// 미터 오프셋 → 좌표 (기준: Coordinate.home)
  static func at(north: Double, east: Double) -> Coordinate {
    let home = Coordinate.home
    return Coordinate(latitude: home.latitude + north / 111_320, longitude: home.longitude + east / (111_320 * cos(home.latitude * .pi / 180)))
  }

  struct Row {
    var summary: DropSummary
    var username: String
    var hoursAgo: Int
    var likes: Int
    var comments: Int
  }

  static let rows: [Row] = {
    func music(_ n: Int, _ who: String, _ title: String, _ content: String, north: Double, east: Double, _ address: String, hours: Int, likes: Int, comments: Int, mine: Bool = false) -> Row {
      let s = song(title)
      return Row(summary: DropSummary(id: String(format: "0199a5e0-3333-7abc-8def-%012d", n), userId: who, kind: .music(songId: s.id, title: s.title, artist: s.artist),
                                      content: content, coordinate: at(north: north, east: east), address: address, imageURL: s.albumImagePath, isMine: mine),
                 username: who, hoursAgo: hours, likes: likes, comments: comments)
    }
    var rows = [
      music(1, "하윤", "난춘", "퇴근길 버스 기다리면서 듣기 좋은 노래.\n강바람이랑 진짜 잘 어울려요.", north: 150, east: -120, "부산 강서구 가락대로 1397번길", hours: 2, likes: 18, comments: 4),
      music(2, "도윤", "사건의 지평선", "여기서 노을 보면서 들으면 끝나요", north: 280, east: 160, "부산 강서구 봉림동", hours: 5, likes: 9, comments: 0),
      music(3, "서아", "Everything", "강변 산책로 따라 걷다가", north: -330, east: 250, "부산 강서구 서낙동로", hours: 8, likes: 24, comments: 0),
      music(4, "민재", "Bubble Gum", "아침 산책 BGM", north: 520, east: -60, "부산 강서구 상덕로", hours: 20, likes: 4, comments: 0),
      music(5, "정현", "파도", "강 보면서 들으면 제목 그대로", north: -120, east: -260, "부산 강서구 서낙동강 둑길", hours: 30, likes: 12, comments: 0, mine: true),
    ]
    let vote = ["난춘", "Everything", "Let It Happen", "밤편지"].map { song($0) }
    rows.append(Row(summary: DropSummary(id: "0199a5e0-3333-7abc-8def-000000000006", userId: "하윤", kind: .vote(topic: "퇴근길 강변에 가장 어울리는 곡은?", optionIds: vote.map(\.id)),
                                         content: "다들 뭐 들어요?", coordinate: at(north: -60, east: 90), address: "부산 강서구 가락대로 정류장 앞", imageURL: vote[0].albumImagePath, isMine: false),
                    username: "하윤", hoursAgo: 4, likes: 6, comments: 2))
    let list = ["난춘", "Everything", "사건의 지평선", "밤편지", "TOMBOY", "Pink + White", "Let It Happen", "파도"].map { song($0) }
    rows.append(Row(summary: DropSummary(id: "0199a5e0-3333-7abc-8def-000000000007", userId: "지우", kind: .playlist(name: "봉림동 퇴근길", songIds: list.map(\.id)),
                                         content: "퇴근길에 한 바퀴 돌면서 들어요", coordinate: at(north: -240, east: -200), address: "부산 강서구 봉죽길", imageURL: list[0].albumImagePath, isMine: false),
                    username: "지우", hoursAgo: 6, likes: 15, comments: 0))
    return rows
  }()
}

extension APIClient {
  /// 서버 없이 쓰는 목 API — 지연을 조금 줘서 로딩 상태도 확인할 수 있게
  public static func mock(latency: Duration = .milliseconds(250)) -> APIClient {
    APIClient(
      nearbyDrops: { center, km in
        try await Task.sleep(for: latency)
        return MockData.rows.map(\.summary).filter { $0.coordinate.distance(to: center) <= km * 1000 }
      },
      musicDropDetail: { id in
        try await Task.sleep(for: latency)
        guard let row = MockData.rows.first(where: { $0.summary.id == id }), case let .music(songId, _, _) = row.summary.kind else {
          throw APIError(status: 404, code: "D2")
        }
        let created = Date(timeIntervalSince1970: 1_790_000_000 - Double(row.hoursAgo) * 3600)
        return MusicDropDetail(droppingId: id, songId: songId, userId: row.summary.userId, username: row.username, content: row.summary.content,
                               createdAt: ISO8601DateFormatter().string(from: created), albumImageUrl: row.summary.imageURL)
      },
      song: { id in
        try await Task.sleep(for: latency)
        guard let s = MockData.songs.first(where: { $0.id == id }) else { throw APIError(status: 404, code: "D3") }
        return s
      },
      stats: { id in
        MockData.rows.first { $0.summary.id == id }.map { DropStats(likes: $0.likes, comments: $0.comments) }
      }
    )
  }
}
