//
//  ChessMove.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "ChessMove.h"
#import "ChessEngine-Swift.h"

@implementation ChessMove

@synthesize bestMove, capturedPiece, destinationSquare, moveType=type, movingPiece, sourceSquare, value;

-(ChessMove *)initializeWithMove:(ChessMove *)move {
    ChessMove *newMove = [self init];
    
    newMove.bestMove = move.bestMove;
    newMove.capturedPiece = move.capturedPiece;
    newMove.destinationSquare = move.destinationSquare;
    newMove.moveType = move.moveType;
    newMove.movingPiece = move.movingPiece;
    newMove.sourceSquare = move.sourceSquare;
    newMove.value = move.value;
    
    return newMove;
}

#pragma mark (Class) Accessing

+(ChessMove *)decodeFrom:(int)encodedMove {
    
    ChessMove *instance = [[ChessMove alloc] init];
    [instance moveEncoded:encodedMove];
    return instance;
}

+(int)basicMoveMask {
    
    return kBasicMoveMask;
}

static ChessMove *NullMove = nil;

// return a placeholder move (#none)
+(ChessMove *)nullMove {
    if (!NullMove) {
        NullMove = [[ChessMove alloc] init];
        NullMove.moveType = kNullMove;
    }
    return NullMove;
}

#pragma mark encoding

//
// return an integer encoding enough of a move for printing
//
-(int)encodedMove {
    
    return destinationSquare + (sourceSquare << 8) + (movingPiece << 16) + (capturedPiece << 24);
}

#pragma mark Accessing

-(void)setDestinationSquare:(int)intValue {
    
    if ((intValue < 0) || (intValue > 63)) {
        NSException *exception = [NSException exceptionWithName:@"Invalid Index"
                                                         reason:@"Board index out of range"
                                                       userInfo:nil];
        [exception raise];
    }
    destinationSquare = intValue;
}

-(void)setSourceSquare:(int)intValue {
    
    if ((intValue < 0) || (intValue > 63)) {
        NSException *exception = [NSException exceptionWithName:@"Invalid Index"
                                                         reason:@"Board index out of range"
                                                       userInfo:nil];
        [exception raise];
    }
    sourceSquare = intValue;
}

-(int)promotion {
    
    return type >> kExtractPromotionShift;
}

#pragma mark Initialize

-(id)init {
    if (self = [super init]) {
        movingPiece = sourceSquare = destinationSquare = 1;
        type = kMoveNormal;
        capturedPiece = 0;
    }
    return self;
}

-(void)captureEnPassant:(int)aPiece from:(int)startSquare to:(int)endSquare {
    
    movingPiece = capturedPiece = aPiece;
    self.sourceSquare = startSquare;
    self.destinationSquare = endSquare;
    type = kMoveCaptureEnPassant;
}

-(void)checkMate:(int)aPiece {
    
    movingPiece = aPiece;
    self.sourceSquare = 0;
    destinationSquare = 0;
    type = kMoveResign;
    capturedPiece = 0;
}

-(void)doublePush:(int)aPiece from:(int)startSquare to:(int)endSquare {
    
    movingPiece = aPiece;
    self.sourceSquare = startSquare;
    self.destinationSquare = endSquare;
    type = kMoveDoublePush;
    capturedPiece = 0;
}

-(void)move:(int)aPiece from:(int)startSquare to:(int)endSquare {
    
    //    if ((1 == aPiece) && ((endSquare < 8) || (startSquare < 8))) {
    //        NSLog(@"illegal move?");
    //    }
    
    movingPiece = aPiece;
    self.sourceSquare = startSquare;
    self.destinationSquare = endSquare;
    type = kMoveNormal;
    capturedPiece = 0;
}

-(void)move:(int)aPiece from:(int)startSquare to:(int)endSquare capture:(int)capture {
    
    movingPiece = aPiece;
    self.sourceSquare = startSquare;
    self.destinationSquare = endSquare;
    type = kMoveNormal;
    capturedPiece = capture;
}

