//
//  TimerDetailViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/3/2.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "TimerDetailViewController.h"
#import <objc/runtime.h>
#import "PureLayout.h"
#import "DeviceListViewController.h"
#import "DeviceModelManager.h"
#import "CSRDatabaseManager.h"
#import "TimerEntity.h"
#import "CSRUtilities.h"
#import "TimerDeviceEntity.h"
#import "DataModelManager.h"
#import "CSRAppStateManager.h"
#import <CSRmesh/DataModelApi.h>

@interface TimerDetailViewController ()<UITextFieldDelegate>
{
    NSNumber *timerIdNumber;
    NSString *name;
    BOOL enabled;
    NSString *time;
    NSString *date;
    NSInteger repeat;
    NSLayoutConstraint *top_chooseTitle;
    
    BOOL mDidSendStreamData;
    BOOL mDidReciveSetCall;
    BOOL mSetCallState;
    
    NSInteger retryCount;
    NSData *retryCmd;
    NSNumber *retryDeviceId;
}

@property (weak, nonatomic) IBOutlet UIDatePicker *timerPicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UIView *weekView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *repeatChooseSegment;
@property (weak, nonatomic) IBOutlet UITextField *nameTF;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UILabel *chooseTitle;

@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) SceneEntity *selectedScene;
@property (nonatomic,strong) NSMutableArray *sceneMutableArray;
@property (nonatomic,strong) UIView *selectedView;
@property (nonatomic,strong) UIView *sceneView;

