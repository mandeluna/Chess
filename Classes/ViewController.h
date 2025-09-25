//
//  ViewController.h
//  
//
//  Created by Steve Wart on 2010-08-15.
//  Copyright Steven Wart 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Chamonix-Swift.h>

@class ChessBoard;
@class ChessMove;
@class ChessBoardView;

@interface ViewController : UIViewController <ChessBoardViewDelegate>
{
    ChessBoard *board;
    ChessBoard *startingBoard;
    NSMutableArray *history;
    NSMutableArray *redoList;
    BOOL animateMove;
    BOOL autoPlay;

    NSTimeInterval elapsedTimeWhite;
    NSTimeInterval elapsedTimeBlack;
    BOOL isClockTicking;
    
    ChessMove *moveHint;
}

@property(nonatomic, retain) NSMutableArray *history;
@property(nonatomic, retain) NSMutableArray *redoList;
@property(nonatomic, retain) ChessBoard *board;
@property(nonatomic, retain) NSString *remoteInstanceName;

@property(nonatomic, retain) IBOutlet ChessBoardView *chessboardView;
@property(nonatomic, retain) IBOutlet UILabel *gameStatusLabel;
@property(nonatomic, retain) IBOutlet UILabel *whiteGameClock;
@property(nonatomic, retain) IBOutlet UILabel *blackGameClock;
@property(nonatomic, retain) IBOutlet UILabel *engineInfoLabel;
@property(nonatomic, retain) IBOutlet UITextView *moveListTextView;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *startButton;
@property (retain, nonatomic) IBOutlet UIButton *moveListExportButton;

-(IBAction)autoPlay;
-(IBAction)switchSides;
-(IBAction)newGame;
-(IBAction)exportMoveList;

-(BOOL)isPlayerWhite;
-(void)finishedGame:(NSNotification *)notification;
-(void)movePieceFrom:(int)sourceSquare to:(int)destSquare;
-(void)completedMove:(ChessMove *)move white:(BOOL)aBool;
-(void)replacedPiece:(int)oldPiece with:(int)newPiece at:(int)square white:(BOOL)isWhitePlayer;
-(void)undoMove:(ChessMove *)move white:(BOOL)isWhitePlayer;
-(NSString *)formatMoveHistory:(BOOL)unicodeGlyphs;

#pragma mark ChessBoardViewDelegate methods

-(SelectionContext *)chessboardView:(ChessBoardView *)chessboardView
                       shouldSelect:(NSInteger)square
               withCurrentSelection:(SelectionContext *)selection;

-(void)chessboardView:(ChessBoardView *)chessboardView
     didMovePieceFrom:(NSInteger)sourceIndex
                   to:(NSInteger)destIndex;

- (NSInteger)chessboardView:(ChessBoardView * _Nonnull)chessboardView pieceFor:(NSInteger)square;

@end
