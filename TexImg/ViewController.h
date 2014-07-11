#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@class GLK2BufferObject;
@class GLKVAObject;
@class TexImgPlane;
@class TexImgTweens;
@class TexImgTweenFunction;
@class CustomCollectionViewController;

typedef struct {
    GLKVector3 positionCoords;
    GLKVector2 textureCoords;
    GLKVector4 colorCoords;
}
CustomPlane;

typedef enum {
    GLOBE,
    WALL,
    RESET
} ViewType;

@interface ViewController : GLKViewController  <UIPopoverControllerDelegate>

@property CustomCollectionViewController* collectionViewController;
@property UIPopoverController* popOverController;
@property(nonatomic, retain) NSMutableArray* shapes;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property CustomPlane *planes; // array of the planes
@property NSMutableArray* tweens;
@property NSMutableArray* allPlanes;

@property BOOL viewChanged;
@property ViewType viewType;
@property double latMx;
@property double longMx;
@property double latMn;
@property double longMn;

@property UIPanGestureRecognizer *panRecognizer;
@property UIPinchGestureRecognizer *pinchRecognizer;
@property(nonatomic,retain) EAGLContext* localContext;
@property (strong) NSMutableDictionary *colorMap;

@property (strong, nonatomic) UIWindow *window;
@property IBOutlet UISlider* durationSlider;
@property IBOutlet UISlider* delaySlider;
@property IBOutlet UISegmentedControl* viewTypeSegments;
@property IBOutlet UIButton* tweenButton;
@property IBOutlet UIButton* resetButton;

-(void) setDuration:(float) val;
-(void) setDelay:(float) val;
-(void) makePlanes;
-(void) makeGlobe;
-(void) changeView:(ViewType)viewType;
-(void) setupGL;
-(void) setTweenFunction:(NSString*) function;

-(IBAction) addDelay:(id)sender;
-(IBAction) resetView:(id) sender;
-(IBAction) changeDuration:(id)sender;
-(IBAction) openFunctionMenu:(id) sender;
-(IBAction) segmentValueChanged:(id)sender;


@end
