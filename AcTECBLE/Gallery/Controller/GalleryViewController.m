//
//  GalleryViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/1/2.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
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
#import "DeviceModelManager.h"
#import "ImproveTouchingExperience.h"
#import "ControlMaskView.h"
#import "CSRUtilities.h"
#import "PureLayout.h"

@interface GalleryViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate,GalleryEditToolViewDelegate,GalleryControlImageViewDelegate,MBProgressHUDDelegate,GalleryDropViewDelegate>

@property (nonatomic,strong) NSMutableArray *galleryEntitys;
@property (nonatomic,strong) NSMutableArray *controlImageViewArray;
@property (nonatomic,strong) NSMutableArray *toolViewArray;
//@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic,assign) BOOL isEditing;
@property (nonatomic,assign) NSInteger adjustRow;
@property (nonatomic,assign) float adjustHeight;
@property (nonatomic,assign) BOOL isChange;
@property (nonatomic,strong) MBProgressHUD *hud;
@property (nonatomic,strong) NSNumber *originalLevel;
@property (nonatomic,strong) ImproveTouchingExperience *improver;
@property (nonatomic,strong) ControlMaskView *maskLayer;
@property (strong, nonatomic) IBOutlet UIView *noneView;
@property (nonatomic,strong) UIScrollView *scrollView;


@end

@implementation GalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
//    if (@available(iOS 11.0, *)) {
//    } else {
//        self.automaticallyAdjustsScrollViewInsets = NO;
//        [_scrollView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64.0];
//        [_scrollView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:50.0];
//    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange) name:ZZAppLanguageDidChangeNotification object:nil];
    
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Gallery", @"Localizable");
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(galleryEditAction:)];
    self.navigationItem.rightBarButtonItem = edit;
    self.navigationItem.leftBarButtonItem = nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getData) name:@"reGetDataForPlaceChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteDeviceEntity) name:@"deleteDeviceEntity" object:nil];
    
    _scrollView = [[UIScrollView alloc] init];
    self.improver = [[ImproveTouchingExperience alloc] init];
    _isEditing = NO;
    _adjustRow = -1;
    _adjustHeight = -1.0f;
    
    [self getData];
}

- (void)deleteDeviceEntity {
    [self getData];
}

#pragma mark - actions

- (void)galleryEditAction:(UIBarButtonItem *)item {
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(galleryDoneAction:)];
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
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(galleryEditAction:)];
    self.navigationItem.rightBarButtonItem = edit;
    self.navigationItem.leftBarButtonItem = nil;
    _isEditing = NO;
    
    __weak GalleryViewController *weakSelf = self;
    [UIView animateWithDuration:0.5 animations:^{
        
        [weakSelf layoutViewRightFrame];
    }];
    
    if (_isChange) {
        [self.controlImageViewArray enumerateObjectsUsingBlock:^(GalleryControlImageView *controlImageView, NSUInteger idx, BOOL * _Nonnull stop) {
            [controlImageView removePanGestureRecognizer];
            
            GalleryEntity *gallery = [[CSRDatabaseManager sharedInstance] getGalleryEntityWithID:controlImageView.galleryId];
            gallery.sortId = @(idx);
            gallery.boundWidth = @(controlImageView.bounds.size.width/WIDTH);
            gallery.boundHeight = @(controlImageView.bounds.size.height/WIDTH);
            [[CSRDatabaseManager sharedInstance] saveContext];
        }];
    }
    
    [_hud hideAnimated:YES];
}

- (void)galleryAddAction:(UIBarButtonItem *)item {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *camera = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Camera", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self alertAction:0];
        
    }];
    UIAlertAction *album = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ChooseFromAlbum", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self alertAction:1];
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"" preferredStyle:UIAlertControllerStyleAlert];
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"RemovePhoto", @"Localizable")];
    [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
    [alertController setValue:attributedMessage forKey:@"attributedMessage"];
    [alertController.view setTintColor:DARKORAGE];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *removeAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Remove", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
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
    detailVC.isNewAdd = NO;
    detailVC.galleryId = galleryId;
    
    detailVC.handle = ^{
        [self getData];
    };
    
    UINavigationController *nav= [[UINavigationController alloc] initWithRootViewController:detailVC];
    [nav setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
    
}

#pragma mark - <UINavigationControllerDelegate,UIImagePickerControllerDelegate>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    GalleryDetailViewController *gdvc = [[GalleryDetailViewController alloc] init];
    gdvc.isNewAdd = YES;
    gdvc.image = [CSRUtilities fixOrientation:image];
    gdvc.isEditing = YES;
    gdvc.handle = ^{
        [self getData];
    };
    
    UINavigationController *nav= [[UINavigationController alloc] initWithRootViewController:gdvc];
    [nav setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:NO completion:nil];
}

