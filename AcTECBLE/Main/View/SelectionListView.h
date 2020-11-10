//
//  SelectionListView.h
//  AcTECBLE
//
//  Created by AcTEC on 2020/10/29.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SelectionListViewSelectionMode)
{
    SelectionListViewSelectionMode_Sonos = 0,
    SelectionListViewSelectionMode_Music = 1,
    SelectionListViewSelectionMode_Cycle = 2,
    SelectionListViewSelectionMode_Source = 3
};

@protocol SelectionListViewDelegate <NSObject>

- (void)selectionListViewCancelAction;
- (void)selectionListViewSaveAction:(NSArray *_Nullable)ary selectionMode:(SelectionListViewSelectionMode)mode;

@end

NS_ASSUME_NONNULL_BEGIN

@interface SelectionListView : UIView<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *dataArray;
@property (nonatomic, assign) SelectionListViewSelectionMode sMode;
@property (nonatomic, weak) id<SelectionListViewDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *selectedAry;

- (instancetype)initWithFrame:(CGRect)frame dataArray:(NSArray *)dataArray tite:(NSString *)title mode:(SelectionListViewSelectionMode)mode;

@end

NS_ASSUME_NONNULL_END
