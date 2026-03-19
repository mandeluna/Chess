//
//  ChessBoardView.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-11.
//

import Foundation
import UIKit

@objc
protocol ChessBoardViewDelegate: AnyObject {
    // Primary method for selection validation
    func chessboardView(_ chessboardView: ChessBoardView,
                        shouldSelect square: Int,
                        withCurrentSelection: SelectionContext?) -> SelectionContext?
    
    // Move execution
    func chessboardView(_ chessboardView: ChessBoardView,
                        didMovePieceFrom fromSquare: Int,
                        to toSquare: Int)

    // Piece information
    func chessboardView(_ chessboardView: ChessBoardView, pieceFor square: Int) -> Int
    
}

@objc
class SelectionContext : NSObject {
    @objc public let isWhite : Bool
    @objc public let piece : Int
    @objc public let square : Int
    @objc public var moves : [ChessMove] = []
    @objc public var captures : [Int] = []
    
    @objc init(isWhite: Bool, piece: Int, square: Int) {
        self.isWhite = isWhite
        self.piece = piece
        self.square = square
    }
}

class ChessBoardView: UIView {

    @objc
    weak var delegate: ChessBoardViewDelegate?
    
    @objc
    public func switchSides() {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)

        boardDirection *= -1
        updateLabelLayers()
        updateBoardTransforms()

