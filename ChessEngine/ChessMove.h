//
//  ChessMove.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChessBoard;

enum {
    kMoveNormal = 1,
    kMoveDoublePush,
    kMoveCaptureEnPassant,
    kMoveCastlingKingSide,
    kMoveCastlingQueenSide,
    kMoveResign,
    kMoveStaleMate,
    kMoveNeededHint
};

#define kBasicMoveMask  15
#define kPromotionShift 4           // left shift
#define kExtractPromotionShift  4   // right shift

#define kEvalTypeAccurate   0
#define kEvalTypeUpperBound 1
#define kEvalTypeLowerBound 2

#define kNullMove    0

@interface ChessMove : NSObject <NSCopying> {

    int movingPiece;
    int capturedPiece;
    int sourceSquare;
    int destinationSquare;
    int type;
    int value;
    int bestMove;
}

@property(nonatomic, assign) int bestMove;
@property(nonatomic, assign) int capturedPiece;
@property(nonatomic, assign) int destinationSquare;
@property(nonatomic, assign) int moveType;
@property(nonatomic, assign) int movingPiece;
@property(nonatomic, assign) int sourceSquare;
@property(nonatomic, assign) int value;

// ARC support
-(nonnull ChessMove *)initializeWithMove:(nonnull ChessMove *)move;

// class methods

+(nonnull ChessMove *)decodeFrom:(int)encodedMove;
+(nonnull ChessMove *)nullMove;

// initialize
-(void)captureEnPassant:(int)aPiece from:(int)startSquare to:(int)endSquare;
-(void)checkMate:(int)aPiece;
-(void)doublePush:(int)aPiece from:(int)startSquare to:(int)endSquare;
-(void)move:(int)aPiece from:(int)startSquare to:(int)endSquare;
-(void)move:(int)aPiece from:(int)startSquare to:(int)endSquare capture:(int)capture;
-(void)moveCastlingKingSide:(int)aPiece from:(int)startSquare to:(int)endSquare;
-(void)moveCastlingQueenSide:(int)aPiece from:(int)startSquare to:(int)endSquare;
-(void)moveEncoded:(int)intValue;
-(void)promote:(nonnull ChessMove *)move to:(int)intValue;
-(void)staleMate:(int)aPiece;

// encoding

-(int)encodedMove;
-(int)promotion;

// copying

-(nonnull ChessMove *)copyWithZone:(nullable NSZone *)zone;

// comparing

-(BOOL)isEqual:(nullable id)object;
-(NSInteger)hash;
-(BOOL)isNullMove;

// printing

-(nonnull NSString *)description;
-(nonnull NSString *)uciString;
-(nonnull NSString *)sanStringForBoard:(nonnull ChessBoard *)board;
-(nonnull NSString *)sanStringForBoard:(nonnull ChessBoard *)board unicodeGlyphs:(BOOL)useUnicode;

@end
