//
//  SelectionListView.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/10/29.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "SelectionListView.h"
#import "SelectionListModel.h"

@implementation SelectionListView

- (instancetype)initWithFrame:(CGRect)frame dataArray:(NSArray *)dataArray tite:(NSString *)title mode:(SelectionListViewSelectionMode)mode
{
    self = [super initWithFrame:frame];
    if (self) {
        _dataArray = dataArray;
        _sMode = mode;
        _selectedAry = [[NSMutableArray alloc] init];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 44)];
        titleLabel.textColor = ColorWithAlpha(100, 100, 100, 1);
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.text = title;
        [self addSubview:titleLabel];
        
        UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(0, 44, frame.size.width, 1)];
        line1.backgroundColor = ColorWithAlpha(195, 195, 195, 1);
        [self addSubview:line1];
        
        UIButton *cancel = [[UIButton alloc] initWithFrame:CGRectMake(0, frame.size.height - 44, (frame.size.width-1)/2, 44)];
        [cancel setTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") forState:UIControlStateNormal];
        [cancel setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [cancel addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:cancel];
        
        UIButton *save = [[UIButton alloc] initWithFrame:CGRectMake((frame.size.width-1)/2 + 1, frame.size.height - 44, (frame.size.width-1)/2, 44)];
        [save setTitle:AcTECLocalizedStringFromTable(@"Save", @"Localizable") forState:UIControlStateNormal];
        [save setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [save addTarget:self action:@selector(saveAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:save];
        
        UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height - 45, frame.size.width, 1)];
        line2.backgroundColor = ColorWithAlpha(195, 195, 195, 1);
        [self addSubview:line2];
        
        UIView *line3 = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width-1)/2, frame.size.height - 44, 1, 44)];
        line3.backgroundColor = ColorWithAlpha(195, 195, 195, 1);
        [self addSubview:line3];
        
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 45, frame.size.width, frame.size.height-90)];
        tableView.dataSource = self;
        tableView.delegate = self;
        [self addSubview:tableView];
        
        self.backgroundColor = ColorWithAlpha(246, 246, 246, 0.96);
        self.layer.cornerRadius = 14;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1;
        self.layer.borderColor = ColorWithAlpha(195, 195, 195, 1).CGColor;
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SELECTIONLISTCELL"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SELECTIONLISTCELL"];
    }
    SelectionListModel *model = [self.dataArray objectAtIndex:indexPath.row];
    cell.imageView.image = model.selected ? [UIImage imageNamed:@"Be_selected"] : [UIImage imageNamed:@"To_select"];
    cell.textLabel.text = model.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SelectionListModel *model = [self.dataArray objectAtIndex:indexPath.row];
    model.selected = !model.selected;
    if (_sMode == SelectionListViewSelectionMode_Sonos) {
        if (model.selected) {
            if (![_selectedAry containsObject:model]) {
                [_selectedAry addObject:model];
            }
        }else {
            if ([_selectedAry containsObject:model]) {
                [_selectedAry removeObject:model];
            }
        }
    }else if (_sMode == SelectionListViewSelectionMode_Music
              || _sMode == SelectionListViewSelectionMode_Cycle
              || _sMode == SelectionListViewSelectionMode_Source
              || _sMode == SelectionListViewSelectionMode_PlayStop
              || _sMode == SelectionListViewSelectionMode_NormalMute
              || _sMode == SelectionListViewSelectionMode_ChannelPowerState
              || _sMode == SelectionListViewSelectionMode_Channel
              || _sMode == SelectionListViewSelectionMode_Fengsu
              || _sMode == SelectionListViewSelectionMode_Wendu
              || _sMode == SelectionListViewSelectionMode_Moshi
              || _sMode == SelectionListViewSelectionMode_Fengxiang) {
        if (model.selected) {
            if ([_selectedAry count] > 0) {
                SelectionListModel *model = [_selectedAry firstObject];
                model.selected = NO;
                [_selectedAry removeObject:model];
            }
            [_selectedAry addObject:model];
        }else {
            if ([_selectedAry containsObject:model]) {
                [_selectedAry removeObject:model];
            }
        }
    }
    [tableView reloadData];
}

- (void)cancelAction: (UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(selectionListViewCancelAction)]) {
        [self.delegate selectionListViewCancelAction];
    }
}

- (void)saveAction: (UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(selectionListViewSaveAction:selectionMode:)]) {
        [self.delegate selectionListViewSaveAction:_selectedAry selectionMode:_sMode];
    }
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
