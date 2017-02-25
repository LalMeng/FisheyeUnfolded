//
//  Fisheye.h
//  FisheyeUnfolded
//
//  Created by Lal Meng on 2017/2/25.
//  Copyright © 2017年 Lal Meng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Fisheye : NSObject
-(BOOL)calibrationWithImageNameArray:(NSArray *)array;
-(BOOL)calibrationWithVedioPath:(NSString *)path;
-(UIImage*)undistortImage:(UIImage*)image;

@end