-(void)moveCastlingKingSide:(int)aPiece from:(int)startSquare to:(int)endSquare {
    
    movingPiece = aPiece;
    self.sourceSquare = startSquare;
    self.destinationSquare = endSquare;
    type = kMoveCastlingKingSide;
    capturedPiece = 0;
}

-(void)moveCastlingQueenSide:(int)aPiece from:(int)startSquare to:(int)endSquare {
    
    movingPiece = aPiece;
    self.sourceSquare = startSquare;
    self.destinationSquare = endSquare;
    type = kMoveCastlingQueenSide;
    capturedPiece = 0;
}

-(void)moveEncoded:(int)intValue {
    
    self.destinationSquare = intValue & 255;        // setter checks for a value between 0 and 63
    self.sourceSquare = (intValue >> 8) & 255;      // setter checks for a value between 0 and 63
    movingPiece = (intValue >> 16) & 255;
    capturedPiece = (intValue >> 24) & 255;
    type = kMoveNormal;
    
    assert(intValue == [self encodedMove]);
}

-(void)promote:(ChessMove *)move to:(int)intValue {
    
    movingPiece = [move movingPiece];
    capturedPiece = [move capturedPiece];
    self.sourceSquare = [move sourceSquare];
    self.destinationSquare = [move destinationSquare];
    type = [move moveType];
    type = type | (intValue << kPromotionShift);
}

-(void)staleMate:(int)aPiece {
    
    movingPiece = aPiece;
    sourceSquare = 0;
    destinationSquare = 0;
    type = kMoveStaleMate;
    capturedPiece = 0;
}

#pragma mark copying

// shallow copy
-(ChessMove *)copyWithZone:(NSZone *)zone {
    return [[ChessMove alloc] initializeWithMove:self];
}

#pragma mark Comparing

-(BOOL)isNullMove {
    return (kNullMove == self.moveType);
}

-(BOOL)isEqual:(ChessMove *)aMove {
    if (movingPiece != aMove.movingPiece) return NO;
    if (capturedPiece != aMove.capturedPiece) return NO;
    if (type != aMove.moveType) return NO;
    if (sourceSquare != aMove.sourceSquare) return NO;
    if (destinationSquare != aMove.destinationSquare) return NO;
    return YES;
}

-(NSInteger)hash {
    NSUInteger mh = [[NSNumber numberWithInt:movingPiece] hash];
    NSUInteger ch = [[NSNumber numberWithInt:capturedPiece] hash];
    NSUInteger sh = [[NSNumber numberWithInt:sourceSquare] hash];
    NSUInteger dh = [[NSNumber numberWithInt:destinationSquare] hash];
    NSUInteger th = [[NSNumber numberWithInt:type] hash];
    
    return (mh ^ ch ^ sh ^ dh ^ th);
}

#pragma mark Printing

// print the SAN string for the move, using the board to resolve ambiguous abbreviations
// PGN compatible moves as described in https://en.wikipedia.org/wiki/Portable_Game_Notation#Movetext
-(nonnull NSString *)sanStringForBoard:(nonnull ChessBoard *)board {
    return [self sanStringForBoard:board unicodeGlyphs:NO];
}

