//
//  ViewController.m
//  virusGame
//
//  Created by William Klein on 03/10/12.
//  Copyright (c) 2012 William Klein. All rights reserved.
//

#import "ViewController.h"
#import "Config.h"
#import "ParametersViewController.h"
#import <AudioToolbox/AudioToolbox.h>

#define GAME_TITLE  @"Kontaminate"
#define MAP_WIDTH   7
#define MAP_HEIGHT  7
#define MAP_BLANK   0
#define MAP_BLACK   1
#define MAP_WHITE   2
#define MAP_OFFSETX 48
#define MAP_OFFSETY 108
#define SCREEN_SIZE 230

NSInteger mapArray[MAP_WIDTH][MAP_HEIGHT];
NSArray *indexArray[MAP_WIDTH*MAP_HEIGHT+1];

#pragma mark - ViewController declaration

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    AI_type = [[prefs objectForKey:@"AI_TYPE"] intValue];
    AI_difficulty = [[prefs objectForKey:@"AI_DIFFICULTY"] intValue];
    
    [self createNewGame];
}

#pragma mark - Game events

/* Popup to choose who will begin */
- (void)chooseBeginner
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:GAME_TITLE message:@"Who play first ?" delegate:self cancelButtonTitle:@"Computer" otherButtonTitles:@"Me", nil];
    alert.tag = 666;
    [alert show];
    [alert release];
}

/* Change turn */
- (void)changeTurnToYou:(BOOL)you
{
    yourTurn = you;
    if(yourTurn)
    {
        [yourTurnGlow setHidden:NO];
        [hisTurnGlow setHidden:YES];
    }
    else
    {
        [yourTurnGlow setHidden:YES];
        [hisTurnGlow setHidden:NO];
    }
}

/* Create new game - reset board */
- (void)createNewGame
{
    // Definitions
    gamePaused = NO;
    [yourTurnGlow setHidden:YES];
    [hisTurnGlow setHidden:YES];
    
    // Reset map
    for (int y = 0; y < MAP_WIDTH; y++) {
        for (int x = 0; x < MAP_HEIGHT; x++) {
            if(x==0 && y==0) {
                mapArray[x][y] = MAP_BLACK;
            } else if(x==MAP_WIDTH-1 && y==MAP_HEIGHT-1) {
                mapArray[x][y] = MAP_BLACK;
            } else if(x==MAP_WIDTH-1 && y==0) {
                mapArray[x][y] = MAP_WHITE;
            } else if(x==0 && y==MAP_HEIGHT-1) {
                mapArray[x][y] = MAP_WHITE;
            } else {
                mapArray[x][y] = MAP_BLANK;
            }
        }
    }
    
    // Draw new map
    [self drawMap];
    
    // Popup to choose who begin
    [self chooseBeginner];
}

/* Check and fill blanks in game */
- (void)checkAndFillBlanks
{
    // Loop to find blank spots where player cannot play
    int isBlackNeighbor = 0;
    for (int y = 0; y < MAP_HEIGHT; y++) {
        for (int x = 0; x < MAP_WIDTH; x++) {
            if(mapArray[x][y]==MAP_BLANK)
            {
                for(int i = -1; i < 2; i++) {
                    for(int j = -1; j < 2; j++) {
                        if(
                           (i != 0 || j != 0) &&
                           x+i >= 0 && x+i < MAP_WIDTH &&
                           y+j >= 0 && y+j < MAP_HEIGHT
                           ){
                            switch (mapArray[x+i][y+j]) {
                                case MAP_BLACK:
                                    isBlackNeighbor++;
                                    break;
                                default:
                                    break;
                            }
                        }
                    }
                }
            }
        }
    }
    // Fill blanks with white pieces because player cannot play here
    if(isBlackNeighbor == 0)
    {
        for (int y = 0; y < MAP_HEIGHT; y++) {
            for (int x = 0; x < MAP_WIDTH; x++) {
                if(mapArray[x][y]==MAP_BLANK)
                {
                    mapArray[x][y]=MAP_WHITE;
                }
            }
        }
    }
}

