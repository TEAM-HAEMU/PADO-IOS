import SwiftUI

/// 앨범 아트 URL을 불러와 디자인 시스템 컴포넌트에 Image로 넘긴다 (로딩·실패 중엔 nil → 컴포넌트의 기본 모양).
struct RemoteArt<Content: View>: View {
  let url: URL?
  @ViewBuilder let content: (Image?) -> Content

  var body: some View {
    AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.2))) { phase in
      content(phase.image)
    }
  }
}