@property (nonatomic, strong) NSMutableArray *mMembersToApply;
@property (nonatomic, strong) NSMutableArray *fails;
@property (nonatomic, strong) CSRDeviceEntity *mDeviceToApply;
@property (nonatomic, strong) UIView *translucentBgView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation TimerDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = done;
    
    [self setDatePickerTextColor:self.timerPicker];
    [self setDatePickerTextColor:self.datePicker];
    self.nameTF.delegate = self;
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_scrollView];
    [_scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *top;
    if (@available(iOS 11.0,*)) {
        top = [NSLayoutConstraint constraintWithItem:_scrollView
                                           attribute:NSLayoutAttributeTop
                                           relatedBy:NSLayoutRelationEqual
                                              toItem:self.view.safeAreaLayoutGuide
                                           attribute:NSLayoutAttributeTop
                                          multiplier:1.0
                                            constant:0];
    }else {
        self.automaticallyAdjustsScrollViewInsets = NO;
        top = [NSLayoutConstraint constraintWithItem:_scrollView
                                           attribute:NSLayoutAttributeTop
                                           relatedBy:NSLayoutRelationEqual
                                              toItem:self.view
                                           attribute:NSLayoutAttributeTop
                                          multiplier:1.0
                                            constant:64];
    }
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
    NSLayoutConstraint *bottom;
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) {
        bottom = [NSLayoutConstraint constraintWithItem:_scrollView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1.0
                                               constant:50.0];
    }else {
        bottom = [NSLayoutConstraint constraintWithItem:_scrollView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1.0
                                               constant:0];
        
    }
    
    [NSLayoutConstraint activateConstraints:@[top,left,bottom,right]];
    
    [_scrollView addSubview:_bgView];
    [_bgView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [_bgView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_bgView autoSetDimension:ALDimensionHeight toSize:44];
    [_bgView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    _sceneMutableArray = [[NSMutableArray alloc] init];
    NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.scenes allObjects] mutableCopy];
    if (areaMutableArray != nil || [areaMutableArray count] != 0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sceneID" ascending:YES];
        [areaMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        for (SceneEntity *sceneEntity in areaMutableArray) {
            if ([sceneEntity.members count]>0 && [sceneEntity.srDeviceId isEqualToNumber:@(-1)]) {
                [_sceneMutableArray addObject:sceneEntity];
            }
        }
    }
    
    if (!self.newadd && self.timerEntity) {
        self.navigationItem.title = self.timerEntity.name;
        self.nameTF.text = self.timerEntity.name;
        
        _selectedScene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:self.timerEntity.sceneID];
        _selectedView = [self addSelectedView:_selectedScene];
        [_scrollView addSubview:_selectedView];
        [_selectedView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_bgView];
        [_selectedView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_selectedView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_selectedView autoSetDimension:ALDimensionHeight toSize:45];
        
        [_sceneMutableArray removeObject:_selectedScene];
        
        [_scrollView addSubview:_chooseTitle];
        top_chooseTitle = [_chooseTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_bgView withOffset:57];
        [_chooseTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
        
        _sceneView = [self addSceneView:_sceneMutableArray];
        [_scrollView addSubview:_sceneView];
        [_sceneView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_chooseTitle withOffset:10];
        [_sceneView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_sceneView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        if (_sceneMutableArray && [_sceneMutableArray count]>0) {
            [_sceneView autoSetDimension:ALDimensionHeight toSize:45*[_sceneMutableArray count]-1];
        }else {
            _sceneView.backgroundColor = [UIColor clearColor];
            [_sceneView autoSetDimension:ALDimensionHeight toSize:1];
        }
        
        [_scrollView addSubview:_timerPicker];
        [_timerPicker autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_timerPicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_sceneView withOffset:12];
        
        [_scrollView addSubview:_repeatChooseSegment];
        [_repeatChooseSegment autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_repeatChooseSegment autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_timerPicker withOffset:12];
        [_repeatChooseSegment autoSetDimension:ALDimensionHeight toSize:30];
        [_repeatChooseSegment autoSetDimension:ALDimensionWidth toSize:140];
        
        [self.timerPicker setDate:self.timerEntity.fireTime];
        
        if ([self.timerEntity.repeat isEqualToString:@"00000000"]) {
            [self.repeatChooseSegment setSelectedSegmentIndex:1];
            [_scrollView addSubview:self.datePicker];
            [self.datePicker autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.datePicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:12.0];
            [self.datePicker autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
            [self.datePicker autoSetDimension:ALDimensionHeight toSize:160.0];
            
            [self.datePicker setDate:self.timerEntity.fireDate];
            
            [_scrollView addSubview:_deleteButton];
            [_deleteButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_datePicker withOffset:12.0];
            [_deleteButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [_deleteButton autoSetDimension:ALDimensionWidth toSize:WIDTH];
            
            if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) {
                _scrollView.contentSize = CGSizeMake(WIDTH-321, 45*[_sceneMutableArray count]-1+573);
            }else {
                _scrollView.contentSize = CGSizeMake(WIDTH, 45*[_sceneMutableArray count]-1+573);
            }
            
        }else {
            [self.repeatChooseSegment setSelectedSegmentIndex:0];
            [_scrollView addSubview:self.weekView];
            [self.weekView autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:44.0];
            [self.weekView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
            [self.weekView autoSetDimension:ALDimensionHeight toSize:60.0];
            
            NSString *repeat = [self.timerEntity.repeat substringFromIndex:1];
            [self.weekView.subviews enumerateObjectsUsingBlock:^(UIButton * btn, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *str = [repeat substringWithRange:NSMakeRange(6-idx, 1)];
                if ([str boolValue]) {
                    btn.selected = YES;
                    [btn setBackgroundImage:[UIImage imageNamed:@"weekBtnSelected"] forState:UIControlStateNormal];
                }else {
                    btn.selected = NO;
                    [btn setBackgroundImage:[UIImage imageNamed:@"weekBtnSelect"] forState:UIControlStateNormal];
                }
            }];
            
            [_scrollView addSubview:_deleteButton];
            [_deleteButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_weekView withOffset:44.0];
            [_deleteButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [_deleteButton autoSetDimension:ALDimensionWidth toSize:WIDTH];
            
            if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) {
                _scrollView.contentSize = CGSizeMake(WIDTH-321, 45*[_sceneMutableArray count]-1+537);
            }else {
                _scrollView.contentSize = CGSizeMake(WIDTH, 45*[_sceneMutableArray count]-1+537);
            }
        }
        
    }else {
        
        [_scrollView addSubview:_chooseTitle];
        top_chooseTitle = [_chooseTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_bgView withOffset:12];
        [_chooseTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
        
        _sceneView = [self addSceneView:_sceneMutableArray];
        [_scrollView addSubview:_sceneView];
        [_sceneView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_chooseTitle withOffset:10];
        [_sceneView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_sceneView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_sceneView autoSetDimension:ALDimensionHeight toSize:45*[_sceneMutableArray count]-1];
        
        [_scrollView addSubview:_timerPicker];
        [_timerPicker autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_timerPicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_sceneView withOffset:12];
        
        [_scrollView addSubview:_repeatChooseSegment];
        [_repeatChooseSegment autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_repeatChooseSegment autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_timerPicker withOffset:12];
        [_repeatChooseSegment autoSetDimension:ALDimensionHeight toSize:30];
        [_repeatChooseSegment autoSetDimension:ALDimensionWidth toSize:140];
        
        [_scrollView addSubview:_weekView];
        [_weekView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_repeatChooseSegment withOffset:44];
        [_weekView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_weekView autoSetDimension:ALDimensionHeight toSize:60.0];
        
        if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) {
            _scrollView.contentSize = CGSizeMake(WIDTH-321, 45*[_sceneMutableArray count]-1+493);
        }else {
            _scrollView.contentSize = CGSizeMake(WIDTH, 45*[_sceneMutableArray count]-1+493);
        }
        
    }
}

- (UIView *)addSceneView:(NSMutableArray *)scenes {
    UIView *bgView = [[UIView alloc] init];
    bgView.backgroundColor = [UIColor whiteColor];
    [scenes enumerateObjectsUsingBlock:^(SceneEntity *sceneEntity, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = [sceneEntity.sceneID integerValue] + 100;
        [btn addTarget:self action:@selector(sceneSelectAction:) forControlEvents:UIControlEventTouchUpInside];
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.frame = CGRectMake(20, 12, 150, 20);
        titleLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        titleLabel.font = [UIFont systemFontOfSize:14];
        if ([sceneEntity.sceneName isEqualToString:@"Home"] || [sceneEntity.sceneName isEqualToString:@"Away"] || [sceneEntity.sceneName isEqualToString:@"Scene1"] || [sceneEntity.sceneName isEqualToString:@"Scene2"] || [sceneEntity.sceneName isEqualToString:@"Scene3"] || [sceneEntity.sceneName isEqualToString:@"Scene4"]) {
            titleLabel.text = AcTECLocalizedStringFromTable(sceneEntity.sceneName, @"Localizable");
        }else {
            titleLabel.text = sceneEntity.sceneName;
        }
        [btn addSubview:titleLabel];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"To_select"]];
        [btn addSubview:imageView];
        
        [imageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:11];
        [imageView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16];
        [imageView autoSetDimension:ALDimensionHeight toSize:22];
        [imageView autoSetDimension:ALDimensionWidth toSize:22];
        
        [bgView addSubview:btn];
        
        [btn autoSetDimension:ALDimensionHeight toSize:44.0];
        [btn autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [btn autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [btn autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:idx*45];
        
        if (idx !=0) {
            UIView *line = [[UIView alloc] init];
            line.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
            [bgView addSubview:line];
            [line autoSetDimension:ALDimensionHeight toSize:1];
            [line autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
            [line autoPinEdgeToSuperviewEdge:ALEdgeRight];
            [line autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:44+(idx-1)*45];
        }
    }];
    return bgView;
}

- (void)sceneSelectAction:(UIButton *)button {
    SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:[NSNumber numberWithInteger:button.tag - 100]];
    if (_selectedScene) {
        [_sceneMutableArray addObject:_selectedScene];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sceneID" ascending:YES];
        [_sceneMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        [_selectedView removeFromSuperview];
    }
    _selectedView = [self addSelectedView:scene];
    [_scrollView addSubview:_selectedView];
    [_selectedView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_bgView];
    [_selectedView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_selectedView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_selectedView autoSetDimension:ALDimensionHeight toSize:45];
    
    _selectedScene = scene;
    [_sceneMutableArray removeObject:scene];
    
    top_chooseTitle.constant = 57;
    
    [_sceneView removeFromSuperview];
    _sceneView = [self addSceneView:_sceneMutableArray];
    [_scrollView addSubview:_sceneView];
    [_sceneView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_chooseTitle withOffset:10];
    [_sceneView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_sceneView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    if (_sceneMutableArray && [_sceneMutableArray count]>0) {
        [_sceneView autoSetDimension:ALDimensionHeight toSize:45*[_sceneMutableArray count]-1];
    }else {
        _sceneView.backgroundColor = [UIColor clearColor];
        [_sceneView autoSetDimension:ALDimensionHeight toSize:1];
    }
    
    [_timerPicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_sceneView withOffset:12];

    [_repeatChooseSegment autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_timerPicker withOffset:12];
    
    if (_repeatChooseSegment.selectedSegmentIndex == 0) {
        [_weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_repeatChooseSegment withOffset:44];
        if (_newadd) {
            _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+538);
        }else {
            [_deleteButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_weekView withOffset:44.0];
            _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+582);
        }
    }else {
        [_datePicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_repeatChooseSegment withOffset:12.0];
        if (_newadd) {
            _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+574);
        }else {
            _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+618);
        }
    }
    
}

- (UIView *)addSelectedView:(SceneEntity *)scene {
    UIView *selectedBgView = [[UIView alloc] init];
    selectedBgView.backgroundColor = [UIColor whiteColor];
    UIView *line = [[UIView alloc] initWithFrame:CGRectZero];
    line.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    [selectedBgView addSubview:line];
    [line autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [line autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [line autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [line autoSetDimension:ALDimensionHeight toSize:1];
    UILabel *selectedTitleLabel = [[UILabel alloc] init];
    selectedTitleLabel.frame = CGRectMake(20, 12, 150, 20);
    selectedTitleLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
    selectedTitleLabel.font = [UIFont systemFontOfSize:14];
    if ([scene.sceneName isEqualToString:@"Home"] || [scene.sceneName isEqualToString:@"Away"] || [scene.sceneName isEqualToString:@"Scene1"] || [scene.sceneName isEqualToString:@"Scene2"] || [scene.sceneName isEqualToString:@"Scene3"] || [scene.sceneName isEqualToString:@"Scene4"]) {
        selectedTitleLabel.text = AcTECLocalizedStringFromTable(scene.sceneName, @"Localizable");
    }else {
        selectedTitleLabel.text = scene.sceneName;
    }
    [selectedBgView addSubview:selectedTitleLabel];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Be_selected"]];
    [selectedBgView addSubview:imageView];
    [imageView autoSetDimension:ALDimensionWidth toSize:22];
    [imageView autoSetDimension:ALDimensionHeight toSize:22];
    [imageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:11];
    [imageView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16];
    return selectedBgView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addAlarmCall:) name:@"addAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteAlarmCall:) name:@"deleteAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSendStreamData:) name:@"didSendStreamData" object:nil];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"deleteAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"didSendStreamData" object:nil];
}

#pragma mark - 修改日期选择器的字体颜色

- (void)setDatePickerTextColor:(UIDatePicker *)picker {
    unsigned int outCount;
    int i;
    objc_property_t *pProperty = class_copyPropertyList([UIDatePicker class], &outCount);
    for (i = outCount -1; i >= 0; i--)
    {
        //         循环获取属性的名字   property_getName函数返回一个属性的名称
        NSString *getPropertyName = [NSString stringWithCString:property_getName(pProperty[i]) encoding:NSUTF8StringEncoding];
        if([getPropertyName isEqualToString:@"textColor"])
        {
            [picker setValue:DARKORAGE forKey:@"textColor"];
        }
    }
    //通过NSSelectorFromString获取setHighlightsToday方法
    SEL selector = NSSelectorFromString(@"setHighlightsToday:");
    //创建NSInvocation
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDatePicker instanceMethodSignatureForSelector:selector]];
    BOOL no = NO;
    [invocation setSelector:selector];
    //setArgument中第一个参数的类picker，第二个参数是SEL，
    [invocation setArgument:&no atIndex:2];
    //让invocation执行setHighlightsToday方法
    [invocation invokeWithTarget:picker];
}

