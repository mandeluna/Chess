import QuartzCore

class ChessPieceLayer: CALayer {
    var isWhite: Bool = false
    var piece: Int = 0
    var sourceSquare: Int = 0  // for dragging
}