        CATransaction.commit()
        setNeedsDisplay()
    }
    
    @objc
    public func isWhiteOnBottom() -> Bool {
        return boardDirection > 0
    }
    
    @objc
    public func addPiece(_ piece: Int, at square: Int, white: Bool) {
        let pieceLayer = newPiece(piece, white: white)
        let squareLayer = squares[square]
        pieceLayer.position = squareLayer.position
        squareLayer.pieceLayer = pieceLayer
    }
    
    @objc
    public func removePiece(_ piece: Int, at square: Int) {
        let squareLayer = squares[square]
        squareLayer.pieceLayer?.removeFromSuperlayer()
        squareLayer.setNeedsDisplay()
        squareLayer.pieceLayer = nil
    }

    @objc
    public func movePiece(from origin: Int, to destination: Int) {
        let sourceSquareLayer = squares[origin]
        let sourceLayer = sourceSquareLayer.pieceLayer!
        let destLayer = squares[destination]
        sourceLayer.position = destLayer.position
        sourceSquareLayer.pieceLayer = nil
        destLayer.pieceLayer = sourceLayer
    }

    @objc
    public func addMoveIndicationLayers(at square: Int, moves: [ChessMove], captures: [Int]) {
        if moves.count == 0 {
            return
        }
        let thisLayer = squares[square]
        addMoveStartIndicationTo(thisLayer)
        
        for move in moves {
            let destLayer = squares[Int(move.destinationSquare)]
            if captures.contains(Int(move.destinationSquare)) {
                addMoveCaptureIndicationLayerTo(destLayer)
            }
            else {
                addMoveIndicationLayerTo(destLayer)
            }
        }
    }

    private func addMoveStartIndicationTo(_ square: SquareLayer) {
        let spot = CALayer()
        spot.bounds = square.bounds
        spot.name = "spot"
        spot.position = CGPoint(x: cellWidth / 2, y: cellWidth / 2)
        spot.backgroundColor = UIColor(named: "move_highlight")!.cgColor
        square.addSublayer(spot)
    }

    private func addMoveCaptureIndicationLayerTo(_ square: SquareLayer) {
        let highlightColor = UIColor(named: "move_highlight")!.cgColor
        let spot = createCaptureIndicationLayer(width: cellWidth, color: highlightColor)
        spot.bounds = square.bounds
        spot.name = "spot"
        spot.position = CGPoint(x: cellWidth / 2, y: cellWidth / 2)
        spot.backgroundColor = highlightColor
        square.addSublayer(spot)
    }

    private func addMoveIndicationLayerTo(_ square: SquareLayer) {
        let spot = CALayer()
        spot.bounds = CGRectMake(0, 0, cellWidth / 3, cellWidth / 3)
        spot.cornerRadius = cellWidth / 6
        spot.name = "spot"
        spot.position = CGPoint(x: cellWidth / 2, y: cellWidth / 2)
        spot.backgroundColor = UIColor(named: "move_highlight")!.cgColor
        square.addSublayer(spot)
    }

    private func createCaptureIndicationLayer(width: CGFloat, color: CGColor) -> CALayer {
        // Create the content layer
        let contentLayer = CALayer()
        contentLayer.frame = CGRectMake(0, 0, width, width)
        contentLayer.backgroundColor = color
        
        // Create the inverse mask
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, width), false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        // Fill entire context with black (opaque)
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRectMake(0, 0, width, width))
        
        // Clear the rounded rectangle area (make it transparent)
        context.setBlendMode(.clear)
        context.setFillColor(UIColor.clear.cgColor)
        
        let roundedPath = UIBezierPath(roundedRect:CGRectMake(0, 0, width, width), cornerRadius:width / 4.0)
        context.addPath(roundedPath.cgPath)
        context.fillPath()
        
        let maskImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Create and apply the mask layer
        let maskLayer = CALayer()
        maskLayer.frame = contentLayer.bounds
        maskLayer.contents = maskImage.cgImage
        
        contentLayer.mask = maskLayer
        
        return contentLayer
    }
    
    @objc
    public func removeAttackIndicationLayers() {
        for square in squares {
            removeAttackIndicationLayerFrom(square)
        }
    }
    
    @objc
    public func removeMoveIndicationLayers() {
        for square in squares {
            removeMoveIndicationLayerFrom(square)
        }
    }
    
    private func removeAttackIndicationLayerFrom(_ square: SquareLayer) {
        removeSublayers(square, named: "attack")
    }

    private func removeMoveIndicationLayerFrom(_ square: SquareLayer) {
        removeSublayers(square, named: "spot")
    }

    private func removeSublayers(_ square: SquareLayer, named: String) {
        guard let sublayers = square.sublayers else { return }
        for sublayer in sublayers {
            if sublayer.name == named {
                sublayer.removeFromSuperlayer()
                square.setNeedsDisplay()
            }
        }
    }

    @objc
    func addKingAttackIndicator(to destination: Int) {
        // radial-gradient(ellipse at center, rgb(255, 0, 0) 0%, rgb(231, 0, 0) 25%, rgba(169, 0, 0, 0) 89%, rgba(158, 0, 0, 0) 100%)
        let square = squares[destination]
        let squareRect = square.bounds.size
        
        let attack = CAGradientLayer()
        attack.frame = square.bounds
        attack.type = .radial
        attack.colors = [
            UIColor(red: 1.0, green: 0, blue: 0, alpha: 1.0).cgColor,
            UIColor(red: 231.0/255.0, green: 0, blue: 0, alpha: 1.0).cgColor,
            UIColor(red: 169/255.0, green: 0, blue: 0, alpha: 0.0).cgColor,
            UIColor(red: 158.0/255.0, green: 0, blue: 0, alpha: 0.0).cgColor
        ]
        attack.locations = [0, 0.25, 0.89, 1.0].map { NSNumber(value: $0) }
        attack.startPoint = CGPoint(x: 0.5, y: 0.5)
        attack.endPoint = CGPoint(x: 1.15, y: 1.15)
        attack.name = "attack"
        
        attack.position = CGPoint(x: squareRect.width / 2, y: squareRect.height / 2)
        square.addSublayer(attack)
    }

    private func newPiece(_ piece: Int, white isWhite: Bool) -> ChessPieceLayer {
        let imageNames : [String] = [
            "whitePawnImage.png",
            "whiteKnightImage.png",
            "whiteBishopImage.png",
            "whiteRookImage.png",
            "whiteQueenImage.png",
            "whiteKingImage.png",
            
            "blackPawnImage.png",
            "blackKnightImage.png",
            "blackBishopImage.png",
            "blackRookImage.png",
            "blackQueenImage.png",
            "blackKingImage.png"
        ]

        let pieceLayer = ChessPieceLayer()
        let index = isWhite ? piece - 1 : piece + 5
        let image = UIImage(named: imageNames[index])!

        pieceLayer.contents = image.cgImage
        pieceLayer.isWhite = isWhite
        pieceLayer.piece = piece
        pieceLayer.bounds = CGRect(x: 0, y: 0, width: cellWidth, height: cellWidth)
        pieceLayer.transform = CATransform3DMakeScale(boardDirection, boardDirection, 1.0)

        boardLayer.addSublayer(pieceLayer)
        return pieceLayer
    }
    
    private let boardLayer = CALayer()
    private var squares = [SquareLayer]()
    private var labels = [CATextLayer]()
    private var boardDirection = 1.0
    private var cellWidth = 80.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        layer.addSublayer(boardLayer)
        updateCellSize()
        // 0,0 is the top left corner of the view, as god intended
        boardLayer.isGeometryFlipped = true
        boardLayer.anchorPoint = CGPoint(x:0.5, y:0.5)
        boardLayer.position = CGPoint(x: 0.0, y: 0.0)
        boardLayer.masksToBounds = true
        setupSquareLayers()
        setupLabelLayers()
        updateBoardTransforms()
    }
    