- (IBAction)repeatClick:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        [self.datePicker removeFromSuperview];
        [_scrollView addSubview:self.weekView];
        [self.weekView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:44.0];
        [self.weekView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.weekView autoSetDimension:ALDimensionHeight toSize:60.0];
        if (_newadd) {
            if (_selectedScene) {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+538);
            }else {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+493);
            }
        }else {
            [_deleteButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_weekView withOffset:44.0];
            if (_selectedScene) {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+582);
            }else {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+537);
            }
        }
        
        
    }else {
        [self.weekView removeFromSuperview];
        [_scrollView addSubview:self.datePicker];
        [self.datePicker autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.datePicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:12.0];
        [self.datePicker autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
        [self.datePicker autoSetDimension:ALDimensionHeight toSize:160.0];
        if (_newadd) {
            if (_selectedScene) {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+574);
            }else {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+529);
            }
        }else {
            [_deleteButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_datePicker withOffset:12.0];
            if (_selectedScene) {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+618);
            }else {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+573);
            }
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    textField.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    textField.backgroundColor = [UIColor whiteColor];
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - weekButton

- (IBAction)weekButtonClick:(UIButton *)sender {
    __block BOOL exist = 0;
    [_weekView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)obj;
            if (btn.tag!=sender.tag && btn.selected) {
                exist = YES;
                *stop = YES;
            }
        }
    }];
    if (exist) {
        sender.selected = !sender.selected;
        UIImage *bgImage = sender.selected? [UIImage imageNamed:@"weekBtnSelected"]:[UIImage imageNamed:@"weekBtnSelect"];
        [sender setBackgroundImage:bgImage forState:UIControlStateNormal];
    }
    
}

