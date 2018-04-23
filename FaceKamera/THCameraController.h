
#import <AVFoundation/AVFoundation.h>
#import "THBaseCameraController.h"
#import "THFaceDetectionDelegate.h"

//cc_1

@interface THCameraController : THBaseCameraController

@property (weak, nonatomic) id <THFaceDetectionDelegate> faceDetectionDelegate;

@end
