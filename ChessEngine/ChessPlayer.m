//
//  ChessPlayer.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "ChessPlayer.h"
#import "ChessBoard.h"
#import "ChessMove.h"
#import "ChessMoveGenerator.h"
#import "ChessMoveList.h"

// piece values

static int PieceValues[7] = {0, 100, 300, 350, 500, 900, 2000};

// center scores

static int PieceCenterScores[7][64] = {
    
    // PieceCenterScores[kEmptySquare] -- placeholder
    
    { 0 },
    
    // PieceCenterScores[kPawn]
    
    { 0 },
    
    // PieceCenterScores[kKnight]
    {
        -4,	0,	0,	0,	0,	0,	0,	-4,
        -4,	0,	2,	2,	2,	2,	0,	-4,
        -4,	2,	3,	2,	2,	3,	2,	-4,
        -4,	1,	2,	5,	5,	2,	2,	-4,
        -4,	1,	2,	5,	5,	2,	2,	-4,
        -4,	2,	3,	2,	2,	3,	2,	-4,
        -4,	0,	2,	2,	2,	2,	0,	-4,
        -4,	0,	0,	0,	0,	0,	0,	-4
    },
    
    // PieceCenterScores[kBishop]
    {
        -2,	-2,	-2,	-2,	-2,	-2,	-2,	-2,
        -2,	0,	0,	0,	0,	0,	0,	-2,
        -2,	0,	1,	1,	1,	1,	0,	-2,
        -2,	0,	1,	2,	2,	1,	0,	-2,
        -2,	0,	1,	2,	2,	1,	0,	-2,
        -2,	0,	1,	1,	1,	1,	0,	-2,
        -2,	0,	0,	0,	0,	0,	0,	-2,
        -2,	-2,	-2,	-2,	-2,	-2,	-2,	-2
    },
    
    // PieceCenterScores[kRook]
    
    { 0 },
    
    // PieceCenterScores[kQueen]
    {
        -3,	0,	0,	0,	0,	0,	0,	-3,
        -2,	0,	0,	0,	0,	0,	0,	-2,
        -2,	0,	1,	1,	1,	1,	0,	-2,
        -2,	0,	1,	2,	2,	1,	0,	-2,
        -2,	0,	1,	2,	2,	1,	0,	-2,
        -2,	0,	1,	1,	1,	1,	0,	-2,
        -2,	0,	0,	0,	0,	0,	0,	-2,
        -3,	0,	0,	0,	0,	0,	0,	-3
    },
    
    // PieceCenterScores[kKing]
    
    { 0 }
};

@implementation ChessPlayer
@synthesize opponent, board, numPawns, enpassantSquare, castlingRookSquare, castlingStatus, positionalValue, materialValue;

#pragma mark Initialize

-(id)init {
    if (self = [super init]) {
        //    bzero(pieces, 64 * sizeof(char));
        pieces = calloc(64, sizeof(unsigned char));
        
        if (!pieces) {
            NSLog(@"memory allocation failed");
            return nil;
        }
        
        materialValue = 0;
        positionalValue = 0;
        numPawns = 0;
        enpassantSquare = -1;
        castlingRookSquare = -1;
        castlingStatus = 0;
    }
    return self;
}

-(ChessPlayer *)initializeWithPlayer:(ChessPlayer *)player {
  [self init];
  
  memcpy(pieces, player.pieces, 64 * sizeof(unsigned char));
  opponent = player.opponent;
  board = player.board;
  materialValue = player.materialValue;
  positionalValue = player.positionalValue;
  numPawns = player.numPawns;
  enpassantSquare = player.enpassantSquare;
  castlingRookSquare = player.castlingRookSquare;
  castlingStatus = player.castlingStatus;
  
  return self;
}

//
// Clear enpassant square and reset any pending extra kings
//
-(void)prepareNextMove {
    
    enpassantSquare = -1;
    
    if (castlingRookSquare >= 0) {
        pieces[castlingRookSquare] = kRook;
    }
    
    castlingRookSquare = -1;
}

#pragma mark Adding/Removing