- (void)doneAction {
    if (!_selectedScene) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"mustSelectScene", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
        [alertController.view setTintColor:DARKORAGE];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    [self showLoading];
    
    if (_newadd) {
        enabled = YES;
        if (!_timerEntity) {
            timerIdNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"TimerEntity"];
            _timerEntity = [NSEntityDescription insertNewObjectForEntityForName:@"TimerEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
        }
    }else {
        if (_timerEntity) {
            timerIdNumber = _timerEntity.timerID;
            enabled = [_timerEntity.enabled boolValue];
            if (![_timerEntity.sceneID isEqualToNumber:_selectedScene.sceneID]) {
                for (TimerDeviceEntity *td in [_timerEntity.timerDevices mutableCopy]) {
                    [self.mMembersToApply addObject:td];
                }
            }
            
        }
    }
    
    if (![CSRUtilities isStringEmpty:_nameTF.text]) {
        name = _nameTF.text;
    }else {
        name = [NSString stringWithFormat:@"timer %@",timerIdNumber];
    }
    
    NSDateFormatter *dateFormate_time = [[NSDateFormatter alloc] init];
    [dateFormate_time setDateFormat:@"HHmm"];
    time = [dateFormate_time stringFromDate:_timerPicker.date];
    
    NSString *repeatStr = @"";
    NSDate *d = [NSDate date];
    if (_repeatChooseSegment.selectedSegmentIndex == 0) {
        for (UIButton *btn in self.weekView.subviews) {
            repeatStr = [NSString stringWithFormat:@"%d%@",btn.selected,repeatStr];
        }
        repeatStr = [NSString stringWithFormat:@"0%@",repeatStr];
    }else {
        repeatStr = @"00000000";
        d = _datePicker.date;
    }
    NSDateFormatter *dateFormate_date = [[NSDateFormatter alloc] init];
    [dateFormate_date setDateFormat:@"yyyyMMdd"];
    date = [dateFormate_date stringFromDate:_datePicker.date];
    repeat = 0;
    for (int i = 0; i < 7; i ++) {
        repeat = repeat + [[repeatStr substringWithRange:NSMakeRange(i+1, 1)] boolValue] * pow(2, 6-i);
    }
    
    _timerEntity.timerID = timerIdNumber;
    _timerEntity.name = name;
    _timerEntity.enabled = @(enabled);
    _timerEntity.fireTime = [dateFormate_time dateFromString:time];
    _timerEntity.fireDate = [dateFormate_date dateFromString:date];
    _timerEntity.repeat = repeatStr;
    _timerEntity.sceneID = _selectedScene.sceneID;
    [[CSRAppStateManager sharedInstance].selectedPlace addTimersObject:_timerEntity];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    if ([_selectedScene.members count]>0) {
        for (SceneMemberEntity *sm in [_selectedScene.members mutableCopy]) {
            [self.mMembersToApply addObject:sm];
        }
    }
    if (![self nextOperation]) {
        [self hideLoading];
        if (self.handle) {
            self.handle();
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (NSMutableArray *)mMembersToApply {
    if (!_mMembersToApply) {
        _mMembersToApply = [[NSMutableArray alloc] init];
    }
    return _mMembersToApply;
}

- (NSMutableArray *)fails {
    if (!_fails) {
        _fails = [[NSMutableArray alloc] init];
    }
    return _fails;
}

- (BOOL)nextOperation {
    if ([self.mMembersToApply count]>0) {
        id obj = [_mMembersToApply firstObject];
        if ([obj isKindOfClass:[TimerDeviceEntity class]]) {
            TimerDeviceEntity *td = (TimerDeviceEntity *)obj;
            _mDeviceToApply = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:td.deviceID];
            if (_mDeviceToApply == nil) {
                [_mMembersToApply removeObject:obj];
                return [self nextOperation];
            }else {
                
                Byte bIndex[]={};
                bIndex[0] = (Byte)(([td.timerIndex integerValue] & 0xFF00)>>8);
                bIndex[1] = (Byte)([td.timerIndex integerValue] & 0x00FF);
                
                [self performSelector:@selector(setTimerTimeOut) withObject:nil afterDelay:10.0];
                
                if ([CSRUtilities belongToTwoChannelSwitch:_mDeviceToApply.shortName]
                    || [CSRUtilities belongToThreeChannelSwitch:_mDeviceToApply.shortName]
                    || [CSRUtilities belongToTwoChannelDimmer:_mDeviceToApply.shortName]
                    || [CSRUtilities belongToSocketTwoChannel:_mDeviceToApply.shortName]
                    || [CSRUtilities belongToTwoChannelCurtainController:_mDeviceToApply.shortName]) {
                    Byte byte[] = {0x50, 0x04, 0x07, [td.channel integerValue], bIndex[1], bIndex[0]};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
                    retryCount = 0;
                    retryCmd = cmd;
                    retryDeviceId = td.deviceID;
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:td.deviceID data:cmd];
                }else {
                    if ([_mDeviceToApply.cvVersion integerValue] > 18) {
                        Byte byte[] = {0x85, 0x02, bIndex[1], bIndex[0]};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        retryCount = 0;
                        retryCmd = cmd;
                        retryDeviceId = td.deviceID;
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:td.deviceID data:cmd];
                    }else {
                        Byte byte[] = {0x85, 0x01, [td.timerIndex integerValue]};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
                        retryCount = 0;
                        retryCmd = cmd;
                        retryDeviceId = td.deviceID;
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:td.deviceID data:cmd];
                    }
                }
                
                return YES;
            }
        }else if ([obj isKindOfClass:[SceneMemberEntity class]]) {
            SceneMemberEntity *sm = (SceneMemberEntity *)obj;
            _mDeviceToApply = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:sm.deviceID];
            if (_mDeviceToApply == nil) {
                [_mMembersToApply removeObject:obj];
                return [self nextOperation];
            }else {
                NSNumber *timerIndex;
                TimerDeviceEntity *timerDeviceE;
                if (_newadd) {
                    timerIndex = [[CSRDatabaseManager sharedInstance] getNextFreeTimerIDOfDeivice:sm.deviceID];
                    timerDeviceE = [NSEntityDescription insertNewObjectForEntityForName:@"TimerDeviceEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                }else {
                    for (TimerDeviceEntity *timerDevice in _timerEntity.timerDevices) {
                        if ([timerDevice.deviceID isEqualToNumber:sm.deviceID] && [timerDevice.channel isEqualToNumber:sm.channel]) {
                            timerIndex = timerDevice.timerIndex;
                            timerDeviceE = timerDevice;
                            break;
                        }
                    }
                    if (!timerIndex) {
                        timerIndex = [[CSRDatabaseManager sharedInstance] getNextFreeTimerIDOfDeivice:sm.deviceID];
                        timerDeviceE = [NSEntityDescription insertNewObjectForEntityForName:@"TimerDeviceEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                    }
                }
                timerDeviceE.timerID = timerIdNumber;
                timerDeviceE.deviceID = sm.deviceID;
                timerDeviceE.timerIndex = timerIndex;
                timerDeviceE.channel = sm.channel;
                [_timerEntity addTimerDevicesObject:timerDeviceE];
                [[CSRDatabaseManager sharedInstance] saveContext];
                
                [self addAlarm:sm index:[timerIndex integerValue]];
                
                return YES;
            }
        }else {
            [_mMembersToApply removeObject:obj];
            return [self nextOperation];
        }
    }
    return NO;
}

- (void)addAlarm:(SceneMemberEntity *)member index:(NSInteger)index {
    
    Byte bIndex[] = {};
    bIndex[0] = (Byte)((index & 0xFF00)>>8);
    bIndex[1] = (Byte)(index & 0x00FF);
    
    NSInteger y = [[date substringWithRange:NSMakeRange(2, 2)] integerValue];
    NSInteger M = [[date substringWithRange:NSMakeRange(4, 2)] integerValue];
    NSInteger d = [[date substringWithRange:NSMakeRange(6, 2)] integerValue];
    NSInteger h = [[time substringWithRange:NSMakeRange(0, 2)] integerValue];
    NSInteger m = [[time substringWithRange:NSMakeRange(2, 2)] integerValue];
    
    NSDate *dt = [NSDate date];
    NSDateFormatter *dateFormate_date = [[NSDateFormatter alloc] init];
    [dateFormate_date setDateFormat:@"yyyyMMddHHmmss"];
    NSString *dtstr = [dateFormate_date stringFromDate:dt];
    NSInteger ys = [[dtstr substringWithRange:NSMakeRange(2, 2)] integerValue];
    NSInteger Ms = [[dtstr substringWithRange:NSMakeRange(4, 2)] integerValue];
    NSInteger ds = [[dtstr substringWithRange:NSMakeRange(6, 2)] integerValue];
    NSInteger hs = [[dtstr substringWithRange:NSMakeRange(8, 2)] integerValue];
    NSInteger ms = [[dtstr substringWithRange:NSMakeRange(10, 2)] integerValue];
    NSInteger ss = [[dtstr substringWithRange:NSMakeRange(12, 2)] integerValue];
    
    [self performSelector:@selector(setTimerTimeOut) withObject:nil afterDelay:12.0];
    if ([CSRUtilities belongToTwoChannelSwitch:member.kindString]
        || [CSRUtilities belongToThreeChannelSwitch:member.kindString]
        || [CSRUtilities belongToTwoChannelDimmer:member.kindString]
        || [CSRUtilities belongToSocketTwoChannel:member.kindString]
        || [CSRUtilities belongToTwoChannelCurtainController:member.kindString]) {
        
        Byte byte[] = {0x50, 0x18, 0x01, [member.channel integerValue], bIndex[1], bIndex[0], enabled, y, M, d, h, m, 0x00, repeat, [member.eveType integerValue], [member.eveD0 integerValue], [member.eveD1 integerValue], [member.eveD2 integerValue], [member.eveD3 integerValue], 0x00, ys, Ms, ds, hs, ms, ss};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:26];
        retryCount = 0;
        retryCmd = cmd;
        retryDeviceId = member.deviceID;
        [[DataModelManager shareInstance] sendDataByStreamDataTransfer:member.deviceID data:cmd];
    }else {
        if ([_mDeviceToApply.cvVersion integerValue] > 18) {
            Byte byte[] = {0x83, 0x16, bIndex[1], bIndex[0], enabled, y, M, d, h, m, 0x00, repeat, [member.eveType integerValue], [member.eveD0 integerValue], [member.eveD1 integerValue], [member.eveD2 integerValue], [member.eveD3 integerValue], 0x00, ys, Ms, ds, hs, ms, ss};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:24];
            retryCount = 0;
            retryCmd = cmd;
            retryDeviceId = member.deviceID;
            [[DataModelManager shareInstance] sendDataByStreamDataTransfer:member.deviceID data:cmd];
        }else {
            Byte byte[] = {0x83, 0x15, index, enabled, y, M, d, h, m, 0x00, repeat, [member.eveType integerValue], [member.eveD0 integerValue], [member.eveD1 integerValue], [member.eveD2 integerValue], [member.eveD3 integerValue], 0x00, ys, Ms, ds, hs, ms, ss};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:23];
            retryCount = 0;
            retryCmd = cmd;
            retryDeviceId = member.deviceID;
            [[DataModelManager shareInstance] sendDataByStreamDataTransfer:member.deviceID data:cmd];
        }
    }
    
}

