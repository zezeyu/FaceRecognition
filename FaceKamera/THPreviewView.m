
#import "THPreviewView.h"

@interface THPreviewView ()

@property(nonatomic,strong)CALayer *overLayer;
@property(nonatomic,strong)NSMutableDictionary *faceLayers;
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;
@end

@implementation THPreviewView

+ (Class)layerClass {

    //cc_07

    return [AVCaptureVideoPreviewLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {

    self.faceLayers = [NSMutableDictionary dictionary];
    ///以什么形式铺满
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    self.overLayer = [CALayer layer];
    
    self.overLayer.frame = self.bounds;
    
    self.overLayer.sublayerTransform = CATransform3DMakePerspective(1000);
    
    [self.previewLayer addSublayer:self.overLayer];

}

- (AVCaptureSession*)session {

    //cc_09
    return self.previewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session {

    self.previewLayer.session = session;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {

    //cc_11
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (void)didDetectFaces:(NSArray *)faces {

    ///1.直接获取的人脸数据，针对摄像头坐标系，而不是针对UIKit
    NSArray *transformFaces = [self transformedFacesFromFaces:faces];
    
    ///移除列表 如何判定人脸是否该移除
    NSMutableArray *lostFaces = [self.faceLayers.allKeys mutableCopy];
    for (AVMetadataFaceObject *face in transformFaces) {
        ///获取人脸id
        NSNumber * faceID = @(face.faceID);
        
        [lostFaces removeObject:faceID];
        
        CALayer *layer = self.faceLayers[faceID];
        //key-->faceID
        //value--->对应的图层
        
        if (!layer) {
            ///new face
            layer = [self makeFaceLayer];
            
            [self.overLayer addSublayer:layer];
            ///把最新的人脸数据添加到字典中
            self.faceLayers[faceID] = layer;
            
            
        }
        ///frame
        ///transform 缩放、旋转、移动
        layer.transform = CATransform3DIdentity;
        
        layer.frame = face.bounds;
        ///角度
        ///roll Angle--斜倾角，认得头部围绕肩部方向的倾斜角度
        ///yaw Angle --偏转角 人脸围绕Y轴旋转
        
        ///底部如何实现旋转的？？？
        if (face.hasRollAngle) {
            //3D -- 就是一个简单的矩阵
            CATransform3D t = [self transformForRollAngle:face.rollAngle];
        
            ///连接 如何连接  用线性代数
            //1.layer图层的矩阵 * 旋转矩阵
            layer.transform = CATransform3DConcat(layer.transform, t);
            
        }
        ///是否有偏转角(左右摇头)
        if (face.hasYawAngle) {
            CATransform3D t = [self transformForYawAngle:face.yawAngle];
            
            layer.transform = CATransform3DConcat(layer.transform, t);
        }
    }
    
    //移除列表
    for (NSNumber * faceID in lostFaces) {
        CALayer *layer = self.faceLayers[faceID];
        [layer removeFromSuperlayer];
        [self.faceLayers removeObjectForKey:faceID];
    }

}

- (NSArray *)transformedFacesFromFaces:(NSArray *)faces {

    NSMutableArray *transformFaces = [NSMutableArray array];
    for (AVMetadataObject *face in faces) {
        AVMetadataObject *face1 = [self.previewLayer transformedMetadataObjectForMetadataObject:face];
        
        [transformFaces addObject:face1];
    }

    return transformFaces;
}
///制造一个图层
- (CALayer *)makeFaceLayer {

    CALayer *layer = [CALayer layer];
    layer.borderWidth = 5.0f;
    layer.borderColor = [UIColor redColor].CGColor;
    layer.contents = (id)[UIImage imageNamed:@"透明view"].CGImage;
    return layer;
}



- (CATransform3D)transformForRollAngle:(CGFloat)rollAngleInDegrees {

    //cc_15
    //从度数--》弧度
    CGFloat rollAngleInRadians = THDegreesToRadians(rollAngleInDegrees);
    //旋转方法
    /*
     弧度
     围绕x,y,z
     rollAngle是针对Z轴的旋转
     CATransform3D 返回一个矩阵
     */
    
    return CATransform3DMakeRotation(rollAngleInRadians, 0.0f, 0.0f, 1.0f);
}

- (CATransform3D)transformForYawAngle:(CGFloat)yawAngleInDegrees {

    //cc_16
    CGFloat yawAnagleInRaians = THDegreesToRadians(yawAngleInDegrees);
    
    CATransform3D yawTransform = CATransform3DMakeRotation(yawAnagleInRaians, 0.0f, -1.0f, 0.0f);
    return CATransform3DConcat(yawTransform, [self orientationTransform]);
}

- (CATransform3D)orientationTransform {

    CGFloat angle = 0.0;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIDeviceOrientationLandscapeRight:
            angle = -M_PI /2.0f;
            break;
        case UIDeviceOrientationLandscapeLeft:
            angle = M_PI/2.0f;
            break;
        default:
            angle = 0.0f;
            break;
    }
    return CATransform3DMakeRotation(angle, 0.0f, 0.0f, 1.0f);
}

// The clang pragmas can be removed when you're finished with the project.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused"

static CGFloat THDegreesToRadians(CGFloat degrees) {

    //cc_18
    return degrees * M_PI/180;
}

static CATransform3D CATransform3DMakePerspective(CGFloat eyePosition) {

    //cc_19
    
    CATransform3D transform = CATransform3DIdentity;
    ///透视效果，（远小，近大） 越小透视效果就会越明显
    transform.m34 = -1.0/eyePosition;

    return transform;

}
#pragma clang diagnostic pop

@end
