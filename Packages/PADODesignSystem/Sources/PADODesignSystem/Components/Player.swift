import SwiftUI

/// 점으로 이루어진 파형 — Figma: Particle waveform (점 3, 세로 간격 2, 열 간격 3)
///
/// 재생된 부분은 primary, 남은 부분은 ink-3. 실제 음원 파형이 아니라 모양을 나타내는 장식이라
/// 열마다 점 개수는 Figma 시안의 패턴을 그대로 반복해 쓴다.
public struct PADOWaveform: View {
  /// Figma 시안의 열별 점 개수 (34열)
  public static let figmaPattern = [3, 7, 5, 4, 6, 6, 1, 1, 2, 1, 1, 2, 6, 5, 4, 6, 7, 2, 1, 2, 1, 1, 1, 5, 5, 4, 6, 7, 3, 1, 2, 1, 1, 1]

  let progress: Double
  let pattern: [Int]

  static let dot: CGFloat = 3
  static let rowGap: CGFloat = 2
  static let columnGap: CGFloat = 3

  public init(progress: Double, pattern: [Int] = PADOWaveform.figmaPattern) {
    self.progress = min(max(progress, 0), 1)
    self.pattern = pattern
  }

  public var body: some View {
    Canvas { ctx, size in
      let step = Self.dot + Self.columnGap
      let columns = Int((size.width + Self.columnGap) / step)
      let played = Int((Double(columns) * progress).rounded())
      for c in 0..<columns {
        let dots = pattern[c % pattern.count]
        let height = CGFloat(dots) * Self.dot + CGFloat(dots - 1) * Self.rowGap
        let top = (size.height - height) / 2
        let color = c < played ? T.Color.primary : T.Color.ink3
        for r in 0..<dots {
          let rect = CGRect(x: CGFloat(c) * step, y: top + CGFloat(r) * (Self.dot + Self.rowGap), width: Self.dot, height: Self.dot)
          ctx.fill(Path(ellipseIn: rect), with: .color(color))
        }
      }
    }
    .frame(height: 33)
    .accessibilityHidden(true)
  }
}

/// 30초 미리듣기 줄 — 재생 버튼 + 파형 + 남은/지난 시간. Figma: Preview (높이 48, 간격 12)
public struct PADOPreviewBar: View {
  let isPlaying: Bool
  let progress: Double
  let timeText: String
  let onToggle: () -> Void

  public init(isPlaying: Bool, progress: Double, timeText: String, onToggle: @escaping () -> Void) {
    self.isPlaying = isPlaying
    self.progress = progress
    self.timeText = timeText
    self.onToggle = onToggle
  }

  public var body: some View {
    HStack(spacing: 12) {
      PADOPlayButton(isPlaying: isPlaying, action: onToggle)
      PADOWaveform(progress: progress)
      Text(timeText)
        .padoText(T.Typography.number)
        .foregroundStyle(T.Color.primary)
        .monospacedDigit() // 매초 바뀌는 숫자라 흔들리지 않게 고정폭 (Figma보다 최대 1pt 넓음)
        .accessibilityLabel("재생 시간 \(timeText)")
    }
    .frame(height: 48)
  }
}

/// 핀 미리보기 위의 큰 디스크 — Figma: Disc 112 (primary 테두리 3, 바깥 고리 132, 가운데 구멍 14)
public struct PADODisc: View {
  let art: Image?
  let size: CGFloat

  public init(art: Image?, size: CGFloat = 112) {
    self.art = art
    self.size = size
  }

  public var body: some View {
    ZStack {
      Circle()
        .stroke(T.Color.primary, lineWidth: 1)
        .frame(width: size * 132 / 112, height: size * 132 / 112)
      PADOArt(art, size: size)
        .background(T.Color.page, in: Circle())
        .overlay(Circle().strokeBorder(T.Color.primary, lineWidth: 3))
        .shadow(color: T.Color.glow.opacity(0.21), radius: 15)
      Circle()
        .fill(T.Color.page)
        .overlay(Circle().strokeBorder(T.Color.primary, lineWidth: 1.5))
        .frame(width: size / 8, height: size / 8)
    }
    .accessibilityHidden(true)
  }
}

/// 지도 위 작은 재생 디스크 — Figma: B/Mini Disc (60, 진행 고리 2.5)
public struct PADOMiniDisc: View {
  let art: Image?
  let progress: Double
  let isPlaying: Bool

  public init(art: Image?, progress: Double, isPlaying: Bool) {
    self.art = art
    self.progress = progress
    self.isPlaying = isPlaying
  }

  public var body: some View {
    ZStack {
      Circle().stroke(T.Color.line, lineWidth: 2.5).frame(width: 56, height: 56)
      Circle()
        .trim(from: 0, to: min(max(progress, 0), 1))
        .stroke(T.Color.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .frame(width: 56, height: 56)
      PADOArt(art, size: 52)
      if isPlaying {
        Circle()
          .fill(T.Color.page)
          .overlay(Circle().strokeBorder(T.Color.primary, lineWidth: 1.5))
          .frame(width: 12, height: 12)
      } else {
        Circle().fill(T.Color.page.opacity(0.75)).frame(width: 24, height: 24)
        PADOIconView(.play, size: 12, color: T.Color.primary)
      }
    }
    .frame(width: 60, height: 60)
    .shadow(color: T.Color.glow.opacity(isPlaying ? 0.19 : 0.08), radius: 7)
    .accessibilityElement()
    .accessibilityLabel(isPlaying ? "재생 중" : "일시정지됨")
  }
}
