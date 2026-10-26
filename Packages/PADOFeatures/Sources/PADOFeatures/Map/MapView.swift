import ComposableArchitecture
import MapKit
import PADODesignSystem
import PADOKit
import SwiftUI

/// 지도 홈 화면 — Figma J 2.1 지도 홈 / 2.2 핀 미리보기
public struct MapView: View {
  @Bindable var store: StoreOf<MapFeature>
  @State private var camera: MapCameraPosition = .automatic
  @State private var tab: PADODock.Tab = .map

  public init(store: StoreOf<MapFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      map
      fades
      VStack(spacing: 0) {
        header
        Spacer()
        if store.player.track != nil {
          HStack {
            Spacer()
            Button { store.send(.miniDiscTapped) } label: {
              RemoteArt(url: store.player.track?.artURL) { art in
                PADOMiniDisc(art: art, progress: store.player.progress, isPlaying: store.player.isPlaying)
              }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("재생 중인 드랍 열기")
            .padding(.trailing, 14)
            .padding(.bottom, 12)
          }
          .transition(.opacity)
        }
        nearbyStrip
        PADODock(selection: tab, onSelect: { tab = $0 }, onDrop: {})
          .padding(.horizontal, 16)
          .padding(.bottom, 8)
      }
      previewLayer
    }
    .background(PADOTokens.Color.page)
    .task { await store.send(.task).finish() }
    .onChange(of: store.center) { _, center in
      guard let center else { return }
      camera = .region(MKCoordinateRegion(center: center.clLocation, latitudinalMeters: 1400, longitudinalMeters: 1400))
    }
    .animation(.easeOut(duration: 0.28), value: store.preview != nil)
    .animation(.easeOut(duration: 0.2), value: store.player.track?.id)
  }

  // MARK: 지도

  private var map: some View {
    Map(position: $camera) {
      if let center = store.center {
        Annotation("내 위치", coordinate: center.clLocation, anchor: .center) { PADOMeMarker() }
      }
      ForEach(store.drops) { drop in
        Annotation(drop.title, coordinate: drop.coordinate.clLocation, anchor: .bottom) {
          Button { store.send(.pinTapped(id: drop.id)) } label: { pin(for: drop) }
            .buttonStyle(.plain)
            .accessibilityLabel("\(drop.title), \(drop.subtitle)")
        }
      }
    }
    .mapStyle(.standard(emphasis: .muted, pointsOfInterest: .excludingAll))
    .mapControls {}
    .ignoresSafeArea()
  }

  @ViewBuilder private func pin(for drop: DropSummary) -> some View {
    let active = store.selectedDropId == drop.id
    switch drop.kind {
    case .music:
      RemoteArt(url: drop.imageURL) { art in
        PADODropPin(.music(art: art), isActive: active, title: drop.title, subtitle: distanceLabel(drop))
      }
    case .vote:
      PADODropPin(.vote)
    case let .playlist(_, ids):
      RemoteArt(url: drop.imageURL) { art in PADODropPin(.playlist(arts: [art], count: ids.count)) }
    }
  }

  // MARK: 위·아래 겹침 (Figma: 지도 위아래 흰색 페이드)

  private var fades: some View {
    VStack(spacing: 0) {
      LinearGradient(colors: [PADOTokens.Color.page, PADOTokens.Color.page.opacity(0)], startPoint: .top, endPoint: .bottom).frame(height: 190)
      Spacer()
      LinearGradient(colors: [PADOTokens.Color.page.opacity(0), PADOTokens.Color.page], startPoint: .top, endPoint: .bottom).frame(height: 354)
    }
    .ignoresSafeArea()
    .allowsHitTesting(false)
  }

  private var header: some View {
    HStack(spacing: 4) {
      Text(store.placeName ?? "내 주변")
        .padoText(PADOTokens.Typography.title)
        .foregroundStyle(PADOTokens.Color.ink)
      PADOIconView(.chevronDown, size: 18, color: PADOTokens.Color.ink)
      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)
    .overlay(alignment: .bottomLeading) { statusBanner.offset(y: 44) }
  }

  @ViewBuilder private var statusBanner: some View {
    switch store.loading {
    case let .failed(message):
      Button { store.send(.retryTapped) } label: {
        Text(message).padoText(PADOTokens.Typography.caption).foregroundStyle(PADOTokens.Color.ink)
          .padding(.horizontal, 14).padding(.vertical, 8)
          .background(PADOTokens.Color.card, in: Capsule())
          .overlay(Capsule().strokeBorder(PADOTokens.Color.line))
      }
      .buttonStyle(.plain)
      .padding(.leading, 20)
    case .loaded where store.drops.isEmpty:
      Text("아직 주변에 남겨진 노래가 없어요")
        .padoText(PADOTokens.Typography.caption).foregroundStyle(PADOTokens.Color.ink2)
        .padding(.leading, 20)
    default:
      EmptyView()
    }
  }

  private var nearbyStrip: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 6) {
        Text("가까운 드랍").padoText(PADOTokens.Typography.captionStrong).foregroundStyle(PADOTokens.Color.ink)
        Text("\(store.drops.count)").padoText(PADOTokens.Typography.number).foregroundStyle(PADOTokens.Color.primary)
      }
      .padding(.leading, 20)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 14) {
          ForEach(store.nearby) { drop in
            Button { store.send(.pinTapped(id: drop.id)) } label: {
              RemoteArt(url: drop.imageURL) { art in
                PADONearbyItem(title: drop.title, artist: drop.subtitle, art: art, isNear: isNear(drop))
              }
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 20)
      }
    }
    .padding(.bottom, 16)
    .opacity(store.drops.isEmpty ? 0 : 1)
  }

  // MARK: 핀 미리보기 (튕김 없이 아래에서 올라옴)

  @ViewBuilder private var previewLayer: some View {
    if let previewStore = store.scope(state: \.preview, action: \.preview.presented) {
      ZStack(alignment: .bottom) {
        PADOTokens.Color.page.opacity(0.35)
          .ignoresSafeArea()
          .onTapGesture { store.send(.preview(.dismiss)) }
          .accessibilityLabel("미리보기 닫기")
          .accessibilityAddTraits(.isButton)
        PinPreviewView(store: previewStore, player: store.player)
          .gesture(DragGesture(minimumDistance: 12).onEnded { value in
            if value.translation.height > 80 { store.send(.preview(.dismiss)) }
          })
      }
      .ignoresSafeArea(edges: .bottom)
      .transition(.move(edge: .bottom).combined(with: .opacity))
    }
  }

  // MARK: 표시용

  private func distanceMeters(_ drop: DropSummary) -> Double? { store.center.map { drop.coordinate.distance(to: $0) } }

  private func distanceLabel(_ drop: DropSummary) -> String {
    guard let m = distanceMeters(drop) else { return drop.subtitle }
    return "\(drop.subtitle) · \(Int(m.rounded()))m"
  }

  /// 300m 안은 진하게, 그 밖은 흐리게 (Figma 가까운 드랍 줄)
  private func isNear(_ drop: DropSummary) -> Bool { (distanceMeters(drop) ?? 0) <= 300 }
}

extension Coordinate {
  var clLocation: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}
