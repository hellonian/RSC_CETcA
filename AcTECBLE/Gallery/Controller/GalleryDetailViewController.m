//
//  GalleryDetailViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/1/2.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "GalleryDetailViewController.h"

#import "DeviceListViewController.h"

#import "GalleryDropView.h"
#import "CSRDatabaseManager.h"
#import "GalleryEntity.h"
#import "CSRAppStateManager.h"
#import "DropEntity.h"
#import "CSRDeviceEntity.h"
#import "GalleryControlImageView.h"
#import "CSRmeshDevice.h"
#import "CSRDevicesManager.h"
#import "DeviceModelManager.h"
#import "ImproveTouchingExperience.h"
#import "ControlMaskView.h"
#import "SelectModel.h"

@interface GalleryDetailViewController ()<GalleryControlImageViewDelegate,GalleryDropViewDelegate>

@property (nonatomic, copy) GalleryControlImageView *controlImageView;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) BOOL isChange;
@property (nonatomic, strong) GalleryEntity *MyGalleryEntity;
@property (nonatomic,strong) NSNumber *originalLevel;
@property (nonatomic,strong) ImproveTouchingExperience *improver;
@property (nonatomic,strong) ControlMaskView *maskLayer;
@property (nonatomic,assign) BOOL backRefresh;

@end

@implementation GalleryDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithRed:195/255.0 green:195/255.0 blue:195/255.0 alpha:1];
    
    [self prepareNavigationItem];
    
    _controlImageView = [[GalleryControlImageView alloc] init];
    _controlImageView.delegate = self;
    _controlImageView.center = CGPointMake(WIDTH/2, (HEIGHT-64)/2+64);
    [_controlImageView.deleteButton setHidden:YES];
    
    if (_isNewAdd && _image) {
        
        _controlImageView.image = _image;
        _controlImageView.isEditing = YES;
        CGFloat fixelW = CGImageGetWidth(_image.CGImage);
        CGFloat fixelH = CGImageGetHeight(_image.CGImage);
        if (fixelW/fixelH > WIDTH/(HEIGHT-64)) {
            _controlImageView.bounds = CGRectMake(0, 0, WIDTH, fixelH/fixelW*WIDTH);
        }else {
            _controlImageView.bounds = CGRectMake(0, 0, fixelW/fixelH*(HEIGHT-64), HEIGHT-64);
        }
        
    }
    else if (_galleryId)
    {
        _controlImageView.isEditing = NO;
        NSArray *gallerys = [[CSRAppStateManager sharedInstance].selectedPlace.gallerys allObjects];
        [gallerys enumerateObjectsUsingBlock:^(GalleryEntity *galleryEntity, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([galleryEntity.galleryID isEqualToNumber:_galleryId]) {
                UIImage *myImage = [UIImage imageWithData:galleryEntity.galleryImage];
                _controlImageView.image = myImage;
                _MyGalleryEntity = galleryEntity;
                CGFloat fixelW = CGImageGetWidth(myImage.CGImage);
                CGFloat fixelH = CGImageGetHeight(myImage.CGImage);
                if (fixelW/fixelH > WIDTH/(HEIGHT-64)) {
                    _controlImageView.bounds = CGRectMake(0, 0, WIDTH, fixelH/fixelW*WIDTH);
                }else {
                    _controlImageView.bounds = CGRectMake(0, 0, fixelW/fixelH*(HEIGHT-64), HEIGHT-64);
                }
                if (galleryEntity.drops != nil && [galleryEntity.drops count] > 0) {
                    for (DropEntity * dropEntity in galleryEntity.drops) {
                        GalleryDropView * dropView = [_controlImageView addDropViewInRightLocation:dropEntity];
                        dropView.delegate = self;
                    }
                }
                *stop = YES;
            }
        }];
    }

    [self.view addSubview:_controlImageView];
    
    self.improver = [[ImproveTouchingExperience alloc] init];
}

