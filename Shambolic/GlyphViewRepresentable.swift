import SwiftUI

struct GlyphViewRepresentable: UIViewRepresentable {
    var glyph: String
    var fontName: String = "Apple Symbols"
    var fontSize: CGFloat = 80
    var fillColor: UIColor = .black
    var strokeColor: UIColor = .clear
    var strokeWidth: CGFloat = 0
    
    func makeUIView(context: Context) -> GlyphView {
        let view = GlyphView()
        view.glyph = glyph
        view.fontName = fontName
        view.fontSize = fontSize
        view.fillColor = fillColor
        view.strokeColor = strokeColor
        view.strokeWidth = strokeWidth
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: GlyphView, context: Context) {
        uiView.glyph = glyph
        uiView.fontName = fontName
        uiView.fontSize = fontSize
        uiView.fillColor = fillColor
        uiView.strokeColor = strokeColor
        uiView.strokeWidth = strokeWidth
    }
}

// MARK: - SwiftUI Preview for testing

#Preview("GlyphViewRepresentable") {
    VStack(spacing: 24) {
        GlyphViewRepresentable(glyph: "♞", fontName: "Apple Symbols", fontSize: 90, fillColor: .systemIndigo, strokeColor: .black, strokeWidth: 3)
            .frame(width: 120, height: 120)
        GlyphViewRepresentable(glyph: "♛", fontName: "Apple Symbols", fontSize: 80, fillColor: .systemYellow, strokeColor: .systemOrange, strokeWidth: 2)
            .frame(width: 100, height: 100)
        GlyphViewRepresentable(glyph: "♙", fontName: "Apple Symbols", fontSize: 70, fillColor: .white, strokeColor: .black, strokeWidth: 1.5)
            .frame(width: 80, height: 80)
    }
    .padding()
    .background(Color(.systemGray5))
}