-(void)addBlackPieces {
        
    for (int i=48; i<=55; i++) {
        [self addPiece:kPawn at: i];
    }
    
    [self addPiece:kRook at:56];
    [self addPiece:kKnight at:57];
    [self addPiece:kBishop at:58];
    [self addPiece:kQueen at:59];
    [self addPiece:kKing at:60];
    [self addPiece:kBishop at:61];
    [self addPiece:kKnight at:62];
    [self addPiece:kRook at:63];
}

-(void)addPiece:(int)piece at:(int)square {
    
    pieces[square] = piece;
    materialValue += PieceValues[piece];
    positionalValue += PieceCenterScores[piece][square];
    
    if (kPawn == piece) {
        numPawns++;
    }
    
    [board updateHash:piece at:square from:self];
}

-(void)addWhitePieces {
    
    [self addPiece:kRook at:0];
    [self addPiece:kKnight at:1];
    [self addPiece:kBishop at:2];
    [self addPiece:kQueen at:3];
    [self addPiece:kKing at:4];
    [self addPiece:kBishop at:5];
    [self addPiece:kKnight at:6];
    [self addPiece:kRook at:7];

    for (int i=8; i<=15; i++) {
        [self addPiece:kPawn at: i];
    }    
}

-(void)movePiece:(int)piece from:(int)sourceSquare to:(int)destSquare {
    
    int *score = PieceCenterScores[piece];
    positionalValue -= score[sourceSquare];
    positionalValue += score[destSquare];
    pieces[sourceSquare] = 0;
    pieces[destSquare] = piece;
    
    [board updateHash:piece at:sourceSquare from:self];
    [board updateHash:piece at:destSquare from:self];
}

-(void)removePiece:(int)piece at:(int)square {
    
    pieces[square] = 0;
    materialValue -= PieceValues[piece];
    positionalValue -= PieceCenterScores[piece][square];
    
    if (kPawn == piece) {
        numPawns--;
    }
    
    [board updateHash:piece at:square from:self];
}

-(void)replacePiece:(int)oldPiece with:(int)newPiece at:(int)square {
    
    pieces[square] = newPiece;
    materialValue = materialValue - PieceValues[oldPiece] + PieceValues[newPiece];
    positionalValue -= PieceCenterScores[oldPiece][square];
    positionalValue += PieceCenterScores[newPiece][square];
    
    if (kPawn == oldPiece) {
        numPawns--;
    }
    
    if (kPawn == newPiece) {
        numPawns++;
    }
    
    [board updateHash:oldPiece at:square from:self];
    [board updateHash:newPiece at:square from:self];
}

#pragma mark moving

-(void)applyCastleKingSideMove:(ChessMove *)move {
 
    [self movePiece:[move movingPiece] from:[move sourceSquare] to:[move destinationSquare]];
    [self movePiece:kRook from:[move sourceSquare]+3 to:(castlingRookSquare = [move sourceSquare]+1)];
    
    pieces[castlingRookSquare] = kKing;
    castlingStatus ^= kCastlingDone;
}

-(void)applyCastleQueenSideMove:(ChessMove *)move {
    
    [self movePiece:[move movingPiece] from:[move sourceSquare] to:[move destinationSquare]];
    [self movePiece:kRook from:[move sourceSquare]-4 to:(castlingRookSquare = [move sourceSquare]-1)];
    
    pieces[castlingRookSquare] = kKing;
    castlingStatus ^= kCastlingDone;
}

-(void)applyDoublePushMove:(ChessMove *)move {
    
    // calculate the field between start and destination (bitShift: -1)
    enpassantSquare = (move.sourceSquare + move.destinationSquare) >> 1;
    
    [self movePiece:[move movingPiece] from:[move sourceSquare] to:[move destinationSquare]];
}

-(void)applyEnPassantMove:(ChessMove *)move {
    
    [opponent removePiece:[move capturedPiece] at:[move destinationSquare] - ([self isWhitePlayer] ? 8 : -8)];
    [self movePiece:[move movingPiece] from:[move sourceSquare] to:[move destinationSquare]];
}

