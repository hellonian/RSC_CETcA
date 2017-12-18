//
//  PrimaryDeviceListController.h
//  BluetoothAcTEC
//
//  Created by hua on 10/12/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "SpecialFlowLayoutCollectionController.h"
#import "MJRefresh.h"
#import <CSRmesh/MeshServiceApi.h>
#import "CSRDevicesManager.h"
#import "CSRConstants.h"
#import "CSRBluetoothLE.h"
#import "CSRAppStateManager.h"
#import "CSRBridgeRoaming.h"
#import "CSRNewDeviceTableViewCell.h"
#import "CSRUtilities.h"
#import "CSRWizardPopoverViewController.h"
#import "CSRPlaceEntity.h"
#import "PrimaryItemCell.h"

@interface PrimaryDeviceListController : SpecialFlowLayoutCollectionController

- (void)queryPrimaryMeshNode;

@end
