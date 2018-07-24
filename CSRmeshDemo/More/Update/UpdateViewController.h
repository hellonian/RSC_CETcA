//
//  UpdateViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/11/2.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "DiscoverViewController.h"
#import "OTAU.h"
#import "UpdateDeviceModel.h"

@interface UpdateViewController : UIViewController <OTAUDelegate>
@property (weak, nonatomic) IBOutlet UIButton *firmwareName;
@property (weak, nonatomic) IBOutlet UIButton *targetName;
@property (weak, nonatomic) IBOutlet UIButton *updateButtonName;

@property (strong, nonatomic) NSString *firmwareFilename;
@property (nonatomic,strong) UpdateDeviceModel *targetModel;
@property (weak, nonatomic) IBOutlet UITextView *statusLog;

- (IBAction)startUpdate:(id)sender;
- (IBAction)abortUpdate:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *percentLabel;
@property (weak, nonatomic) IBOutlet UIButton *abortButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UILabel *deviceAddress;
@property (weak, nonatomic) IBOutlet UILabel *connectionState;
@property (weak, nonatomic) IBOutlet UILabel *crystalTrim;
@property (weak, nonatomic) IBOutlet UILabel *fwVersion;
@property (weak, nonatomic) IBOutlet UILabel *modeLabel;
@property (weak, nonatomic) IBOutlet UILabel *challengeLabel;
@property (weak, nonatomic) IBOutlet UILabel *appVersion;
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@end