- (void)addAlarmCall:(NSNotification *)result {
    NSDictionary *userInfo = result.userInfo;
    NSNumber *sDeviceID = userInfo[@"deviceId"];
    NSNumber *channel = userInfo[@"channel"];
    mSetCallState = [userInfo[@"state"] boolValue];
    id obj = [_mMembersToApply firstObject];
    if ([obj isKindOfClass:[SceneMemberEntity class]]) {
        SceneMemberEntity *sm = (SceneMemberEntity *)obj;
        if ([sDeviceID isEqualToNumber:sm.deviceID] && [channel isEqualToNumber:sm.channel]) {
            
            mDidReciveSetCall = YES;
            if (mDidReciveSetCall && mDidSendStreamData) {
                [self didSendStreamDataAndDidReciveSetCall];
            }
        }
    }
}

- (void)didSendStreamData:(NSNotification *)result {
    NSDictionary *userInfo = result.userInfo;
    NSNumber *sDeviceID = userInfo[@"deviceId"];
    NSNumber *channel = userInfo[@"channel"];
    id obj = [_mMembersToApply firstObject];
    if ([obj isKindOfClass:[SceneMemberEntity class]]) {
        SceneMemberEntity *sm = (SceneMemberEntity *)obj;
        if ([sDeviceID isEqualToNumber:sm.deviceID] && [channel isEqualToNumber:sm.channel]) {
            mDidSendStreamData = YES;
            if (mDidReciveSetCall && mDidSendStreamData) {
                [self didSendStreamDataAndDidReciveSetCall];
            }
        }
    }
}