#pragma mark - getData

- (void)getData {
    NSMutableArray *galleryMutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.gallerys allObjects] mutableCopy];
    if (galleryMutableArray != nil || [galleryMutableArray count] != 0 ) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
        [galleryMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        
        self.galleryEntitys = galleryMutableArray;
        
    }
    if ([self.galleryEntitys count] != 0) {
        [_noneView removeFromSuperview];
        [self.view addSubview:self.scrollView];
        [_scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSLayoutConstraint *top;
        NSLayoutConstraint *bottom;
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_scrollView
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1.0
                                                                 constant:0];
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_scrollView
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.view
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1.0
                                                                  constant:0];
        if (@available(iOS 11.0, *)) {
            top = [NSLayoutConstraint constraintWithItem:_scrollView
                                               attribute:NSLayoutAttributeTop
                                               relatedBy:NSLayoutRelationEqual
                                                  toItem:self.view.safeAreaLayoutGuide
                                               attribute:NSLayoutAttributeTop
                                              multiplier:1.0
                                                constant:0];
            bottom = [NSLayoutConstraint constraintWithItem:_scrollView
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view.safeAreaLayoutGuide
                                                  attribute:NSLayoutAttributeBottom
                                                 multiplier:1.0
                                                   constant:0];
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
            top = [NSLayoutConstraint constraintWithItem:_scrollView
                                               attribute:NSLayoutAttributeTop
                                               relatedBy:NSLayoutRelationEqual
                                                  toItem:self.view
                                               attribute:NSLayoutAttributeTop
                                              multiplier:1.0
                                                constant:0];
            bottom = [NSLayoutConstraint constraintWithItem:_scrollView
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeBottom
                                                 multiplier:1.0
                                                   constant:0];
        }
        [NSLayoutConstraint activateConstraints:@[top,left,bottom,right]];
        [self firstLayoutView];
    }else {
        [_scrollView removeFromSuperview];
        [self.view addSubview:_noneView];
        [_noneView setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSLayoutConstraint *top;
        NSLayoutConstraint *bottom;
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_noneView
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1.0
                                                                 constant:0];
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_noneView
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.view
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1.0
                                                                  constant:0];
        if (@available(iOS 11.0, *)) {
            top = [NSLayoutConstraint constraintWithItem:_noneView
                                               attribute:NSLayoutAttributeTop
                                               relatedBy:NSLayoutRelationEqual
                                                  toItem:self.view.safeAreaLayoutGuide
                                               attribute:NSLayoutAttributeTop
                                              multiplier:1.0
                                                constant:0];
            bottom = [NSLayoutConstraint constraintWithItem:_noneView
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view.safeAreaLayoutGuide
                                                  attribute:NSLayoutAttributeBottom
                                                 multiplier:1.0
                                                   constant:0];
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
            top = [NSLayoutConstraint constraintWithItem:_noneView
                                               attribute:NSLayoutAttributeTop
                                               relatedBy:NSLayoutRelationEqual
                                                  toItem:self.view
                                               attribute:NSLayoutAttributeTop
                                              multiplier:1.0
                                                constant:0];
            bottom = [NSLayoutConstraint constraintWithItem:_noneView
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeBottom
                                                 multiplier:1.0
                                                   constant:0];
        }
        [NSLayoutConstraint activateConstraints:@[top,left,bottom,right]];
    }
    
    
}

#pragma mark - layoutView

