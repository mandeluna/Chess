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

static ChessMove *NullMove = nil;

// return a placeholder move (#none)
+(ChessMove *)nullMove {
    if (!NullMove) {
        NullMove = [[ChessMove alloc] init];
        NullMove.moveType = kNullMove;
    }
    return NullMove;
}

#pragma mark Accessing

-(void)setDestinationSquare:(int)intValue {
    if (intValue < 0) {
        NSException *exception = [NSException exceptionWithName:@"Invalid Index"
                                                         reason:@"Board index cannot be negative"
                                                       userInfo:nil];
        [exception raise];
    }
    destinationSquare = intValue;
}

-(void)setSourceSquare:(int)intValue {
    if (intValue < 0) {
        NSException *exception = [NSException exceptionWithName:@"Invalid Index"
                                                         reason:@"Board index cannot be negative"
                                                       userInfo:nil];
        [exception raise];
    }
    sourceSquare = intValue;
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
    
    self.destinationSquare = intValue & 255;
    self.sourceSquare = (intValue << 8) & 255;
    movingPiece = (intValue << 16) & 255;
    capturedPiece = (intValue << 24) && 255;
    type = kMoveNormal;
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

-(id)copyWithZone:(NSZone *)zone {
    
    // shallow copy
    id copy = NSCopyObject(self, 0, zone);
    
    return copy;
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

-(NSString *)moveString {
    
    char *labels[] = { "", "", "N", "B", "R", "Q", "K" };
    char *c1 = labels[movingPiece];
    char c2 = 'a' + (sourceSquare & 7);
    char c3 = '1' + (sourceSquare >> 3);
    char c4 = (capturedPiece == 0) ? '-' : 'x';
    char *c5 = labels[capturedPiece];
    char c6 = 'a' + (destinationSquare & 7);
    char c7 = '1' + (destinationSquare >> 3);
    
    return [NSString stringWithFormat:@"%s%c%c%c%s%c%c", c1, c2, c3, c4, c5, c6, c7];
    
}

-(NSString *)description {
    
    return [NSString stringWithFormat:@"%@", [self moveString]];
}

@end