- (void)didSendStreamDataAndDidReciveSetCall {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setTimerTimeOut) object:nil];
    SceneMemberEntity *sm = (SceneMemberEntity *)[_mMembersToApply firstObject];
    [_mMembersToApply removeObject:sm];
    if (!mSetCallState) {
        [self.fails addObject:sm];
        for (TimerDeviceEntity *td in _timerEntity.timerDevices) {
            if ([td.deviceID isEqualToNumber:sm.deviceID] && [td.channel isEqualToNumber:sm.channel]) {
                [_timerEntity removeTimerDevicesObject:td];
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:td];
                [[CSRDatabaseManager sharedInstance] saveContext];
                break;
            }
        }
    }
    
    _mDeviceToApply = nil;
    
    mDidSendStreamData = NO;
    mDidReciveSetCall = NO;
    
    if (![self nextOperation]) {
        if ([self.fails count] > 0) {
            [self hideLoading];
            [self showFailAler];
        }else {
            [self hideLoading];
            if (self.handle) {
                self.handle();
            }
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)setTimerTimeOut {
    id obj = [_mMembersToApply firstObject];
    if (retryCount < 1) {
        if ([obj isKindOfClass:[SceneMemberEntity class]]) {
            [self performSelector:@selector(setTimerTimeOut) withObject:nil afterDelay:12];
            [[DataModelManager shareInstance] sendDataByStreamDataTransfer:retryDeviceId data:retryCmd];
        }else if ([obj isKindOfClass:[TimerDeviceEntity class]]) {
            [self performSelector:@selector(setTimerTimeOut) withObject:nil afterDelay:10];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:retryDeviceId data:retryCmd];
        }
        retryCount ++;
    }else {
        [_mMembersToApply removeObject:obj];
        [self.fails addObject:obj];
        if ([obj isKindOfClass:[SceneMemberEntity class]]) {
            SceneMemberEntity *sm = (SceneMemberEntity *)obj;
            for (TimerDeviceEntity *td in _timerEntity.timerDevices) {
                if ([td.deviceID isEqualToNumber:sm.deviceID] && [td.channel isEqualToNumber:sm.channel]) {
                    [_timerEntity removeTimerDevicesObject:td];
                    [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:td];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    break;
                }
            }
        }
        
        _mDeviceToApply = nil;
        mDidSendStreamData = NO;
        mDidReciveSetCall = NO;
        
        if (![self nextOperation]) {
            [self hideLoading];
            [self showFailAler];
        }
    }
}

