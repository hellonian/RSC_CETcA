//
//  VisualFloorOrganizeController.m
//  BluetoothTest
//
//  Created by hua on 9/1/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "VisualFloorOrganizeController.h"
#import "PureLayout.h"
#import "CameraAndAlbum.h"
#import "ConfiguredDeviceListController.h"
#import "CameraAndAlbumController.h"

@interface VisualFloorOrganizeController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate,VisualControlContentViewDelegate>

@property (nonatomic,strong) UIButton *cameraButton;
@property (nonatomic,strong) UIButton *listButton;

@end

@implementation VisualFloorOrganizeController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgImage"]];
    imageView.frame = [UIScreen mainScreen].bounds;
    [self.view addSubview:imageView];
    self.floorDelegate = [[Floor alloc] init];
    [self layoutView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)layoutView {
    self.content = [[VisualControlContentView alloc] initWithFrame:CGRectZero];
    [self.content enableEdit];
    self.content.delegate = self;
    [self.view addSubview:self.content];
    
    [self.content autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(64, 0, 0, 0) excludingEdge:ALEdgeBottom];
    self.bottomLayout = [self.content autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.view withOffset:0];
    
    [self stepOn:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *camera = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self openCamera];
            [alertController dismissViewControllerAnimated:YES completion:nil];
        }];
        UIAlertAction *album = [UIAlertAction actionWithTitle:@"Choose from Album" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self openGllery];
            [alertController dismissViewControllerAnimated:YES completion:nil];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:camera];
        [alertController addAction:album];
        [alertController addAction:cancel];
        
        UIPopoverPresentationController *popover = alertController.popoverPresentationController;
        
        if (popover) {
            
            popover.sourceView = self.view;
            popover.sourceRect = CGRectMake([UIScreen mainScreen].bounds.size.width*0.3,[UIScreen mainScreen].bounds.size.height*0.5,1.0,1.0);
            popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
        }
        
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

#pragma mark - Public

- (void)setOrganizingHandle:(VisualFloorOrganizeHandle)handle {
    _handle = handle;
}

#pragma mark - Step 

-(void)openGllery{
    CGFloat margin = 10;
    CGFloat space = 10;
    CGFloat unit = 64;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    layout.sectionInset = UIEdgeInsetsMake(margin, margin, margin, margin);
    layout.minimumLineSpacing = space;
    layout.minimumInteritemSpacing = space;
    layout.itemSize = CGSizeMake(unit, unit);
    
    CameraAndAlbumController *picker = [[CameraAndAlbumController alloc]initWithCollectionViewLayout:layout];
    [picker setCompletionHandler:^(UIImage *fetchImage){
        //base on image's geometry
        if (self.photoGeometry>1) {
            CGFloat fixH = self.view.bounds.size.height-self.view.bounds.size.width/self.photoGeometry;
            self.bottomLayout.constant = -fixH;
        }
        self.content.image = fetchImage;
        self.floorDelegate.floorImage = fetchImage;
        [self stepOn:2];
    }];
    
    [self.navigationController pushViewController:picker animated:YES];
}
- (void)openCamera {
    CameraAndAlbum *camera = [[CameraAndAlbum alloc]initCamera];
    camera.delegate = self;
    [camera setPickerHandler:^(UIImage *picture){
        //base on image's geometry
        if (self.photoGeometry>1) {
            CGFloat fixH = self.view.bounds.size.height-self.view.bounds.size.width/self.photoGeometry;
            self.bottomLayout.constant = -fixH;
        }
        self.content.image = picture;
        self.floorDelegate.floorImage = picture;
        [self stepOn:2];
    }];
    
    [self presentViewController:camera animated:YES completion:nil];
}

- (void)openDeviceList {
    ConfiguredDeviceListController *list = [[ConfiguredDeviceListController alloc] initWithItemPerSection:3 cellIdentifier:@"LightClusterCell"];
    list.fromStr = @"gallery";
    [list setSelectMode:Single];
    [list setSelectDeviceHandle:^(NSArray *selectedDevice) {
        if (selectedDevice.count>0) {
            NSNumber *deviceId = selectedDevice[0];
            
            ImageDropButton *button = [[ImageDropButton alloc]initWithFrame:CGRectMake(16, 16, 128, 128)];
            button.deviceId = deviceId;
            [self.content addLightRepresentation:button];
            if (!self.isEdit) {
                [self stepOn:3];
            }else{
                [self editAddItem];
            }
        }
    }];
    [self.navigationController pushViewController:list animated:YES];
}

