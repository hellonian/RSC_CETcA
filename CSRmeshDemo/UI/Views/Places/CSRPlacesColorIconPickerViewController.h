//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRMainViewController.h"

typedef NS_ENUM(NSUInteger, CSRPlacesCollectionViewMode)
{
    CSRPlacesCollectionViewMode_ColorPicker = 0,
    CSRPlacesCollectionViewMode_IconPicker = 1
};

@protocol CSRPlacesColorIconPickerDelegate <NSObject>

- (id)selectedItem:(id)item;

@end

@interface CSRPlacesColorIconPickerViewController : CSRMainViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic) CSRPlacesCollectionViewMode mode;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (assign, nonatomic) id <CSRPlacesColorIconPickerDelegate> delegate;

- (IBAction)cancel:(id)sender;

@end
