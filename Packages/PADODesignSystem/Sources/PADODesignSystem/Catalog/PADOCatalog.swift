import SwiftUI

/// 디자인 시스템 카탈로그 — 토큰과 컴포넌트를 한 화면에서 확인한다 (앱 디버그 메뉴·Xcode 미리보기용)
public struct PADOCatalog: View {
  @State private var playing = true
  @State private var tab: PADODock.Tab = .map

  public init() {}

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 32) {
        section("색 (Figma J · 스카이 퓨어)") {
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
            ForEach(PADOTokens.colorNames, id: \.name) { item in
              VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: PADOTokens.Radius.sm)
                  .fill(color(named: item.name))
                  .overlay(RoundedRectangle(cornerRadius: PADOTokens.Radius.sm).strokeBorder(PADOTokens.Color.line))
                  .frame(height: 48)
                Text(item.name).padoText(PADOTokens.Typography.captionStrong).foregroundStyle(PADOTokens.Color.ink)
                Text(item.hex).padoText(PADOTokens.Typography.label).foregroundStyle(PADOTokens.Color.ink3)
              }
            }
          }
        }

        section("글자") {
          VStack(alignment: .leading, spacing: 12) {
            ForEach(PADOTokens.textStyles) { style in
              HStack(alignment: .firstTextBaseline) {
                Text("음악이 남아 있는 거리").padoText(style).foregroundStyle(PADOTokens.Color.ink)
                Spacer()
                Text("\(style.name) \(Int(style.size))/\(style.lineHeight.map { "\(Int($0))" } ?? "auto")")
                  .padoText(PADOTokens.Typography.label).foregroundStyle(PADOTokens.Color.ink3)
              }
            }
          }
        }

        section("아이콘") {
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 56))], spacing: 16) {
            ForEach(PADOIcon.allCases, id: \.self) { icon in
              VStack(spacing: 4) {
                PADOIconView(icon, size: 24)
                Text(icon.rawValue).font(.system(size: 9)).foregroundStyle(PADOTokens.Color.ink3).lineLimit(1)
              }
            }
          }
        }

        section("버튼") {
          VStack(spacing: 12) {
            PADOButton("시작하기", action: {})
            PADOButton("이메일로 계속하기", icon: .user, style: .secondary, action: {})
            PADOButton("카카오로 계속하기", style: .kakao, action: {})
            HStack(spacing: 10) {
              PADOCountPill(.heart, count: 18, label: "좋아요", action: {})
              PADOCountPill(.comment, count: 4, label: "댓글", action: {})
              PADOListenButton(service: .spotify, action: {})
            }
          }
        }

        section("재생") {
          VStack(spacing: 20) {
            PADOPreviewBar(isPlaying: playing, progress: 0.38, timeText: "0:26") { playing.toggle() }
            HStack(spacing: 24) {
              PADODisc(art: nil, size: 80)
              PADOMiniDisc(art: nil, progress: 0.6, isPlaying: true)
              PADOMiniDisc(art: nil, progress: 0.6, isPlaying: false)
            }
            .frame(maxWidth: .infinity)
          }
        }

        section("지도") {
          VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .bottom, spacing: 20) {
              PADODropPin(.music(art: nil))
              PADODropPin(.vote)
              PADODropPin(.playlist(arts: [], count: 8))
              PADOFarPin()
              PADOMeMarker()
            }
            PADODropPin(.music(art: nil), isActive: true, title: "난춘", subtitle: "새소년 · 180m")
            HStack(spacing: 14) {
              PADONearbyItem(title: "난춘", artist: "새소년", art: nil)
              PADONearbyItem(title: "긴 꿈", artist: "새소년", art: nil, isNear: false)
            }
            PADODock(selection: tab, hasUnread: true, onSelect: { tab = $0 }, onDrop: {})
          }
        }

        section("태그 · 정보") {
          VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) { ForEach(PADODropKind.allCases, id: \.self) { PADOTag($0) } }
            PADOMetaLabel(.pin, "부산 강서구 가락대로 1397번길")
            PADONoteCard(author: "하윤", time: "9월 21일 18:40", text: PADOPinPreviewCard.Model.sample.note)
          }
        }
      }
      .padding(20)
    }
    .background(PADOTokens.Color.page)
  }

  private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(title).padoText(PADOTokens.Typography.title).foregroundStyle(PADOTokens.Color.ink)
      content()
    }
  }

  private func color(named name: String) -> Color {
    let hex = PADOTokens.colorNames.first { $0.name == name }?.hex ?? "#000000"
    let v = UInt32(hex.dropFirst(), radix: 16) ?? 0
    return Color(.sRGB, red: Double(v >> 16 & 255) / 255, green: Double(v >> 8 & 255) / 255, blue: Double(v & 255) / 255)
  }
}

#Preview("카탈로그") { PADOCatalog() }
