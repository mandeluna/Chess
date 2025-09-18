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

    __weak ChessPieceLayer *pieceLayer;
    long square;
}

@property(nonatomic, weak)ChessPieceLayer *pieceLayer;
@property(nonatomic, assign) long square;

@end
