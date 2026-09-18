import SwiftUI
import CoreText

enum FontRegistrar {
    private static var hasRegistered = false

    static func registerFonts() {
        guard !hasRegistered else { return }
        hasRegistered = true

        let fontFiles = [
            "Inter-Bold.otf",
            "Inter-SemiBold.otf",
            "Inter-Medium.otf",
            "Inter-Regular.otf",
            "PlayfairDisplay-Variable.ttf"
        ]

        for file in fontFiles {
            let nsFile = file as NSString
            if let url = Bundle.main.url(forResource: nsFile.deletingPathExtension, withExtension: nsFile.pathExtension) {
                var error: Unmanaged<CFError>?
                let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
                if success {
                    print("✅ [Font] Registered \(file)")
                }
            }
        }
    }
}

extension Font {
    enum InterWeight {
        case bold
        case semiBold
        case medium
        case regular

        var fontName: String {
            switch self {
            case .bold: return "Inter-Bold"
            case .semiBold: return "Inter-SemiBold"
            case .medium: return "Inter-Medium"
            case .regular: return "Inter-Regular"
            }
        }
    }

    static func inter(_ weight: InterWeight, size: CGFloat) -> Font {
        .custom(weight.fontName, size: size)
    }

    static func newsLargeTitle() -> Font {
        .custom("Inter-Bold", size: 34)
    }

    static func newsTitle() -> Font {
        .custom("Inter-Bold", size: 22)
    }

    static func newsHeadline() -> Font {
        .custom("Inter-SemiBold", size: 16)
    }

    static func newsSubheadline() -> Font {
        .custom("Inter-Medium", size: 14)
    }

    static func newsBody() -> Font {
        .custom("Inter-Regular", size: 16)
    }

    static func newsMeta() -> Font {
        .custom("Inter-Medium", size: 13)
    }

    static func newsCaption() -> Font {
        .custom("Inter-Regular", size: 12)
    }
}
