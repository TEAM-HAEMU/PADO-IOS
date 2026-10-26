#if os(iOS)
import SnapshotTesting
import SwiftUI
import XCTest
@testable import PADODesignSystem

/// 컴포넌트 모양 회귀 테스트 — 기준 이미지는 __Snapshots__/에 있고, 모양이 바뀌면 실패한다.
/// 의도한 변경이면 SNAPSHOT_RECORD=1 로 한 번 돌려 기준 이미지를 다시 만든다.
/// 기준 기기: iPhone 17 시뮬레이터 (@3x, 라이트)
@MainActor
final class ComponentSnapshotTests: XCTestCase {
  override func invokeTest() {
    withSnapshotTesting(record: ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1" ? .all : .missing) {
      super.invokeTest()
    }
  }

  private func snap<V: View>(_ view: V, width: CGFloat = 402, height: CGFloat? = nil, named name: String? = nil, file: StaticString = #filePath, testName: String = #function, line: UInt = #line) {
    let host = view
      .frame(width: width)
      .fixedSize(horizontal: false, vertical: height == nil)
      .frame(height: height)
      .background(PADOTokens.Color.page)
      .environment(\.colorScheme, .light)
    let layout: SwiftUISnapshotLayout = height.map { .fixed(width: width, height: $0) } ?? .sizeThatFits
    assertSnapshot(of: host, as: .image(precision: 0.995, perceptualPrecision: 0.98, layout: layout, traits: .init(displayScale: 3)), named: name, file: file, testName: testName, line: line)
  }

  func testPinPreviewCard() {
    snap(
      VStack { Spacer(minLength: 80); PADOPinPreviewCard(model: .sample, art: nil, isPlaying: true, progress: 13.0 / 34, timeText: "0:26") }
        .background(PADOTokens.Color.card2),
      height: 560
    )
  }

  func testButtons() {
    snap(VStack(spacing: 12) {
      PADOButton("시작하기", action: {})
      PADOButton("이메일로 계속하기", style: .secondary, action: {})
      PADOButton("카카오로 계속하기", style: .kakao, action: {})
      HStack(spacing: 10) {
        PADOCountPill(.heart, count: 18, label: "좋아요", action: {})
        PADOCountPill(.comment, count: 4, label: "댓글", action: {})
        PADOListenButton(service: .spotify, action: {})
      }
    }.padding(20))
  }

  func testPreviewBarStates() {
    snap(VStack(spacing: 16) {
      PADOPreviewBar(isPlaying: true, progress: 0.38, timeText: "0:26", onToggle: {})
      PADOPreviewBar(isPlaying: false, progress: 0, timeText: "0:30", onToggle: {})
    }.padding(20))
  }

  func testMapPieces() {
    snap(VStack(alignment: .leading, spacing: 24) {
      HStack(alignment: .bottom, spacing: 20) {
        PADODropPin(.music(art: nil))
        PADODropPin(.vote)
        PADODropPin(.playlist(arts: [], count: 8))
        PADOFarPin()
        PADOMeMarker()
        PADOMiniDisc(art: nil, progress: 0.6, isPlaying: true)
      }
      PADODropPin(.music(art: nil), isActive: true, title: "난춘", subtitle: "새소년 · 180m")
      HStack(spacing: 14) {
        PADONearbyItem(title: "난춘", artist: "새소년", art: nil)
        PADONearbyItem(title: "긴 꿈", artist: "새소년", art: nil, isNear: false)
      }
    }.padding(20))
  }

  func testDock() {
    snap(PADODock(selection: .map, hasUnread: true, onSelect: { _ in }, onDrop: {}).padding(16))
  }

  func testTypographyRamp() {
    snap(VStack(alignment: .leading, spacing: 8) {
      ForEach(PADOTokens.textStyles) { Text("음악이 남아 있는 거리 \($0.name)").padoText($0).foregroundStyle(PADOTokens.Color.ink) }
    }.padding(20).frame(maxWidth: .infinity, alignment: .leading))
  }
}
#endif
