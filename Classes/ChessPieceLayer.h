//
//  ChessPieceLayer.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "ChessUserAgent.h"

@interface ChessPieceLayer : CALayer {

    BOOL isWhite;
    int piece;
    id<ChessUserAgent> chessBoard;
    int sourceSquare;
}

@property(nonatomic, assign) BOOL isWhite;
@property(nonatomic, assign) int piece;
@property(nonatomic, assign) id<ChessUserAgent> chessBoard;
@property(nonatomic, assign) int sourceSquare;  // for dragging

@end
