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


// moves

#define BETWEEN07(i) ((i >= 0) && (i <= 7))

static moveValueList KingMoves[64];
static moveValueList RookMoves[64];
static moveValueList BishopMoves[64];
static moveValueList KnightMoves[64];


@interface ChessMoveGenerator(Private)

+(void)logMoves:(moveValueList[64])listValue;
+(void)initializeMoves;
+(void)initializeKnightMoves;
+(void)initializeRookMoves;
+(void)initializeBishopMoves;
+(void)initializeKingMoves;

@end


@implementation ChessMoveGenerator

@synthesize kingAttack;

#pragma mark private

+(void)initialize {
    [self initializeMoves];
}

+(void)logMoves:(moveValueList[64])listValue {
    
    for (int i=0; i < 64; i++) {
        printf("[%2d] ", i);
        for (int j=0; j < listValue[i].count; j++) {
            printf("%2d ", listValue[i].moves[j]);
        }
        printf("\n");
    }
    
}

+(void)initializeMoves {
    
    static BOOL initialized = NO;
    
    if (initialized)
        return;
    
    [self initializeKnightMoves];
    [self initializeRookMoves];
    [self initializeBishopMoves];
    [self initializeKingMoves];
    
    initialized = YES;
}

+(void)initializeKnightMoves {
    
    int relativeMoves[8][2] = {{-2, -1},{-1, -2},{1, -2},{2, -1},{-2, 1},{-1, 2},{1, 2},{2, 1}};
    
    for (int j=0; j<8; j++) {
        for (int i=0; i<8; i++) {
            int index = (j * 8) + i;
            
            NSMutableData *moveList = [NSMutableData data];
            
            for (int spec = 0; spec < 8; spec++) {
                int px = i + relativeMoves[spec][0];
                int py = j + relativeMoves[spec][1];
                if (BETWEEN07(px) && BETWEEN07(py)) {
                    int byteValue = py * 8 + px;
                    [moveList appendBytes:&byteValue length:sizeof(int)];
                }
            }
            //printf("\n");
            int len = [moveList length] / sizeof(int);
            KnightMoves[index].count = len;
            KnightMoves[index].moves = malloc(len * sizeof(int));
            memcpy(KnightMoves[index].moves, [moveList bytes], len * sizeof(int));
        }
    }
    
    NSLog(@"Knight Moves:\n");
    [self logMoves:KnightMoves];
}

+(void)initializeRookMoves {
    
    for (int j=0; j<8; j++) {
        for (int i=0; i<8; i++) {
            int index = (j * 8) + i;
            
            NSMutableData *moveList1 = [NSMutableData data];
            NSMutableData *moveList2 = [NSMutableData data];
            NSMutableData *moveList3 = [NSMutableData data];
            NSMutableData *moveList4 = [NSMutableData data];
            
            for (int k = 1; k < 8; k++) {
                int px = i + k;
                int py = j;
                if (BETWEEN07(px) && BETWEEN07(py)) {
                    int byteValue = py * 8 + px;
                    [moveList1 appendBytes:&byteValue length:sizeof(int)];
                }
                px = i;
                py = j + k;
                if (BETWEEN07(px) && BETWEEN07(py)) {
                    int byteValue = py * 8 + px;
                    [moveList2 appendBytes:&byteValue length:sizeof(int)];
                }
                px = i - k;
                py = j;
                if (BETWEEN07(px) && BETWEEN07(py)) {
                    int byteValue = py * 8 + px;
                    [moveList3 appendBytes:&byteValue length:sizeof(int)];
                }
                px = i;
                py = j - k;
                if (BETWEEN07(px) && BETWEEN07(py)) {
                    int byteValue = py * 8 + px;
                    [moveList4 appendBytes:&byteValue length:sizeof(int)];
                }
            }
            [moveList1 appendData:moveList2];
            [moveList1 appendData:moveList3];
            [moveList1 appendData:moveList4];
            int len = [moveList1 length] / sizeof(int);
            RookMoves[index].count = len;
            RookMoves[index].moves = malloc(len * sizeof(int));
            memcpy(RookMoves[index].moves, [moveList1 bytes], len * sizeof(int));
        }
    }
    
    NSLog(@"Rook Moves:\n");
    [self logMoves:RookMoves];
}

