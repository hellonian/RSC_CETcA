//
//  CameraAndAlbumCell.h
//  BluetoothTest
//
//  Created by hua on 6/14/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CameraAndAlbumCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *preview;
@property (nonatomic,copy) NSString *representedAssetIdentifier;
@end