- (void)prepareNavigationItem {
    _controlImageView.isEditing = _isEditing;
    if (_isEditing) {
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(galleryDetailDoneAction:)];
        UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(galleryAddAction:)];
        self.navigationItem.rightBarButtonItem = done;
        self.navigationItem.leftBarButtonItem = add;
        
    }else {
        UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(galleryDetailEditAction:)];
        self.navigationItem.rightBarButtonItem = edit;
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.bounds = CGRectMake(0, 0, 80, 40);
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [btn addTarget:self action:@selector(galleryDetailCloseAction:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
    }
    
    [_controlImageView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[GalleryDropView class]]) {
            GalleryDropView *dropView = (GalleryDropView *)obj;
            dropView.isEditing = _isEditing;
        }
    }];
    
}

- (void)galleryDetailEditAction:(UIBarButtonItem *)item {
    _isEditing = YES;
    [self prepareNavigationItem];
}

- (void)galleryDetailCloseAction:(UIBarButtonItem *)item {
    
    if (_isChange || _backRefresh) {
        if (self.handle) {
            self.handle();
            _isChange = NO;
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)galleryDetailDoneAction:(UIBarButtonItem *)item {
    _isEditing = NO;
    [self prepareNavigationItem];
    if (_isNewAdd) {
        _isNewAdd = NO;
        _backRefresh = YES;
        NSNumber *galleryIdNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"GalleryEntity"];
        _galleryId = galleryIdNumber;
        float boundWR = 0.549 * _controlImageView.bounds.size.width/_controlImageView.bounds.size.height;
        
        GalleryEntity *galleryEntity = [[CSRDatabaseManager sharedInstance] saveNewGallery:galleryIdNumber galleryImage:_image galleryBoundeWR:@(boundWR)];
        
        [_controlImageView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[GalleryDropView class]]) {
                GalleryDropView *dropView = (GalleryDropView *)obj;
                
                float boundR = dropView.bounds.size.width/_controlImageView.bounds.size.width;
                float centerXR = dropView.center.x/_controlImageView.bounds.size.width;
                float centerYR = dropView.center.y/_controlImageView.bounds.size.height;
                __block CSRDeviceEntity *device;
                NSArray *devices = [[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects];
                [devices enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([deviceEntity.deviceId isEqualToNumber:dropView.deviceId]) {
                        device = deviceEntity;
                        *stop = YES;
                    }
                }];
                
                NSNumber *dropIdNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"DropEntity"];
                dropView.dropId = dropIdNumber;
                DropEntity *dropEntity = [[CSRDatabaseManager sharedInstance] saveNewDrop:dropIdNumber device:device dropBoundRatio:@(boundR) centerXRatio:@(centerXR) centerYRatio:@(centerYR) galleryId:galleryIdNumber channel:dropView.channel];
                if (dropEntity) {
                    [galleryEntity addDropsObject:dropEntity];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }
            }
        }];
    }else if (_isChange) {
        
        [_controlImageView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[GalleryDropView class]]) {
                GalleryDropView *dropView = (GalleryDropView *)obj;
                
                float boundR = dropView.bounds.size.width/_controlImageView.bounds.size.width;
                float centerXR = dropView.center.x/_controlImageView.bounds.size.width;
                float centerYR = dropView.center.y/_controlImageView.bounds.size.height;
                __block CSRDeviceEntity *device;
                NSArray *devices = [[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects];
                [devices enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([deviceEntity.deviceId isEqualToNumber:dropView.deviceId]) {
                        device = deviceEntity;
                        *stop = YES;
                    }
                }];
                
                NSNumber *dropIdNumber;
                
                DropEntity *dropEntity = [[[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"DropEntity" withPredicate:@"dropID == %@",dropView.dropId] firstObject];
                if (dropEntity) {
                    dropIdNumber = dropEntity.dropID;
                }else {
                    dropIdNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"DropEntity"];
                    dropView.dropId = dropIdNumber;
                }
                [[CSRDatabaseManager sharedInstance] saveNewDrop:dropIdNumber device:device dropBoundRatio:@(boundR) centerXRatio:@(centerXR) centerYRatio:@(centerYR) galleryId:_galleryId channel:dropView.channel];
                
            }
        }];
    }
}

