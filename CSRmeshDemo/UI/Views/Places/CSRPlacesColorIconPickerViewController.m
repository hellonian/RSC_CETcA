//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRPlacesColorIconPickerViewController.h"
#import "CSRPlaceColorCollectionViewCell.h"
#import "CSRPlaceIconCollectionViewCell.h"
#import "CSRmeshStyleKit.h"
#import "CSRUtilities.h"
#import "CSRConstants.h"

@interface CSRPlacesColorIconPickerViewController ()
{
    NSArray *itemsArray;
}

@end

@implementation CSRPlacesColorIconPickerViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set delegate and data source for collection view
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    [self populateCollectionItemsWithMode:_mode];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_mode == CSRPlacesCollectionViewMode_ColorPicker) {
        _titleLabel.text = @"Select color";
    } else if (_mode == CSRPlacesCollectionViewMode_IconPicker) {
        _titleLabel.text = @"Select image";
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.view = nil;
}

#pragma mark - Configure view with mode
- (void)populateCollectionItemsWithMode:(CSRPlacesCollectionViewMode)mode
{
    
    switch (mode) {
        case CSRPlacesCollectionViewMode_ColorPicker:
            itemsArray = kPlaceColors;
            break;
        case CSRPlacesCollectionViewMode_IconPicker:
            itemsArray = kPlaceIcons;
            break;
            
        default:
            break;
    }
    
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [itemsArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    
    if (_mode == CSRPlacesCollectionViewMode_ColorPicker) {
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:CSRPlaceColorCellIdentifier forIndexPath:indexPath];
        ((CSRPlaceColorCollectionViewCell *)cell).placeColor.backgroundColor = [CSRUtilities colorFromHex:[itemsArray objectAtIndex:indexPath.row]];
        ((CSRPlaceColorCollectionViewCell *)cell).placeColor.layer.cornerRadius = ((CSRPlaceColorCollectionViewCell *)cell).placeColor.bounds.size.width / 2;
        
    } else {
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:CSRPlaceIconCellIdentifier forIndexPath:indexPath];
        
        SEL imageSelector = NSSelectorFromString(((NSDictionary *)[itemsArray objectAtIndex:indexPath.row])[@"iconImage"]);
        
        if ([CSRmeshStyleKit respondsToSelector:imageSelector]) {
            ((CSRPlaceIconCollectionViewCell *)cell).placeIcon.image = (UIImage *)[CSRmeshStyleKit performSelector:imageSelector];
        }
        
        ((CSRPlaceIconCollectionViewCell *)cell).placeIcon.image = [((CSRPlaceIconCollectionViewCell *)cell).placeIcon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        ((CSRPlaceIconCollectionViewCell *)cell).placeIcon.tintColor = [CSRUtilities colorFromHex:kColorDarkBlueCSR];
        
    }
    
    return cell;
}

#pragma mark <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize cellSize;
    
    if (_mode == CSRPlacesCollectionViewMode_IconPicker) {
        
        cellSize = CGSizeMake(45., 45.);
        
    } else if (_mode == CSRPlacesCollectionViewMode_ColorPicker) {
        
        cellSize = CGSizeMake(45., 45.);
        
    }
    
    return cellSize;
}



#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [_delegate selectedItem:[itemsArray objectAtIndex:indexPath.row]];
    [self cancel:nil];
}

#pragma mark - <CSRPlacesColorIconPickerDelegate>

- (id)selectedItem:(id)item
{
    return item;
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
