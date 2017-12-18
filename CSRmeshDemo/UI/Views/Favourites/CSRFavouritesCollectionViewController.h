//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRMainViewController.h"

typedef NS_ENUM(NSUInteger, CSRActivitiesAreasSwitch)
{
    CSRActivitiesAreas_ActivitiesPicker = 0,
    CSRActivitiesAreas_AreasPicker = 1
};

@interface CSRFavouritesCollectionViewController : CSRMainViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic) CSRActivitiesAreasSwitch mode;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *activitiesCollectionView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;

@property (nonatomic, retain) NSMutableArray *deviceCollectionArray;
@property (nonatomic, retain) NSMutableArray *favouritesArray;
@property (nonatomic, retain) NSMutableArray *activitiesArray;

- (IBAction)segmentSwitch:(UISegmentedControl*)sender;

@end
