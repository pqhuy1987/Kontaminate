//
//  ParametersViewController.m
//  virusGame
//
//  Created by William Klein on 05/10/12.
//  Copyright (c) 2012 William Klein. All rights reserved.
//

#import "ParametersViewController.h"
#import "Config.h"

@interface ParametersViewController ()

@end

@implementation ParametersViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [typeOfAI setSelectedSegmentIndex:[[prefs objectForKey:@"AI_TYPE"] intValue]];
    [levelAI setSelectedSegmentIndex:[[prefs objectForKey:@"AI_DIFFICULTY"] intValue]];
}

- (IBAction)saveSettings:(id)sender
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    switch (typeOfAI.selectedSegmentIndex) {
        case 0:
            [prefs setObject:[[NSNumber alloc] initWithInt:AI_TYPE_MINMAX] forKey:@"AI_TYPE"];
            break;
        case 1:
            [prefs setObject:[[NSNumber alloc] initWithInt:AI_TYPE_ALPHABETA] forKey:@"AI_TYPE"];
            break;
        default:
            break;
    }
    switch (levelAI.selectedSegmentIndex) {
        case 0:
            [prefs setObject:[[NSNumber alloc] initWithInt:AI_DIFFICULTY_1] forKey:@"AI_DIFFICULTY"];
            break;
        case 1:
            [prefs setObject:[[NSNumber alloc] initWithInt:AI_DIFFICULTY_2] forKey:@"AI_DIFFICULTY"];
            break;
        case 2:
            [prefs setObject:[[NSNumber alloc] initWithInt:AI_DIFFICULTY_3] forKey:@"AI_DIFFICULTY"];
            break;
        default:
            break;
    }
}

- (IBAction)quit:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
