//
//  MusicListTableViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/9/7.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MusicListTableViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "GetDataTools.h"
#import <MediaPlayer/MediaPlayer.h>
#import "MusicPlayTools.h"

@interface MusicListTableViewController ()<MusicPlayToolsDelegate>

@property (nonatomic,strong) NSArray * dataArray;
@property (nonatomic,assign) NSInteger selectedRow;

@end

@implementation MusicListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [[GetDataTools shareGetData] getDataAndPassValue:^(NSArray *array) {
        self.dataArray = array;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
    
    [MusicPlayTools shareMusicPlay].delegate = self;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([MusicPlayTools shareMusicPlay].mediaItem) {
        __block NSInteger blockSelectedIndex = -1;
        [[GetDataTools shareGetData].dataArray enumerateObjectsUsingBlock:^(MPMediaItem *item, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([[MusicPlayTools shareMusicPlay].mediaItem isEqual:item]) {
                blockSelectedIndex = idx;
                *stop = YES;
            }
        }];
        _selectedRow = blockSelectedIndex;
    }else {
        _selectedRow = -1;
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.dataArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"musicListCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"musicListCell"];
    }
    if (indexPath.row == _selectedRow) {
        cell.textLabel.textColor = DARKORAGE;
    }else {
        cell.textLabel.textColor = [UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1];
    }
    
    MPMediaItem *item = self.dataArray[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld   %@",indexPath.row+1,[item valueForProperty:MPMediaItemPropertyTitle]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self play:indexPath.row];
}

- (void)play:(NSInteger)index {
    if ([[MusicPlayTools shareMusicPlay].mediaItem isEqual:[[GetDataTools shareGetData] getModelWithIndex:index]]) {
        if ([MusicPlayTools shareMusicPlay].audioPlayer.playing) {
            [[MusicPlayTools shareMusicPlay] musicPause];
        }else {
            [[MusicPlayTools shareMusicPlay] musicPlay];
        }
        return;
    }
    NSArray *array = @[[NSIndexPath indexPathForRow:_selectedRow inSection:0],[NSIndexPath indexPathForRow:index inSection:0]];
    _selectedRow = index;
    [self.tableView reloadRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationNone];
    
    
    [[MusicPlayTools shareMusicPlay] musicPause];
    
    MPMediaItem *mediaItem = [[GetDataTools shareGetData] getModelWithIndex:index];
    [MusicPlayTools shareMusicPlay].mediaItem = mediaItem;
    [MusicPlayTools shareMusicPlay].deviceId = _deviceId;
    [[MusicPlayTools shareMusicPlay] preparePlay];
}

- (void)endOfPlayAction {
    if (_selectedRow == [GetDataTools shareGetData].dataArray.count - 1) {
        [self play:0];
    }else {
        [self play:_selectedRow+1];
    }
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