- (void)showLoading {
    [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
    [[UIApplication sharedApplication].keyWindow addSubview:self.indicatorView];
    [self.indicatorView autoCenterInSuperview];
    [self.indicatorView startAnimating];
    
}

- (void)hideLoading {
    [self.indicatorView stopAnimating];
    [self.indicatorView removeFromSuperview];
    [self.translucentBgView removeFromSuperview];
    self.indicatorView = nil;
    self.translucentBgView = nil;
}

- (void)showFailAler {
    if ([self.fails count]==0) {
        return;
    }
    NSString *message = @"";
    NSString *nt = @"";
    NSString *ns = @"";
    for (id obj in self.fails) {
        if ([obj isKindOfClass:[TimerDeviceEntity class]]) {
            TimerDeviceEntity *td = (TimerDeviceEntity *)obj;
            CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:td.deviceID];
            if ([CSRUtilities belongToTwoChannelSwitch:d.shortName]
                || [CSRUtilities belongToThreeChannelSwitch:d.shortName]
                || [CSRUtilities belongToTwoChannelDimmer:d.shortName]
                || [CSRUtilities belongToSocketTwoChannel:d.shortName]
                || [CSRUtilities belongToTwoChannelCurtainController:d.shortName]) {
                NSString *channelStr = @"";
                if ([td.channel integerValue] == 1) {
                    channelStr = AcTECLocalizedStringFromTable(@"Channel1", @"Localizable");
                }else if ([td.channel integerValue] == 2) {
                    channelStr = AcTECLocalizedStringFromTable(@"Channel2", @"Localizable");
                }else if ([td.channel integerValue] == 4) {
                    channelStr = AcTECLocalizedStringFromTable(@"Channel3", @"Localizable");
                }
                nt = [NSString stringWithFormat:@"%@ %@(%@)",nt, d.name,channelStr];
            }else {
                nt = [NSString stringWithFormat:@"%@ %@",nt, d.name];
            }
            
        }else if ([obj isKindOfClass:[SceneMemberEntity class]]) {
            SceneMemberEntity *sm = (SceneMemberEntity *)obj;
            CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:sm.deviceID];
            if ([CSRUtilities belongToTwoChannelSwitch:d.shortName]
                || [CSRUtilities belongToThreeChannelSwitch:d.shortName]
                || [CSRUtilities belongToTwoChannelDimmer:d.shortName]
                || [CSRUtilities belongToSocketTwoChannel:d.shortName]
                || [CSRUtilities belongToTwoChannelCurtainController:d.shortName]) {
                NSString *channelStr = @"";
                if ([sm.channel integerValue] == 1) {
                    channelStr = AcTECLocalizedStringFromTable(@"Channel1", @"Localizable");
                }else if ([sm.channel integerValue] == 2) {
                    channelStr = AcTECLocalizedStringFromTable(@"Channel2", @"Localizable");
                }else if ([sm.channel integerValue] == 4) {
                    channelStr = AcTECLocalizedStringFromTable(@"Channel3", @"Localizable");
                }
                ns = [NSString stringWithFormat:@"%@ %@(%@)",ns, d.name,channelStr];
            }else {
                ns = [NSString stringWithFormat:@"%@ %@",ns, d.name];
            }
            
        }
    }
    if ([nt length]>0) {
        message = [NSString stringWithFormat:@"%@ %@",AcTECLocalizedStringFromTable(@"removetimerfail", @"Localizable"), nt];
    }
    if ([ns length]>0) {
        message = [NSString stringWithFormat:@"%@ %@ %@",message,AcTECLocalizedStringFromTable(@"addtimerfail", @"Localizable"), ns];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.fails removeAllObjects];
        if (_timerEntity && [_timerEntity.timerDevices count] == 0) {
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_timerEntity];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
        if (self.handle) {
            self.handle();
        }
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alert addAction:yes];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIView *)translucentBgView {
    if (!_translucentBgView) {
        _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _translucentBgView.backgroundColor = [UIColor blackColor];
        _translucentBgView.alpha = 0.4;
    }
    return _translucentBgView;
}

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] init];
        _indicatorView.hidesWhenStopped = YES;
        _indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    }
    return _indicatorView;
}

