import ComposableArchitecture
import PADODesignSystem
import PADOFeatures
import SwiftUI

@main
struct PADOApp: App {
  /// 앱 전체 상태는 지도 홈 하나에서 시작한다 (2단계에서 로그인·탭이 붙으면 AppFeature로 감싼다)
  @MainActor static let store = Store(initialState: MapFeature.State()) { MapFeature() }

  init() {
    PADOFonts.register()
  }

  var body: some Scene {
    WindowGroup {
      MapView(store: Self.store)
        .preferredColorScheme(.light)
    }
  }
}
