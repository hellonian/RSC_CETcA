//
//  GalleryViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/2.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "GalleryViewController.h"
#import "GalleryDetailViewController.h"
#import "CSRAppStateManager.h"
#import "GalleryEntity.h"
#import "DropEntity.h"
#import "GalleryControlImageView.h"
#import "GalleryDropView.h"
#import "CSRDatabaseManager.h"
#import "GalleryEditToolView.h"
#import <MBProgressHUD.h>

@interface GalleryViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate,GalleryEditToolViewDelegate,GalleryControlImageViewDelegate,MBProgressHUDDelegate>

@property (nonatomic,strong) NSMutableArray *galleryEntitys;
@property (nonatomic,strong) NSMutableArray *controlImageViewArray;
@property (nonatomic,strong) NSMutableArray *toolViewArray;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic,assign) BOOL isEditing;
@property (nonatomic,assign) NSInteger adjustRow;
@property (nonatomic,assign) float adjustHeight;
@property (nonatomic,assign) BOOL isChange;
@property (nonatomic,strong) MBProgressHUD *hud;
@end

@implementation GalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationItem.title = @"Gallery";
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(galleryEditAction:)];
    self.navigationItem.rightBarButtonItem = edit;
    self.navigationItem.leftBarButtonItem = nil;
    _isEditing = NO;
    _adjustRow = -1;
    _adjustHeight = -1.0f;
    
    [self getData];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

#pragma mark - actions

- (void)galleryEditAction:(UIBarButtonItem *)item {
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(galleryDoneAction:)];
    self.navigationItem.rightBarButtonItem = done;
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(galleryAddAction:)];
    self.navigationItem.leftBarButtonItem = add;
    _isEditing = YES;
    
    [UIView animateWithDuration:0.5 animations:^{
        [self layoutViewRightFrame];
    }];
    
    [self.controlImageViewArray enumerateObjectsUsingBlock:^(GalleryControlImageView *controlImageView, NSUInteger idx, BOOL * _Nonnull stop) {
        [controlImageView addPanGestureRecognizer];
    }];
    
    _isChange = NO;
    
}

- (void)galleryDoneAction:(UIBarButtonItem *)item {
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.mode = MBProgressHUDModeIndeterminate;
    _hud.delegate = self;
    
    [self performSelector:@selector(doneAction) withObject:nil afterDelay:0.01];

}

- (void)doneAction {
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(galleryEditAction:)];
    self.navigationItem.rightBarButtonItem = edit;
    self.navigationItem.leftBarButtonItem = nil;
    _isEditing = NO;
    
    __weak GalleryViewController *weakSelf = self;
    [UIView animateWithDuration:0.5 animations:^{
        
        [weakSelf layoutViewRightFrame];
    }];
    
    
    
    [self.controlImageViewArray enumerateObjectsUsingBlock:^(GalleryControlImageView *controlImageView, NSUInteger idx, BOOL * _Nonnull stop) {
        [controlImageView removePanGestureRecognizer];
        if (_isChange) {
            [[CSRDatabaseManager sharedInstance] saveNewGallery:controlImageView.galleryId galleryImage:controlImageView.image galleryBoundeWR:@(controlImageView.bounds.size.width/WIDTH) galleryBoundHR:@(controlImageView.bounds.size.height/WIDTH) newGalleryId:@(idx+1)];
        }
    }];
    
    [self.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[GalleryDropView class]]) {
            [obj removeFromSuperview];
        }
    }];
    
    [_hud hideAnimated:YES];
}

