//
//  SquareLayer.h
//  ChessMail
//
//  Created by Steve Wart on 10-09-05.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class ChessPieceLayer;

@interface SquareLayer : CALayer {

    ChessPieceLayer *pieceLayer;
    int squarePosition;
}

@property(nonatomic, assign)ChessPieceLayer *pieceLayer;
@property(nonatomic, assign) int squarePosition;

@end
