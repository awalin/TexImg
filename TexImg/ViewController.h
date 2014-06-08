#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@class GLK2BufferObject;
@class GLKVAObject;
@class TexImgPlane;




@interface ViewController : GLKViewController


@property(nonatomic, retain) NSMutableArray* shapes;

-(void)setupGL;

//-(GLKVector4) severityMap:(float) sev;

@property (strong, nonatomic) GLKBaseEffect *effect;

typedef struct {
    GLKVector3 positionCoords;
    GLKVector2 textureCoords;
    GLKVector4 colorCoords;
}
CustomPlane;


@property CustomPlane *planes;
@property NSMutableArray* allPlanes;

@property double latMx;
@property double longMx;
@property double latMn;
@property double longMn;

@property (strong) NSMutableDictionary *colorMap;

@property (strong, nonatomic) UIWindow *window;

-(void) makePlanes;

//-(void) zoomInOut;
@property(nonatomic,retain) EAGLContext* localContext;

@end