- (void)galleryAddAction:(UIBarButtonItem *)item {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *camera = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self alertAction:0];
        
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction *album = [UIAlertAction actionWithTitle:@"Choose from Album" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self alertAction:1];
        
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:camera];
    [alert addAction:album];
    [alert addAction:cancel];
    
    alert.popoverPresentationController.barButtonItem = self.navigationItem.leftBarButtonItem;
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)alertAction:(NSInteger)tag {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePickerController.delegate = self;
        imagePickerController.allowsEditing = YES;
        if (tag == 0) {
            imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }
        if (tag == 1) {
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }
    }else {
        imagePickerController.delegate = self;
        imagePickerController.allowsEditing = YES;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

#pragma mark - <GalleryControlImageViewDelegate>

- (void) galleryControlImageViewDeleteAction:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Remove photo?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *removeAction = [UIAlertAction actionWithTitle:@"REMOVE" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        GalleryControlImageView *controlImageView = (GalleryControlImageView *)sender;
        
        [controlImageView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[GalleryDropView class]]) {
                GalleryDropView *dropView = (GalleryDropView *)obj;
                DropEntity *dropEntity = [[[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"DropEntity" withPredicate:@"dropID == %@",dropView.dropId] firstObject];
                if (dropEntity) {
                    [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:dropEntity];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }
            }
        }];
        
        GalleryEntity *galleryEntity = [[[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"GalleryEntity" withPredicate:@"galleryID == %@",controlImageView.galleryId] firstObject];
        
        if (galleryEntity) {
            [[CSRAppStateManager sharedInstance].selectedPlace removeGallerysObject:galleryEntity];
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:galleryEntity];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
        
        [self getData];
        
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:removeAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)galleryControlImageViewAdjustLocation:(id)sender oldRect:(CGRect)oldRect {
    _isChange = YES;
    GalleryControlImageView *strongControlImageView = (GalleryControlImageView *)sender;
    if ([self inOldPlace:oldRect newRect:strongControlImageView.frame]) {
        [UIView animateWithDuration:0.3 animations:^{
            strongControlImageView.frame = oldRect;
        }];
        return;
    }
    
    __block GalleryControlImageView *controlImageView = strongControlImageView;
    [self.toolViewArray enumerateObjectsUsingBlock:^(GalleryEditToolView * toolView, NSUInteger idx, BOOL * _Nonnull stop) {

        if (toolView.center.y > controlImageView.center.y) {
            CGFloat boundH;
            if (toolView.tag == 100) {
                boundH = toolView.center.y-20-1/17.0*WIDTH;
                
            }else {
                GalleryEditToolView *lastToolView = self.toolViewArray[idx-1];
                boundH = toolView.center.y-40-lastToolView.center.y;
            }
            controlImageView.bounds = CGRectMake(controlImageView.bounds.origin.x, controlImageView.bounds.origin.y, boundH*controlImageView.bounds.size.width/controlImageView.bounds.size.height, boundH);
            
            __block BOOL isLastOne = YES;
            [self.controlImageViewArray enumerateObjectsUsingBlock:^(GalleryControlImageView *control, NSUInteger index, BOOL * _Nonnull stop) {
                
                if (toolView.tag == 100) {
                    if (control.center.y > 0) {
                        if (control.center.x > controlImageView.center.x || control.center.y>toolView.center.y) {
                            [self.controlImageViewArray removeObjectAtIndex:controlImageView.tag];
                            [self.controlImageViewArray insertObject:controlImageView atIndex:control.tag];
                            __weak GalleryViewController *weakSelf = self;
                            [UIView animateWithDuration:0.5 animations:^{
                                [weakSelf layoutViewRightFrame];
                            }];
                            isLastOne = NO;
                            *stop = YES;
                        }
                    }
                }
                else {
                    GalleryEditToolView *lastToolView2 = self.toolViewArray[idx-1];
                    if (control.center.y > lastToolView2.center.y) {
                        if (control.center.x > controlImageView.center.x || control.center.y>toolView.center.y) {
                            [self.controlImageViewArray removeObjectAtIndex:controlImageView.tag];
                            [self.controlImageViewArray insertObject:controlImageView atIndex:control.tag];
                            __weak GalleryViewController *weakSelf = self;
                            [UIView animateWithDuration:0.5 animations:^{
                                [weakSelf layoutViewRightFrame];
                            }];
                            isLastOne = NO;
                            *stop = YES;
                        }
                    }
                }

            }];
            
            if (isLastOne) {
                [self.controlImageViewArray removeObjectAtIndex:controlImageView.tag];
                [self.controlImageViewArray addObject:controlImageView];
                __weak GalleryViewController *weakSelf = self;
                [UIView animateWithDuration:0.5 animations:^{
                    [weakSelf layoutViewRightFrame];
                }];
            }
            
            *stop = YES;
        }
    }];
    
    
}

