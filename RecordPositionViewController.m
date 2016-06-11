//
//  RecordPositionViewController.m
//  HelloMyMap
//
//  Created by Joe Chen on 2016/5/24.
//  Copyright © 2016年 Joe Chen. All rights reserved.
//

#import "RecordPositionViewController.h"

@interface RecordPositionViewController ()
@property (weak, nonatomic) IBOutlet UITextView *positionText;

@end

@implementation RecordPositionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self showCoordinates];
}

- (IBAction)back:(UIButton *)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)showCoordinates{
   
    NSLog(@"%@",_getPosition);
    
    for(int i=0;i<_getPosition.count;i++){
        NSDictionary * temp  = _getPosition[i];
        NSString * lat = [temp objectForKey:@"latitude"];
        NSString * lon = [temp objectForKey:@"longitude"];
        _positionText.text = [_positionText.text stringByAppendingString:[NSString stringWithFormat:@"latitude=%@,longitude=%@\n",lat,lon]];
    }
    
}

@end