- (void)deleteAlarmCall:(NSNotification *)result {
    NSDictionary *userInfo = result.userInfo;
    NSNumber *dDeviceID = userInfo[@"deviceId"];
    NSNumber *channel = userInfo[@"channel"];
    BOOL state = [userInfo[@"state"] boolValue];
    id obj = [_mMembersToApply firstObject];
    if ([obj isKindOfClass:[TimerDeviceEntity class]]) {
        TimerDeviceEntity *td = (TimerDeviceEntity *)obj;
        if ([dDeviceID isEqualToNumber:td.deviceID] && [channel isEqualToNumber:td.channel]) {
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setTimerTimeOut) object:nil];
            
            if (_timerEntity) {
                [_timerEntity removeTimerDevicesObject:td];
            }
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:td];
            [[CSRDatabaseManager sharedInstance] saveContext];
            [_mMembersToApply removeObject:obj];
            if (!state) {
                [self.fails addObject:td];
            }
            
            _mDeviceToApply = nil;
            
            if (![self nextOperation]) {
                if ([self.fails count] > 0) {
                    [self hideLoading];
                    [self showFailAler];
                }else {
                    [self hideLoading];
                    if (self.handle) {
                        self.handle();
                    }
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
            
        }
    }
}

- (IBAction)deleteTimerAction:(UIButton *)sender {
    
    [self showLoading];
    
    for (TimerDeviceEntity *td in [_timerEntity.timerDevices mutableCopy]) {
        [self.mMembersToApply addObject:td];
    }
    
    [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_timerEntity];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    if (![self nextOperation]) {
        [self hideLoading];
        if (self.handle) {
            self.handle();
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}



@end
