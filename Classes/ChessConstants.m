//
//  ChessConstants.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "ChessConstants.h"

@interface ChessConstants(Private)

+(void)logMoves:(moveValueList[64])listValue;

@end

@implementation ChessConstants

+(void)initialize {
    
    [self initializeCastlingConstants];
    [self initializeMoves];
    [self initializeBishopMovers];
    [self initializeRookMovers];
}

+(void)initializeCastlingConstants {
    
    CastlingDone = 1 << 0;
    CastlingDisableKingSide = 1 << 1;
    CastlingDisableQueenSide = 1 << 2;
    CastlingDisableAll = CastlingDisableQueenSide | CastlingDisableKingSide;
    CastlingEnableKingSide = CastlingDone | CastlingDisableKingSide;
    CastlingEnableQueenSide = CastlingDone | CastlingDisableQueenSide;    
}

+(void)initializePieceValues {
    
    PieceValues[kPawn] = 100;
    PieceValues[kKnight] = 300;
    PieceValues[kBishop] = 350;
    PieceValues[kRook] = 500;
    PieceValues[kQueen] = 900;
    PieceValues[kKing] = 2000;    
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

+(void)initializeBishopMovers {
    
}

+(void)initializeRookMovers {
    
}

@end
