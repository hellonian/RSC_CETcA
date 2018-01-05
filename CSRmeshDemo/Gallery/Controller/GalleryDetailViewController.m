//
//  GalleryDetailViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/2.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "GalleryDetailViewController.h"
#import "GalleryControlImageView.h"
#import "ConfiguredDeviceListController.h"
#import "GalleryDropView.h"
#import "CSRDatabaseManager.h"
#import "GalleryEntity.h"
#import "CSRAppStateManager.h"
#import "DropEntity.h"
#import "CSRDeviceEntity.h"

@interface GalleryDetailViewController ()<GalleryControlImageViewDelegate>

@property (nonatomic, strong) GalleryControlImageView *controlImageView;
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
    
    if (_image) {
        _controlImageView = [[GalleryControlImageView alloc] init];
        _controlImageView.delegate = self;
        _controlImageView.image = _image;
        _controlImageView.center = CGPointMake(WIDTH/2, (HEIGHT-64-50)/2+64);
        _controlImageView.isEditing = YES;
        CGFloat fixelW = CGImageGetWidth(_image.CGImage);
        CGFloat fixelH = CGImageGetHeight(_image.CGImage);
        if (fixelW/fixelH > WIDTH/(HEIGHT-64-50)) {
            _controlImageView.bounds = CGRectMake(0, 0, WIDTH, fixelH/fixelW*WIDTH);
        }else {
            _controlImageView.bounds = CGRectMake(0, 0, fixelW/fixelH*(HEIGHT-64-50), HEIGHT-64-50);
        }
        [self.view addSubview:_controlImageView];
    }
    
    
    
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
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)galleryDetailEditAction:(UIBarButtonItem *)item {
    _isEditing = YES;
    [self prepareNavigationItem];
    
}

- (void)galleryDetailDoneAction:(UIBarButtonItem *)item {
    _isEditing = NO;
    [self prepareNavigationItem];
    
    NSNumber *galleryIdNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"GalleryEntity"];
    
    float boundWR = 0.288 * _controlImageView.bounds.size.width/_controlImageView.bounds.size.height;

    GalleryEntity *galleryEntity = [[CSRDatabaseManager sharedInstance] saveNewGallery:galleryIdNumber galleryImage:_image galleryBoundeWR:@(boundWR) galleryBoundHR:@(0.288)];

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
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert!" message:@"Are you sure to remove this light representaion?" preferredStyle:UIAlertControllerStyleAlert];
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
