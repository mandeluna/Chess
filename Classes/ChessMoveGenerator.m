//
//  ChessMoveGenerator.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "ChessMoveGenerator.h"
#import "ChessPlayer.h"
#import "ChessConstants.h"
#import "ChessMove.h"
#import "ChessMoveList.h"

#define NUM_PLIES   100                 // size of streamList array
#define NUM_MOVES   30 * NUM_PLIES      // size of moveList array

@implementation ChessMoveGenerator

@synthesize kingAttack;

#pragma mark public

-(char *)attackSquares {
    
    return attackSquares;
}

//
// Find all possible moves. This method does not check if the move is legal,
// e.g., if the king of the player is under attack after the move.
// If the opponent is check mate (e.g., the king could be taken in the next move) the method returns nil.
// If the game is stale mate (e.g., the receiver has no move left) this method returns an empty array.
//
-(ChessMoveList *)findAllPossibleMovesFor:(ChessPlayer *)player {
    
    ChessPlayer *opponent = [player opponent];
    
    myPlayer = player;
    memcpy(myPieces, [player pieces], 64*sizeof(char));
    memcpy(itsPieces, [opponent pieces], 64*sizeof(char));
    castlingStatus = [player castlingStatus];
    enpassantSquare = [opponent enpassantSquare];
    
    if (firstMoveIndex != lastMoveIndex) {
        NSLog(@"I am confused");
        NSException *exception = [NSException exceptionWithName:@"Index corruption"
                                                         reason:@"Move indexes are out of sync" userInfo:nil];
        [exception raise];
    }
    
    self.kingAttack = nil;
    
    int square = 0;
    BOOL isWhite = [myPlayer isWhitePlayer];
    
    while (square < 64) {
        for (int i=square; myPieces[i]; i++);
        
        if (0 == square)
            break;
        
        int piece = myPieces[square];
        
        switch (piece) {
            case kPawn:
                isWhite ? [self moveWhitePawnAt:square] : [self moveBlackPawnAt:square];
                break;
            case kKnight:
                [self moveKnightAt:square];
                break;
            case kBishop:
                [self moveBishopAt:square];
                break;
            case kRook:
                [self moveRookAt:square];
                break;
            case kQueen:
                [self moveQueenAt:square];
                break;
            case kKing:
                isWhite ? [self moveWhiteKingAt:square] : [self moveBlackKingAt:square];
                break;
            default:
                NSLog(@"Unknown piece %d", piece);
                NSException *exception = [NSException exceptionWithName:@"Invalid piece"
                                                                 reason:@"myPieces are corrupt!" userInfo:nil];
                [exception raise];
        }
        
        if (kingAttack)
            break;
    }
    
    return [self moveList];
}

//
// Mark all the fields of a board that are attacked by the given player.
// The pieces attacking a field are encoded as (1 << Piece) so that we can
// record all types of pieces that attack the square.
//
-(char *)findAttackSquaresFor:(ChessPlayer *)player {
    
    forceCaptures = NO;
    bzero(attackSquares, 64 * sizeof(char));
    
    ChessMoveList *list = [self findAllPossibleMovesFor:player];
    
    for (ChessMove *move in list) {
        
        int square = [move destinationSquare];
        int piece = [move movingPiece];
        int attack = attackSquares[square];
        attack |= (1 << piece);
        attackSquares[square] = attack;
    }
    
    [self recycleMoveList:list];
    
    return attackSquares;
}

-(ChessMoveList *)findPossibleMovesFor:(ChessPlayer *)player {
    
    forceCaptures = NO;
    return [self findAllPossibleMovesFor:player];
}

-(ChessMoveList *)findPossibleMovesFor:(ChessPlayer *)player at:(int)square {
    
    forceCaptures = NO;
    myPlayer = player;
    ChessPlayer *opponent = [player opponent];
    memcpy(myPieces, [player pieces], 64*sizeof(char));
    memcpy(itsPieces, [opponent pieces], 64*sizeof(char));
    castlingStatus = [player castlingStatus];
    enpassantSquare = [opponent enpassantSquare];
    
    if (firstMoveIndex != lastMoveIndex) {
        NSLog(@"findPossibleMovesFor:at: is confused");
        NSException *exception = [NSException exceptionWithName:@"Index corruption"
                                                         reason:@"Move indexes are out of sync" userInfo:nil];
        [exception raise];
    }
    
    self.kingAttack = nil;
    
    int piece = myPieces[square];
    
    switch (piece) {
        case kPawn:
            [self movePawnAt:square];
            break;
        case kKnight:
            [self moveKnightAt:square];
            break;
        case kBishop:
            [self moveBishopAt:square];
            break;
        case kRook:
            [self moveRookAt:square];
            break;
        case kQueen:
            [self moveQueenAt:square];
            break;
        case kKing:
            [self moveKingAt:square];
            break;
        default:
            // do nothing (kEmptySquare)
            break;
    }
    
    return [self moveList];
}

