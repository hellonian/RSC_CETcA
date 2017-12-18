//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

//We are not using this class, but the plan is to keep it here for later use.

#import <UIKit/UIKit.h>
#import "CSRBluetoothLE.h"


@interface CSRBridgeDiscoveryViewController : UITableViewController <CSRBluetoothLEDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableOfBridges;
//@property (nonatomic, assign) BOOL isPresented;

@end
