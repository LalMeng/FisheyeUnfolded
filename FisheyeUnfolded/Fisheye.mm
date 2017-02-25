//
//  Fisheye.m
//  FisheyeUnfolded
//
//  Created by Lal Meng on 2017/2/25.
//  Copyright © 2017年 Lal Meng. All rights reserved.
//

#import "Fisheye.h"
using namespace cv;

@interface Fisheye(){
    Matx33d K;
    Vec4d D;
    
    //角点数量
    cv::Size boardSize;
    
}

@end
@implementation Fisheye
- (instancetype)init
{
    self = [super init];
    if (self) {
        boardSize = cv::Size(6,9);
    }
    return self;
}



-(BOOL)calibrationWithVedioPath:(NSString *)path{
    
    std::vector<std::vector<Point2f>> imagePoints;
    cv::VideoCapture capture = VideoCapture(std::string([path UTF8String]));
    cv::Size imageSize;

    
    //打开视频
    if(capture.isOpened()){
        /*
         * 不知道什么原因VideoCapture的get和set方法都不好用，get不到值、set不生效
         * long long totalFrameNumber = capture.get(CV_CAP_PROP_FRAME_COUNT);
         * NSLog(@"共%lld帧",totalFrameNumber);
         */
        //输出接收帧
        Mat frame;
        long long l=0;
        
        while (capture.read(frame)) {
            l++;
            //当视频帧较多的时候全部读取会比较内存同时在计算时会比较耗费时间所以目前没隔几帧去一次
            if(l%10 != 0){
                continue;
            }
            //转换成3通道矩阵
            Mat rgbFrame ;
            cvtColor(frame, rgbFrame, CV_RGBA2RGB);
            
            std::vector<Point2f> point;
            if (findCorners(rgbFrame,boardSize,point)) {
                imagePoints.push_back(point);
            }
            imageSize = frame.size();
        }
    }else{
        NSLog(@"Failed to open");
        return NO;
    }
    return [self calibrationWithImagePotints:imagePoints imageSize:imageSize];
}

-(BOOL)calibrationWithImageNameArray:(NSArray *)array{
    
    if (array.count<1) {
        return NO;
    }
    
    std::vector<std::vector<Point2f>> imagePoints;
    cv::Size imageSize;

    
    Mat temp = [self cvMatFromUIImage:[UIImage imageNamed:array[0]]];
    imageSize = temp.size();

    for (NSString *name in array) {
        Mat frame = [self cvMatFromUIImage:[UIImage imageNamed:name]];
        
        Mat rgbFrame ;
        cvtColor(frame, rgbFrame, CV_RGBA2RGB);
        
        std::vector<Point2f> point;
        if (findCorners(rgbFrame,boardSize,point)) {
            imagePoints.push_back(point);
        }

    }
    
    return [self calibrationWithImagePotints:imagePoints imageSize:imageSize];
    
}

-(UIImage*)undistortImage:(UIImage*)image{
    
    Mat newK;
    Mat rview;
    Mat view =  [self cvMatFromUIImage:image];
    
    
    fisheye::estimateNewCameraMatrixForUndistortRectify(K, D, view.size(), Matx33d::eye(), newK, 1);
    fisheye::undistortImage(view, rview, K, D,newK);
    return  [self UIImageFromCVMat:rview];
}

-(BOOL)calibrationWithImagePotints:(std::vector<std::vector<Point2f>>)imagePoints imageSize:(cv::Size)imageSize {
    
    if (imagePoints.empty()) {
        return NO;
    }
    //定标版角点的三围坐标
    std::vector<std::vector<Point3f>>  objectPoints;
    
    for (int p = 0; p<imagePoints.size(); p++)
    {
        std::vector<Point3f> tempPoint;
        for (int i = 0; i<boardSize.height; i++)
        {
            for (int j = 0; j<boardSize.width; j++)
            {
                tempPoint.push_back(Point3f(i, j, 10.0));
            }
        }
        objectPoints.push_back(tempPoint);
    }
    
    
    
    std::vector<Vec3d> rvecs;
    std::vector<Vec3d> tvecs;
    int flag = 0;
    flag |= fisheye::CALIB_RECOMPUTE_EXTRINSIC;
    flag |= fisheye::CALIB_CHECK_COND;
    flag |= fisheye::CALIB_FIX_SKEW;
    
    fisheye::calibrate(objectPoints, imagePoints, imageSize, K, D, rvecs, tvecs,flag, TermCriteria(3, 20, 1e-6));
    return YES;
}

bool findCorners(Mat image,cv::Size boardSize,std::vector<Point2f>& point){
    bool found = findChessboardCorners(image, boardSize, point,CV_CALIB_CB_ADAPTIVE_THRESH | CV_CALIB_CB_FAST_CHECK | CV_CALIB_CB_NORMALIZE_IMAGE);
    
    if (found) {
        //如果找到角点则进行亚像素精确
        Mat grayImage = image;
        //转换为灰度矩阵
        cvtColor(image, grayImage, CV_RGB2GRAY);
        cornerSubPix(grayImage, point, cv::Size(11,11), cv::Size(-1,-1), TermCriteria( CV_TERMCRIT_EPS+CV_TERMCRIT_ITER, 30, 0.1 ));
        //        drawChessboardCorners(image, boardSize, Mat(point), found);
    }else{
        NSLog(@"没有找到角点");
        return NULL;
        
    }
    return found;
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