//
// Quiescence moves are moves that involve capturing pieces
//
-(ChessMoveList *)findQuiescenceMovesFor:(ChessPlayer *)player at:(int)square {
    
    forceCaptures = YES;
    return [self findAllPossibleMovesFor:player];
}

-(ChessMoveList *)moveList {
    
    if (kingAttack) {
        lastMoveIndex = firstMoveIndex;
        return nil;
    }
    
    streamListIndex++;
    ChessMoveList *list = [streamList objectAtIndex:streamListIndex];
    [list on:moveList from:firstMoveIndex+1 to:lastMoveIndex];
    firstMoveIndex = lastMoveIndex;
    
    return list;
}

-(void)profileGenerationFor:(ChessPlayer *)player {
    
}

-(void)recycleMoveList:(ChessMoveList *)aChessMoveList {
    
    if (aChessMoveList != [streamList objectAtIndex:streamListIndex]) {
        NSLog(@"recycleMoveList is confused");
        NSException *exception = [NSException exceptionWithName:@"Index corruption"
                                                         reason:@"Move indexes are out of sync" userInfo:nil];
        [exception raise];
    }
    streamListIndex--;
    firstMoveIndex = lastMoveIndex = [aChessMoveList startIndex] - 1;
}

#pragma mark moves-pawns

-(void)blackPawnCaptureAt:(int)square direction:(int)dir {
    
    int destSquare = square - 8 - dir;
    int piece = itsPieces[destSquare];
    
    if (piece) {
        ChessMove *move = [moveList objectAtIndex:lastMoveIndex++];
        [move move:kPawn from:square to:destSquare capture:piece];
        
        if (kKing == piece) {
            self.kingAttack = move;
        }
        
        if (destSquare < 8) {   // a promotion!
            [self promotePawn:move];
        }
    }
    
    // attempt an en-passant capture
    if (destSquare == enpassantSquare) {
        [[moveList objectAtIndex:lastMoveIndex++] captureEnPassant:kPawn from:square to:destSquare];
    }
}

-(void)blackPawnPushAt:(int)square {
    
    // try to push this pawn
    int destSquare = square - 8;
    if (myPieces[destSquare])
        return;
    if (itsPieces[destSquare])
        return;
    
    ChessMove *move = [moveList objectAtIndex:lastMoveIndex++];
    [move move:kPawn from:square to:destSquare];
    
    if (destSquare < 8) {   // a promotion (can't be double-push so get out)
        return [self promotePawn:move];
    }
    
    // try to double-push if possible
    if (square > 47)
        return;
    destSquare = square - 16;
    if (myPieces[destSquare])
        return;
    if (itsPieces[destSquare])
        return;
    
    [[moveList objectAtIndex:lastMoveIndex++] doublePush:kPawn from:square to:destSquare];
}

//
// Pawns move only in one direction, so check for which direction to use
//
-(void)moveBlackPawnAt:(int)square {
    
    if (!forceCaptures) {
        [self blackPawnPushAt:square];
    }
    
    if (1 != (square & 7)) {
        [self blackPawnCaptureAt:square direction:1];
    }
    
    if (0 != (square & 7)) {
        [self blackPawnCaptureAt:square direction:-1];
    }
}

-(void)whitePawnCaptureAt:(int)square direction:(int)dir {
    
    int destSquare = square + 8 + dir;
    int piece = itsPieces[destSquare];
    
    if (piece) {
        ChessMove *move = [moveList objectAtIndex:lastMoveIndex++];
        [move move:kPawn from:square to:destSquare capture:piece];
        
        if (kKing == piece) {
            self.kingAttack = move;
        }
        
        if (destSquare > 55) {   // a promotion!
            [self promotePawn:move];
        }
    }
    
    // attempt an en-passant capture
    if (destSquare == enpassantSquare) {
        [[moveList objectAtIndex:lastMoveIndex++] captureEnPassant:kPawn from:square to:destSquare];
    }
}