//
// apply the given move
//
-(void)applyMove:(ChessMove *)move {
    
    int type = [move moveType] & kBasicMoveMask;
        
    switch(type) {
        case kMoveNormal:
            [self applyNormalMove:move];
            break;
        case kMoveDoublePush:
            [self applyDoublePushMove:move];
            break;
        case kMoveCaptureEnPassant:
            [self applyEnPassantMove:move];
            break;
        case kMoveCastlingKingSide:
            [self applyCastleKingSideMove:move];
            break;
        case kMoveCastlingQueenSide:
            [self applyCastleQueenSideMove:move];
            break;
        case kMoveResign:
            [self applyResign:move];
            break;
        case kMoveStaleMate:
            [self applyStaleMate:move];
            break;
        default:
            NSLog(@"applying unknown move %d", type);
            break;
    }
    
    // promote if necessary
    [self applyPromotion:move];
    
    // maintain castling status
    [self updateCastlingStatus:move];
}

-(void)applyNormalMove:(ChessMove *)move {
    
    int piece = [move capturedPiece];
    
    if (kEmptySquare != piece) {
        [opponent removePiece:piece at:[move destinationSquare]];
    }
    
    [self movePiece:[move movingPiece] from:[move sourceSquare] to:[move destinationSquare]];
}

-(void)applyPromotion:(ChessMove *)move {
    
    int piece = [move promotion];
    
    if (piece) {
        [self replacePiece:[move movingPiece] with:piece at:[move destinationSquare]];
    }
}

-(void)applyResign:(ChessMove *)move {
    
//    if ([self userAgent]) {
//        [[self userAgent] finishedGame:![self isWhitePlayer]];
//    }
}

-(void)applyStaleMate:(ChessMove *)move {
    
//    if ([self userAgent]) {
//        [[self userAgent] finishedGame:0.5];
//    }
}

-(void)updateCastlingStatus:(ChessMove *)move {
    
    // cannot castle when king has moved
    if (kKing == [move movingPiece]) {
        castlingStatus |= kCastlingDisableAll;
        return;
    }
    
    // see if a rook has moved
    if (kRook == [move movingPiece]) {
        return;
    }
    
    if ([self isWhitePlayer]) {
        if (0 == [move sourceSquare]) {
            castlingStatus |= kCastlingDisableQueenSide;
        }
        else if (7 == [move sourceSquare]) {
            castlingStatus |= kCastlingDisableKingSide;
        }
    }
    else {
        if (56 == [move sourceSquare]) {
            castlingStatus |= kCastlingDisableQueenSide;
        }
        else if (63 == [move sourceSquare]) {
            castlingStatus |= kCastlingDisableKingSide;
        }
    }
}

#pragma mark accessing

-(int)pieceAt:(int)square {
    
    if (square > 63) {
        NSLog(@"index out of range: pieces[%2d]", square);
        NSException *exception = [NSException exceptionWithName:@"Index out of range"
                                                         reason:@"" userInfo:nil];
        [exception raise];
    }
    
    return pieces[square];
}

-(unsigned char *)pieces {
    
    return pieces;
}

#pragma mark testing

-(BOOL)canCastleKingSide {
    
    if (castlingStatus & kCastlingEnableKingSide) {
        return NO;
    }
    
    if ([self isWhitePlayer]) {
        if (pieces[5] || pieces[6] || [opponent pieceAt:5] || [opponent pieceAt:6]) {
            return NO;
        }
    }
    else {
        if (pieces[61] || pieces[62] || [opponent pieceAt:61] || [opponent pieceAt:62]) {
            return NO;
        }
    }
    
    return YES;
}

-(BOOL)canCastleQueenSide {
    
    if (castlingStatus & kCastlingEnableQueenSide) {
        return NO;
    }
    
    if ([self isWhitePlayer]) {
        if (pieces[1] || pieces[2] || pieces[3] || [opponent pieceAt:1] || [opponent pieceAt:2] || [opponent pieceAt:3]) {
            return NO;
        }
    }
    else {
        if (pieces[57] || pieces[58] || pieces[59] || [opponent pieceAt:57] || [opponent pieceAt:58] || [opponent pieceAt:59]) {
            return NO;
        }
    }
    
    return YES;
}

//
// if the receiver's king can't be taken after applying the move, it is valid
//
-(BOOL)isValidMove:(ChessMove *)move {
    
    ChessBoard *copy = [board copy];
    [copy nextMove:move];
    
    NSArray *possibleMoves = [[copy activePlayer] findPossibleMoves];
    
    return (nil != possibleMoves);
}

-(BOOL)isValidMoveFrom:(int)sourceSquare to:(int)destSquare {
    
    for (ChessMove *move in [self findValidMovesAt:sourceSquare]) {
       if (destSquare == [move destinationSquare]) {
           return YES;
       }
    }
    return NO;
}

