//
//  PlaceDetailsViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/12/26.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "PlaceDetailsViewController.h"
#import "PlaceColorIconPickerView.h"
#import "PureLayout.h"
#import "CSRUtilities.h"
#import "CSRmeshStyleKit.h"
#import "CSRConstants.h"
#import "CSRmeshStyleKit.h"
#import "CSRDatabaseManager.h"
#import "CSRSettingsEntity.h"
#import "CSRAppStateManager.h"

@interface PlaceDetailsViewController ()<UITextFieldDelegate,CSRCheckboxDelegate,PlaceColorIconPickerViewDelegate,CSRCheckboxDelegate>
{
    NSUInteger pickerMode;
    PlaceColorIconPickerView *pickerView;
    NSUInteger placeIconId;
}

@end

@implementation PlaceDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _placeNameTF.delegate = self;
    _placeNetworkKeyTF.delegate = self;
    _placeNetworkKeyTF.secureTextEntry = YES;
    
    _showPasswordCheckbox.delegate = self;
    _showPasswordCheckbox.selected = YES;
    _showPasswordCheckbox.highlighted = NO;
    
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
    self.navigationItem.leftBarButtonItem = back;
    
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveAction)];
    self.navigationItem.rightBarButtonItem = save;
    
    _placeColorSelectionButton.backgroundColor = [UIColor clearColor];
    _placeColorSelectionButton.layer.cornerRadius = _placeColorSelectionButton.bounds.size.width / 2;
    _placeColorSelectionButton.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    _placeColorSelectionButton.layer.borderWidth = 0.5;
    
    _placeIconSelectionButton.backgroundColor = [UIColor clearColor];
    _placeIconSelectionButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    _placeIconSelectionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    _placeIconSelectionButton.imageView.image = [_placeIconSelectionButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_placeIconSelectionButton.imageView sizeToFit];
    _placeIconSelectionButton.tintColor = [UIColor grayColor];
    
    [_deleteButton setImage:[[CSRmeshStyleKit imageOfTrashcan] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    _deleteButton.imageView.tintColor = [UIColor whiteColor];
    [_deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    
    if (_placeEntity.name) {
        _placeNameTF.text = _placeEntity.name;
    }
    if (_placeEntity && ![CSRUtilities isStringEmpty:_placeEntity.passPhrase]) {
        _placeNetworkKeyTF.text = _placeEntity.passPhrase;
    }
    if ([_placeEntity.iconID integerValue] > -1) {
        NSArray *placeIcons = kPlaceIcons;
        [placeIcons enumerateObjectsUsingBlock:^(NSDictionary *placeIconsDictionary, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([placeIconsDictionary[@"id"] integerValue] > -1 && [placeIconsDictionary[@"id"] integerValue] == [_placeEntity.iconID integerValue]) {
                SEL imageSelector = NSSelectorFromString(placeIconsDictionary[@"iconImage"]);
                if ([CSRmeshStyleKit respondsToSelector:imageSelector]) {
                    [_placeIconSelectionButton setImage:(UIImage *)[CSRmeshStyleKit performSelector:imageSelector] forState:UIControlStateNormal];
                    _placeIconSelectionButton.imageView.tintColor = [UIColor grayColor];
                }
                *stop = YES;
            }
        }];
    }
    if (_placeEntity.color) {
        _placeColorSelectionButton.backgroundColor = [CSRUtilities colorFromRGB:[_placeEntity.color integerValue]];
    }
    if (!_placeIconSelectionButton.imageView.image) {
        [_placeIconSelectionButton setImage:[CSRmeshStyleKit imageOfHouse] forState:UIControlStateNormal];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_placeEntity) {
        _deleteButton.hidden = YES;
    }
}

#pragma mark - Actions

- (void) backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveAction {
    if (!placeIconId) {
        placeIconId = [_placeEntity.iconID integerValue];
    }
    
    if (_placeEntity && ![CSRUtilities isStringEmpty:_placeEntity.passPhrase]) {
        if (![CSRUtilities isStringEmpty:_placeNameTF.text] && ![CSRUtilities isStringEmpty:_placeNetworkKeyTF.text]) {
            
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.passPhrase = _placeNetworkKeyTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:_placeColorSelectionButton.backgroundColor]);
            _placeEntity.iconID = @(placeIconId);
            _placeEntity.owner = @"My place";
            _placeEntity.networkKey = nil;
            
            [self checkForSettings];
            [[CSRDatabaseManager sharedInstance] saveContext];
            [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
            [[CSRAppStateManager sharedInstance] setupPlace];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            [self showAlert];
        }
    }
    
    if (!_placeEntity) {
        if (![CSRUtilities isStringEmpty:_placeNameTF.text] && ![CSRUtilities isStringEmpty:_placeNetworkKeyTF.text]) {
            
            _placeEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRPlaceEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
            
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.passPhrase = _placeNetworkKeyTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:_placeColorSelectionButton.backgroundColor]);
            _placeEntity.iconID = @(placeIconId);
            _placeEntity.owner = @"My place";
            _placeEntity.networkKey = nil;
            
            [self checkForSettings];
            [[CSRDatabaseManager sharedInstance] saveContext];
            [[CSRAppStateManager sharedInstance] setupPlace];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            [self showAlert];
        }
    }
}