//    private var label = UILabel()

    public override func layoutSubviews() {
        super.layoutSubviews()
//        label.text = "size: \(bounds.size)"
//        label.textColor = .white
//        label.backgroundColor = UIColor(white: 0.2, alpha: 0.5)
//        label.frame = CGRect(x: 80, y: 150, width: 160, height: 20)
//        addSubview(label)
        updateCellSize()
    }
    
    public func updateBoard(_ pieces: [ChessPiece?]) {
        for square in 0..<64 {
            let newPiece = pieces[square]
            let existingPiece = squares[square].pieceLayer

            // 1. removing a piece
            if newPiece == nil && existingPiece != nil {
                removePiece(Int(existingPiece!.piece), at: square)
            }
            // 2. adding a piece
            else if newPiece != nil && existingPiece == nil {
                addPiece(Int(newPiece!.piece), at: square, white: newPiece!.isWhite)
            }
            // 3. replacing a piece
            else if newPiece != nil && existingPiece != nil {
                removePiece(Int(existingPiece!.piece), at: square)
                addPiece(Int(newPiece!.piece), at: square, white: newPiece!.isWhite)
            }
        }
    }

    public func updateCellSize() {
        let newSize = min(bounds.size.width, bounds.size.height)
        guard newSize != .zero else { return }

        cellWidth = newSize / 8.0
        boardLayer.frame = CGRect(x: 0, y: 0, width: newSize, height: newSize)
        updateBoardTransforms()
        updateSquareLayers()
        updateLabelLayers()
        setNeedsDisplay()
    }

    private func updateBoardTransforms() {
        let boardRotation = boardDirection > 0 ? 0.0 : Double.pi
        let boardTransform = CATransform3DMakeRotation(boardRotation, 0.0, 0.0, 1.0)
        let piecesTransform = CATransform3DMakeScale(boardDirection, boardDirection, 1.0)
        
        boardLayer.transform = boardTransform
        
        for squareLayer in squares {
            if let pieceLayer = squareLayer.pieceLayer {
                pieceLayer.transform = piecesTransform
            }
        }
        for textLayer in labels {
            textLayer.transform = piecesTransform
        }
    }

    private func setupSquareLayers() {
        for _ in 0..<64 {
            let squareLayer = SquareLayer()
            squares.append(squareLayer)
            boardLayer.addSublayer(squareLayer)
        }
        updateSquareLayers()
    }
    
    private func updateSquareLayers() {
        if squares.isEmpty { return }

        let white = UIColor(named: "white_square") ?? UIColor.white
        let black = UIColor(named: "black_square") ?? UIColor.darkGray

        for row in 0..<8 {
            for col in 0..<8 {
                let index = row * 8 + col
                let isWhiteSquare = row % 2 == 0 && col % 2 != 0 || row % 2 != 0 && col % 2 == 0

                let rect = CGRect(x: CGFloat(col) * cellWidth,
                                  y: CGFloat(row) * cellWidth,
                                  width: cellWidth,
                                  height: cellWidth)

                let squareLayer = squares[index]
                squareLayer.backgroundColor = isWhiteSquare ? white.cgColor : black.cgColor
                squareLayer.frame = rect
                squares[index].square = index

                if let pieceLayer = squareLayer.pieceLayer {
                    pieceLayer.bounds = CGRect(x: 0, y: 0, width: cellWidth, height: cellWidth)
                    pieceLayer.position = squareLayer.position
                }
            }
        }
    }
    
    private func setupLabelLayers() {
        for _ in 0..<16 {
            labels.append(CATextLayer())
        }
        updateLabelLayers()
    }
    
    private func updateLabelLayers() {
        if labels.isEmpty { return }

        let rankLabels = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let fileLabels = ["1", "2", "3", "4", "5", "6", "7", "8"]

        let white = UIColor(named: "white_square") ?? UIColor.white
        let black = UIColor(named: "black_square") ?? UIColor.darkGray

        let fontSize = 16.0 * cellWidth / 80.0
        let leftMargin = 12.0 * cellWidth / 80.0
        let rightMargin = 14.0 * cellWidth / 80.0
        let bottomMargin = 10.0 * cellWidth / 80.0
        let bottomLeft = CGPoint(x: leftMargin, y: bottomMargin)
        let topRight = CGPoint(x: cellWidth - rightMargin, y: cellWidth - bottomMargin)
        
        var label_column = 7
        var label_row = 0
        if boardDirection < 0 {
            label_column = 0
            label_row = 7
        }
        var labelIndex = 0
        for row in 0..<8 {
            for col in 0..<8 {
                let index = row * 8 + col
                let squareLayer = squares[index]
                let isWhiteSquare = row % 2 == 0 && col % 2 != 0 || row % 2 != 0 && col % 2 == 0

                let file = fileLabels[row]
                let rank = rankLabels[col]
                
                if col == label_column {
                    let labelLayer = boardDirection > 0 ? labels[labelIndex] : labels[7 - labelIndex]
                    labelIndex += 1
                    labelLayer.foregroundColor =  isWhiteSquare ? black.cgColor : white.cgColor
                    labelLayer.position = boardDirection > 0 ? topRight : bottomLeft
                    labelLayer.string = file
                    labelLayer.bounds = CGRectMake(0, 0, 18 * cellWidth / 80.0, 18 * cellWidth / 80.0)
                    labelLayer.alignmentMode = .right
                    labelLayer.contentsScale = UIScreen.main.scale
                    labelLayer.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
                    labelLayer.fontSize = fontSize
                    squareLayer.addSublayer(labelLayer)
                }
                if row == label_row {
                    let labelLayer = labels[labelIndex]
                    labelIndex += 1
                    labelLayer.foregroundColor =  isWhiteSquare ? black.cgColor : white.cgColor
                    labelLayer.position = boardDirection > 0 ? bottomLeft : topRight
                    labelLayer.string = rank
                    labelLayer.bounds = CGRectMake(0, 0, 18 * cellWidth / 80.0, 18 * cellWidth / 80.0)
                    labelLayer.alignmentMode = .left
                    labelLayer.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
                    labelLayer.fontSize = fontSize
                    labelLayer.contentsScale = UIScreen.main.scale
                    squareLayer.addSublayer(labelLayer)
                }
            }
        }
    }
    
    @objc
    public var currentSelection : SelectionContext? = nil

    @objc
    public func selectionInfo(for square: Int) -> SelectionContext? {
        if square >= 0 && square < 64 {
            let squareLayer = squares[square]
            guard let pieceLayer = squareLayer.pieceLayer else { return nil }
            return SelectionContext(isWhite: pieceLayer.isWhite, piece: pieceLayer.piece, square: square)
        }
        else {
            return nil
        }
    }

    @objc
    public func selectSquare(_ square: Int) {
        if square >= 0 && square < 64 {
            let squareLayer = squares[Int(square)]
            if let pieceLayer = squareLayer.pieceLayer {
                currentSelection = SelectionContext(isWhite: pieceLayer.isWhite, piece: pieceLayer.piece, square: square)
            }
            return
        }
        currentSelection = nil
    }

    private func squareFor(_ touch: UITouch) -> Int {
        let globalLoc = touch.location(in: self)
        let layerLoc = boardLayer.convert(globalLoc, from: touch.view?.layer)
        let index = self.squareIndexForLayerLocation(layerLoc)
        return index
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        let index = squareFor(touch)
        self .handleSelection(at: index)
    }
    
    private func handleSelection(at square: Int) {
        guard let delegate = delegate else { return }

        let newSelection = delegate.chessboardView(self, shouldSelect: square, withCurrentSelection: currentSelection)
    
        // deselect when tapping selected piece a second time, or tapping an invalid piece or an empty square
        // unless the target is in the current list of valid moves
        // (omitting the current square, because we need to ensure it can be deselected)
        if let currentSelection = currentSelection {
            let possibleMoves = currentSelection.moves.map { Int($0.destinationSquare) }
            if !possibleMoves.contains(square) || square == currentSelection.square {
                clearSelection()
            }
        }

        // when tapping own player's piece show possible moves
        if let newSelection = newSelection {
            if currentSelection?.square != square {
                updateSelection(newSelection)
            }
        }
    }

    private func updateSelection(_ selection: SelectionContext) {
        currentSelection = selection
        addMoveIndicationLayers(at: selection.square, moves: selection.moves, captures: selection.captures)
        if let currentSelection = currentSelection,
           let selectedPiece = squares[currentSelection.square].pieceLayer {
            selectedPiece.zPosition += 1
        }
        setNeedsDisplay() // Redraw to show highlights
    }
    
    private func clearSelection(removeMoveHighlights: Bool = true) {
        if let currentSelection = currentSelection,
           let selectedPiece = squares[currentSelection.square].pieceLayer {
            selectedPiece.zPosition -= 1
        }
        currentSelection = nil
        if removeMoveHighlights {
            removeMoveIndicationLayers()
        }
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
            let touch = touches.first,
            let currentSelection = currentSelection,
            let selectedPiece = squares[currentSelection.square].pieceLayer
        else { return }
        
        let globalLoc = touch.location(in: self)

        // disable animations for tracking the movement of pieces
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        selectedPiece.position = boardLayer.convert(globalLoc, from: touch.view?.layer)
        CATransaction.commit()
    }

    // allow tap piece to move then select destination, or drag and drop
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let currentSelection = currentSelection
        else { return }
        
        let square = squareFor(touch)
        let possibleMoves = currentSelection.moves.map { Int($0.destinationSquare) }

        if possibleMoves.contains(square) {
            delegate?.chessboardView(self, didMovePieceFrom: currentSelection.square, to: square)
            clearSelection()
        }
        else {
            if let pieceLayer = squares[currentSelection.square].pieceLayer {
                // animate the piece to its original position
                let originalSquareLayer = squares[currentSelection.square]
                pieceLayer.position = originalSquareLayer.position
            }
        }
    }

    @objc
    public func squareIndexForLayerLocation(_ screenLoc: CGPoint) -> Int {
        var i = 0
        var j = 0
        
        if (screenLoc.x > boardLayer.bounds.size.width) {
            return -1
        }
        else if (screenLoc.x <= 0) {
            return -1
        }
        else {
            i = Int((screenLoc.x / boardLayer.bounds.size.width) * 8)
        }
        
        if (screenLoc.y > boardLayer.bounds.size.height) {
            return -1
        }
        else if (screenLoc.y <= 0) {
            return -1
        }
        else {
            j = Int((screenLoc.y / boardLayer.bounds.size.height) * 8)
        }
        
        return j * 8 + i
    }
    
}