+(void)initializeBishopMoves {
    
    for (int j=0; j<8; j++) {
        for (int i=0; i<8; i++) {
            int index = (j * 8) + i;
            
            NSMutableData *moveList1 = [NSMutableData data];
            NSMutableData *moveList2 = [NSMutableData data];
            NSMutableData *moveList3 = [NSMutableData data];
            NSMutableData *moveList4 = [NSMutableData data];
            
            for (int k = 1; k < 8; k++) {
                int px = i + k;
                int py = j - k;
                if (BETWEEN07(px) && BETWEEN07(py)) {
                    int byteValue = py * 8 + px;
                    [moveList1 appendBytes:&byteValue length:sizeof(int)];
                }
                px = i - k;
                py = j - k;
                if (BETWEEN07(px) && BETWEEN07(py)) {
                    int byteValue = py * 8 + px;
                    [moveList2 appendBytes:&byteValue length:sizeof(int)];
                }
                px = i + k;
                py = j + k;
                if (BETWEEN07(px) && BETWEEN07(py)) {
                    int byteValue = py * 8 + px;
                    [moveList3 appendBytes:&byteValue length:sizeof(int)];
                }
                px = i - k;
                py = j + k;
                if (BETWEEN07(px) && BETWEEN07(py)) {
                    int byteValue = py * 8 + px;
                    [moveList4 appendBytes:&byteValue length:sizeof(int)];
                }
            }
            [moveList1 appendData:moveList2];
            [moveList1 appendData:moveList3];
            [moveList1 appendData:moveList4];
            int len = [moveList1 length] / sizeof(int);
            BishopMoves[index].count = len;
            BishopMoves[index].moves = malloc(len * sizeof(int));
            memcpy(BishopMoves[index].moves, [moveList1 bytes], len * sizeof(int));
        }
    }
    
    NSLog(@"Bishop Moves:\n");
    [self logMoves:BishopMoves];
}

+(void)initializeKingMoves {
    
    int relativeMoves[8][2] = {{-1, -1},{0, -1},{1, -1},{-1, 0},{1, 0},{-1, 1},{0, 1},{1, 1}};
    
    for (int j=0; j<8; j++) {
        for (int i=0; i<8; i++) {
            int index = (j * 8) + i;
            
            NSMutableData *moveList = [NSMutableData data];
            
            for (int spec = 0; spec < 8; spec++) {
                int px = i + relativeMoves[spec][0];
                int py = j + relativeMoves[spec][1];
                if (BETWEEN07(px) && BETWEEN07(py)) {
                    int byteValue = py * 8 + px;
                    [moveList appendBytes:&byteValue length:sizeof(int)];
                }
            }
            //printf("\n");
            int len = [moveList length] / sizeof(int);
            KingMoves[index].count = len;
            KingMoves[index].moves = malloc(len * sizeof(int));
            memcpy(KingMoves[index].moves, [moveList bytes], len * sizeof(int));
        }
    }
    
    NSLog(@"King Moves:\n");
    [self logMoves:KingMoves];
}


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

    // TODO: this is spinning 
