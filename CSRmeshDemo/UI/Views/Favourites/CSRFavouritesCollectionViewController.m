//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRFavouritesCollectionViewController.h"
#import "CSRFavouritesCollectionViewCell.h"
#import "CSRDeviceEntity.h"
#import "CSRAreaEntity.h"
#import "CSRDatabaseManager.h"
#import "CSRmeshStyleKit.h"
#import "CSRDeviceDetailsViewController.h"
#import "CSRAreasDetailViewController.h"
#import "CSRConstants.h"
#import "CSRDevicesManager.h"
#import "CSRmeshArea.h"
#import "CSRmeshDevice.h"
#import "CSRLightViewController.h"
#import "CSRSegmentDevicesViewController.h"
#import "CSRAppStateManager.h"

@interface CSRFavouritesCollectionViewController ()
{
    NSUInteger selectedIndex;
}

@end

@implementation CSRFavouritesCollectionViewController

- (void) viewWillAppear:(BOOL)animated
{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    
    _deviceCollectionArray = [NSMutableArray new];
    _deviceCollectionArray = [[CSRAppStateManager sharedInstance].selectedPlace.devices mutableCopy];
    
    NSSet *areasSet = [CSRAppStateManager sharedInstance].selectedPlace.areas;

    for (CSRAreaEntity *areaEntity in areasSet) {
        [_deviceCollectionArray addObject:areaEntity];
    }
    
    _favouritesArray = [NSMutableArray new];
    _activitiesArray = [NSMutableArray new];
    
    for (CSRAreaEntity *areaEntity in areasSet) {
        [_activitiesArray addObject:areaEntity];
    }
    
    [self populateFavouritesWithMode:_mode];

}

#pragma mark - Configure view with mode
- (void)populateFavouritesWithMode:(CSRActivitiesAreasSwitch)mode
{
    
    switch (mode) {
        case CSRActivitiesAreas_ActivitiesPicker:
        {
            [_activitiesArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                CSRAreaEntity *areaEntity = (CSRAreaEntity*)obj;
                    if ([areaEntity.favourite boolValue] == YES) {
                        [_favouritesArray addObject:areaEntity];
                }
                
            }];
        }
            break;
        case CSRActivitiesAreas_AreasPicker:
        {
            [_deviceCollectionArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                if ([obj isKindOfClass:[CSRDeviceEntity class]]) {
                    CSRDeviceEntity *deviceEntity = (CSRDeviceEntity*)obj;
                    if ([deviceEntity.favourite boolValue] == YES) {
                        [_favouritesArray addObject:deviceEntity];
                    }
                    
                    
                } else {
                    CSRAreaEntity *areaEntity = (CSRAreaEntity*)obj;
                    if ([areaEntity.favourite boolValue] == YES) {
                        [_favouritesArray addObject:areaEntity];
                    }
                }
                
            }];
        }
            break;
            
        default:
            break;
    }
    
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    return _favouritesArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CSRFavouriteCellIdentifier forIndexPath:indexPath];
    
    id obj = [_favouritesArray objectAtIndex:indexPath.row];
    CSRDeviceEntity *deviceEntity = nil;
    CSRAreaEntity *areaEntity = nil;
    
    if ([obj isKindOfClass:[CSRDeviceEntity class]]) {
        deviceEntity = (CSRDeviceEntity*)obj;
    } else if ([obj isKindOfClass:[CSRAreaEntity class]]) {
        areaEntity = (CSRAreaEntity *)obj;
    }
    if (deviceEntity) {
        ((CSRFavouritesCollectionViewCell *)cell).imageView.image = [CSRmeshStyleKit imageOfLight_on];
        ((CSRFavouritesCollectionViewCell *)cell).labelText.text = deviceEntity.name;
    }
    
    if (areaEntity) {
        ((CSRFavouritesCollectionViewCell *)cell).imageView.image = [CSRmeshStyleKit imageOfAreaDevice];
        ((CSRFavouritesCollectionViewCell *)cell).labelText.text = areaEntity.areaName;
        
    }
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id obj = [_favouritesArray objectAtIndex:indexPath.row];
    selectedIndex = indexPath.row;
    
    
    CSRDeviceEntity *deviceEntity = nil;
    CSRAreaEntity *areaEntity = nil;
    
    if ([obj isKindOfClass:[CSRDeviceEntity class]]) {
        deviceEntity = (CSRDeviceEntity*)obj;
    } else if ([obj isKindOfClass:[CSRAreaEntity class]]) {
        areaEntity = (CSRAreaEntity *)obj;
    }
    
    CSRmeshArea *meshArea = [[CSRDevicesManager sharedInstance] getAreaFromId:areaEntity.areaID];
    CSRmeshDevice *meshDevice = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:deviceEntity.deviceId];
    [[CSRDevicesManager sharedInstance] setSelectedDevice:meshDevice];
    [[CSRDevicesManager sharedInstance] setSelectedArea:meshArea];
    
    if (areaEntity) {
        [self performSegueWithIdentifier:@"segmentToDevices" sender:self];
    }
    if (deviceEntity && ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameLight)])) {
        [self performSegueWithIdentifier:@"lightControlSegue" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segmentToDevices"]) {
//        UINavigationController *navController = (UINavigationController*)[segue destinationViewController];
        CSRSegmentDevicesViewController *vc = (CSRSegmentDevicesViewController*)[segue destinationViewController];
        
        id obj = [_favouritesArray objectAtIndex:selectedIndex];
        
        if ([obj isKindOfClass:[CSRAreaEntity class]]) {
            vc.areaEntity = (CSRAreaEntity*)obj;
        }
        if ([obj isKindOfClass:[CSRDeviceEntity class]]) {
            vc.deviceEntity = (CSRDeviceEntity*)obj;
        }

    }
    if ([segue.identifier isEqualToString:@"lightControlSegue"]) {
        
    }

}

#pragma mark --
#pragma mark Segment Control

- (IBAction)segmentSwitch:(UISegmentedControl*)sender
{
    NSUInteger index = sender.selectedSegmentIndex;
    switch (index) {
        case 0:
        {
            [_favouritesArray removeAllObjects];
            [self populateFavouritesWithMode:CSRActivitiesAreas_ActivitiesPicker];
            [_collectionView reloadData];
        }
            break;
        case 1:
        {
            [_favouritesArray removeAllObjects];
            [self populateFavouritesWithMode:CSRActivitiesAreas_AreasPicker];
            [_collectionView reloadData];
        }
            break;
            
        default:
            break;
    }
    
}


@end