// print the SAN string for the move, using the board to resolve ambiguous abbreviations
// PGN compatible moves as described in https://en.wikipedia.org/wiki/Portable_Game_Notation#Movetext
-(nonnull NSString *)sanStringForBoard:(nonnull ChessBoard *)board unicodeGlyphs:(BOOL)useUnicode {
    if ([self isNullMove]) {
        return @"0000";
    }
    // SAN kingside castling is indicated by the sequence O-O; queenside castling is indicated by
    // the sequence O-O-O (note that these are capital Os, not zeroes, contrary to the FIDE standard for notation)
    if (type == kMoveCastlingKingSide) {
        return @"O-O";
    }
    if (type == kMoveCastlingQueenSide) {
        return @"O-O-O";
    }
    
    // The pawn is given an empty abbreviation in SAN movetext
    NSArray *labels = useUnicode ? @[ @"", @"", @"♘", @"♗", @"♖", @"♕", @"♔" ] : @[ @"", @"", @"N", @"B", @"R", @"Q", @"K" ];
    
    // For most moves the SAN consists of the letter abbreviation for the piece
    NSString *name = labels[movingPiece];

    // an x if there is a capture, and the two-character algebraic name of the final square the piece moved to.
    NSString *capture = (capturedPiece == 0) ? @"" : @"x";
    char file = 'a' + (destinationSquare & 7);
    char rank = '1' + (destinationSquare >> 3);

    // if a pawn is capturing, indicate the file (not specified above, but Stockfish NNUE appears to do this)
    if ((movingPiece == kPawn) && (capturedPiece != 0)) {
        capture = [[NSString stringWithFormat:@"%c", 'a' + (sourceSquare & 7)] stringByAppendingString:capture];
    }

    // Pawn promotions are notated by appending = to the destination square, followed by the piece the pawn is promoted to
    NSString *promotion = @"";
    int promoted = [self promotion];
    if (promoted != 0) {
        promotion = [NSString stringWithFormat:@"=%@", labels[promoted]];
    }
    
    ChessBoard *newBoard = [board copy];
    [newBoard copyBoard:board];
    [newBoard nextMove:self];

    // If the move is a checking move, + is also appended; if the move is a checkmating move, # is appended instead
    NSArray *their_moves = [newBoard.activePlayer findValidMoves];
    NSString *kingAttack = (newBoard.generator.kingAttack) ? ((their_moves.count == 0) ? @"#" : @"+") : @"";

    NSString *unambiguous = [NSString stringWithFormat:@"%@%c%c%@%@", capture, file, rank, promotion, kingAttack];

#if !__has_feature(objc_arc)
    [newBoard release];
#endif

    // In a few cases, a more detailed representation is needed to resolve ambiguity;
    // if so, the piece's file letter, numerical rank, or the exact square is inserted
    // after the moving piece's name (in that order of preference).
    NSArray *our_moves = [board.activePlayer findValidMoves];
    NSString *prefix = [self disambiguatingPrefix:our_moves];

    NSString *result = [NSString stringWithFormat:@"%@%@%@", name, prefix, unambiguous];
    return result;
}

// avoid ambiguity if multiple pieces with the same name can move to the same destination
-(NSString *)disambiguatingPrefix:(NSArray *)moves {
    BOOL disambiguateFile = NO;
    BOOL disambiguateRank = NO;

    char file = 'a' + (sourceSquare & 7);
    char rank = '1' + (sourceSquare >> 3);

    for (ChessMove *move in moves) {
        // if piece is not the same type, the move will not be ambiguous
        if ((move.movingPiece != movingPiece) ||
            (move.destinationSquare != destinationSquare) ||  /* skip non-conflicting moves */
            (move.sourceSquare == sourceSquare))  /* skip self */ {
            continue;
        }

        char move_file = 'a' + (move.sourceSquare & 7);
        char move_rank = '1' + (move.sourceSquare >> 3);

        disambiguateRank = disambiguateRank || (move_file == file);
        disambiguateFile = disambiguateFile || (move_rank == rank);
        // Knights might be on a different rank and file, if so disambiguate by file
        if ((move.movingPiece == kKnight) && !((move_file == file) || (move_rank == rank))) {
            disambiguateFile = YES;
        }
    }

    if (disambiguateRank && disambiguateFile > 0) {
        return [NSString stringWithFormat:@"%c%c", file, rank];
    }
    if (disambiguateFile) {
        return [NSString stringWithFormat:@"%c", file];
    }
    if (disambiguateRank) {
        return [NSString stringWithFormat:@"%c", rank];
    }

    return @"";
}

// UCI expects a straightforward encoding of source and destination squares
-(nonnull NSString *)uciString {
    if ([self isNullMove]) {
        return @"0000";
    }
    
    char c2 = 'a' + (sourceSquare & 7);
    char c3 = '1' + (sourceSquare >> 3);
    char c6 = 'a' + (destinationSquare & 7);
    char c7 = '1' + (destinationSquare >> 3);
    
    return [NSString stringWithFormat:@"%c%c%c%c", c2, c3, c6, c7];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@", [self uciString]];
}

@end
