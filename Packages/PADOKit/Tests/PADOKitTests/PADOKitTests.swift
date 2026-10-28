import Foundation
import Testing
@testable import PADOKit

@Suite("PADOKit")
struct PADOKitTests {
  @Test("서버 드랍 JSON → 앱 모델 (type별, 모르는 type은 버림)")
  func decodeNearby() throws {
    let json = """
    {"droppings":[
      {"type":"MUSIC","droppingId":"d1","userId":"u1","content":"강바람","latitude":35.19,"longitude":128.90,"address":"부산","isMyDropping":false,"songId":"s1","title":"난춘","artist":"새소년","albumImageUrl":"https://example.com/a.jpg"},
      {"type":"VOTE","droppingId":"d2","userId":"u2","content":"","latitude":35.18,"longitude":128.90,"address":"부산","topic":"퇴근길 곡은?","options":["s1","s2"],"firstAlbumImageUrl":null},
      {"type":"PLAYLIST","droppingId":"d3","userId":"u3","content":"","latitude":35.18,"longitude":128.91,"address":"부산","playlistName":"봉림동 퇴근길","songIds":["s1","s2","s3"]},
      {"type":"STORY","droppingId":"d4","userId":"u4","content":"","latitude":0,"longitude":0,"address":""}
    ]}
    """.data(using: .utf8)!
    let drops = try JSONDecoder().decode(NearbyResponse.self, from: json).droppings.compactMap(\.summary)
    #expect(drops.map(\.id) == ["d1", "d2", "d3"])
    #expect(drops[0].kind == .music(songId: "s1", title: "난춘", artist: "새소년"))
    #expect(drops[0].imageURL == URL(string: "https://example.com/a.jpg"))
    #expect(drops[1].subtitle == "투표 · 2곡")
    #expect(drops[2].title == "봉림동 퇴근길")
  }

  @Test("미리듣기 곡 고르기: 제목·가수가 모두 맞는 첫 곡")
  func previewMatch() {
    let rows: [ITunesResult.Row] = [
      .init(trackName: "난춘 (Live)", artistName: "다른 가수", previewUrl: "https://x/1"),
      .init(trackName: "난춘", artistName: "SE SO NEON (새소년)", previewUrl: "https://x/2"),
    ]
    #expect(PreviewMatcher.pick(rows, title: "난춘", artist: "새소년")?.previewUrl == "https://x/2")
    #expect(PreviewMatcher.pick(rows, title: "파도", artist: "새소년") == nil)
    #expect(PreviewMatcher.normalize("Pink + White") == "pinkwhite")
  }

  @Test("한글 제목은 영문 음역 결과를 1순위로 믿는다 (실제 iTunes: 난춘 → Nan Chun / SE SO NEON)")
  func previewFuzzyHangul() {
    let us: [ITunesResult.Row] = [.init(trackName: "Nan Chun", artistName: "SE SO NEON", previewUrl: "https://x/nanchun")]
    #expect(PreviewMatcher.pick(us, title: "난춘", artist: "새소년") == nil)
    #expect(PreviewMatcher.fuzzyPick(us, title: "난춘", artist: "새소년")?.previewUrl == "https://x/nanchun")
    #expect(PreviewMatcher.fuzzyPick(us, title: "Robbers", artist: "The 1975") == nil) // 영문 제목은 추정하지 않음
  }

  @Test("목 API: 1km 안의 드랍만, 음악 드랍 상세·곡")
  func mockAPI() async throws {
    let api = APIClient.mock(latency: .zero)
    let near = try await api.nearbyDrops(.home, 1)
    #expect(near.count == 7)
    #expect(near.allSatisfy { $0.coordinate.distance(to: .home) <= 1000 })
    let detail = try await api.musicDropDetail(near[0].id)
    #expect(detail.username == "하윤")
    let song = try await api.song(detail.songId)
    #expect(song.title == "난춘")
    #expect(song.albumImagePath != nil) // 가상 커버
  }

  @Test("거리 계산 (하버사인)")
  func distance() {
    let a = Coordinate.home
    let b = MockData.at(north: 150, east: 0)
    #expect(abs(a.distance(to: b) - 150) < 1)
  }

  @Test("깨진 항목·빈 URL이 있어도 나머지 드랍과 곡은 보인다")
  func decodeLenient() throws {
    let json = """
    {"droppings":[
      {"type":"MUSIC","droppingId":"d1","userId":null,"content":null,"latitude":35.19,"longitude":128.90,"address":null,"songId":"s1","title":"난춘","artist":"새소년","albumImageUrl":""},
      {"type":"MUSIC","droppingId":"d2","latitude":"깨짐","longitude":128.90},
      {"type":"MUSIC","droppingId":"d3","userId":"u3","content":"","latitude":35.18,"longitude":128.91,"address":"부산","songId":"s2","title":"파도","artist":"새소년"}
    ]}
    """.data(using: .utf8)!
    let drops = try JSONDecoder().decode(NearbyResponse.self, from: json).droppings.compactMap(\.summary)
    #expect(drops.map(\.id) == ["d1", "d3"])
    #expect(drops[0].imageURL == nil && drops[0].content == "")

    let song = try JSONDecoder().decode(Song.self, from: """
    {"id":"s1","title":"난춘","artist":"새소년","duration":250,"albumImagePath":"","links":{"spotify":"https://open.spotify.com/track/x","youtubeMusic":null}}
    """.data(using: .utf8)!)
    #expect(song.albumImagePath == nil)
    #expect(song.links.spotify == URL(string: "https://open.spotify.com/track/x"))
  }
}
