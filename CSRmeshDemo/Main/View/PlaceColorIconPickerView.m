//
//  PlaceColorIconPickerView.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/12/27.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "PlaceColorIconPickerView.h"
#import "PlaceIconCollectionViewCell.h"
#import "PlaceColorCollectionViewCell.h"
#import "CSRConstants.h"
#import "CSRUtilities.h"
#import "CSRmeshStyleKit.h"

@implementation PlaceColorIconPickerView

- (id)initWithFrame:(CGRect)frame withMode:(CollectionViewPickerMode)viewMode{
    self = [super initWithFrame:frame];
    if (self) {
        _mode = viewMode;
        [self populateCollectionItemsWithMode:viewMode];
        [self drawViews];
        self.backgroundColor = [UIColor colorWithRed:246/255.0 green:246/255.0 blue:246/255.0 alpha:246/255.0];
        self.alpha = 0.9;
        self.layer.cornerRadius = 14;
        self.layer.masksToBounds = YES;
    }
    return self;
}

#pragma mark - Configure view with mode
- (void)populateCollectionItemsWithMode:(CollectionViewPickerMode)mode
{
    
    switch (mode) {
        case CollectionViewPickerMode_PlaceColorPicker:
            _itemsArray = kPlaceColors;
            break;
        case CollectionViewPickerMode_PlaceIconPicker:
            _itemsArray = kPlaceIcons;
            break;
        case CollectionViewPickerMode_SceneIconPicker:
            _itemsArray = kSceneIcons;
            break;
        case CollectionViewPickerMode_GroupIconPicker:
            _itemsArray = kGroupIcons;
            break;
        default:
            break;
    }
    
}

- (void)drawViews {

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(270*0.5-100, 5, 200, 20)];
    _titleLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    if (_mode == CollectionViewPickerMode_PlaceColorPicker) {
        _titleLabel.text = @"Select color";
    }else if (_mode == CollectionViewPickerMode_PlaceIconPicker) {
        _titleLabel.text = @"Select image";
    }else if (_mode == CollectionViewPickerMode_SceneIconPicker) {
        _titleLabel.text = AcTECLocalizedStringFromTable(@"SceneIcons", @"Localizable");
    }else if (_mode == CollectionViewPickerMode_GroupIconPicker) {
        _titleLabel.text = AcTECLocalizedStringFromTable(@"GroupIcons", @"Localizable");
    }
    [self addSubview:_titleLabel];
    
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 29, 270, 1)];
    topLine.backgroundColor = [UIColor colorWithRed:195/255.0 green:195/255.0 blue:195/255.0 alpha:1];
    [self addSubview:topLine];
    
    _cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(270*0.5-100, 160, 200, 20)];
    [_cancelButton setTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") forState:UIControlStateNormal];
    [_cancelButton setTitleColor:DARKORAGE forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_cancelButton];
    
    UIView *botLine = [[UIView alloc] initWithFrame:CGRectMake(0, 150, 270, 1)];
    botLine.backgroundColor = [UIColor colorWithRed:195/255.0 green:195/255.0 blue:195/255.0 alpha:1];
    [self addSubview:botLine];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 12;
    layout.minimumInteritemSpacing = 7;
    layout.sectionInset = UIEdgeInsetsMake(12, 16, 12, 16);
    layout.itemSize = CGSizeMake(42, 42);
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 30, 270, 120) collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.backgroundColor = [UIColor clearColor];
    [self addSubview:_collectionView];
    [_collectionView registerNib:[UINib nibWithNibName:@"PlaceColorCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:PlaceColorCellIdentifier];
    [_collectionView registerNib:[UINib nibWithNibName:@"PlaceIconCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:PlaceIconCellIdentifier];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.itemsArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = nil;
    
    if (_mode == CollectionViewPickerMode_PlaceColorPicker) {
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:PlaceColorCellIdentifier forIndexPath:indexPath];
        ((PlaceColorCollectionViewCell *)cell).placeColor.backgroundColor = [CSRUtilities colorFromHex:[_itemsArray objectAtIndex:indexPath.row]];
        ((PlaceColorCollectionViewCell *)cell).placeColor.layer.cornerRadius = ((PlaceColorCollectionViewCell *)cell).placeColor.bounds.size.width / 2;
        
    } else if (_mode == CollectionViewPickerMode_PlaceIconPicker) {
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:PlaceIconCellIdentifier forIndexPath:indexPath];
        
        SEL imageSelector = NSSelectorFromString(((NSDictionary *)[_itemsArray objectAtIndex:indexPath.row])[@"iconImage"]);
        
        if ([CSRmeshStyleKit respondsToSelector:imageSelector]) {
            ((PlaceIconCollectionViewCell *)cell).placeIcon.image = (UIImage *)[CSRmeshStyleKit performSelector:imageSelector];
        }
        
        ((PlaceIconCollectionViewCell *)cell).placeIcon.image = [((PlaceIconCollectionViewCell *)cell).placeIcon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        ((PlaceIconCollectionViewCell *)cell).placeIcon.tintColor = [CSRUtilities colorFromHex:kColorDarkBlueCSR];
        
    } else if (_mode == CollectionViewPickerMode_SceneIconPicker) {
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:PlaceIconCellIdentifier forIndexPath:indexPath];
        
        ((PlaceIconCollectionViewCell *)cell).placeIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"Scene_%@_gray",_itemsArray[indexPath.row]]];
        
    }else if (_mode == CollectionViewPickerMode_GroupIconPicker) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:PlaceIconCellIdentifier forIndexPath:indexPath];
        ((PlaceIconCollectionViewCell *)cell).placeIcon.image = [UIImage imageNamed:_itemsArray[indexPath.row]];
    }
    
    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate && [self.delegate respondsToSelector:@selector(selectedItem:)] && [self.delegate respondsToSelector:@selector(cancel:)]) {
        [self.delegate selectedItem:[_itemsArray objectAtIndex:indexPath.row]];
        [self.delegate cancel:nil];
    }
}

#pragma mark - Actions

- (void) cancelAction: (UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancel:)]) {
        [self.delegate cancel:nil];
    }
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
