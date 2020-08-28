//
//  PlaceColorIconPickerView.h
//  AcTECBLE
//
//  Created by AcTEC on 2017/12/27.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CollectionViewPickerMode)
{
    CollectionViewPickerMode_PlaceColorPicker = 0,
    CollectionViewPickerMode_PlaceIconPicker = 1,
    CollectionViewPickerMode_SceneIconPicker = 2,
    CollectionViewPickerMode_GroupIconPicker = 3
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
@property (nonatomic,assign) CollectionViewPickerMode mode;
@property (nonatomic,weak) id <PlaceColorIconPickerViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame withMode:(CollectionViewPickerMode)viewMode;

@end