- (BOOL)inOldPlace:(CGRect)oldRect newRect:(CGRect)newRect{
    float distanceX = newRect.origin.x - oldRect.origin.x;
    float distanceY = newRect.origin.y - oldRect.origin.y;
    if (fabsf(distanceX) < oldRect.size.width && fabsf(distanceY) < oldRect.size.height/2+20) {
        return YES;
    }
    return NO;
}

- (void)galleryControlImageViewPresentDetailViewAction:(id)sender {
    NSNumber *galleryId = (NSNumber *)sender;
    
    GalleryDetailViewController *detailVC = [[GalleryDetailViewController alloc] init];
    detailVC.galleryId = galleryId;
    [self.navigationController pushViewController:detailVC animated:NO];
    [UIView transitionWithView:self.navigationController.view duration:1 options:UIViewAnimationOptionTransitionFlipFromRight animations:nil completion:nil];
}

#pragma mark - <UINavigationControllerDelegate,UIImagePickerControllerDelegate>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    GalleryDetailViewController *gdvc = [[GalleryDetailViewController alloc] init];
    gdvc.image = [self fixOrientation:image];
    gdvc.isEditing = YES;
    gdvc.handle = ^{
        NSLog(@"block");
        [self getData];
    };
    [self.navigationController pushViewController:gdvc animated:NO];
    
    
}

//相机拍的照片带有imageOrientation属性，在显示的时候会自动摆正方向，而存放的时候按统一方向存放，开发使用时需摆正方向。
- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

#pragma mark - getData

- (void)getData {
    
    NSMutableArray *galleryMutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.gallerys allObjects] mutableCopy];
    if (galleryMutableArray != nil || [galleryMutableArray count] != 0 ) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"galleryID" ascending:YES];
        [galleryMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        
        self.galleryEntitys = galleryMutableArray;
        
    }
    
    [self firstLayoutView];
    
}

#pragma mark - layoutView