/* Check end game status */ 
- (void)checkEndGameStatus
{
    if(!gamePaused)
    {
        BOOL gameEnded = YES;
        
        // Loop to find blank pieces
        for (int y = 0; y < MAP_WIDTH; y++) {
            for (int x = 0; x < MAP_HEIGHT; x++) {
                if(mapArray[x][y]==MAP_BLANK)
                {
                    // Game is not finished if any blank piece left
                    gameEnded = NO;
                }
            }
        }
        
        // Here game is finished
        if(gameEnded)
        {
            // Pause game, reset text
            gamePaused = YES;
            
            // Score calculation
            int scoreX = 0;
            int scoreO = 0;
            for (int y = 0; y < MAP_WIDTH; y++) {
                for (int x = 0; x < MAP_HEIGHT; x++) {
                    switch (mapArray[x][y]) {
                        case MAP_BLACK:
                            scoreX++;
                            break;
                        case MAP_WHITE:
                            scoreO++;
                            break;
                        default:
                            break;
                    }
                }
            }
            
            // Popup display
            NSString *title = [[NSString alloc] init];
            NSString *message = [[NSString alloc] init];
            
            if(scoreX > scoreO) {
                title = @"Congratulations !";
                message = [NSString stringWithFormat:@"You win with %d versus %d pieces !", scoreX, scoreO];
            } else if(scoreX < scoreO) {
                title = @"Too bad !";
                message = [NSString stringWithFormat:@"You lose with %d versus %d pieces...", scoreX, scoreO];
            } else {
                title = @"Equality !";
                message = [NSString stringWithFormat:@"Equality ! %d versus %d pieces !", scoreX, scoreO];
            }
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"New game" otherButtonTitles:nil];
            alert.tag = 777;
            [alert show];
            [alert release];
        }
    }
}

#pragma mark - Map events

/* Draw map on screen */
- (void)drawMap
{
    // Clean current map
    for (UIView *view in self.view.subviews) {
        if(view.tag != 0)
        {
            [view removeFromSuperview];
        }
    }
    
    int score_black = 0;
    int score_white = 0;
    int i = 1;
    
    // Loop to draw map
    for (int y = 0; y < MAP_WIDTH; y++) {
        for (int x = 0; x < MAP_HEIGHT; x++) {
            NSNumber *firstNumber = [[NSNumber alloc] initWithInt:x];
            NSNumber *secondNumber = [[NSNumber alloc] initWithInt:y];
            indexArray[i] = [[NSArray alloc] initWithObjects:firstNumber, secondNumber, nil];
            
            UIButton *tmp = [[UIButton alloc] initWithFrame:CGRectMake(x*(SCREEN_SIZE/MAP_WIDTH)+MAP_OFFSETX, y*(SCREEN_SIZE/MAP_HEIGHT)+MAP_OFFSETY, (SCREEN_SIZE/MAP_WIDTH)-1, (SCREEN_SIZE/MAP_HEIGHT)-1)];
            tmp.tag = i;
            [tmp addTarget:self
                    action:@selector(caseCliked:)
          forControlEvents:UIControlEventTouchUpInside];
            switch (mapArray[x][y]) {
                case MAP_BLACK:
                    [tmp setBackgroundImage:[UIImage imageNamed:@"black.png"] forState:UIControlStateNormal];
                    score_black++;
                    break;
                case MAP_WHITE:
                    [tmp setBackgroundImage:[UIImage imageNamed:@"white.png"] forState:UIControlStateNormal];
                    score_white++;
                    break;
                default:
                    [tmp setBackgroundImage:[UIImage imageNamed:@"blank.png"] forState:UIControlStateNormal];
                    break;
            }
            [self.view addSubview:tmp];
            i++;
        }
    }
    
    // Update score
    [scoreblack setText:[NSString stringWithFormat:@"%d", score_black]];
    [scorewhite setText:[NSString stringWithFormat:@"%d", score_white]];
}

/* Evaluate score for AI on given map */
- (int) evaluate:(NSInteger[MAP_WIDTH][MAP_HEIGHT])map
{
    int score_black = 0;
    int score_white = 0;
    
    // Loop to calculate score for AI
    for (int y = 0; y < MAP_WIDTH; y++) {
        for (int x = 0; x < MAP_HEIGHT; x++) {
            switch (map[x][y]) {
                case MAP_BLACK:
                    score_black++;
                    break;
                case MAP_WHITE:
                    score_white++;
                    break;
            }
        }
    }
    return score_white - score_black;
}