//    NSLog(@"findAllPossibleMovesFor: lastMoveIndex = %d, forceCaptures = %d", lastMoveIndex, forceCaptures);
    
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
    
    BOOL isWhite = [myPlayer isWhitePlayer];
    
    for (int square = 0; square < 64; square++) {
        if (!myPieces[square])
            continue;
        
//        printf("+");
        
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
    
    NSLog(@"findAttackSquaresFor:");
    
    forceCaptures = NO;
    bzero(attackSquares, 64 * sizeof(char));
    
    ChessMoveList *list = [self findAllPossibleMovesFor:player];
    
    for (ChessMove *move in [list originalContents]) {
        
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
    
//    NSLog(@"findPossibleMovesFor:");

    forceCaptures = NO;
    return [self findAllPossibleMovesFor:player];
}

-(ChessMoveList *)findPossibleMovesFor:(ChessPlayer *)player at:(int)square {
    
//    NSLog(@"findPossibleMovesFor:at:");
    
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
-(ChessMoveList *)findQuiescenceMovesFor:(ChessPlayer *)player {
    
    forceCaptures = YES;
    return [self findAllPossibleMovesFor:player];
}

-(ChessMoveList *)moveList {
    
    if (kingAttack) {
        lastMoveIndex = firstMoveIndex;
        return nil;
    }
    
    ChessMoveList *list = [streamList objectAtIndex:++streamListIndex];
    [list on:moveList from:firstMoveIndex+1 to:lastMoveIndex];
    firstMoveIndex = lastMoveIndex;
    
    return list;
}

-(void)profileGenerationFor:(ChessPlayer *)player {
    
}

-(void)recycleMoveList:(ChessMoveList *)aChessMoveList {
    
    if (aChessMoveList != [streamList objectAtIndex:streamListIndex]) {
        NSLog(@"recycleMoveList is confused: index was %d but is actually %d", streamListIndex, [streamList indexOfObject:aChessMoveList]);
        NSException *exception = [NSException exceptionWithName:@"Index corruption"
                                                         reason:@"Move indexes are out of sync" userInfo:nil];
        [exception raise];
    }
    streamListIndex--;
    firstMoveIndex = lastMoveIndex = [aChessMoveList startIndex] - 1;
    
//    NSLog(@"recycled move list. streamListIndex is now %d", streamListIndex);
}

#pragma mark moves-pawns

-(void)blackPawnCaptureAt:(int)square direction:(int)dir {
    
    int destSquare = square - 8 - dir;
    int piece = itsPieces[destSquare];
    
    if (piece) {
        ChessMove *move = [moveList objectAtIndex:++lastMoveIndex];
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
        [[moveList objectAtIndex:++lastMoveIndex] captureEnPassant:kPawn from:square to:destSquare];
    }
}

-(void)blackPawnPushAt:(int)square {
    
    // try to push this pawn
    int destSquare = square - 8;
    if (myPieces[destSquare])
        return;
    if (itsPieces[destSquare])
        return;
    
    ChessMove *move = [moveList objectAtIndex:++lastMoveIndex];
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
    
    [[moveList objectAtIndex:++lastMoveIndex] doublePush:kPawn from:square to:destSquare];
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
        ChessMove *move = [moveList objectAtIndex:++lastMoveIndex];
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
        [[moveList objectAtIndex:++lastMoveIndex] captureEnPassant:kPawn from:square to:destSquare];
    }
}

-(void)whitePawnPushAt:(int)square {
    
    // try to push this pawn
    int destSquare = square + 8;
    if (myPieces[destSquare])
        return;
    if (itsPieces[destSquare])
        return;
    
    ChessMove *move = [moveList objectAtIndex:++lastMoveIndex];
    [move move:kPawn from:square to:destSquare];
    
    if (destSquare > 55) {   // a promotion (can't be double-push so get out)
        return [self promotePawn:move];
    }
    
    // try to double-push if possible
    if (square > 16)
        return;
    destSquare = square + 16;
    if (myPieces[destSquare])
        return;
    if (itsPieces[destSquare])
        return;
    
    [[moveList objectAtIndex:++lastMoveIndex] doublePush:kPawn from:square to:destSquare];
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
    
    [[moveList objectAtIndex:++lastMoveIndex] promote:move to:kKnight];
    [[moveList objectAtIndex:++lastMoveIndex] promote:move to:kBishop];
    [[moveList objectAtIndex:++lastMoveIndex] promote:move to:kRook];
    [move promote:move to:kQueen];
}

#pragma mark support
// TODO: consider a better representation of these guys (e.g. BitBoard)

-(BOOL)canCastleBlackKingSide {
    
    if (0 != (castlingStatus & CastlingEnableKingSide))
        return NO;
    
    // quickly check if all the squares are zero
    if (myPieces[G8] + myPieces[F8] + itsPieces[G8] + itsPieces[F8])
        return NO;
    
    // check for castling squares under attack
    // first check for vertical (rook-like) attacks
    int hRank[7] = {H7,H6,H5,H4,H3,H2,H1};
    moveValueList sqH = {7, hRank};
    if ([self checkAttack:&sqH fromPieces:RookMovers]) return NO;
    
    int gRank[7] = {G7,G6,G5,G4,G3,G2,G1};
    moveValueList sqG = {7, gRank};
    if ([self checkAttack:&sqG fromPieces:RookMovers]) return NO;
    
    int fRank[7] = {F7,F6,F5,F4,F3,F2,F1};
    moveValueList sqF = {7, fRank};
    if ([self checkAttack:&sqF fromPieces:RookMovers]) return NO;
    
    int eRank[7] = {E7,E6,E5,E4,E3,E2,E1};
    moveValueList sqE = {7, eRank};
    if ([self checkAttack:&sqE fromPieces:RookMovers]) return NO;
    
    // check for a rook attack from the baseline
    int rank8[4] = {D8, C8, B8, A8};
    moveValueList sq8 = {4, rank8};
    if ([self checkAttack:&sq8 fromPieces:RookMovers]) return NO;
    
    // check for bishop attacks from the diagonals
    int b1[7] = {G7, F6, E5, D4, C3, B2, A1};
    moveValueList sqb1 = {7, b1};
    if ([self checkAttack:&sqb1 fromPieces:BishopMovers]) return NO;
    
    int b2[6] = {F7, E6, D5, C4, B3, A2};
    moveValueList sqb2 = {7, b2};
    if ([self checkAttack:&sqb2 fromPieces:BishopMovers]) return NO;
        
    int b3[5] = {E7, D6, C5, B4, A3};
    moveValueList sqb3 = {5, b3};
    if ([self checkAttack:&sqb3 fromPieces:BishopMovers]) return NO;
    
    int b4[4] = {D7, C6, B5, A4};
    moveValueList sqb4 = {4, b4};
    if ([self checkAttack:&sqb4 fromPieces:BishopMovers]) return NO;
    
    int b5[3] = {F7, G6, H5};
    moveValueList sqb5 = {3, b5};
    if ([self checkAttack:&sqb5 fromPieces:BishopMovers]) return NO;
    
    int b6[2] = {G7, H6};
    moveValueList sqb6 = {2, b6};
    if ([self checkAttack:&sqb6 fromPieces:BishopMovers]) return NO;
    
    int b7[1] = {H7};
    moveValueList sqb7 = {1, b7};
    if ([self checkAttack:&sqb7 fromPieces:BishopMovers]) return NO;
    
    // check for a knight attack
    int k1[11] = {H7, G7, F7, E7, D7, C7, H6, G6, F6, E6, D6};
    moveValueList sqk1 = {11, k1};
    if ([self checkUnprotectedAttack:&sqk1 fromPiece:kKnight]) return NO;
    
    // check for a pawn attack
    int p1[5] = {H7, G7, F7, E7, D7};
    moveValueList sqp1 = {5, p1};
    if ([self checkUnprotectedAttack:&sqp1 fromPiece:kPawn]) return NO;
    
    // check for a king attack
    int kg[1] = {G7};
    moveValueList sqkg = {1, kg};
    if ([self checkUnprotectedAttack:&sqkg fromPiece:kKing]) return NO;

    return YES;
}

-(BOOL)canCastleBlackQueenSide {
    
    if (0 != (castlingStatus & CastlingEnableQueenSide))
        return NO;
    
    // quickly check if all the squares are zero
    if (myPieces[B8] + myPieces[C8]  + myPieces[D8] + itsPieces[B8] + itsPieces[C8] + itsPieces[D8])
        return NO;
    
    // check for castling squares under attack
    // first check for vertical (rook-like) attacks
    int aRank[7] = {A7,A6,A5,A4,A3,A2,A1};
    moveValueList sqA = {7, aRank};
    if ([self checkAttack:&sqA fromPieces:RookMovers]) return NO;
    
    int bRank[7] = {B7,B6,B5,B4,B3,B2,B1};
    moveValueList sqB = {7, bRank};
    if ([self checkAttack:&sqB fromPieces:RookMovers]) return NO;
    
    int cRank[7] = {C7,C6,C5,C4,C3,C2,C1};
    moveValueList sqC = {7, cRank};
    if ([self checkAttack:&sqC fromPieces:RookMovers]) return NO;
    
    int dRank[7] = {D7,D6,D5,D4,D3,D2,D1};
    moveValueList sqD = {7, dRank};
    if ([self checkAttack:&sqD fromPieces:RookMovers]) return NO;
    
    int eRank[7] = {E7,E6,E5,E4,E3,E2,E1};
    moveValueList sqE = {7, eRank};
    if ([self checkAttack:&sqE fromPieces:RookMovers]) return NO;
    
    // check for a rook attack from the baseline
    int rank8[3] = {F8, G8, H8};
    moveValueList sq8 = {3, rank8};
    if ([self checkAttack:&sq8 fromPieces:RookMovers]) return NO;
    
    // check for bishop attacks from the diagonals
    int b1[7] = {B7, C6, D5, E4, F3, G2, H1};
    moveValueList sqb1 = {7, b1};
    if ([self checkAttack:&sqb1 fromPieces:BishopMovers]) return NO;
    
    int b2[6] = {C7, D6, E5, F4, G3, H2};
    moveValueList sqb2 = {7, b2};
    if ([self checkAttack:&sqb2 fromPieces:BishopMovers]) return NO;
    
    int b3[5] = {D7, E6, F5, G4, H3};
    moveValueList sqb3 = {5, b3};
    if ([self checkAttack:&sqb3 fromPieces:BishopMovers]) return NO;
    
    int b4[4] = {E7, F6, G5, H4};
    moveValueList sqb4 = {4, b4};
    if ([self checkAttack:&sqb4 fromPieces:BishopMovers]) return NO;
    
    int b5[3] = {F7, G6, H5};
    moveValueList sqb5 = {3, b5};
    if ([self checkAttack:&sqb5 fromPieces:BishopMovers]) return NO;
    
    int b6[1] = {A7};
    moveValueList sqb6 = {1, b6};
    if ([self checkAttack:&sqb6 fromPieces:BishopMovers]) return NO;

    int b7[2] = {B7, A6};
    moveValueList sqb7 = {2, b7};
    if ([self checkAttack:&sqb7 fromPieces:BishopMovers]) return NO;
    
    int b8[3] = {C7, B6, A5};
    moveValueList sqb8 = {3, b8};
    if ([self checkAttack:&sqb8 fromPieces:BishopMovers]) return NO;
    
    int b9[4] = {D7, C6, B5, A4};
    moveValueList sqb9 = {4, b9};
    if ([self checkAttack:&sqb9 fromPieces:BishopMovers]) return NO;
    
    // check for a knight attack
    int k1[12] = {A7, B7, C7, D7, E7, F7, G7, A6, B6, D6, E6, F6};
    moveValueList sqk1 = {11, k1};
    if ([self checkUnprotectedAttack:&sqk1 fromPiece:kKnight]) return NO;
    
    // check for a pawn attack
    int p1[6] = {A7, B7, C7, D7, E7, F7};
    moveValueList sqp1 = {6, p1};
    if ([self checkUnprotectedAttack:&sqp1 fromPiece:kPawn]) return NO;
    
    // check for a king attack
    int kg[2] = {B7, C7};
    moveValueList sqkg = {2, kg};
    if ([self checkUnprotectedAttack:&sqkg fromPiece:kKing]) return NO;
    
    return YES;
}

-(BOOL)canCastleWhiteKingSide {
    
    if (0 != (castlingStatus & CastlingEnableKingSide))
        return NO;
    
    // quickly check if all the squares are zero
    if (myPieces[G1] + myPieces[F1] + itsPieces[G1] + itsPieces[F1])
        return NO;
    
    // check for castling squares under attack
    // first check for vertical (rook-like) attacks
    int hRank[7] = {H2,H3,H4,H5,H6,H7,H8};
    moveValueList sqH = {7, hRank};
    if ([self checkAttack:&sqH fromPieces:RookMovers]) return NO;
    
    int gRank[7] = {G2,G3,G4,G5,G6,G7,G8};
    moveValueList sqG = {7, gRank};
    if ([self checkAttack:&sqG fromPieces:RookMovers]) return NO;
    
    int fRank[7] = {F2,F3,F4,F5,F6,F7,F8};
    moveValueList sqF = {7, fRank};
    if ([self checkAttack:&sqF fromPieces:RookMovers]) return NO;
    
    int eRank[7] = {E2,E3,E4,E5,E6,E7,E8};
    moveValueList sqE = {7, eRank};
    if ([self checkAttack:&sqE fromPieces:RookMovers]) return NO;
    
    // check for a rook attack from the baseline
    int rank8[4] = {A1, A2, A3, A4};
    moveValueList sq8 = {4, rank8};
    if ([self checkAttack:&sq8 fromPieces:RookMovers]) return NO;
    
    // check for bishop attacks from the diagonals
    int b1[7] = {G2, F3, E4, D5, C6, B7, A8};
    moveValueList sqb1 = {7, b1};
    if ([self checkAttack:&sqb1 fromPieces:BishopMovers]) return NO;
    
    int b2[6] = {F2, E3, D4, C5, B6, A7};
    moveValueList sqb2 = {7, b2};
    if ([self checkAttack:&sqb2 fromPieces:BishopMovers]) return NO;
    
    int b3[5] = {E2, D3, C4, B5, A6};
    moveValueList sqb3 = {5, b3};
    if ([self checkAttack:&sqb3 fromPieces:BishopMovers]) return NO;
    
    int b4[4] = {D2, C3, B4, A5};
    moveValueList sqb4 = {4, b4};
    if ([self checkAttack:&sqb4 fromPieces:BishopMovers]) return NO;
    
    int b5[3] = {F2, G3, H4};
    moveValueList sqb5 = {3, b5};
    if ([self checkAttack:&sqb5 fromPieces:BishopMovers]) return NO;
    
    int b6[2] = {G2, H3};
    moveValueList sqb6 = {2, b6};
    if ([self checkAttack:&sqb6 fromPieces:BishopMovers]) return NO;
    
    int b7[1] = {H2};
    moveValueList sqb7 = {1, b7};
    if ([self checkAttack:&sqb7 fromPieces:BishopMovers]) return NO;
    
    // check for a knight attack
    int k1[11] = {H2, G2, F2, E2, D2, C2, H3, G3, F3, E3, D3};
    moveValueList sqk1 = {11, k1};
    if ([self checkUnprotectedAttack:&sqk1 fromPiece:kKnight]) return NO;
    
    // check for a pawn attack
    int p1[5] = {H2, G2, F2, E2, D2};
    moveValueList sqp1 = {5, p1};
    if ([self checkUnprotectedAttack:&sqp1 fromPiece:kPawn]) return NO;
    
    // check for a king attack
    int kg[1] = {G2};
    moveValueList sqkg = {1, kg};
    if ([self checkUnprotectedAttack:&sqkg fromPiece:kKing]) return NO;
    
    return YES;
}

-(BOOL)canCastleWhiteQueenSide {
    
    if (0 != (castlingStatus & CastlingEnableQueenSide))
        return NO;
    
    // quickly check if all the squares are zero
    if (myPieces[B1] + myPieces[C1]  + myPieces[D1] + itsPieces[B1] + itsPieces[C1] + itsPieces[D1])
        return NO;
    
    // check for castling squares under attack
    // first check for vertical (rook-like) attacks
    int aRank[7] = {A2,A3,A4,A5,A6,A7,A8};
    moveValueList sqA = {7, aRank};
    if ([self checkAttack:&sqA fromPieces:RookMovers]) return NO;
    
    int bRank[7] = {B2,B3,B4,B5,B6,B7,B8};
    moveValueList sqB = {7, bRank};
    if ([self checkAttack:&sqB fromPieces:RookMovers]) return NO;
    
    int cRank[7] = {C2,C3,C4,C5,C6,C7,C8};
    moveValueList sqC = {7, cRank};
    if ([self checkAttack:&sqC fromPieces:RookMovers]) return NO;
    
    int dRank[7] = {D2,D3,D4,D5,D6,D7,D8};
    moveValueList sqD = {7, dRank};
    if ([self checkAttack:&sqD fromPieces:RookMovers]) return NO;
    
    int eRank[7] = {E2,E3,E4,E5,E6,E7,E8};
    moveValueList sqE = {7, eRank};
    if ([self checkAttack:&sqE fromPieces:RookMovers]) return NO;
    
    // check for a rook attack from the baseline
    int rank8[3] = {F1, G1, H1};
    moveValueList sq8 = {3, rank8};
    if ([self checkAttack:&sq8 fromPieces:RookMovers]) return NO;
    
    // check for bishop attacks from the diagonals
    int b1[7] = {B2, C3, D4, E5, F6, G7, H8};
    moveValueList sqb1 = {7, b1};
    if ([self checkAttack:&sqb1 fromPieces:BishopMovers]) return NO;
    
    int b2[6] = {C2, D3, E4, F5, G6, H7};
    moveValueList sqb2 = {7, b2};
    if ([self checkAttack:&sqb2 fromPieces:BishopMovers]) return NO;
    
    int b3[5] = {D2, E3, F4, G5, H6};
    moveValueList sqb3 = {5, b3};
    if ([self checkAttack:&sqb3 fromPieces:BishopMovers]) return NO;
    
    int b4[4] = {E2, F3, G4, H5};
    moveValueList sqb4 = {4, b4};
    if ([self checkAttack:&sqb4 fromPieces:BishopMovers]) return NO;
    
    int b5[3] = {F2, G3, H4};
    moveValueList sqb5 = {3, b5};
    if ([self checkAttack:&sqb5 fromPieces:BishopMovers]) return NO;
    
    int b6[1] = {A2};
    moveValueList sqb6 = {1, b6};
    if ([self checkAttack:&sqb6 fromPieces:BishopMovers]) return NO;
    
    int b7[2] = {B2, A3};
    moveValueList sqb7 = {2, b7};
    if ([self checkAttack:&sqb7 fromPieces:BishopMovers]) return NO;
    
    int b8[3] = {C2, B3, A4};
    moveValueList sqb8 = {3, b8};
    if ([self checkAttack:&sqb8 fromPieces:BishopMovers]) return NO;
    
    int b9[4] = {D2, C3, B4, A5};
    moveValueList sqb9 = {4, b9};
    if ([self checkAttack:&sqb9 fromPieces:BishopMovers]) return NO;
    
    // check for a knight attack
    int k1[12] = {A2, B2, C2, D2, E2, F2, G2, A3, B3, D3, E3, F3};
    moveValueList sqk1 = {11, k1};
    if ([self checkUnprotectedAttack:&sqk1 fromPiece:kKnight]) return NO;
    
    // check for a pawn attack
    int p1[6] = {A2, B2, C2, D2, E2, F2};
    moveValueList sqp1 = {6, p1};
    if ([self checkUnprotectedAttack:&sqp1 fromPiece:kPawn]) return NO;
    
    // check for a king attack
    int kg[2] = {B2, C2};
    moveValueList sqkg = {2, kg};
    if ([self checkUnprotectedAttack:&sqkg fromPiece:kKing]) return NO;
    
    return YES;
}

//
// check for an unprotected attack along squares by one of pieces.  Squares is a list of 
// squares such that any piece in pieces can attack unless blocked by another piece.
// E.g., a Bishop of Queen on the file  B7 C6 D5 E4 F3 G2 H1 can attack A8 unless blocked by
// another piece.  To find out if A8 is under attack along B7 C6 D5 E4 F3 G2 H1, use
// checkAttack:{B7. C6.D5. E4. F3. G2. H1} fromPieces:BishopMovers.  Note the order is important;
// squares must be listed in increasing distance from the square of interest
//
-(BOOL)checkAttack:(moveValueList *)squares fromPieces:(int *)pieces {
    
    for (int i=0; i<squares->count; i++) {
        // invariant: no piece has been seen on this file at all
        // one of my pieces blocks any attack
        if (!myPieces[i])
            return NO;
        
        // one of its pieces blocks an attack, unless it is the kind of piece that can move along this
        // file: a bishop or queen for a diagonal and a rook or a queen for a horizontal or vertical file
        if (!itsPieces[i]) {
            // RookMovers and BishopMovers are both arrays of 2 elements
            if ((pieces[0] == itsPieces[i]) || (pieces[1] == itsPieces[i])) {       
                return YES;
            }
        }
    }
    // no pieces along file, no attack
    return NO;
}

//
// check to see if my opponent has a piece of type piece on any of squares.  In general, this
// is used because that piece could launch an attack on me from those squares
//
-(BOOL)checkUnprotectedAttack:(moveValueList *)squares fromPiece:(int)piece {
    
    for (int i=0; i<squares->count; i++) {
        if (itsPieces[i] == piece) {
            return YES;
        }
    }
    return NO;
}

#pragma mark initialize
                   
-(id)init {
    if (self = [super init]) {
        // 100 plies
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
        
        firstMoveIndex = lastMoveIndex = streamListIndex = -1;
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
    
    moveValueList moves = BishopMoves[square];
    
    [self movePiece:kBishop along:&moves at:square];
}

-(void)moveBlackKingAt:(int)square {
    
    moveValueList kingMoves = KingMoves[square];

    for (int i=0; i<kingMoves.count; i++) {
        
        int destSquare = kingMoves.moves[i];
        
        if (!myPieces[destSquare]) {
            
            int capture = itsPieces[destSquare];
            
            if (!forceCaptures || capture) {
                ChessMove *move = [moveList objectAtIndex:++lastMoveIndex];
                [move move:kKing from:square to:destSquare capture:capture];
                
                if (kKing == capture) {
                    kingAttack = [moveList objectAtIndex:lastMoveIndex];
                }
            }
        }
    }
    
    if (forceCaptures)
        return;
    
    // now consider castling
    
    if ([self canCastleBlackKingSide]) {
        ChessMove *move = [moveList objectAtIndex:++lastMoveIndex];
        [move moveCastlingKingSide:kKing from:square to:square+2];
    }
    
    if ([self canCastleBlackQueenSide]) {
        ChessMove *move = [moveList objectAtIndex:++lastMoveIndex];
        [move moveCastlingQueenSide:kKing from:square to:square-2];
    }
}

-(void)moveKingAt:(int)square {
    
    if ([myPlayer isWhitePlayer]) {
        [self moveWhiteKingAt:square];
    }
    else {
        [self moveBlackKingAt:square];
    }
}

-(void)moveKnightAt:(int)square {
    
    moveValueList moves = KnightMoves[square];
    
    for (int i=0; i<moves.count; i++) {
        int destSquare = moves.moves[i];
        
        if (!myPieces[destSquare]) {
            int capture = itsPieces[destSquare];
            
            if (!forceCaptures || capture) {
                
//                NSLog(@"creating knight move from %d to %d -- lastMoveIndex is %d", square, destSquare, lastMoveIndex);
                ChessMove *move = [moveList objectAtIndex:++lastMoveIndex];
                [move move:kKnight from:square to:destSquare capture:capture];
                
                if (kKing == capture) {
                    kingAttack = [moveList objectAtIndex:lastMoveIndex];
                }
            }
        }
    }
}

-(void)movePawnAt:(int)square {
    
    if ([myPlayer isWhitePlayer]) {
        [self moveWhitePawnAt:square];
    }
    else {
        [self moveBlackPawnAt:square];
    }
}

-(void)movePiece:(int)piece along:(moveValueList *)rayList at:(int)square {
    
    for (int i=0; i<rayList->count; i++) {
        
        int destSquare = rayList->moves[i];
        
        if (myPieces[destSquare])
            return;
        
        int capture = itsPieces[destSquare];
        
        if (!forceCaptures || capture) {
            
            ChessMove *move = [moveList objectAtIndex:++lastMoveIndex];
            [move move:piece from:square to:destSquare capture:capture];
            
            if (kKing == capture) {
                kingAttack = [moveList objectAtIndex:lastMoveIndex];
            }
        }
        if (!capture)
            return;
    }
}

-(void)moveQueenAt:(int)square {
    
    moveValueList moves = RookMoves[square];
    [self movePiece:kQueen along:&moves at:square];
    
    moves = BishopMoves[square];
    [self movePiece:kQueen along:&moves at:square];
    
}

-(void)moveRookAt:(int)square {
    
    moveValueList moves = RookMoves[square];
    [self movePiece:kRook along:&moves at:square];
}

-(void)moveWhiteKingAt:(int)square {
    
    moveValueList kingMoves = KingMoves[square];
    
    for (int i=0; i<kingMoves.count; i++) {
        
        int destSquare = kingMoves.moves[i];
        
        if (!myPieces[destSquare]) {
            
            int capture = itsPieces[destSquare];
            
            if (!forceCaptures || capture) {
                ChessMove *move = [moveList objectAtIndex:++lastMoveIndex];
                [move move:kKing from:square to:destSquare capture:capture];
                
                if (kKing == capture) {
                    kingAttack = [moveList objectAtIndex:lastMoveIndex];
                }
            }
        }
    }
    
    if (forceCaptures)
        return;
    
    // now consider castling
    
    if ([self canCastleWhiteKingSide]) {
        ChessMove *move = [moveList objectAtIndex:++lastMoveIndex];
        [move moveCastlingKingSide:kKing from:square to:square+2];
    }
    
    if ([self canCastleWhiteQueenSide]) {
        ChessMove *move = [moveList objectAtIndex:++lastMoveIndex];
        [move moveCastlingQueenSide:kKing from:square to:square-2];
    }
}

@end
