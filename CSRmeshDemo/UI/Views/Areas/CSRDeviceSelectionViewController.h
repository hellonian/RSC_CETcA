//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRMainViewController.h"
#import "CSRmeshArea.h"
#import "CSRAreaEntity.h"
#import "CSRDeviceEntity.h"

@interface CSRDeviceSelectionViewController : CSRMainViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UITableView *deviceSelctionTableView;
@property (nonatomic, retain) NSArray *devicesArray;
@property (nonatomic, retain) CSRmeshArea *selectedArea;
@property (nonatomic, retain) CSRAreaEntity *areaEntity;
//@property (nonatomic) UIBarButtonItem *backButton;
@property (nonatomic, retain) NSMutableArray *listOfLocalDevices;
@property (nonatomic, retain) NSMutableData *groupsData;
@property (nonatomic, retain) NSMutableData *actualData;

@property (nonatomic, retain) NSMutableSet *checkedIndexPaths;

@property (nonatomic, retain) NSMutableArray *theDefaultArray;
@property (nonatomic, retain) NSMutableArray *theNewArray;
@property (nonatomic, retain) NSMutableArray *theAddArray;
@property (nonatomic, retain) NSMutableArray *theDeleteArray;


-(IBAction)saveDevicesSelection:(id)sender;
-(IBAction)cancelAction:(id)sender;
-(IBAction)back:(id)sender;

@end
