import CoreText
import SwiftUI

/// 패키지에 들어 있는 Pretendard를 앱 실행 중 한 번만 등록한다 (Info.plist의 UIAppFonts 없이 쓰기 위해).
public enum PADOFonts {
  private static let registration: Void = {
    for name in ["Pretendard-Regular", "Pretendard-Medium", "Pretendard-SemiBold", "Pretendard-Bold"] {
      guard let url = Bundle.module.url(forResource: name, withExtension: "otf") else {
        assertionFailure("글꼴 파일 없음: \(name).otf")
        continue
      }
      CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
  }()

  /// 앱 시작 시 한 번 부른다. 여러 번 불러도 한 번만 등록된다.
  public static func register() { _ = registration }

  /// 스타일에 맞는 SwiftUI 글꼴. Dynamic Type을 따라 커지되, 기본 크기는 Figma 값과 같다.
  public static func font(_ style: PADOTextStyle) -> Font {
    register()
    return .custom(style.postScriptName, size: style.size)
  }

  /// 글꼴이 원래 가진 줄 높이 (ascent + descent + leading). Figma 줄 높이와의 차이를 여백으로 채울 때 쓴다.
  static func naturalLineHeight(_ style: PADOTextStyle) -> CGFloat {
    register()
    let ct = CTFontCreateWithName(style.postScriptName as CFString, style.size, nil)
    return CTFontGetAscent(ct) + CTFontGetDescent(ct) + CTFontGetLeading(ct)
  }
}
