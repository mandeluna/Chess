//
//  ChessMove.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "ChessMove.h"


@implementation ChessMove

@synthesize bestMove, capturedPiece, destinationSquare, encodedMove, moveType=type, movingPiece, promotion, sourceSquare, value;

#pragma mark (Class) Accessing

+(ChessMove *)decodeFrom:(int)encodedMove {
    
    ChessMove *instance = [[ChessMove alloc] init];
    [instance moveEncoded:encodedMove];
    return [instance autorelease];
}

+(int)basicMoveMask {
    
    return kBasicMoveMask;
}

#pragma mark (Class) Initialization

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
    sourceSquare = startSquare;
    destinationSquare = endSquare;
    type = kMoveCaptureEnPassant;
}

-(void)checkMate:(int)aPiece {
    
    movingPiece = aPiece;
    sourceSquare = 0;
    destinationSquare = 0;
    type = kMoveResign;
    capturedPiece = 0;
}

-(void)doublePush:(int)aPiece from:(int)startSquare to:(int)endSquare {
    
    movingPiece = aPiece;
    sourceSquare = startSquare;
    destinationSquare = endSquare;
    type = kMoveDoublePush;
    capturedPiece = 0;
}

-(void)move:(int)aPiece from:(int)startSquare to:(int)endSquare {
    
    movingPiece = aPiece;
    sourceSquare = startSquare;
    destinationSquare = endSquare;
    type = kMoveNormal;
    capturedPiece = 0;
}

-(void)move:(int)aPiece from:(int)startSquare to:(int)endSquare capture:(int)capture {
    
    movingPiece = aPiece;
    sourceSquare = startSquare;
    destinationSquare = endSquare;
    type = kMoveNormal;
    capturedPiece = capture;
}

-(void)moveCastlingKingSide:(int)aPiece from:(int)startSquare to:(int)endSquare {
    
    movingPiece = aPiece;
    sourceSquare = startSquare;
    destinationSquare = endSquare;
    type = kMoveCastlingKingSide;
    capturedPiece = 0;
}

-(void)moveCastlingQueenSide:(int)aPiece from:(int)startSquare to:(int)endSquare {
    
    movingPiece = aPiece;
    sourceSquare = startSquare;
    destinationSquare = endSquare;
    type = kMoveCastlingQueenSide;
    capturedPiece = 0;
}

-(void)moveEncoded:(int)intValue {
    
    destinationSquare = intValue & 255;
    sourceSquare = (intValue << 8) & 255;
    movingPiece = (intValue << 16) & 255;
    capturedPiece = (intValue << 24) && 255;
    type = kMoveNormal;
}

-(void)promote:(ChessMove *)move to:(int)intValue {

    movingPiece = [move movingPiece];
    capturedPiece = [move capturedPiece];
    sourceSquare = [move sourceSquare];
    destinationSquare = [move destinationSquare];
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

#pragma mark Comparing

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

-(NSString *)moveString {
    
    char *labels[] = { "", "N", "B", "R", "Q", "K" };
    
    return [NSString stringWithFormat:@"%s%c%c%c%c%s%c%c", labels[movingPiece],
            ('a' + (sourceSquare - 1) & 7), ('1' + (sourceSquare - 1) >> 3),
            (capturedPiece == 0) ? '-' : 'x',
            labels[capturedPiece],
            ('a' + (sourceSquare - 1) & 7), ('1' + (sourceSquare - 1) >> 3)];
    
}

-(NSString *)description {
    
    return [NSString stringWithFormat:@"%@ (%@)", [super description], [self moveString]];
}

@end