//
//  ChessEngineFrameworkTests.swift
//  ChessEngineFrameworkTests
//
//  Created by Steve Wart on 2025-07-23.
//
//  interesting puzzles
//  https://lichess.org/training/mix/9cPIk

import XCTest
@testable import ChessEngine

final class ChessEngineFrameworkTests: XCTestCase {
  
  var board: ChessBoard!
  
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    ChessMoveGenerator.initialize()
    ChessBoard.initialize()
    board = ChessBoard()
    board.initializeSearch()
    board.initializeNewBoard()
    // need this to initialize the generator
    let list = board.generator.findPossibleMoves(for: board.activePlayer)
    board.generator.recycleMoveList(list)
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
    board.initializeFromFEN("r2qk2r/p6p/1p1p1pp1/2p1p3/8/2PP4/PP1QP2P/R3K2R b KQkq - 0 1")
    var move = board.move(uci: "h8g8")!
    XCTAssertEqual(move.sanString(for:board), "Rg8", "Move description is incorrect")
    board.initializeFromFEN("r2qk2r/p6p/1p1p1pp1/2p1p3/8/2PP4/PP1QP2P/R3K2R w KQkq - 0 1")
    move = board.move(uci: "h1f1")!
    XCTAssertEqual(move.sanString(for:board), "Rf1", "Move description is incorrect")
  }

  func testSAN_castling() {
    // test SAN string for move castling king side
    board.initializeFromFEN("r2qk2r/p6p/1p1p1pp1/2p1p3/8/2PP4/PP1QP2P/R3K2R w KQkq - 0 1")
    var move = board.move(uci:"e1g1")!
    XCTAssertEqual(move.sanString(for:board), "O-O", "Move description is incorrect")
    // test SAN string for move castling queen side
    board.initializeFromFEN("r2qk2r/p6p/1p1p1pp1/2p1p3/8/2PP4/PP1QP2P/R3K2R w KQkq - 0 1")
    move = board.move(uci:"e1c1")!
    XCTAssertEqual(move.sanString(for:board), "O-O-O", "Move description is incorrect")
  }

  // test SAN string for pawn promotion to bishop, knight, queen, rook, capture & check
  func testSAN_promotion() {
    board.initializeFromFEN("r2qk2r/p6p/1p1p4/2p1p3/8/7b/PP1QP1pP/R3K2R b KQkq - 0 1")
    var move = board.move(uci:"g2h1b")!
    // bishop and knight moves do not check the king
    XCTAssertEqual(move.sanString(for:board), "gxh1=B", "Move description is incorrect")
    board.initializeFromFEN("r2qk2r/p6p/1p1p4/2p1p3/8/7b/PP1QP1pP/R3K2R b KQkq - 0 1")
    move = board.move(uci:"g2h1n")!
    XCTAssertEqual(move.sanString(for:board), "gxh1=N", "Move description is incorrect")
    board.initializeFromFEN("r2qk2r/p6p/1p1p4/2p1p3/8/7b/PP1QP1pP/R3K2R b KQkq - 0 1")
    move = board.move(uci:"g2h1q")!
    XCTAssertEqual(move.sanString(for:board), "gxh1=Q+", "Move description is incorrect")
    board.initializeFromFEN("r2qk2r/p6p/1p1p4/2p1p3/8/7b/PP1QP1pP/R3K2R b KQkq - 0 1")
    move = board.move(uci:"g2h1r")!
    XCTAssertEqual(move.sanString(for:board), "gxh1=R+", "Move description is incorrect")
    board.initializeFromFEN("r2qk2r/p6p/1p1p4/2p1p3/8/7b/PP1QP1pP/R3K2R b KQkq - 0 1")
    move = board.move(uci:"g2h1b")!
  }

  // test SAN string for checkmate
  func testSAN_checkmate() {
    board.initializeFromFEN("rnbqkbnr/pppp1ppp/4p3/8/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 1")
    let move = board.move(uci:"d8h4")!
    XCTAssertEqual(move.sanString(for:board), "Qh4#", "Move description is incorrect")
  }

  // test SAN string for ambiguous move (same piece name, different rank)
  func testSAN_ambiguous_rank() {
    board.initializeFromFEN("r5k1/5q1p/Q2p4/2p1p3/r7/7b/PP2P2P/R3K3 b Qq - 0 2")
    var move = board.move(uci:"a8a6")!
    var string = move.sanString(for:board)
    XCTAssertEqual(string, "R8xa6", "Move description is incorrect")
    board.initializeFromFEN("r5k1/5q1p/Q2p4/2p1p3/r7/7b/PP2P2P/R3K3 b Qq - 0 2")
    move = board.move(uci:"a4a6")!
    string = move.sanString(for:board)
    XCTAssertEqual(string, "R4xa6", "Move description is incorrect")
    board.initializeFromFEN("1rq1k3/ppp2rpp/2b1p1n1/7Q/2P2pP1/1P1K1n1P/P2P1P2/1RB2B1R b - - 1 33")
    move = board.move(uci:"f3e5")!
    string = move.sanString(for:board)
    XCTAssertEqual(string, "Nfe5+", "Move description is incorrect")
  }

  // test SAN string for ambiguous move (same piece name, different file)
  func testSAN_ambiguous_file() {
    board.initializeFromFEN("r4qk1/7p/Q2p4/2p1p3/4r3/2N3Nb/PP2P2P/R3K3 w Qq - 0 2")
    var move = board.move(uci:"c3e4")!
    var string = move.sanString(for:board)
    XCTAssertEqual(string, "Ncxe4", "Move description is incorrect")
    board.initializeFromFEN("r4qk1/7p/Q2p4/2p1p3/4r3/2N3Nb/PP2P2P/R3K3 w Qq - 0 2")
    move = board.move(uci:"g3e4")!
    string = move.sanString(for:board)
    XCTAssertEqual(string, "Ngxe4", "Move description is incorrect")
  }
  
  var reverseBlock = { (obj1: Any, obj2: Any) -> ComparisonResult in
    let a = obj1 as! Int
    let b = obj2 as! Int
    if (a == b) {
      return ComparisonResult.orderedSame
    }
    else if (a > b) {
      return ComparisonResult.orderedAscending
    }
    else {
      return ComparisonResult.orderedDescending
    }
  }
  
  func testQuicksort() {
    var array: NSMutableArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    var expectedArray: NSMutableArray = [1, 2, 3, 4, 10, 9, 8, 7, 6, 5, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    array.sortSubArray(from:4, to:9, using:reverseBlock)
    XCTAssertEqual(array, expectedArray)
    
    array = [1, 2, 3, 4, 5]
    expectedArray = [1, 2, 4, 3, 5]
    array.sortSubArray(from: 2, to: 3, using:reverseBlock)
    XCTAssertEqual(array, expectedArray)
    
    array = []
    expectedArray = []
    array.sortSubArray(from: 0, to: 0, using:reverseBlock)
    XCTAssertEqual(array, expectedArray)
    
    array = [1]
    expectedArray = [1]
    array.sortSubArray(from: 0, to: 0, using:reverseBlock)
    XCTAssertEqual(array, expectedArray)
    
    array = [1, 2]
    expectedArray = [2, 1]
    array.sortSubArray(from: 0, to: 1, using:reverseBlock)
    XCTAssertEqual(array, expectedArray)
    
  }
  
  // 000rZ,2kr1b1r/p1p2pp1/2pqb3/7p/3N2n1/2NPB3/PPP2PPP/R2Q1RK1 w - - 2 13,d4e6 d6h2,1039,79,100,171,kingsideAttack mate mateIn1 oneMove opening,https://lichess.org/seIMDWkD#25,Scandinavian_Defense Scandinavian_Defense_Modern_Variation
  func testCheckmateIn1_000rZ() async throws {
    let fen = "2kr1b1r/p1p2pp1/2pqb3/7p/3N2n1/2NPB3/PPP2PPP/R2Q1RK1 w - - 2 13"
    board.initializeFromFEN(fen)
    
    let move = board.move(uci: "d4e6")!
    board.nextMove(move)
    
    let nextMove = await board.searchAgent.findMove()
    
    if let move = nextMove {
      XCTAssertEqual(move, "d6h2", "The move \(move) is incorrect")
    }
    else {
      XCTFail("Move not found")
    }
  }
  
  // r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 1 -- mate in 1 (Qxf7#)
  func testCheckmateIn1_ucitestsuite() async throws {
    let fen = "r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 1"
    board.initializeFromFEN(fen)
    
    let nextMove = await board.searchAgent.findMove()
    
    if let move = nextMove {
      XCTAssertEqual(move, "h5f7", "The move \(move) is incorrect")
    }
    else {
      XCTFail("Move not found")
    }
  }
  
  // 9cPIk,2k3r1/8/P4p2/2P5/3n1n2/8/5P1K/RR6 w - - 0 38,a6a7 d4f3 h2h1 g8h8,1491,75,97,23349,endgame mate mateIn2 short,https://lichess.org/gzskFpDu#75,
  func testCheckmateIn2() async throws {
    
    let fen = "2k3r1/8/P4p2/2P5/3n1n2/8/5P1K/RR6 w - - 0 38"
    board.initializeFromFEN(fen)
    
    // move 1w
    var ourMove = board.move(uci:"a6a7")!
    board.nextMove(ourMove)
    print(ourMove)
    
    // move 1b
    var theirMove = await board.searchAgent.findMove()
    
    print(theirMove!)
    XCTAssertEqual(theirMove!, "d4f3", "That move is incorrect")
    var move = board.move(uci:theirMove!)
    board.nextMove(move)
    
    // move 2w
    ourMove = board.move(uci:"h2h1")!
    board.nextMove(ourMove)
    print(ourMove)
    
    // move 2b
    theirMove = await board.searchAgent.findMove()
    print(theirMove!)
    XCTAssertEqual(theirMove!, "g8h8", "That move is incorrect")
    move = board.move(uci:theirMove!)
    board.nextMove(move)
  }
  
  func testMoveEnumeration() throws {
    guard let moveList = board.generator.findAllPossibleMoves(for: board.activePlayer) else {
      XCTFail("Could not generate move list")
      return
    }
    
    XCTAssertEqual(moveList.count(), 20, "There should be 20 moves")
    
    for _ in 0..<20 {
      let move = moveList.next()
      XCTAssertNotNil(move)
    }
    
    board.generator.recycleMoveList(moveList)
    XCTAssertTrue(moveList.count() == 20)
  }
  
  func testFENGeneration() throws {
    let fen = "rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 2"
    board.initializeFromFEN(fen)
    
    XCTAssertEqual(board.generateCastlingString(), "KQkq", "Castling string incorrect")
    XCTAssertEqual(Int(board.enpassantSquare), board.square("d6")!, "En passant square incorrect")
    XCTAssertEqual(board.generateEnPassantString(), "d6", "En passant string incorrect")
    
    let fen2 = board.generateFEN()
    XCTAssertEqual(fen2, fen, "FEN string is incorrect")
  }
  
  func testCastleThroughCheck() throws {
    let fen = "r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/5P1N/PPPP2PP/RNBQK2R w KQkq - 0 1"
    board.initializeFromFEN(fen)
    // attempt to castle through check (Bc4 threatens f1)
    let move = board.move(uci: "e1g1")
    XCTAssertTrue(move == nil)
  }
  
  func testCastleRookUnderThreat() throws {
    let fen = "r2qk2r/ppp2ppp/3p1n2/n1b1p1N1/2B5/1QP1PbP1/PP1P1P1P/RNB1K2R w KQkq - 0 1"
    board.initializeFromFEN(fen)
    // Bf3 threatens h1 (the rook) via the diagonal g2–h1, but not f1 or g1.
    // The rook being under attack does not prevent castling; only king-path squares matter.
    XCTAssertTrue(board.generator.canCastleWhiteKingSide())
  }
  
  func testCastlingUnderThreats() throws {
    board.initializeFromFEN("4kbnr/8/8/8/7P/8/8/R3K2R w KQk - 0 1")
    XCTAssertTrue(board.generator.canCastleWhiteKingSide())
    XCTAssertTrue(board.generator.canCastleWhiteQueenSide())
    board.initializeFromFEN("4kbnr/7p/8/8/8/8/8/R3K2R w KQk - 0 1")
    XCTAssertTrue(board.generator.canCastleWhiteKingSide())
    XCTAssertTrue(board.generator.canCastleWhiteQueenSide())
    board.initializeFromFEN("4kbnr/8/8/8/8/8/6p1/R3K2R w KQk - 0 1")
    XCTAssertFalse(board.generator.canCastleWhiteKingSide())
    XCTAssertTrue(board.generator.canCastleWhiteQueenSide())
    board.initializeFromFEN("4k1n1/8/8/8/8/3b4/8/R3K2R w KQ - 0 1")
    XCTAssertFalse(board.generator.canCastleWhiteKingSide())  // Bd3 attacks f1 via e2-f1 diagonal
    XCTAssertTrue(board.generator.canCastleWhiteQueenSide())  // Bd3 attacks b1 but not c1 or d1
    board.initializeFromFEN("4k3/8/8/8/8/4n3/8/R3K2R w KQ - 0 1")
    XCTAssertFalse(board.generator.canCastleWhiteKingSide())
    XCTAssertFalse(board.generator.canCastleWhiteQueenSide())
    board.initializeFromFEN("4k3/8/8/8/4q3/3p4/4P1P1/R3K2R w KQ - 0 1")
    XCTAssertTrue(board.generator.canCastleWhiteKingSide())
    XCTAssertTrue(board.generator.canCastleWhiteQueenSide())
    board.initializeFromFEN("4k3/8/8/8/4q3/8/4P3/R3K2R w KQha - 0 1")
    XCTAssertTrue(board.generator.canCastleWhiteKingSide())   // Qe4 attacks h1 (rook) via f3-g2-h1, not f1/g1
    XCTAssertTrue(board.generator.canCastleWhiteQueenSide())  // Qe4 attacks b1 via d3-c2-b1, not c1/d1
  }
  
  func testCastlingDisabledFEN() throws {
    // legal dynamic castling situation, but FEN string disables castling for white
    board.initializeFromFEN("4k3/8/8/8/4q3/3p4/4P1P1/R3K2R w kq - 0 1")
    XCTAssertFalse(board.whitePlayer.isCastlingEnabledKingSide())
    XCTAssertFalse(board.whitePlayer.isCastlingEnabledQueenSide())
    XCTAssertTrue(board.activePlayer == board.whitePlayer)
    board.initializeFromFEN("4k3/8/8/8/4q3/3p4/4P1P1/R3K2R b kq - 0 1")
    XCTAssertTrue(board.activePlayer == board.blackPlayer)
  }
  
  func testFindWayToInevitableCheckmate() throws {
    let fen = "3k4/1R6/p4n2/2p5/R1Pb4/3P2r1/8/5K1q w - - 1 46"
    board.initializeFromFEN(fen)
    // inevitably Kf1e2 rg3g2 Ke2f3 qh1f1#
    
    // in this case, white's only escape (temporarily) is e2
    let whiteMoves = board.whitePlayer.findValidMoves()
    
    XCTAssertNotNil(whiteMoves)
    XCTAssertEqual(whiteMoves!.count, 1, "incorrect number of moves")
    
    let move = whiteMoves!.first as! ChessMove
    XCTAssertEqual(move.uciString(), "f1e2", "That is not the right move")
  }
  
  // generating illegal double push from 16 to 32
  func testGenerateIllegalDoublePush() throws {
    let fen = "rnb3kr/ppp1b1pp/1n2p3/3pp2P/3P1P2/PPN3P1/2P3BK/1R1Q1R2 w - a1 0 18"
    board.initializeFromFEN(fen)
    
    let whiteMoves = board.whitePlayer.findValidMoves()
      
    for move in whiteMoves! as! [ChessMove] {
      XCTAssertNotEqual(move.uciString(), "a3a5")
    }
  }
  
  //  illegal move dxc5#, pv=[3 e7d8 f7xg8 d6xc5 c5xe6 g6xh5 c1xb2 h8xh1 0 0 0]
  func testGeneratePV() async throws {
    let fen = "1rbk2r1/5Qp1/p1ppp1p1/2Np3P/P2P4/8/1PP5/2K2R2 2 - a1 0 28"
    board.initializeFromFEN(fen)
    
    let nextMove = await board.searchAgent.findMove()
    print("bestmove \(nextMove!)")
  }
  
  // MARK: - Move struct tests

  func testMoveFieldAccessors() {
    // e2 = square 12 (file e=4, rank 2: 4 + 8*1 = 12), e4 = square 28
    let m = Move.move(piece: kPawn, from: 12, to: 28)
    XCTAssertEqual(m.from, 12)
    XCTAssertEqual(m.to, 28)
    XCTAssertEqual(m.piece, kPawn)
    XCTAssertEqual(m.captured, 0)
    XCTAssertEqual(m.promotion, 0)
    XCTAssertEqual(m.kind, .normal)
    XCTAssertEqual(m.score, 0)
    XCTAssertFalse(m.isNull)
    XCTAssertFalse(m.isCapture)
    XCTAssertFalse(m.isPromotion)
  }

  func testMoveCapture() {
    let m = Move.move(piece: kRook, from: 0, to: 56, captured: kQueen)
    XCTAssertEqual(m.captured, kQueen)
    XCTAssertTrue(m.isCapture)
  }

  func testMovePromotion() {
    // g7 = square 54, g8 = square 62
    let m = Move.promotion(piece: kPawn, from: 54, to: 62, promoteTo: kQueen)
    XCTAssertEqual(m.piece, kPawn)
    XCTAssertEqual(m.promotion, kQueen)
    XCTAssertTrue(m.isPromotion)
    XCTAssertEqual(m.uciString, "g7g8q")
  }

  func testMovePromotionWithCapture() {
    let m = Move.promotion(piece: kPawn, from: 54, to: 63, promoteTo: kKnight, captured: kRook)
    XCTAssertEqual(m.captured, kRook)
    XCTAssertEqual(m.promotion, kKnight)
    XCTAssertEqual(m.uciString, "g7h8n")
  }

  func testMoveKinds() {
    let dp = Move.doublePush(piece: kPawn, from: 12, to: 28)
    XCTAssertEqual(dp.kind, .doublePush)

    let ep = Move.enPassant(piece: kPawn, from: 28, to: 21, captured: kPawn)
    XCTAssertEqual(ep.kind, .enPassant)

    let ck = Move.castleKingside(piece: kKing, from: 4, to: 6)
    XCTAssertTrue(ck.isCastle)
    XCTAssertEqual(ck.kind, .castleKingside)

    let cq = Move.castleQueenside(piece: kKing, from: 4, to: 2)
    XCTAssertTrue(cq.isCastle)
    XCTAssertEqual(cq.kind, .castleQueenside)
  }

  func testMoveNullSentinel() {
    XCTAssertTrue(Move.null.isNull)
    XCTAssertFalse(Move.move(piece: kPawn, from: 12, to: 28).isNull)
    XCTAssertEqual(Move.null.uciString, "0000")
    // null kind
    XCTAssertEqual(Move.null.kind, .null)
  }

  func testMoveUCIString() {
    // a1→a2: from=0 to=8
    XCTAssertEqual(Move.move(piece: kRook, from: 0, to: 8).uciString, "a1a2")
    // e1→g1 (kingside castle): from=4 to=6
    XCTAssertEqual(Move.castleKingside(piece: kKing, from: 4, to: 6).uciString, "e1g1")
    // h7→h8 promote to rook: from=55 to=63
    XCTAssertEqual(Move.promotion(piece: kPawn, from: 55, to: 63, promoteTo: kRook).uciString, "h7h8r")
  }

  func testMoveEqualityIgnoresScore() {
    let m1 = Move.move(piece: kKnight, from: 1, to: 18)
    let m2 = m1.withScore(500)
    let m3 = m1.withScore(-200)
    // Same board action — equal regardless of score
    XCTAssertEqual(m1, m2)
    XCTAssertEqual(m2, m3)
    // withScore round-trips
    XCTAssertEqual(m2.score, 500)
    XCTAssertEqual(m3.score, -200)
    // Hash consistency
    XCTAssertEqual(m1.hashValue, m2.hashValue)
  }

  func testMoveScoreRoundTrip() {
    let m = Move.move(piece: kBishop, from: 2, to: 47)
    XCTAssertEqual(m.withScore(32767).score,  32767)
    XCTAssertEqual(m.withScore(-32768).score, -32768)
    XCTAssertEqual(m.withScore(0).score, 0)
    // Score mutation does not change board-level fields
    let scored = m.withScore(1000)
    XCTAssertEqual(scored.from, m.from)
    XCTAssertEqual(scored.to, m.to)
    XCTAssertEqual(scored.piece, m.piece)
  }

  func testMoveTerminal() {
    XCTAssertTrue(Move.resign(piece: kKing).isTerminal)
    XCTAssertTrue(Move.stalemate(piece: kKing).isTerminal)
    XCTAssertFalse(Move.move(piece: kPawn, from: 8, to: 16).isTerminal)
  }

  // MARK: - MoveGenerator tests

  /// Helper: run the Swift generator against the active player and return the MoveList.
  ///
  /// Uses `board.enpassantSquare` (set by both FEN loading and actual double-push moves)
  /// rather than `opponent.enpassantSquare` (only set by actual double-push moves).
  private func swiftMoves(quiescence: Bool = false) -> MoveList {
    let player = board.activePlayer!
    let opp    = player.opponent!
    return MoveGenerator.shared.generate(
      myPieces:        player.pieces(),
      itsPieces:       opp.pieces(),
      castlingStatus:  Int(player.castlingStatus),
      enpassantSquare: Int(board.enpassantSquare),  // -1 or valid square
      isWhite:         player.isWhitePlayer(),
      quiescence:      quiescence
    )
  }

  /// Cross-validate Swift generator count against ObjC generator count.
  private func assertMoveCountMatches(fen: String, file: StaticString = #file, line: UInt = #line) {
    board.initializeFromFEN(fen)
    let objcList = board.generator.findAllPossibleMoves(for: board.activePlayer)
    let swiftList = swiftMoves()
    if objcList == nil {
      XCTAssertNotNil(swiftList.kingAttack, "ObjC nil (king attack) but Swift has no kingAttack", file: file, line: line)
    } else {
      XCTAssertNil(swiftList.kingAttack, "Swift has unexpected kingAttack for FEN: \(fen)", file: file, line: line)
      XCTAssertEqual(swiftList.moves.count, Int(objcList!.count()),
                     "Move count mismatch for FEN: \(fen)", file: file, line: line)
      board.generator.recycleMoveList(objcList)
    }
  }

  func testMoveGeneratorStartingPosition() {
    // White opening: 16 pawn moves + 4 knight moves = 20
    let list = swiftMoves()
    XCTAssertNil(list.kingAttack)
    XCTAssertEqual(list.moves.count, 20)
    // All should be normal or doublePush kind
    for m in list.moves {
      XCTAssertTrue(m.kind == .normal || m.kind == .doublePush)
    }
  }

  func testMoveGeneratorMatchesObjCStartingPosition() {
    assertMoveCountMatches(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
  }

  func testMoveGeneratorMatchesObjCOpenPosition() {
    // After 1.e4 e5
    assertMoveCountMatches(fen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")
    // Black to move
    assertMoveCountMatches(fen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1")
  }

  func testMoveGeneratorEnPassant() {
    // Make an actual double push so opponent.enpassantSquare is properly set.
    // (FEN en-passant field only sets board.enpassantSquare, not player.enpassantSquare.)
    // Position: white pawn e5, black pawn d7; after d7-d5, white can en-passant e5xd6.
    board.initializeFromFEN("4k3/3p4/8/4P3/8/8/8/4K3 b - - 0 1")
    let dp = board.move(uci: "d7d5")!
    board.nextMove(dp)  // board.enpassantSquare = 43 (d6)
    let list = swiftMoves()
    let epMoves = list.moves.filter { $0.kind == .enPassant }
    XCTAssertEqual(epMoves.count, 1, "Should have exactly one en-passant move")
    XCTAssertEqual(epMoves[0].uciString, "e5d6")
    // Cross-validate with ObjC generator
    let objcList = board.generator.findAllPossibleMoves(for: board.activePlayer)!
    XCTAssertEqual(list.moves.count, Int(objcList.count()), "Move count should match ObjC")
    board.generator.recycleMoveList(objcList)
  }

  func testMoveGeneratorCastling() {
    let fen = "r2qk2r/p6p/1p1p1pp1/2p1p3/8/2PP4/PP1QP2P/R3K2R w KQkq - 0 1"
    board.initializeFromFEN(fen)
    let list = swiftMoves()
    let castles = list.moves.filter { $0.isCastle }
    XCTAssertEqual(castles.count, 2, "Should have both castling moves")
    XCTAssertTrue(castles.contains { $0.kind == .castleKingside })
    XCTAssertTrue(castles.contains { $0.kind == .castleQueenside })
    assertMoveCountMatches(fen: fen)
  }

  func testMoveGeneratorCastleThroughCheck() {
    // Bc5 threatens f2 which is on the king's path for white kingside castling
    let fen = "r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/5P1N/PPPP2PP/RNBQK2R w KQkq - 0 1"
    board.initializeFromFEN(fen)
    let list = swiftMoves()
    let castles = list.moves.filter { $0.isCastle }
    XCTAssertEqual(castles.count, 0, "Should not castle through check")
    assertMoveCountMatches(fen: fen)
  }

  func testMoveGeneratorPromotion() {
    // White pawn on h7 can promote (no captures available).
    // Black king on f8 (not g8/h8) so the pawn's diagonal capture square is empty.
    let fen = "5k2/7P/8/8/8/8/8/6K1 w - - 0 1"
    board.initializeFromFEN(fen)
    let list = swiftMoves()
    let promos = list.moves.filter { $0.isPromotion }
    XCTAssertEqual(promos.count, 4, "Should have 4 promotion moves")
    XCTAssertTrue(promos.contains { $0.promotion == kQueen })
    XCTAssertTrue(promos.contains { $0.promotion == kRook })
    XCTAssertTrue(promos.contains { $0.promotion == kBishop })
    XCTAssertTrue(promos.contains { $0.promotion == kKnight })
    assertMoveCountMatches(fen: fen)
  }

  func testMoveGeneratorKingAttack() {
    // White queen on g2 can slide to g8 (black king) — white's generator sets kingAttack.
    // (Black king in check = illegal FEN, but tests the generator's detection logic.)
    let fen = "6k1/8/8/8/8/8/6Q1/4K3 w - - 0 1"
    board.initializeFromFEN(fen)
    // ObjC generator for white should return nil (kingAttack set)
    let objcList = board.generator.findAllPossibleMoves(for: board.whitePlayer)
    let swiftList = swiftMoves()
    XCTAssertNil(objcList, "ObjC should return nil (king attack detected)")
    XCTAssertNotNil(swiftList.kingAttack, "Swift should set kingAttack")
    XCTAssertTrue(swiftList.moves.isEmpty, "Moves should be empty when king attack is set")
  }

  func testMoveGeneratorQuiescence() {
    // In quiescence mode, only captures are generated
    let fen = "rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2"
    board.initializeFromFEN(fen)
    let full = swiftMoves(quiescence: false)
    let quiet = swiftMoves(quiescence: true)
    // Quiescence should have fewer moves (only captures)
    XCTAssertLessThan(quiet.moves.count, full.moves.count)
    // All quiescence moves should be captures
    for m in quiet.moves {
      XCTAssertTrue(m.isCapture, "Quiescence move \(m) is not a capture")
    }
  }

  func testMoveGeneratorComplexPosition() {
    // Several positions from existing tests
    assertMoveCountMatches(fen: "2kr1b1r/p1p2pp1/2pqb3/7p/3N2n1/2NPB3/PPP2PPP/R2Q1RK1 w - - 2 13")
    assertMoveCountMatches(fen: "r2qk2r/p6p/1p1p1pp1/2p1p3/8/2PP4/PP1QP2P/R3K2R b KQkq - 0 1")
    assertMoveCountMatches(fen: "rnb3kr/ppp1b1pp/1n2p3/3pp2P/3P1P2/PPN3P1/2P3BK/1R1Q1R2 w - a1 0 18")
  }

  func testErrorLevels() {
    let logger = Logger.default()!
    logger.level = Verbose
    logger.logMessage("Setting log level to verbose (all 5 messages should appear)")
    logger.log("Logging a verbose message", level: Verbose)
    logger.log("Logging an info message", level: Info)
    logger.log("Logging a debug message", level: Debug)
    logger.log("Logging a warning message", level: Warning)
    logger.log("Logging an error message", level: Error)
    logger.level = Info
    logger.logMessage("Setting log level to info (only the info message should appear)")
    logger.log("Logging a verbose message", level: Verbose)
    logger.log("Logging an info message", level: Info)
    logger.log("Logging a debug message", level: Debug)
    logger.log("Logging a warning message", level: Warning)
    logger.log("Logging an error message", level: Error)
  }
  
}