- (void)checkForSettings
{
    if (_placeEntity.settings) {
        
        _placeEntity.settings.retryInterval = @500;
        _placeEntity.settings.retryCount = @10;
        _placeEntity.settings.concurrentConnections = @1;
        _placeEntity.settings.listeningMode = @1;
        
    } else {
        
        CSRSettingsEntity *settings = [NSEntityDescription insertNewObjectForEntityForName:@"CSRSettingsEntity"
                                                                    inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
        settings.retryInterval = @500;
        settings.retryCount = @10;
        settings.concurrentConnections = @1;
        settings.listeningMode = @1;
        
        _placeEntity.settings = settings;
        
    }
}

- (void) showAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert!"
                                                                             message:@"Name and Pass Phrase should not be empty, please enter some values"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         
                                                     }];
    
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (IBAction)openPicker:(UIButton *)sender {
    if (!pickerView) {
        
        if ([sender isEqual:_placeColorSelectionButton]) {
            pickerMode = CSRPlacesCollectionViewMode_ColorPicker;
        }
        else if ([sender isEqual:_placeIconSelectionButton]){
            pickerMode = CSRPlacesCollectionViewMode_IconPicker;
        }
        
        pickerView = [[PlaceColorIconPickerView alloc] initWithFrame:CGRectMake((WIDTH-277)/2, (HEIGHT-240)/2, 277, 240) withMode:pickerMode];
        
        pickerView.delegate = self;
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.view addSubview:pickerView];
            [pickerView autoCenterInSuperview];
            [pickerView autoSetDimensionsToSize:CGSizeMake(277, 240)];
        }];
    }
}

- (IBAction)deletePlace:(id)sender
{
    if (![[_placeEntity objectID] isEqual:[[CSRAppStateManager sharedInstance].selectedPlace objectID]]) {
        
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_placeEntity];
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Can't Delete" message:@"You can't delete current selected place" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - <PlaceColorIconPickerViewDelegate>

- (id)selectedItem:(id)item {
    if (pickerMode == CSRPlacesCollectionViewMode_ColorPicker) {
        NSString *selectedColorHex = (NSString *)item;
        _placeColorSelectionButton.backgroundColor = [CSRUtilities colorFromHex:selectedColorHex];
    }
    else if (pickerMode == CSRPlacesCollectionViewMode_IconPicker) {
        NSDictionary *iconImageDictionary = (NSDictionary *)item;
        placeIconId = [(NSNumber *)iconImageDictionary[@"id"] integerValue];
        SEL imageSelector = NSSelectorFromString(iconImageDictionary[@"iconImage"]);
        if ([CSRmeshStyleKit respondsToSelector:imageSelector]) {
            [_placeIconSelectionButton setImage:(UIImage *)[CSRmeshStyleKit performSelector:imageSelector] forState:UIControlStateNormal];
        }
        
        _placeIconSelectionButton.imageView.image = [_placeIconSelectionButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_placeIconSelectionButton.imageView sizeToFit];
        _placeIconSelectionButton.imageView.tintColor = [UIColor grayColor];
        
    }
    return nil;
}

- (void)cancel:(UIButton *)sender {
    if (pickerView) {
        [UIView animateWithDuration:0.5 animations:^{
            [pickerView removeFromSuperview];
            pickerView = nil;
        }];
    }
}

#pragma mark - <CSRCheckbox>

- (void)checkbox:(CSRCheckbox *)sender stateChangeTo:(BOOL)state {
    if (state == _showPasswordCheckbox.selected) {
        _placeNetworkKeyTF.secureTextEntry = state;
    }else {
        _placeNetworkKeyTF.secureTextEntry = _showPasswordCheckbox.selected;
    }
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
