//
//  EveTypeViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/13.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "EveTypeViewController.h"
#import "DataModelManager.h"

@interface EveTypeViewController ()
@property (weak, nonatomic) IBOutlet UILabel *onoffLabel;
@property (weak, nonatomic) IBOutlet UILabel *levelLabel;
@property (nonatomic,assign) NSString *eveType;
@property (nonatomic,assign) CGFloat level;
@property (weak, nonatomic) IBOutlet UISlider *levelSlider;
@property (weak, nonatomic) IBOutlet UISwitch *eveSwitch;

@end

@implementation EveTypeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self enableLevelSlider];
    
    
    
    
}

- (void)enableLevelSlider {
        
    if ([self.deviceShortName isEqualToString:@"D350BT"] && self.eveSwitch.on) {
        self.levelSlider.enabled = YES;
    }else {
        self.levelSlider.enabled = NO;
    }
}

- (IBAction)onoffSwitch:(UISwitch *)sender {
    if (sender.on) {
        _onoffLabel.text = @"ON";
        if (_setEveType) {
            if ([self.deviceShortName isEqualToString:@"D350BT"]) {
                _setEveType(@"12",_levelSlider.value);
            }
            else {
                _setEveType (@"10",255);
            }
        }
    }else {
        _onoffLabel.text = @"OFF";
        if (_setEveType) {
            _setEveType (@"11",0);
        }
    }
    [self enableLevelSlider];
}

- (IBAction)levelSlider:(UISlider *)sender {
    _levelLabel.text = [NSString stringWithFormat:@"Brightness:%.f%%",sender.value/255*100];
    if (_setEveType) {
        if ([self.deviceShortName isEqualToString:@"D350BT"] && _eveSwitch.on) {
            _setEveType(@"12",sender.value);
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
