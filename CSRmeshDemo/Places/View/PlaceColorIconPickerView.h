//
//  PlaceColorIconPickerView.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/12/27.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CSRPlacesCollectionViewMode)
{
    CSRPlacesCollectionViewMode_ColorPicker = 0,
    CSRPlacesCollectionViewMode_IconPicker = 1
};

@protocol PlaceColorIconPickerViewDelegate <NSObject>

- (id)selectedItem:(id)item;
- (void)cancel:(UIButton *)sender;

@end

@interface PlaceColorIconPickerView : UIView<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) UICollectionView *collectionView;
@property (nonatomic,strong) UIButton *cancelButton;
@property (nonatomic,strong) NSArray *itemsArray;
@property (nonatomic,assign) CSRPlacesCollectionViewMode mode;
@property (nonatomic,weak) id <PlaceColorIconPickerViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame withMode:(CSRPlacesCollectionViewMode)viewMode;

@end