- (void)layoutViewRightFrame {

    __block float rowHeight = 0;
    __block float allWidth = 4/320.0;
    __block float allHeight = 4/320.0;
    __block float verticalInterVal;
    __block NSInteger rowIdx = 0;
    if (_isEditing) {
        verticalInterVal = 30.0/WIDTH;
    }else{
        verticalInterVal = 4/320.0;
    }
    
    [self.controlImageViewArray enumerateObjectsUsingBlock:^(GalleryControlImageView *controlImageView, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [controlImageView.deleteButton setHidden:!_isEditing];
        
        if (idx == 0) {
            if (_adjustRow == 0) {
                rowHeight = _adjustHeight - 4/320.0 - verticalInterVal;
            }else {
                rowHeight = controlImageView.bounds.size.height/WIDTH;
            }
            
//            if (rowHeight > (1-8/320.0)/4.0*3.0) {
//                rowHeight = (1-8/320.0)/4.0*3.0;
//                [self limitToolViewWithRowIdx:rowIdx withHeight:allHeight + rowHeight + verticalInterVal];
//            }
            if (rowHeight > (1-8/320.0)/controlImageView.bounds.size.width * controlImageView.bounds.size.height) {
                rowHeight = (1-8/320.0)/controlImageView.bounds.size.width * controlImageView.bounds.size.height;
                [self limitToolViewWithRowIdx:rowIdx withHeight:allHeight + rowHeight + verticalInterVal];
            }
            if (rowHeight < (1-4*4/320.0)/3.0/4.0*3.0) {
                rowHeight = (1-4*4/320.0)/3.0/4.0*3.0;
                [self limitToolViewWithRowIdx:rowIdx withHeight:allHeight + rowHeight + verticalInterVal];
            }
            
        }
        float boundW = controlImageView.bounds.size.width/controlImageView.bounds.size.height*rowHeight;
        allWidth = allWidth + boundW + 4/320.0;
        
        if (allWidth > 1.0) {
            rowIdx++;
            
            if (rowIdx == _adjustRow) {
                float oldRowHeight = rowHeight;
                rowHeight = _adjustHeight - allHeight - rowHeight - 2*verticalInterVal;
                
                if (rowHeight > (1-8/320.0)/controlImageView.bounds.size.width * controlImageView.bounds.size.height) {
                    rowHeight = (1-8/320.0)/controlImageView.bounds.size.width * controlImageView.bounds.size.height;
                    [self limitToolViewWithRowIdx:rowIdx withHeight:allHeight + oldRowHeight + 2*verticalInterVal + rowHeight];
                }
                if (rowHeight < (1-4*4/320.0)/3.0/4.0*3.0) {
                    rowHeight = (1-4*4/320.0)/3.0/4.0*3.0;
                    [self limitToolViewWithRowIdx:rowIdx withHeight:allHeight + oldRowHeight + 2*verticalInterVal + rowHeight];
                    
                }
                
                allHeight = allHeight + oldRowHeight + verticalInterVal;
                boundW = controlImageView.bounds.size.width/controlImageView.bounds.size.height*rowHeight;
            }else {
                allHeight = allHeight + rowHeight + verticalInterVal;
                rowHeight = controlImageView.bounds.size.height/WIDTH;
                boundW = controlImageView.bounds.size.width/WIDTH;
            }
            
            
            
            allWidth = 4/320.0 + boundW + 4/320.0;
            controlImageView.frame = CGRectMake(4/320.0 * WIDTH, allHeight * WIDTH, boundW * WIDTH, rowHeight * WIDTH);
            controlImageView.tag = idx;
            [controlImageView adjustDropViewInRightLocation];
            if (_adjustRow != rowIdx) {
                if (rowIdx < [self.toolViewArray count]) {
                    [self.toolViewArray enumerateObjectsUsingBlock:^(GalleryEditToolView * toolView, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (toolView.tag == rowIdx + 100) {
                            if (_isEditing) {
                                toolView.center = CGPointMake(WIDTH/2, (allHeight+rowHeight) * WIDTH + 15);
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
                controlImageView.frame = CGRectMake(4/320.0 * WIDTH, allHeight * WIDTH, boundW * WIDTH, rowHeight * WIDTH);
                controlImageView.tag = idx;
                [controlImageView adjustDropViewInRightLocation];
                if (_adjustRow != 0) {
                    [self.toolViewArray enumerateObjectsUsingBlock:^(GalleryEditToolView * toolView, NSUInteger idx, BOOL * _Nonnull stop) {
                        
                        if (toolView.tag == rowIdx + 100) {
                            if (_isEditing) {
                                toolView.center = CGPointMake(WIDTH/2, (allHeight+rowHeight) * WIDTH + 15);
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
                controlImageView.frame = CGRectMake((allWidth-boundW-4/320.0) * WIDTH, allHeight * WIDTH, boundW * WIDTH, rowHeight * WIDTH);
                controlImageView.tag = idx;
                [controlImageView adjustDropViewInRightLocation];
            }
            
            if (idx==[self.controlImageViewArray count]-1) {
                [self.toolViewArray enumerateObjectsUsingBlock:^(GalleryEditToolView * toolView, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (toolView.tag > rowIdx+100) {
                        [toolView removeFromSuperview];
                    }
                }];
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
    __block float allWidth = 4/320.0;
    __block float allHeight = 4/320.0;
    __block float verticalInterVal;
    __block NSInteger rowIdx = 0;
    if (_isEditing) {
        verticalInterVal = 30.0/WIDTH;
    }else{
        verticalInterVal = 4/320.0;
    }
    
    [self.galleryEntitys enumerateObjectsUsingBlock:^(GalleryEntity *galleryEntity, NSUInteger idx, BOOL * _Nonnull stop) {
        
        CGRect controlImageViewFrame;
        if (idx == 0) {
            rowHeight = [galleryEntity.boundHeight floatValue];
        }
        float boundW = [galleryEntity.boundWidth floatValue]/[galleryEntity.boundHeight floatValue] * rowHeight;
        
        allWidth = allWidth + boundW + 4/320.0;
        
        if (allWidth > 1.0) {
            
            rowIdx++;
            
            allHeight = allHeight + rowHeight + verticalInterVal;
            rowHeight = [galleryEntity.boundHeight floatValue];
            boundW = [galleryEntity.boundWidth floatValue];
            allWidth = 4/320.0 + boundW + 4/320.0;
            
            controlImageViewFrame = CGRectMake(4/320.0 * WIDTH, allHeight * WIDTH, boundW * WIDTH, rowHeight * WIDTH);
            
            GalleryEditToolView *toolView = [self addEditToolView:allHeight+rowHeight rowIdx:rowIdx+100];
            if (_isEditing) {
                [self.scrollView addSubview:toolView];
            }
            
            
        }else {
            if (idx == 0) {
                controlImageViewFrame = CGRectMake(4/320.0 * WIDTH, allHeight * WIDTH, boundW * WIDTH, rowHeight * WIDTH);
                GalleryEditToolView *toolView = [self addEditToolView:allHeight+rowHeight rowIdx:rowIdx+100];
                if (_isEditing) {
                    [self.scrollView addSubview:toolView];
                }
            }else {
                controlImageViewFrame = CGRectMake((allWidth-boundW-4/320.0) * WIDTH, allHeight * WIDTH, boundW * WIDTH, rowHeight * WIDTH);
            }
        }
        
        [self addGalleryControlImageView:galleryEntity frame:controlImageViewFrame idx:idx];
        
    }];
    
    self.scrollView.contentSize = CGSizeMake(WIDTH, (allHeight+rowHeight+verticalInterVal)*WIDTH);
    
}

- (GalleryEditToolView *) addEditToolView:(float)value rowIdx:(NSInteger)rowIdx {
    
    GalleryEditToolView *toolView = [[GalleryEditToolView alloc] init];
    toolView.center = CGPointMake(WIDTH/2, value * WIDTH + 15);
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
            GalleryDropView *dropView = [controlImageView addDropViewInRightLocation:dropEntity];
            dropView.delegate = self;
        }
    }
    
    [self.scrollView addSubview:controlImageView];
    [self.controlImageViewArray addObject:controlImageView];
}

#pragma mark - GalleryDropViewDelegate

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

- (ControlMaskView*)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [[ControlMaskView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _maskLayer;
}

- (void)languageChange {
//    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Gallery", @"Localizable");
//    UIBarButtonItem *right;
//    if (_isEditing) {
//        right = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(galleryDoneAction: )];
//    }else {
//        right = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(galleryEditAction:)];
//    }
//    self.navigationItem.rightBarButtonItem = right;
    if (self.isViewLoaded && !self.view.window) {
        self.view = nil;
    }
}

@end
