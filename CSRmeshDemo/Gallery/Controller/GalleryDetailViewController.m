//
//  GalleryDetailViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/2.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "GalleryDetailViewController.h"
#import "ConfiguredDeviceListController.h"
#import "GalleryDropView.h"
#import "CSRDatabaseManager.h"
#import "GalleryEntity.h"
#import "CSRAppStateManager.h"
#import "DropEntity.h"
#import "CSRDeviceEntity.h"
#import "GalleryControlImageView.h"


@interface GalleryDetailViewController ()<GalleryControlImageViewDelegate>

@property (nonatomic, copy) GalleryControlImageView *controlImageView;
@property (nonatomic, assign) BOOL isSelected;

@end

@implementation GalleryDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgImage"]];
    imageView.frame = [UIScreen mainScreen].bounds;
    [self.view addSubview:imageView];
    
    [self prepareNavigationItem];
    
    _controlImageView = [[GalleryControlImageView alloc] init];
    _controlImageView.delegate = self;
    _controlImageView.center = CGPointMake(WIDTH/2, (HEIGHT-64-50)/2+64);
    
    if (_image) {
        
        _controlImageView.image = _image;
        _controlImageView.isEditing = YES;
        CGFloat fixelW = CGImageGetWidth(_image.CGImage);
        CGFloat fixelH = CGImageGetHeight(_image.CGImage);
        if (fixelW/fixelH > WIDTH/(HEIGHT-64-50)) {
            _controlImageView.bounds = CGRectMake(0, 0, WIDTH, fixelH/fixelW*WIDTH);
        }else {
            _controlImageView.bounds = CGRectMake(0, 0, fixelW/fixelH*(HEIGHT-64-50), HEIGHT-64-50);
        }
        
        
    }
    else if (_galleryId)
    {
        _controlImageView.isEditing = NO;
        [_controlImageView.deleteButton setHidden:YES];
        NSArray *gallerys = [[CSRAppStateManager sharedInstance].selectedPlace.gallerys allObjects];
        [gallerys enumerateObjectsUsingBlock:^(GalleryEntity *galleryEntity, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([galleryEntity.galleryID isEqualToNumber:_galleryId]) {
                UIImage *myImage = [UIImage imageWithData:galleryEntity.galleryImage];
                _controlImageView.image = myImage;
                CGFloat fixelW = CGImageGetWidth(myImage.CGImage);
                CGFloat fixelH = CGImageGetHeight(myImage.CGImage);
                if (fixelW/fixelH > WIDTH/(HEIGHT-64-50)) {
                    _controlImageView.bounds = CGRectMake(0, 0, WIDTH, fixelH/fixelW*WIDTH);
                }else {
                    _controlImageView.bounds = CGRectMake(0, 0, fixelW/fixelH*(HEIGHT-64-50), HEIGHT-64-50);
                }
                if (galleryEntity.drops != nil && [galleryEntity.drops count] > 0) {
                    for (DropEntity * dropEntity in galleryEntity.drops) {
                        [_controlImageView addDropViewInRightLocation:dropEntity];
                    }
                }
                *stop = YES;
            }
        }];
    }

    
    [self.view addSubview:_controlImageView];
}

- (void)prepareNavigationItem {
    _controlImageView.isEditing = _isEditing;
    if (_isEditing) {
        self.navigationItem.title = @"Editing";
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(galleryDetailDoneAction:)];
        UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(galleryAddAction:)];
        self.navigationItem.rightBarButtonItem = done;
        self.navigationItem.leftBarButtonItem = add;
        
    }else {
        self.navigationItem.title = @"Controlling";
        UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(galleryDetailEditAction:)];
        self.navigationItem.rightBarButtonItem = edit;
        UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(galleryDetailCloseAction:)];
        self.navigationItem.leftBarButtonItem = close;
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
    if (self.handle) {
        self.handle();
    }
    [UIView transitionWithView:self.navigationController.view duration:1 options:UIViewAnimationOptionTransitionFlipFromLeft animations:nil completion:nil];
    [self.navigationController popViewControllerAnimated:NO]; 
}

- (void)galleryDetailDoneAction:(UIBarButtonItem *)item {
    _isEditing = NO;
    [self prepareNavigationItem];
    
    NSNumber *galleryIdNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"GalleryEntity"];
    
    float boundWR = 0.549 * _controlImageView.bounds.size.width/_controlImageView.bounds.size.height;

    GalleryEntity *galleryEntity = [[CSRDatabaseManager sharedInstance] saveNewGallery:galleryIdNumber galleryImage:_image galleryBoundeWR:@(boundWR) galleryBoundHR:@(0.549) newGalleryId:nil];

    [[CSRAppStateManager sharedInstance].selectedPlace addGallerysObject:galleryEntity];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
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
            
            DropEntity *dropEntity = [[CSRDatabaseManager sharedInstance] saveNewDrop:dropIdNumber device:device dropBoundRatio:@(boundR) centerXRatio:@(centerXR) centerYRatio:@(centerYR) galleryId:galleryIdNumber];
            
            if (dropEntity) {
                [galleryEntity addDropsObject:dropEntity];
                [[CSRDatabaseManager sharedInstance] saveContext];
            } 
        }
    }];
    
}

- (void)galleryAddAction:(UIBarButtonItem *)item {
    ConfiguredDeviceListController *list = [[ConfiguredDeviceListController alloc] initWithItemPerSection:3 cellIdentifier:@"LightClusterCell"];
    [list setSelectMode:Single];
    [list setSelectDeviceHandle:^(NSArray *selectedDevice) {
        if (selectedDevice.count > 0) {
            NSNumber *deviceId = selectedDevice[0];
            
            GalleryDropView *dropView = [[GalleryDropView alloc] initWithFrame:CGRectMake(0, 0, 128, 128)];
            dropView.deviceId = deviceId;
            dropView.isEditing = YES;
            [_controlImageView addDropViewInCenter:dropView];
        
        }
    }];
    [self.navigationController pushViewController:list animated:YES];
    
}

- (void)galleryDeleteAction:(UIBarButtonItem *)item {
    
}

#pragma mark - GalleryControlImageViewDelegate

- (void)galleryControlImageViewDeleteDropView:(UIView *)view {
    GalleryDropView *dropView = (GalleryDropView *)view;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Remove light?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *removeAction = [UIAlertAction actionWithTitle:@"REMOVE" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [_controlImageView deleteDropView:view];
        
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:removeAction];
    [self presentViewController:alertController animated:YES completion:nil];
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