-(void)whitePawnPushAt:(int)square {
    
    // try to push this pawn
    int destSquare = square + 8;
    if (myPieces[destSquare])
        return;
    if (itsPieces[destSquare])
        return;
    
    ChessMove *move = [moveList objectAtIndex:lastMoveIndex++];
    [move move:kPawn from:square to:destSquare];
    
    if (destSquare > 55) {   // a promotion (can't be double-push so get out)
        return [self promotePawn:move];
    }
    
    // try to double-push if possible
    if (square < 16)
        return;
    destSquare = square + 16;
    if (myPieces[destSquare])
        return;
    if (itsPieces[destSquare])
        return;
    
    [[moveList objectAtIndex:lastMoveIndex++] doublePush:kPawn from:square to:destSquare];
}

//
// Pawns move only in one direction, so check for which direction to use
//

-(void)moveWhitePawnAt:(int)square {
    
    if (!forceCaptures) {
        [self whitePawnPushAt:square];
    }
    
    if (0 != (square & 7)) {
        [self whitePawnCaptureAt:square direction:1];
    }
    
    if (1 != (square & 7)) {
        [self whitePawnCaptureAt:square direction:-1];
    }
}

//
// Duplicate the given move and embed all promotion types
//
-(void)promotePawn:(ChessMove *)move {
    
    [[moveList objectAtIndex:lastMoveIndex++] promote:move to:kKnight];
    [[moveList objectAtIndex:lastMoveIndex++] promote:move to:kBishop];
    [[moveList objectAtIndex:lastMoveIndex++] promote:move to:kRook];
    [move promote:move to:kQueen];
}

#pragma mark support

-(BOOL)canCastleBlackKingSide {
    
    if (0 != (castlingStatus & CastlingEnableKingSide))
        return NO;
    
    // quickly check if all the squares are zero
    if (myPieces[G8-1] + myPieces[F8-1] + itsPieces[G8-1] + itsPieces[F8-1])
        return NO;
    
    // check for castling squares under attack. See canCastleBlackQueenSide for details
    int hRank[] = {H7,H6,H5,H4,H3,H2,H1,0};
    if ([self checkAttack:hRank fromPieces:RookMovers])
        return NO;
    
    return YES;
}

-(BOOL)canCastleBlackQueenSide {
    
}

-(BOOL)canCastleWhiteKingSide {
    
}

-(BOOL)canCastleWhiteQueenSide {
    
}

-(BOOL)checkAttack:(int *)squares fromPieces:(int *)pieces {
    
}

-(BOOL)checkUnprotectedAttack:(int *)squares fromPieces:(int *)pieces {
    
}

#pragma mark initialize
                   
-(id)init {
    if (self = [super init]) {
        // 100 "plies" -- what's a ply?
        streamList = [[NSMutableArray arrayWithCapacity:NUM_PLIES] retain];
        for (int i=0; i<NUM_PLIES; i++) {
            ChessMoveList *cml = [[ChessMoveList alloc] init];
            [streamList addObject:cml];
            [cml autorelease];
        }
        
        // average 30 moves per ply
        moveList = [[NSMutableArray arrayWithCapacity:NUM_MOVES] retain];
        for (int i=0; i<NUM_MOVES; i++) {
            ChessMove *cm = [[ChessMove alloc] init];
            [moveList addObject:cm];
            [cm autorelease];
        }
        
        firstMoveIndex = lastMoveIndex = streamListIndex = 0;
    }
    return self;
}
                   
-(void)dealloc {
    [super dealloc];
    [streamList release];
    [moveList release];
}

#pragma mark moves-general

-(void)moveBishopAt:(int)square {
    
}

-(void)moveBlackKingAt:(int)square {
    
}

-(void)moveKingAt:(int)square {
    
}

-(void)moveKnightAt:(int)square {
    
}

-(void)movePawnAt:(int)square {
    
}

-(void)movePiece:(int)piece along:(NSArray *)rayList at:(int)square {
    
}

-(void)moveQueenAt:(int)square {
    
}

-(void)moveRookAt:(int)square {
    
}

-(void)moveWhiteKingAt:(int)square {
    
}

@end
