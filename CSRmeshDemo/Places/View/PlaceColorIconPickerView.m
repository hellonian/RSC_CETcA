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

- (id)initWithFrame:(CGRect)frame withMode:(CSRPlacesCollectionViewMode)viewMode{
    self = [super initWithFrame:frame];
    if (self) {
        _mode = viewMode;
        [self populateCollectionItemsWithMode:viewMode];
        [self drawViews];
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

#pragma mark - Configure view with mode
- (void)populateCollectionItemsWithMode:(CSRPlacesCollectionViewMode)mode
{
    
    switch (mode) {
        case CSRPlacesCollectionViewMode_ColorPicker:
            _itemsArray = kPlaceColors;
            break;
        case CSRPlacesCollectionViewMode_IconPicker:
            _itemsArray = kPlaceIcons;
            break;
            
        default:
            break;
    }
    
}

- (void)drawViews {
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(277*0.5-100, 20, 200, 21)];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    if (_mode == CSRPlacesCollectionViewMode_ColorPicker) {
        _titleLabel.text = @"Select color";
    }else if (_mode == CSRPlacesCollectionViewMode_IconPicker) {
        _titleLabel.text = @"Select image";
    }
    [self addSubview:_titleLabel];
    
    _cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(277*0.5-100, 202, 200, 30)];
    [_cancelButton setTitle:@"CANCEL" forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_cancelButton];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    layout.itemSize = CGSizeMake(45, 45);
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(16, 49, 245, 145) collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.backgroundColor = [UIColor whiteColor];
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
    
    if (_mode == CSRPlacesCollectionViewMode_ColorPicker) {
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:PlaceColorCellIdentifier forIndexPath:indexPath];
        ((PlaceColorCollectionViewCell *)cell).placeColor.backgroundColor = [CSRUtilities colorFromHex:[_itemsArray objectAtIndex:indexPath.row]];
        ((PlaceColorCollectionViewCell *)cell).placeColor.layer.cornerRadius = ((PlaceColorCollectionViewCell *)cell).placeColor.bounds.size.width / 2;
        
    } else {
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:PlaceIconCellIdentifier forIndexPath:indexPath];
        
        SEL imageSelector = NSSelectorFromString(((NSDictionary *)[_itemsArray objectAtIndex:indexPath.row])[@"iconImage"]);
        
        if ([CSRmeshStyleKit respondsToSelector:imageSelector]) {
            ((PlaceIconCollectionViewCell *)cell).placeIcon.image = (UIImage *)[CSRmeshStyleKit performSelector:imageSelector];
        }
        
        ((PlaceIconCollectionViewCell *)cell).placeIcon.image = [((PlaceIconCollectionViewCell *)cell).placeIcon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        ((PlaceIconCollectionViewCell *)cell).placeIcon.tintColor = [CSRUtilities colorFromHex:kColorDarkBlueCSR];
        
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