- (void)connectLightToImageButton {
    if (self.handle) {
        __weak VisualFloorOrganizeController *weakSelf = self;
        [self fixPositionOfRepresentation];
        
        CGSize origin = self.content.bounds.size;
        self.content.layoutSize = origin;
        
        //base on the image's geometry
        if (origin.width<origin.height) {
            self.content.bounds = CGRectMake(0, 0, origin.width*0.5, origin.height*0.5);
            self.content.layoutSize = CGSizeMake(origin.width*0.5, origin.height*0.5);
        }
        else {
            CGSize fixSize = CGSizeMake(origin.width-36*2, (origin.width-36*2)/self.photoGeometry);
            self.content.bounds = CGRectMake(0, 0, fixSize.width, fixSize.height);
            self.content.layoutSize = fixSize;
        }
        
        self.floorDelegate.layoutSize = self.content.layoutSize;
        
        NSString *index = [self nextVisualControlIndex];
        self.content.visualControlIndex = index;
        self.floorDelegate.floorIndex = index;
        
        [self.content.subviews enumerateObjectsUsingBlock:^(UIView *subview,NSUInteger idx,BOOL *stop){
            if ([subview isKindOfClass:[ImageDropButton class]]) {
                ImageDropButton *button = (ImageDropButton*)subview;
                [self.floorDelegate.light addObject:button];
            }
        }];

        [self addVisualControlData:[self.floorDelegate archive] withIndex:index];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        self.handle(weakSelf.content);    //insert
        [self.navigationController popViewControllerAnimated:YES];
        
    }
    
}

- (NSString*)nextVisualControlIndex {
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    CGFloat index = [center floatForKey:@"com.actec.bluetooth.visualControlIndex"] + 1;
    [center setFloat:index forKey:@"com.actec.bluetooth.visualControlIndex"];
    [center synchronize];
    return [NSString stringWithFormat:@"VisualControlIndex%f",index];
}

- (void)addVisualControlData:(NSData*)data withIndex:(nonnull NSString *)index {
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    NSDictionary *record = [center dictionaryForKey:@"com.actec.bluetooth.visualControlKey"];
    
    if (record) {
        NSMutableDictionary *updated = [[NSMutableDictionary alloc] initWithDictionary:record];
        [updated setObject:data forKey:index];
        
        [center setObject:updated forKey:@"com.actec.bluetooth.visualControlKey"];
        return;
    }
    [center setObject:@{index:data} forKey:@"com.actec.bluetooth.visualControlKey"];
}

- (void)fixPositionOfRepresentation {
    for (UIView *subview in self.content.subviews) {
        if ([subview isKindOfClass:[ImageDropButton class]]) {
            //store relative position
            CGFloat leftRatio = subview.center.x/self.content.bounds.size.width;
            CGFloat topRatio = subview.center.y/self.content.bounds.size.height;
            CGFloat sizeRatio = subview.bounds.size.width/self.content.bounds.size.width;
            
            ImageDropButton *representation = (ImageDropButton*)subview;
            [representation markPosition:leftRatio relativeTop:topRatio sizeRatio:sizeRatio];
        }
    }
}

#pragma mark - Tutorial

- (void)stepOn:(NSInteger)step {
    if (self.navigationItem.rightBarButtonItems.count+1 != step) {
        return;
    }
    
    switch (step) {
        case 1:
        {
            UIBarButtonItem *cameraItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(openCamera)];
            self.navigationItem.rightBarButtonItem = cameraItem;
            self.navigationItem.title = @"Take Photo";
            break;
        }
        case 2:
        {
            NSMutableArray *items = [[NSMutableArray alloc]init];
            UIBarButtonItem *listItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(openDeviceList)];
            [items addObjectsFromArray:self.navigationItem.rightBarButtonItems];
            [items insertObject:listItem atIndex:0];
            self.navigationItem.rightBarButtonItems = items;
            self.navigationItem.title = @"Select Device";
            break;
        }
        case 3:
        {
            NSMutableArray *items = [[NSMutableArray alloc]init];
            UIBarButtonItem *connectItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"link"] style:UIBarButtonItemStylePlain target:self action:@selector(connectLightToImageButton)];
            [items addObjectsFromArray:self.navigationItem.rightBarButtonItems];
            [items insertObject:connectItem atIndex:0];
            self.navigationItem.rightBarButtonItems = items;
            self.navigationItem.title = @"Set Connection";
            break;
        }
        default:
            break;
    }  
}

- (void)editAddItem {
    UIBarButtonItem *listItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(openDeviceList)];
    UIBarButtonItem *connectItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"link"] style:UIBarButtonItemStylePlain target:self action:@selector(connectLightToImageButton)];
    self.navigationItem.rightBarButtonItems = @[connectItem,listItem];
}

#pragma mark - VisualControlContentView Delegate

- (void)visualControlContentViewRequireDeletingLightRepresentation:(UIView *)representation {
    ImageDropButton *button = (ImageDropButton*)representation;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Are you sure to remove this light representaion?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.content removeLightRepresentation:representation];
        if ([self.floorDelegate.light containsObject:button]) {
            [self.floorDelegate.light removeObject:button];
        }
    }];
    [alert addAction:cancel];
    [alert addAction:confirm];
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark - Camera Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [self dismissViewControllerAnimated:YES completion:^{
        UIImage *pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        self.photoGeometry = pickedImage.size.width/pickedImage.size.height;
        CameraAndAlbum *camera = (CameraAndAlbum*)picker;
        [camera performPickerHandlerWithImage:pickedImage];
    }];
}

@end
