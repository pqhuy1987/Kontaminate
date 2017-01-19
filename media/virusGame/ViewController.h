//
//  ViewController.h
//  virusGame
//
//  Created by William Klein on 03/10/12.
//  Copyright (c) 2012 William Klein. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UIAlertViewDelegate> {
    BOOL gamePaused;
    BOOL yourTurn;
    IBOutlet UILabel *scoreblack;
    IBOutlet UILabel *scorewhite;
    IBOutlet UIImageView *yourTurnGlow;
    IBOutlet UIImageView *hisTurnGlow;
    
    int AI_type;
    int AI_difficulty;
}

@end