-(BOOL)isWhitePlayer {
    
    return ([board whitePlayer] == self);
}

#pragma mark copying

-(void)postCopy {
    unsigned char *piecesCopy = calloc(64, sizeof(unsigned char));
    
    memcpy(piecesCopy, pieces, 64 * sizeof(char));
    pieces = piecesCopy;
}

// shallow copy
-(id)copyWithZone:(NSZone *)zone {
    
  id copy = [[ChessPlayer alloc] initializeWithPlayer:self];
  [copy postCopy];
  
  return copy;
}

//
// copy all volatile state from another player
//
-(void)copyPlayer:(ChessPlayer *)aPlayer {
    
    castlingRookSquare = aPlayer.castlingRookSquare;
    enpassantSquare = aPlayer.enpassantSquare;
    castlingStatus = aPlayer.castlingStatus;
    materialValue = aPlayer.materialValue;
    numPawns = aPlayer.numPawns;
    positionalValue = aPlayer.positionalValue;
    memcpy(pieces, aPlayer.pieces, 64 * sizeof(char));
}

#pragma mark evaluation

-(int)evaluate {
    
    return [self evaluateMaterial] + [self evaluatePosition];
}

//
// Compute the board's material balance, from the point of view of the side
// player.  This is an exact clone of the eval function in CHESS 4.5
//
-(int)evaluateMaterial {
    
    int omv = [opponent materialValue];
    
    if (materialValue == omv)   // both sides are equal
        return 0;
    
    int total = materialValue + omv;
    int diff = materialValue - omv;
    
    return MIN(2400,diff) + ((diff * (12000 - total) * numPawns) / (6400 * (numPawns + 1)));
}

//
// Compute the board's positional balance, from the point of view of the side player
//
-(int)evaluatePosition {
    
    return positionalValue - [opponent positionalValue];
}

#pragma mark moves-general

//
// Find all possible moves. This method does not check if the move is legal,
// e.g., if the king of the player is under attack after the move.
// If the opponent is check mate (e.g., the king could be taken in the next move) the method returns nil.
// If the game is stale mate (e.g., the receiver has no move left) this method returns an empty array.
//
-(NSArray *)findPossibleMoves {
    
    ChessMoveList *moveList = [board.generator findPossibleMovesFor:self];

    if (nil == moveList)
        return nil;
    
    NSMutableArray *moves = [NSMutableArray array];
    NSArray *contentsCopy = [moveList copyContents];
    
    for (ChessMove *move in contentsCopy) {
        ChessMove *moveCopy = [move copy];
        if (moveCopy.destinationSquare > 63) {
            NSLog(@"invalid move");
        }
        [moves addObject:moveCopy];
    }
    
    
    return moves;
}

//
// Find all possible moves at the given square. This method does not check if the move is legal,
// e.g., if the king of the player is under attack after the move.
// If the opponent is check mate (e.g., the king could be taken in the next move) the method returns nil.
// If the game is stale mate (e.g., the receiver has no move left) this method returns an empty array.
//
-(NSArray *)findPossibleMovesAt:(int)square {
    
    ChessMoveList *moveList = [board.generator findPossibleMovesFor:self at:square];
    
    if (nil == moveList)
        return nil;
    
    NSMutableArray *moves = [NSMutableArray array];
    
    NSArray *contentsCopy = [moveList copyContents];
    
    for (ChessMove *move in contentsCopy) {
        ChessMove *moveCopy = [move copy];
        if (moveCopy.destinationSquare > 63) {
            NSLog(@"invalid move");
        }
        [moves addObject:moveCopy];
    }
      
    [board.generator recycleMoveList:moveList];
    
    return moves;
}

//
// Find all possible moves. This method does not check if the move is legal
// e.g., if the king of the player is under attack after the move.
// If the opponent is check mate (e.g., the king could be taken in the next move) the method returns nil.
// If the game is stale mate (e.g., the receiver has no move left) this method returns an empty array.
//
-(NSArray *)findQuiescenceMoves {
    
    ChessMoveList *moveList = [board.generator findQuiescenceMovesFor:self];
    
    if (nil == moveList)
        return nil;
    
    NSMutableArray *moves = [NSMutableArray arrayWithArray:[moveList originalContents]];
    
    for (ChessMove *move in [moveList originalContents]) {
        ChessMove *moveCopy = [move copy];
        if (moveCopy.destinationSquare > 63) {
            NSLog(@"invalid move");
        }
        [moves addObject:moveCopy];
    }
    
    [board.generator recycleMoveList:moveList];
    
    return moves;
}

