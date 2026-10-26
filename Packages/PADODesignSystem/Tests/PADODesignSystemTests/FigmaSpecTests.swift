#if os(iOS)
import SwiftUI
import Testing
import UIKit
@testable import PADODesignSystem

/// Figma 명세 일치 테스트 — 컴포넌트를 실제로 배치했을 때의 크기가 Figma 프레임 크기(pt)와 같은지 본다.
/// 숫자 출처: PADO › UI · 최신 › 7 화이트 오션 시안 › J 2.1 지도 홈 / J 2.2 핀 미리보기
@MainActor
@Suite("Figma 명세 크기")
struct FigmaSpecTests {
  /// 제안 폭 안에서 뷰가 차지하는 크기
  private func size<V: View>(_ view: V, width: CGFloat? = nil) -> CGSize {
    let host = UIHostingController(rootView: view.fixedSize(horizontal: width == nil, vertical: true))
    return host.sizeThatFits(in: CGSize(width: width ?? 1000, height: 10_000))
  }

  private func expectClose(_ actual: CGFloat, _ figma: CGFloat, _ what: String, tolerance: CGFloat = 1) {
    #expect(abs(actual - figma) <= tolerance, "\(what): 앱 \(actual)pt / Figma \(figma)pt")
  }

  @Test("한마디 카드 360×104")
  func noteCard() {
    let s = size(PADONoteCard(author: "하윤", time: "9월 21일 18:40", text: PADOPinPreviewCard.Model.sample.note), width: 360)
    expectClose(s.height, 104, "Note 높이")
  }

  @Test("미리듣기 줄 높이 48, 재생 버튼 48")
  func previewBar() {
    expectClose(size(PADOPreviewBar(isPlaying: true, progress: 0.4, timeText: "0:26", onToggle: {}), width: 360).height, 48, "Preview 높이")
    let b = size(PADOPlayButton(isPlaying: true, action: {}))
    expectClose(b.width, 48, "재생 버튼 폭")
    expectClose(b.height, 48, "재생 버튼 높이")
  }

  @Test("좋아요 알약 70×48, 댓글 알약 65×48, 전체 듣기 높이 52")
  func actions() {
    let like = size(PADOCountPill(.heart, count: 18, label: "좋아요", action: {}))
    expectClose(like.width, 70, "좋아요 폭", tolerance: 1.5)
    expectClose(like.height, 48, "좋아요 높이")
    let comment = size(PADOCountPill(.comment, count: 4, label: "댓글", action: {}))
    expectClose(comment.width, 65, "댓글 폭", tolerance: 1.5)
    expectClose(size(PADOListenButton(service: .spotify, action: {}), width: 205).height, 52, "전체 듣기 높이")
  }

  @Test("태그 높이 20")
  func tag() {
    let s = size(PADOTag(.music))
    expectClose(s.height, 20, "MUSIC 태그 높이")
    expectClose(s.width, 70, "MUSIC 태그 폭", tolerance: 2)
  }

  @Test("곡 제목 블록 높이 62 (38 + 2 + 22)")
  func songTitle() {
    expectClose(size(PADOSongTitle(title: "난춘", artist: "새소년"), width: 360).height, 62, "제목 블록 높이")
  }

  @Test("가까운 드랍 칸 66×104")
  func nearby() {
    let s = size(PADONearbyItem(title: "난춘", artist: "새소년", art: nil))
    expectClose(s.width, 66, "폭")
    expectClose(s.height, 104, "높이")
  }

  @Test("하단 탭 높이 68")
  func dock() {
    expectClose(size(PADODock(selection: .map, onSelect: { _ in }, onDrop: {}), width: 370).height, 68, "Dock 높이")
  }

  @Test("넓은 버튼 높이 54 (로그인 버튼)")
  func button() {
    expectClose(size(PADOButton("카카오로 계속하기", style: .kakao, action: {}), width: 354).height, 54, "버튼 높이")
  }
}
#endif
