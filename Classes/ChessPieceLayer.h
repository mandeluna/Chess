//
//  ChessPieceLayer.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface ChessPieceLayer : CALayer {

    BOOL isWhite;
    long piece;
    long sourceSquare;
}

@property(nonatomic, assign) BOOL isWhite;
@property(nonatomic, assign) long piece;
@property(nonatomic, assign) long sourceSquare;  // for dragging

@end