/* Evaluate score for AI or Player on given map */
- (int) evaluate:(NSInteger[MAP_WIDTH][MAP_HEIGHT])map forPlayer:(int)player
{
    int score_black = 0;
    int score_white = 0;
    
    // Loop to calculate score for AI
    for (int y = 0; y < MAP_WIDTH; y++) {
        for (int x = 0; x < MAP_HEIGHT; x++) {
            switch (map[x][y]) {
                case MAP_BLACK:
                    score_black++;
                    break;
                case MAP_WHITE:
                    score_white++;
                    break;
                default:
                    break;
            }
        }
    }
    if(player == MAP_BLACK) {
        return score_black - score_white;
    }
    else if(player == MAP_WHITE)
    {
        return score_white - score_black;
    }
    else
    {
        return 0;
    }
}

/* Map copying */
- (void)copyMap:(NSInteger[MAP_WIDTH][MAP_HEIGHT])map_source toMap:(NSInteger[MAP_WIDTH][MAP_HEIGHT])map_destination
{
    for (int y = 0; y < MAP_HEIGHT; y++) {
        for (int x = 0; x < MAP_WIDTH; x++) {
            map_destination[x][y] = map_source[x][y];
        }
    }
}

#pragma mark - User actions

- (IBAction)caseCliked:(id)sender
{
    // Get clicked position
    UIButton *tmp = (UIButton *)sender;
    int x = [[indexArray[tmp.tag] objectAtIndex:0] intValue];
    int y = [[indexArray[tmp.tag] objectAtIndex:1] intValue];

    // Verify clicked position
    if(mapArray[x][y]==MAP_BLANK)
    {
        if(yourTurn)
        {
            BOOL canPlayHere = NO;
            for(int i = -1; i < 2; i++) {
                for(int j = -1; j < 2; j++) {
                    if(i != 0 || j != 0) {
                        if( x+i >= 0 && x+i < MAP_WIDTH &&
                           y+j >= 0 && y+j < MAP_HEIGHT &&
                           mapArray[x+i][y+j] == MAP_BLACK)
                        {
                            canPlayHere = YES;
                        }
                    }
                }
            }
            // Player can move here
            if(canPlayHere)
            {
                // Player movement
                [self changeTurnToYou:NO];
                
                [self doMoveOnMap:mapArray forPlayer:MAP_BLACK andX:x andY:y];
                [self vibrate];
                [self checkAndFillBlanks];
                [self drawMap];
                [self checkEndGameStatus];
                
                // Load AI in 1 second
                [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(iaPlay) userInfo:nil repeats:NO];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:GAME_TITLE message:@"You don't have black piece near here !" delegate:self cancelButtonTitle:@"Ok sorry" otherButtonTitles:nil];
                [alert show];
                [alert release];
            }
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:GAME_TITLE message:@"There is already a piece here !" delegate:self cancelButtonTitle:@"Ok sorry" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

#pragma mark - Artificial Intelligence

/* Method to call AI */
- (void)iaPlay
{
    switch (AI_type) {
        case AI_TYPE_MINMAX:
            [self iaPlayByCopyMapAndEvaluate];
            break;
        case AI_TYPE_ALPHABETA:
            [self iaPlayByAlphaBetaComparison];
            break;
        default:
            break;
    }
}

/* AI by evaluating simulated movement on copied map */
- (void)iaPlayByCopyMapAndEvaluate
{
    // Array of possible moves for AI
    NSMutableArray *iaMovesArray = [self calculatePossibleMovesForMap:mapArray andPlayer:MAP_WHITE];
    
    // If moves available
    if([iaMovesArray count] > 0)
    {
        int ia_max_score = -99999;
        int ia_move_x = [[[iaMovesArray objectAtIndex:0] objectAtIndex:0]intValue];
        int ia_move_y = [[[iaMovesArray objectAtIndex:0] objectAtIndex:1]intValue];
        
        // Loop to find the best move for AI
        for (int index = 0; index < [iaMovesArray count]; index++) {
            
            // Copy map in a temporary map to evaluate the best move
            NSInteger copyMap[MAP_WIDTH][MAP_HEIGHT];
            [self copyMap:mapArray toMap:copyMap];
            
            // Simulate move on copied map
            int x = [[[iaMovesArray objectAtIndex:index] objectAtIndex:0]intValue];
            int y = [[[iaMovesArray objectAtIndex:index] objectAtIndex:1]intValue];
            [self doMoveOnMap:copyMap
                    forPlayer:MAP_WHITE
                         andX:x
                         andY:y];
            
            // If evaluation is better, saving position
            if([self evaluate:copyMap] >= ia_max_score)
            {
                ia_max_score = [self evaluate:copyMap];
                ia_move_x = x;
                ia_move_y = y;
            }
        }
        
        // AI really moves here
        [self changeTurnToYou:YES];
        
        [self doMoveOnMap:mapArray forPlayer:MAP_WHITE andX:ia_move_x andY:ia_move_y];
        [self vibrate];
    }
    // Here AI can't move, AI lost
    else
    {
        for (int y = 0; y < MAP_HEIGHT; y++) {
            for (int x = 0; x < MAP_WIDTH; x++) {
                if(mapArray[x][y]==MAP_BLANK)
                {
                    mapArray[x][y]=MAP_BLACK;
                }
            }
        }
    }
    
    [self checkAndFillBlanks];
    [self drawMap];
    [self checkEndGameStatus];
}

/* AI by alpha beta comparison */
- (void)iaPlayByAlphaBetaComparison
{
    // Array of possible moves for AI
    NSMutableArray *iaMovesArray = [self calculatePossibleMovesForMap:mapArray andPlayer:MAP_WHITE];
    
    // If moves available
    if([iaMovesArray count] > 0)
    {
        NSMutableArray *movement = [[NSMutableArray alloc] init];
        
        [self alphaBetaForMap:mapArray withDepth:AI_difficulty andAlpha:-MAP_WIDTH*MAP_HEIGHT andBeta:MAP_WIDTH*MAP_HEIGHT andPlayer:MAP_WHITE bestMovement:movement];
        
        int x = [[movement objectAtIndex:0] intValue];
        int y = [[movement objectAtIndex:1] intValue];
        
        // AI really moves here
        [self changeTurnToYou:YES];
        [self doMoveOnMap:mapArray forPlayer:MAP_WHITE andX:x andY:y];
        [self vibrate];
    }
    // Here AI can't move, AI lost
    else
    {
        for (int y = 0; y < MAP_HEIGHT; y++) {
            for (int x = 0; x < MAP_WIDTH; x++) {
                if(mapArray[x][y]==MAP_BLANK)
                {
                    mapArray[x][y]=MAP_BLACK;
                }
            }
        }
    }
    
    [self checkAndFillBlanks];
    [self drawMap];
    [self checkEndGameStatus];
}

/* Alpha beta comparison */
- (int)alphaBetaForMap:(NSInteger[MAP_WIDTH][MAP_HEIGHT])map withDepth:(int)depth andAlpha:(int)alpha andBeta:(int)beta andPlayer:(int)player bestMovement:(NSMutableArray *)movement
{
    if(depth == 0)
    {
        return [self evaluate:map forPlayer:player];
    }
    
    // Array of possible moves for AI
    NSMutableArray *possiblesMoves = [self calculatePossibleMovesForMap:map andPlayer:player];
    
    if([possiblesMoves count] == 0)
    {
        return [self evaluate:map forPlayer:player];
    }
    
    for (int index = 0; index < [possiblesMoves count]; index++) {
        
        int possible_move_x = [[[possiblesMoves objectAtIndex:index] objectAtIndex:0]intValue];
        int possible_move_y = [[[possiblesMoves objectAtIndex:index] objectAtIndex:1]intValue];
        
        NSInteger copyMap[MAP_WIDTH][MAP_HEIGHT];
        [self copyMap:map toMap:copyMap];
        
        [self doMoveOnMap:copyMap forPlayer:player andX:possible_move_x andY:possible_move_y];
        
        int opponent;
        
        switch (player) {
            case MAP_BLACK:
                opponent = MAP_WHITE;
                break;
            case MAP_WHITE:
                opponent = MAP_BLACK;
                break;
            default:
                break;
        }
        
        NSMutableArray *movement_recurs = [[NSMutableArray alloc] init];
        
        int e = -[self alphaBetaForMap:copyMap withDepth:depth-1 andAlpha:-beta andBeta:-alpha andPlayer:opponent bestMovement:movement_recurs];
        
        if(e > alpha)
        {
            [movement removeAllObjects];
            NSNumber *firstNumber = [[NSNumber alloc] initWithInt:possible_move_x];
            NSNumber *secondNumber = [[NSNumber alloc] initWithInt:possible_move_y];
            [movement addObject:firstNumber];
            [movement addObject:secondNumber];
            alpha = e;
        }
        
        if(alpha >= beta)
        {
            return beta;
        }
    }
    
    return alpha;
}

/* Calculate possible moves for player on given map */
- (NSMutableArray *)calculatePossibleMovesForMap:(NSInteger[MAP_WIDTH][MAP_HEIGHT])map andPlayer:(int)player
{
    // Array of possible moves for AI
    NSMutableArray *iaMovesArray = [[NSMutableArray alloc] init];
    
    // Loop to find possible moves
    for (int y = 0; y < MAP_HEIGHT; y++) {
        for (int x = 0; x < MAP_WIDTH; x++) {
            if(map[x][y]==MAP_BLANK)
            {
                int isWhiteNeighbor = 0;
                int isBlackNeighbor = 0;
                
                for(int i = -1; i < 2; i++) {
                    for(int j = -1; j < 2; j++) {
                        if(
                           (i != 0 || j != 0) &&
                           x+i >= 0 && x+i < MAP_WIDTH &&
                           y+j >= 0 && y+j < MAP_HEIGHT
                           ){
                            switch (map[x+i][y+j]) {
                                case MAP_BLACK:
                                    isBlackNeighbor++;
                                    break;
                                case MAP_WHITE:
                                    isWhiteNeighbor++;
                                    break;
                                default:
                                    break;
                            }
                        }
                    }
                }
                switch (player) {
                    case MAP_BLACK:
                        // This is a possible move
                        if(isBlackNeighbor)
                        {
                            NSNumber *firstNumber = [[NSNumber alloc] initWithInt:x];
                            NSNumber *secondNumber = [[NSNumber alloc] initWithInt:y];
                            [iaMovesArray addObject:[NSArray arrayWithObjects:firstNumber, secondNumber, nil]];
                        }
                        break;
                    case MAP_WHITE:
                        // This is a possible move
                        if(isWhiteNeighbor)
                        {
                            NSNumber *firstNumber = [[NSNumber alloc] initWithInt:x];
                            NSNumber *secondNumber = [[NSNumber alloc] initWithInt:y];
                            [iaMovesArray addObject:[NSArray arrayWithObjects:firstNumber, secondNumber, nil]];
                        }
                        break;
                    default:
                        break;
                }
            }
        }
    }
    
    return iaMovesArray;
}

/* Move on map and return other pieces */
- (void)doMoveOnMap:(NSInteger[MAP_WIDTH][MAP_HEIGHT])map forPlayer:(int)player andX:(int)x andY:(int)y
{
    map[x][y] = player;
    
    for(int i = -1; i < 2; i++) {
        for(int j = -1; j < 2; j++) {
            if(i != 0 || j != 0) {
                if( x+i >= 0 && x+i < MAP_WIDTH &&
                   y+j >= 0 && y+j < MAP_HEIGHT &&
                   map[x+i][y+j] != MAP_BLANK)
                {
                    map[x+i][y+j] = map[x][y];
                }
            }
        }
    }
}

#pragma mark - Alertview delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag==777)
    {
        [self createNewGame];
    }
    else if(alertView.tag == 666)
    {
        if(buttonIndex) {
            [self changeTurnToYou:YES];
        } else {
            [self changeTurnToYou:NO];
            // Load AI in 1 second
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(iaPlay) userInfo:nil repeats:NO];
        }
    }
}

#pragma mark - AudioToolbox
- (void)vibrate {
    //AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
}

#pragma mark - Options
- (IBAction)showOptions:(id)sender
{
    ParametersViewController *parametersVC = [[ParametersViewController alloc] initWithNibName:@"ParametersViewController" bundle:nil];
    parametersVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:parametersVC animated:YES completion:nil];
}

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
