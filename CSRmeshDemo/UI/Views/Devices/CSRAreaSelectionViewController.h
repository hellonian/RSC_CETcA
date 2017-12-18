//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRMainViewController.h"
#import "CSRmeshDevice.h"
#import "CSRmeshArea.h"
#import "CSRDeviceEntity.h"

@interface CSRAreaSelectionViewController : CSRMainViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addAreaButton;
@property (nonatomic, strong) NSMutableArray *deviceAreasArray;
@property (nonatomic, strong) NSMutableArray *areasArray;
@property (nonatomic) UIRefreshControl *refreshControl;

//@property (nonatomic) UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchButton;


//mesh objects
@property (nonatomic) CSRmeshDevice *selectedDevice;
@property (nonatomic) CSRmeshArea *selectedArea;

@property (nonatomic, retain) CSRDeviceEntity *deviceEntity;
@property (nonatomic, retain) NSMutableArray *listOfLocalAreas;

@property (nonatomic, retain) NSMutableData *actualData;
@property (nonatomic, retain) NSNumber *nGroupsValue;

@property (nonatomic, retain) NSMutableArray *areaIdArray;

- (IBAction)addAreaButtonTapped:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)save:(id)sender;

@end