- (void)galleryAddAction:(UIBarButtonItem *)item {

    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_ForDrop;
    [list getSelectedDevices:^(NSArray *devices) {
        if (devices.count > 0) {
            SelectModel *model = devices[0];
            if (!_isNewAdd) {
                _isChange = YES;
            }
            GalleryDropView *dropView = [[GalleryDropView alloc] initWithFrame:CGRectMake(0, 0, 128, 128)];
            dropView.deviceId = model.deviceID;
            dropView.isEditing = YES;
            dropView.channel = model.channel;
            dropView.delegate = self;
            
            CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:model.deviceID];
            dropView.kindName = d.shortName;
            
            [_controlImageView addDropViewInCenter:dropView];
        }
    }];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
    
}

#pragma mark - GalleryControlImageViewDelegate

- (void)galleryControlImageViewDeleteDropView:(UIView *)view {
    if (!_isNewAdd) {
        _isChange = YES;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"" preferredStyle:UIAlertControllerStyleAlert];
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"RemoveLight", @"Localizable")];
    [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
    [alertController setValue:attributedMessage forKey:@"attributedMessage"];
    alertController.view.tintColor = DARKORAGE;
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *removeAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Remove", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        GalleryDropView *dropView = (GalleryDropView *)view;
        [_controlImageView deleteDropView:view];
        
        DropEntity *dropEntity = [[[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"DropEntity" withPredicate:@"dropID == %@",dropView.dropId] firstObject];
        if (dropEntity) {
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:dropEntity];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
        
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:removeAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)galleryControlImageViewPichDropView:(id)sender {
    if ([sender isKindOfClass:[NSNumber class]]) {
        NSNumber *isChange = (NSNumber *)sender;
        _isChange = [isChange boolValue];
    }
}

#pragma mark - GalleryDropViewDelegate

- (void)galleryDropViewPanLocationAction:(NSNumber *)value {
    if (!_isNewAdd) {
        _isChange = [value boolValue];
    }
}

- (void)galleryDropViewPanBrightnessWithTouchPoint:(CGPoint)touchPoint withOrigin:(CGPoint)origin toLight:(NSNumber *)deviceId channel:(NSNumber *)channel withPanState:(UIGestureRecognizerState)state {
    
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
    
    if (state == UIGestureRecognizerStateBegan) {
        self.originalLevel = model.level;
        [self.improver beginImproving];
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:deviceId channel:channel withLevel:self.originalLevel withState:state direction:PanGestureMoveDirectionHorizontal];
        return;
    }
    if (state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateEnded) {
        NSInteger updateLevel = [self.improver improveTouching:touchPoint referencePoint:origin primaryBrightness:[self.originalLevel integerValue]];
        CGFloat percentage = updateLevel/255.0*100;
        [self showControlMaskLayerWithAlpha:updateLevel/255.0 text:[NSString stringWithFormat:@"%.f",percentage]];
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:deviceId channel:channel withLevel:@(updateLevel) withState:state direction:PanGestureMoveDirectionHorizontal];
        
        if (state == UIGestureRecognizerStateEnded) {
            [self hideControlMaskLayer];
        }
        
        return;
    }
}

- (void)showControlMaskLayerWithAlpha:(CGFloat)percentage text:(NSString*)text {
    if (!_maskLayer.superview) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication].keyWindow addSubview:self.maskLayer];
        });
    }
    
    [self.maskLayer updateProgress:percentage withText:text];
}

- (void)hideControlMaskLayer {
    if (_maskLayer && _maskLayer.superview) {
        [self.maskLayer removeFromSuperview];
    }
}

- (ControlMaskView*)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [[ControlMaskView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _maskLayer;
}

@end
