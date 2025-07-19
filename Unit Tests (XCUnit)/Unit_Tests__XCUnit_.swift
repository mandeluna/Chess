//
//  Unit_Tests__XCUnit_.swift
//  Unit Tests (XCUnit)
//
//  Created by Steve Wart on 2025-07-16.
//

import XCTest

final class Unit_Tests__XCUnit_: XCTestCase {

  override func setUpWithError() throws {
      // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDownWithError() throws {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  //  ╔══╤══╤══╤══╤══╤══╤══╤══╗╮
  //  ║56│57│58│59│60│61│62│63║8
  //  ║48│49│50│51│52│53│54│55║7
  //  ║40│41│42│43│44│45│46│47║6
  //  ║32│33│34│35│36│37│38│39║5
  //  ║24│25│26│27│28│29│30│31║4
  //  ║16│17│18│19│20│21│22│23║3
  //  ║ 8│ 9│10│11│12│13│14│15║2
  //  ║ 0│ 1│ 2│ 3│ 4│ 5│ 6│ 7║1
  //  ╚══╧══╧══╧══╧══╧══╧══╧══╝┊
  //  ╰┈a┈┈b┈┈c┈┈d┈┈e┈┈f┈┈g┈┈h┈╯

func testSquareToIndex() {
    XCTAssertTrue(ChessMove.squareToIndex("a1") == 0)
    XCTAssertTrue(ChessMove.squareToIndex("b1") == 1)
    XCTAssertTrue(ChessMove.squareToIndex("e5") == 36)
    XCTAssertTrue(ChessMove.squareToIndex("e6") == 44)
    XCTAssertTrue(ChessMove.squareToIndex("a2") == 8)
    XCTAssertTrue(ChessMove.squareToIndex("h8") == 63)
  }
  
  func testRookMoveDescription() {
    var move = ChessMove(piece: Int32(kRook), start: 62, end: 63)
    XCTAssertTrue(move.description() == "Rg8-h8", "Move description is incorrect")
    move = ChessMove(piece: Int32(kRook), start: 62, end: 61)
    XCTAssertTrue(move.description() == "Rg8-f8", "Move description is incorrect")
  }

  // 000rZ,2kr1b1r/p1p2pp1/2pqb3/7p/3N2n1/2NPB3/PPP2PPP/R2Q1RK1 w - - 2 13,d4e6 d6h2,1039,79,100,171,kingsideAttack mate mateIn1 oneMove opening,https://lichess.org/seIMDWkD#25,Scandinavian_Defense Scandinavian_Defense_Modern_Variation
  func testCheckmateIn1() async throws {
    let board = ChessBoard()
    board.initializeNewBoard()
    
    let fen = "2kr1b1r/p1p2pp1/2pqb3/7p/3N2n1/2NPB3/PPP2PPP/R2Q1RK1"
    board.initializeFromFEN(fen)
    
    // move generator needs to know to move the white knight from d4 to e6
    board.activePlayer = board.whitePlayer
    let start = ChessMove.squareToIndex("d4")
    let end = ChessMove.squareToIndex("e6")
    let piece = board.whitePlayer.piece(at: Int32(start))
    XCTAssertTrue(piece == kKnight, "That piece is incorrect")
    let move = ChessMove(piece: piece, start: Int32(start), end: Int32(end))
    XCTAssertTrue(move.description() == "Nd4-e6", "That move is incorrect")
    board.nextMove(move)
    
    // changing from white to black
    board.searchAgent.setActivePlayer(board.blackPlayer)

    let nextMove = await board.searchAgent.findMove()
    XCTAssertTrue(nextMove!.description() == "Qd6xh2", "That move is incorrect")
  }

  // 9cPIk,2k3r1/8/P4p2/2P5/3n1n2/8/5P1K/RR6 w - - 0 38,a6a7 d4f3 h2h1 g8h8,1491,75,97,23349,endgame mate mateIn2 short,https://lichess.org/gzskFpDu#75,
  func testCheckmateIn2() async throws {
    let board = ChessBoard()
    board.initializeNewBoard()
    
    let fen = "2k3r1/8/P4p2/2P5/3n1n2/8/5P1K/RR6"
    board.initializeFromFEN(fen)
    
    // move 1w
    var ourMove = ChessMove(san:"Pa6a7")
    board.movePiece(from: ourMove.sourceSquare, to: ourMove.destinationSquare)
    print(ourMove)

    // move 1b
    var theirMove = await board.searchAgent.findMove()
    print(theirMove!)
    XCTAssertTrue(theirMove!.description() == "Nd4-f3", "That move is incorrect")
    board.movePiece(from: theirMove!.sourceSquare, to: theirMove!.destinationSquare)

    // move 2w
    ourMove = ChessMove(san:"Kh2h1")
    board.movePiece(from: ourMove.sourceSquare, to: ourMove.destinationSquare)
    print(ourMove)

    // move 2b
    theirMove = await board.searchAgent.findMove()
    print(theirMove!)
    XCTAssertTrue(theirMove!.description() == "Rg8-h8", "That move is incorrect")
    board.movePiece(from: theirMove!.sourceSquare, to: theirMove!.destinationSquare)
  }
}


// interesting puzzles
// https://lichess.org/training/mix/9cPIk
