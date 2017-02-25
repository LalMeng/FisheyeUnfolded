//
//  ViewController.m
//  FisheyeUnfolded
//
//  Created by Lal Meng on 2017/2/25.
//  Copyright © 2017年 Lal Meng. All rights reserved.
//

#import "ViewController.h"
#import "Fisheye.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIImage *image = [UIImage imageNamed:@"cat-cap"];
    _imageView.image = image;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Fisheye *fisheye = [[Fisheye alloc] init];
        //视频标定
//        NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"20170217172421.avi" ofType:nil];
//        [fisheye calibrationWithVedioPath:imagePath];
        //图片标定
        [fisheye calibrationWithImageNameArray:@[@"cat-cap1",@"cat-cap2",@"cat-cap3",
                                                 @"cat-cap4",@"cat-cap5",@"cat-cap6"]];

        UIImage *undistortImage = [fisheye undistortImage:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            _imageView.image = undistortImage;
        });
    });
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