- (void)layoutViewRightFrame {

    __block float rowHeight = 0;
    __block float allWidth = 1/17.0;
    __block float allHeight = 1/17.0;
    __block float verticalInterVal;
    __block NSInteger rowIdx = 0;
    if (_isEditing) {
        verticalInterVal = 40.0/WIDTH;
    }else{
        verticalInterVal = 1/17.0;
    }
    
    [self.controlImageViewArray enumerateObjectsUsingBlock:^(GalleryControlImageView *controlImageView, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [controlImageView.deleteButton setHidden:!_isEditing];
        
        if (idx == 0) {
            if (_adjustRow == 0) {
                rowHeight = _adjustHeight - 1/17.0 - verticalInterVal;
            }else {
                rowHeight = controlImageView.bounds.size.height/WIDTH;
            }
            
            if (rowHeight > (1-2/17.0)/4.0*3.0) {
                rowHeight = (1-2/17.0)/4.0*3.0;
                [self limitToolViewWithRowIdx:rowIdx withHeight:allHeight + rowHeight + verticalInterVal];
            }
            if (rowHeight < 78/289.0) {
                rowHeight = 78/289.0;
                [self limitToolViewWithRowIdx:rowIdx withHeight:allHeight + rowHeight + verticalInterVal];
            }
            
        }
        float boundW = controlImageView.bounds.size.width/controlImageView.bounds.size.height*rowHeight;
        allWidth = allWidth + boundW + 1/17.0;
        if (allWidth > 1.0) {
            rowIdx++;
            
            if (rowIdx == _adjustRow) {
                float oldRowHeight = rowHeight;
                rowHeight = _adjustHeight - allHeight - rowHeight - 2*verticalInterVal;
                
                if (rowHeight > (1-2/17.0)/4.0*3.0) {
                    rowHeight = (1-2/17.0)/4.0*3.0;
                    [self limitToolViewWithRowIdx:rowIdx withHeight:allHeight + oldRowHeight + 2*verticalInterVal + rowHeight];
                }
                if (rowHeight < 78/289.0) {
                    rowHeight = 78/289.0;
                    [self limitToolViewWithRowIdx:rowIdx withHeight:allHeight + oldRowHeight + 2*verticalInterVal + rowHeight];
                    
                }
                
                allHeight = allHeight + oldRowHeight + verticalInterVal;
                boundW = controlImageView.bounds.size.width/controlImageView.bounds.size.height*rowHeight;
            }else {
                allHeight = allHeight + rowHeight + verticalInterVal;
                rowHeight = controlImageView.bounds.size.height/WIDTH;
                boundW = controlImageView.bounds.size.width/WIDTH;
            }
            
            
            
            allWidth = 1/17.0 + boundW + 1/17.0;
            controlImageView.frame = CGRectMake(1/17.0 * WIDTH, allHeight * WIDTH, boundW * WIDTH, rowHeight * WIDTH);
            controlImageView.tag = idx;
            [controlImageView adjustDropViewInRightLocation];
            if (_adjustRow != rowIdx) {
                if (rowIdx < [self.toolViewArray count]) {
                    [self.toolViewArray enumerateObjectsUsingBlock:^(GalleryEditToolView * toolView, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (toolView.tag == rowIdx + 100) {
                            if (_isEditing) {
                                toolView.center = CGPointMake(WIDTH/2, (allHeight+rowHeight) * WIDTH + 20);
                                [self.scrollView addSubview:toolView];
                                [self.scrollView sendSubviewToBack:toolView];
                            }else {
                                [toolView removeFromSuperview];
                            }
                            *stop = YES;
                        }
                    }];
                }else {
                    GalleryEditToolView *toolView = [self addEditToolView:allHeight+rowHeight rowIdx:rowIdx + 100];
                    [self.scrollView addSubview:toolView];
                }
                
            }
            
        }else {
            if (idx==0) {
                controlImageView.frame = CGRectMake(1/17.0 * WIDTH, allHeight * WIDTH, boundW * WIDTH, rowHeight * WIDTH);
                controlImageView.tag = idx;
                [controlImageView adjustDropViewInRightLocation];
                if (_adjustRow != 0) {
                    [self.toolViewArray enumerateObjectsUsingBlock:^(GalleryEditToolView * toolView, NSUInteger idx, BOOL * _Nonnull stop) {
                        
                        if (toolView.tag == rowIdx + 100) {
                            if (_isEditing) {
                                toolView.center = CGPointMake(WIDTH/2, (allHeight+rowHeight) * WIDTH + 20);
                                [self.scrollView addSubview:toolView];
                                [self.scrollView sendSubviewToBack:toolView];
                            }else {
                                [toolView removeFromSuperview];
                            }
                            *stop = YES;
                        }
                    }];
                }
                
            }else {
                controlImageView.frame = CGRectMake((allWidth-boundW-1/17.0) * WIDTH, allHeight * WIDTH, boundW * WIDTH, rowHeight * WIDTH);
                controlImageView.tag = idx;
                [controlImageView adjustDropViewInRightLocation];
            }
        }
    }];
    self.scrollView.contentSize = CGSizeMake(WIDTH, (allHeight+rowHeight+verticalInterVal)*WIDTH);
    
}

- (void)limitToolViewWithRowIdx:(NSInteger)rowIdx withHeight:(float)height {
    [self.toolViewArray enumerateObjectsUsingBlock:^(GalleryEditToolView * toolView, NSUInteger idx, BOOL * _Nonnull stop) {
        if (toolView.tag == rowIdx+100) {
            toolView.isLimitHeight = height;
            *stop = YES;
        }
    }];
}

