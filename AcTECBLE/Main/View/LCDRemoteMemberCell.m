//
//  LCDRemoteMemberCell.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/1/2.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "LCDRemoteMemberCell.h"
#import "LCDSelectModel.h"
#import "CSRDatabaseManager.h"
#import "CSRConstants.h"
#import "CSRUtilities.h"

@implementation LCDRemoteMemberCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureAction:)];
    [self addGestureRecognizer:longPressGesture];
    
    UIPanGestureRecognizer *movePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(movePanGestureAction:)];
    [_icon addGestureRecognizer:movePanGesture];
}

- (void)configureCellWithInfo:(id)info indexPath:(NSIndexPath *)indexPath {
    self.cellIndexPath = indexPath;
    if ([info isKindOfClass:[NSNumber class]]) {
        _add.hidden = NO;
        _icon.hidden = YES;
        _name.hidden = YES;
    }else if ([info isKindOfClass:[LCDSelectModel class]]) {
        _add.hidden = YES;
        _icon.hidden = NO;
        _name.hidden = NO;
        
        LCDSelectModel *lMod = (LCDSelectModel *)info;
        _name.text = lMod.name;
        NSInteger a = [lMod.typeID integerValue]*1000+[lMod.iconID integerValue];
        NSString *b;
        if (a<10000) {
            b = [NSString stringWithFormat:@"00%ld",(long)a];
        }else if (a<100000) {
            b = [NSString stringWithFormat:@"0%ld",(long)a];
        }else {
            b = [NSString stringWithFormat:@"%ld",(long)a];
        }
        _icon.image = [UIImage imageNamed:b];
    }
}

- (void)layoutSubviews {
    _icon.layer.cornerRadius = 34.0*self.bounds.size.width/54.0/2.0;
    _icon.layer.masksToBounds = YES;
}

- (void)longPressGestureAction:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (self.cellDelgate && [self.cellDelgate respondsToSelector:@selector(LCDRemoteMemberCellLongPressItemAtIndexPath:)]) {
            [self.cellDelgate LCDRemoteMemberCellLongPressItemAtIndexPath:self.cellIndexPath];
        }
    }
}

- (void)movePanGestureAction:(UIPanGestureRecognizer *)gesture {
    if (self.cellDelgate && [self.cellDelgate respondsToSelector:@selector(LCDRemoteMemberCellMoveItem:)]) {
        [self.cellDelgate LCDRemoteMemberCellMoveItem:gesture];
    }
}

@end