//
// find all the valid moves
//
-(NSArray *)findValidMoves {
    
    NSArray *moveList = [self findPossibleMoves];
    
    if (nil == moveList)
        return nil;
    
    NSMutableArray *moves = [NSMutableArray arrayWithCapacity:[moveList count]];
    
    for (ChessMove *move in moveList) {
        if ([self isValidMove:move]) {
            ChessMove *moveCopy = [move copy];
            if (moveCopy.destinationSquare > 63) {
                NSLog(@"invalid move");
            }
            [moves addObject:moveCopy];
        }
    }
    
    return moves;
}

-(NSArray *)findValidMovesAt:(int)square {
    
    NSArray *moveList = [self findPossibleMovesAt:square];
    
    if (nil == moveList)
        return nil;
    
    NSMutableArray *moves = [NSMutableArray arrayWithCapacity:[moveList count]];
    
    for (ChessMove *move in moveList) {
        if ([self isValidMove:move]) {
            ChessMove *copy = [move copy];
            [moves addObject:copy];
            if (copy.destinationSquare > 63) {
                NSLog(@"invalid move");
            }
        }
    }
    
    return moves;
}

#pragma mark undo

-(void)undoCastlingKingSideMove:(ChessMove *)move {
    
    // remove extra kings
    [self prepareNextMove];
    
    [self movePiece:[move movingPiece] from:[move destinationSquare] to:[move sourceSquare]];
    [self movePiece:kRook from:[move sourceSquare]+1 to:[move sourceSquare]+3];
}

-(void)undoCastlingQueenSideMove:(ChessMove *)move {
    
    // remove extra kings
    [self prepareNextMove];
    
    [self movePiece:[move movingPiece] from:[move destinationSquare] to:[move sourceSquare]];
    [self movePiece:kRook from:[move sourceSquare]-1 to:[move sourceSquare]-4];
}

-(void)undoDoublePushMove:(ChessMove *)move {
    
    enpassantSquare = -1;
    [self movePiece:[move movingPiece] from:[move destinationSquare] to:[move sourceSquare]];
}

-(void)undoEnpassantMove:(ChessMove *)move {
    
    [self movePiece:[move movingPiece] from:[move destinationSquare] to:[move sourceSquare]];
    
    [opponent addPiece:[move capturedPiece] at:[move destinationSquare] - ([self isWhitePlayer] ? 8 : -8)];
}

-(void)undoMove:(ChessMove *)move {
    
    int type = [move moveType] & kBasicMoveMask;

    switch(type) {
        case kMoveNormal:
            [self undoNormalMove:move];
            break;
        case kMoveDoublePush:
            [self undoDoublePushMove:move];
            break;
        case kMoveCaptureEnPassant:
            [self undoEnpassantMove:move];
            break;
        case kMoveCastlingKingSide:
            [self undoCastlingKingSideMove:move];
            break;
        case kMoveCastlingQueenSide:
            [self undoCastlingQueenSideMove:move];
            break;
        case kMoveResign:
            [self undoResign:move];
            break;
        case kMoveStaleMate:
            [self undoStaleMate:move];
            break;
        default:
            NSLog(@"applying unknown move %d", type);
            break;
    }
}

-(void)undoNormalMove:(ChessMove *)move {
    
    [self movePiece:[move movingPiece] from:[move destinationSquare] to:[move sourceSquare]];
    
    int piece = [move capturedPiece];
    
    if (kEmptySquare != piece) {
        [opponent addPiece:piece at:[move destinationSquare]];
    }
}

-(void)undoPromotion:(ChessMove *)move {
    
    int piece = [move promotion];
    
    if (piece) {
        [self replacePiece:piece with:[move movingPiece] at:[move destinationSquare]];
    }
}

-(void)undoResign:(ChessMove *)move {
    
}

-(void)undoStaleMate:(ChessMove *)move {
    
}

@end