- (void)firstLayoutView {
    [self.controlImageViewArray removeAllObjects];
    [self.toolViewArray removeAllObjects];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    __block float rowHeight = 0;
    __block float allWidth = 1/17.0;
    __block float allHeight = 1/17.0;
    __block float verticalInterVal;
    __block NSInteger rowIdx = 0;
    if (_isEditing) {
        verticalInterVal = 40.0/WIDTH;
    }else{
        verticalInterVal = 1/17.0;
    }
    
    [self.galleryEntitys enumerateObjectsUsingBlock:^(GalleryEntity *galleryEntity, NSUInteger idx, BOOL * _Nonnull stop) {
        
        CGRect controlImageViewFrame;
        if (idx == 0) {
            rowHeight = [galleryEntity.boundHeight floatValue];
        }
        float boundW = [galleryEntity.boundWidth floatValue]/[galleryEntity.boundHeight floatValue] * rowHeight;
        
        allWidth = allWidth + boundW + 1/17.0;
        
        if (allWidth > 1.0) {
            
            rowIdx++;
            
            allHeight = allHeight + rowHeight + verticalInterVal;
            rowHeight = [galleryEntity.boundHeight floatValue];
            boundW = [galleryEntity.boundWidth floatValue];
            allWidth = 1/17.0 + boundW + 1/17.0;
            
            controlImageViewFrame = CGRectMake(1/17.0 * WIDTH, allHeight * WIDTH, boundW * WIDTH, rowHeight * WIDTH);
            
            GalleryEditToolView *toolView = [self addEditToolView:allHeight+rowHeight rowIdx:rowIdx+100];
            if (_isEditing) {
                [self.scrollView addSubview:toolView];
            }
            
            
        }else {
            if (idx == 0) {
                controlImageViewFrame = CGRectMake(1/17.0 * WIDTH, allHeight * WIDTH, boundW * WIDTH, rowHeight * WIDTH);
                GalleryEditToolView *toolView = [self addEditToolView:allHeight+rowHeight rowIdx:rowIdx+100];
                if (_isEditing) {
                    [self.scrollView addSubview:toolView];
                }
            }else {
                controlImageViewFrame = CGRectMake((allWidth-boundW-1/17.0) * WIDTH, allHeight * WIDTH, boundW * WIDTH, rowHeight * WIDTH);
            }
        }
        
        [self addGalleryControlImageView:galleryEntity frame:controlImageViewFrame idx:idx];
        
    }];
    
    self.scrollView.contentSize = CGSizeMake(WIDTH, (allHeight+rowHeight+verticalInterVal)*WIDTH);
    
}

- (GalleryEditToolView *) addEditToolView:(float)value rowIdx:(NSInteger)rowIdx {
    
    GalleryEditToolView *toolView = [[GalleryEditToolView alloc] init];
    toolView.center = CGPointMake(WIDTH/2, value * WIDTH + 20);
    toolView.tag = rowIdx;
    toolView.delegate = self;
    
    [self.toolViewArray addObject:toolView];
    
    return toolView;
}

- (void) addGalleryControlImageView:(GalleryEntity *)galleryEntity frame:(CGRect)frame idx:(NSInteger)idx {
    GalleryControlImageView *controlImageView = [[GalleryControlImageView alloc] init];
    controlImageView.tag = idx;
    controlImageView.frame = frame;
    controlImageView.image = [UIImage imageWithData:galleryEntity.galleryImage];
    controlImageView.galleryId = galleryEntity.galleryID;
    controlImageView.delegate = self;
    [controlImageView.deleteButton setHidden:!_isEditing];
    if (galleryEntity.drops != nil && [galleryEntity.drops count] > 0) {
        for (DropEntity * dropEntity in galleryEntity.drops) {
            [controlImageView addDropViewInRightLocation:dropEntity];
        }
    }
    
    [self.scrollView addSubview:controlImageView];
    [self.controlImageViewArray addObject:controlImageView];
}

#pragma mark - GalleryEditToolViewDelegate

- (void)adjustControlImageSize:(NSInteger)row adjustHeight:(float)height {
    @synchronized (self) {
        _isChange = YES;
        _adjustRow = row;
        _adjustHeight = height;
        [self layoutViewRightFrame];
        _adjustRow = -1;
        _adjustHeight = -1.0f;
    }
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

#pragma mark - lazy

- (NSMutableArray *)controlImageViewArray {
    if (!_controlImageViewArray) {
        _controlImageViewArray = [[NSMutableArray alloc] init];
    }
    return _controlImageViewArray;
}

- (NSMutableArray *)toolViewArray {
    if (!_toolViewArray) {
        _toolViewArray = [[NSMutableArray alloc] init];
    }
    return _toolViewArray;
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