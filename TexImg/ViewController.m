
#import "ViewController.h"
#import "GLK2DrawCall.h"
#import "GLKVAObject.h"
#import "GLK2BufferObject.h"
#import "TexImgPlane.h"
#import "TexImgTween.h"
#import "TexImgTweenFunction.h"
#import "TexImgFrameBuffer.h"
#import "CustomCollectionViewController.h"



@implementation ViewController {
    
    float friction;
    int taps;
    GLKTextureInfo * info ;
    GLKVector3 velocity;
    
    BOOL touchEnded;
    // modelView properties
    GLfloat zoomscale;
    GLKVector3 modelTranslation;
    GLKVector3 modelrotation;
    GLfloat zTranslation;
    NSTimeInterval _duration;
    NSTimeInterval delay;
    GLKVector3 currentRotation;
    int rows;
    int cols;
    float radius;
    float spanX ;
    float offsetX;
    float spanY;
    float offsetY;
    GLfloat eachWidth;
    GLfloat eachHeight;
    BOOL resetCalled;
    
    
    NSTimeInterval totalTimeElapsed;
    NSTimeInterval durationRemaining;
    TexImgTweenFunction* tweenFunction;
    
    BOOL pickingMode;
    GLuint pickFBO;
    GLuint glVertexAttributeBufferID;
    GLuint glColorAttributeBufferID;
    int currentTween;
    int prevTween;
    
    GLuint vertexBuffer;
    GLuint colorBuffer;
    
    CGPoint startPoint;
    CGPoint moveToPoint;
}


@synthesize effect;

-(void) viewDidLoad
{
	[super viewDidLoad];
    
    /** Creating and "making current" an EAGLContext must be the very first thing any OpenGL app does! */
	if( self.localContext == nil )
	{
		self.localContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	}
	NSAssert( self.localContext != nil, @"Failed to create ES context");
	[EAGLContext setCurrentContext:self.localContext]; // VERY important! GL silently stops working without this

    //setting up initial values from UI
    [self changeDuration:self.durationSlider];
    [self addDelay:self.delaySlider];
    [self segmentValueChanged: self.viewTypeSegments];


   UIStoryboard *myStoryboard = [UIStoryboard storyboardWithName:@"main"
                                                           bundle:[NSBundle mainBundle]];
    self.collectionViewController = [myStoryboard instantiateViewControllerWithIdentifier:@"collectionViewController"];
    self.collectionViewController.clearsSelectionOnViewWillAppear = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEasing:) name:@"Easing" object:nil];

	
	/** Enable GL rendering by enabling the GLKView (enable it by giving it an EAGLContext to render to) */
	GLKView *view = (GLKView *)self.view;
	view.context = self.localContext;
	view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    //To enable multisamle, it needs to be compiled as iPad, not univresal device.
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    
    
//	[view bindDrawable];
    ////jesture //////
    UITapGestureRecognizer * dtRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    dtRec.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:dtRec];
    
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotateWithPanGesture:)];
    [self.view addGestureRecognizer:self.panRecognizer];
    
    self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomWithPinchGesture:)];
    [self.view addGestureRecognizer:self.pinchRecognizer];
    
    [self initData];
    [self setupGL];
    totalTimeElapsed= 0.0;
}


-(void) makePlanes{
    
    GLfloat s=0.0,t=0.0;
    GLfloat y = offsetY+ eachHeight/2;
    //the first plane is on the BL corner of the screen
    for(int i=0; i< rows; i++){ // fixed phi
        
        GLfloat x = offsetX + eachWidth/2;
        for(int j =0; j < cols; j++) { // fixed theta
            
            TexImgPlane* plane = [self.allPlanes objectAtIndex:(cols*i+j)];    //Position
            
            //BL
            s =  x - plane.width/2 ;
            t =  y - plane.height/2;
            GLKVector3 vrtx = GLKVector3Make(s, t, 0);
            plane.vertices[0] = vrtx;
            
            //BR
            s =  x + plane.width/2 ;//s+eachRow;
            t =  y - plane.height/2;  //t;
            vrtx = GLKVector3Make(s, t, 0);
            plane.vertices[1] = vrtx;
            
            
            //TL
            s =  x - plane.width/2 ;//s+eachRow;
            t =  y + plane.height/2;  //t;
            vrtx = GLKVector3Make(s, t, 0); // base
            plane.vertices[2] = vrtx;
            
            
            //TR
            s =  x+ plane.width/2 ;//s+eachRow;
            t =  y+ plane.height/2;  //t;
            vrtx =  GLKVector3Make(s, t, 0); // base
            plane.vertices[3] = vrtx;
            
            //two more
            //BR
            s = x + plane.width/2 ;//s+eachRow;
            t = y - plane.height/2;  //t;
            vrtx = GLKVector3Make(s, t, 0); // base
            plane.vertices[4] = vrtx;
            
            //TL
            s = x - plane.width/2 ;//s+eachRow;
            t = y + plane.height/2;  //t;
            vrtx = GLKVector3Make(s, t, 0); // base
            plane.vertices[5] = vrtx;
            
            //end of vertex creation
            x = x + eachWidth;
        }
        y = y + eachHeight;
    }
    
    
    for(int i=0; i< rows; i++){
        for(int j =0; j < cols; j++) {
            int index = (cols*i+j);
            TexImgPlane* plane = [self.allPlanes objectAtIndex:index];
            index = 6*(cols*i+j);
            for(int t =0; t < 6; t++){
                self.planes[index+t].positionCoords = plane.vertices[t];
                self.planes[index+t].textureCoords = plane.texCoord[t];
                self.planes[index+t].colorCoords = plane.colors[t];
            }
        }
    }
}

//This is static part//

-(void) initData{
    
    int total =500*6;
    self.planes = (CustomPlane*) malloc(total*sizeof(CustomPlane));
    self.allPlanes = [[NSMutableArray alloc] initWithCapacity:500];
    self.tweens = [[NSMutableArray alloc] initWithCapacity:500];
    self.shapes = [[NSMutableArray alloc] init];
    touchEnded = NO;
    friction = 0.90;
    durationRemaining = _duration;
    velocity = GLKVector3Make(0,0,0);
   
    rows=20;
    cols=25;
    radius = 1;
    resetCalled = NO;
    tweenFunction= [[TexImgTweenFunction alloc] init];
    
    prevTween=-1;
    currentTween=-1;
    
    spanX = 2.0*5/4;
    offsetX = -1.0;
    
    spanY = 2.0f;//rect.size.height;// 2.0;
    offsetY = -1.0f;
    // (u, v) is the centre of the texture
    eachWidth = spanX/cols;
    eachHeight = spanY/rows;
    
    GLfloat s=0.0,t=0.0;
    GLfloat u=0.0,v=0.0;
    GLKVector2 txtr;
    float spanTX = 1.0; //rect.size.width;//2.0;
    float offsetTX = 0.0;
    
    float spanTY = 1.0f;//rect.size.height;// 2.0;
    float offsetTY = 0.0f;
    GLfloat eachWidthT = spanTX/cols;
    GLfloat eachHeightT = spanTY/rows;
    
    // centre point for each plane
    v = offsetTY+ eachHeightT/2;
    GLfloat y = offsetY+ eachHeight/2;
    GLfloat eachTheta = GLKMathDegreesToRadians(180.0f/rows);
    // 0 to 180, inclination from vertical axis, bottom row, inclination 180, top row inclination 0
    GLfloat eachPhi = GLKMathDegreesToRadians(360.0f/cols); // 0 to 360, azimuthal, 14.
    
    float theta = GLKMathDegreesToRadians(180.0f) - eachTheta/2;
    
    for(int i=0; i< rows; i++){ // fixed phi
        
        GLfloat x = offsetX + eachWidth/2;
        float phi = GLKMathDegreesToRadians(-180.0f); // j*eachPhi;
        
        u = offsetTX + eachWidthT/2; // center x of texture
        int j;
        for( j =0; j < cols; j++) { // fixed theta
            
            TexImgPlane* plane = [[TexImgPlane alloc] init];
            int index = (cols*i+j);
            plane.theta = theta;
            plane.planeId= index;
            plane.phi = phi;
            plane.row = i;
            plane.col = j;
            plane.height = eachHeight*0.9;
            plane.width= eachWidth*0.9;
            
            TexImgTween* tween = [[TexImgTween alloc] init];
            tween.planeId = index;
            tween.targetPhi = phi;
            tween.targetTheta = theta;
            tween.plane = plane;
            tween.delay = index*delay;
            
            GLfloat x1 = radius*sin(plane.theta)*cos(plane.phi);
            GLfloat y1 = radius*sin(plane.theta)*sin(plane.phi);
            GLfloat z1 = radius*cos(plane.theta);
            
            tween.globeCenter = GLKVector3Make( y1, z1, x1 );
            tween.wallCenter =  GLKVector3Make(x,y,0);
            tween.duration = _duration;
            
            //Texture
            //BL (0,0)
            s = u - eachWidthT/2;
            t = v - eachHeightT/2;
            txtr = GLKVector2Make(s, t); // BL (0,0)
            plane.texCoord[0] = txtr;
            
            //BR (1,0)
            s = u + eachWidthT/2;
            t = v - eachHeightT/2;
            txtr = GLKVector2Make(s, t); // BR
            plane.texCoord[1] = txtr;
            
            //TL (0,1)
            s = u - eachWidthT/2;
            t = v + eachHeightT/2;
            txtr = GLKVector2Make(s, t); // TL
            plane.texCoord[2] = txtr;
            
            //TR
            s = u + eachWidthT/2;
            t = v + eachHeightT/2;
            txtr = GLKVector2Make(s, t); // TR
            plane.texCoord[3] = txtr;
            
            //two more
            //BR (1,0)
            s = u + eachWidthT/2;
            t = v - eachHeightT/2;
            txtr = GLKVector2Make(s, t); // BR
            plane.texCoord[4] = txtr;
            
            
            //TL (0,1)
            s = u - eachWidthT/2;
            t = v + eachHeightT/2;
            txtr = GLKVector2Make(s, t); // TL
            plane.texCoord[5] = txtr;
            
            plane.colorId = index+1;
            
            
			int red = plane.colorId % 255;
			int green = plane.colorId>= 255 ? (plane.colorId/255)%255 : 0;
			int blue = plane.colorId>=255*255 ? (plane.colorId/255)/255 : 0;
			GLKVector4 colorV  = GLKVector4Make(red/255.0f, green/255.0f, blue/255.0f, 1);

            //Colors
//            GLKVector4 colorV =  GLKVector4Make((i+0.0f)/rows, (j+0.0f)/cols, 0.0, 1.0);//white color
            plane.colors[0]= colorV;
            plane.colors[1]= colorV;
            plane.colors[2]= colorV;
            plane.colors[3]= colorV;
            plane.colors[4]= colorV;
            plane.colors[5]= colorV;
            
            [self.allPlanes insertObject:plane atIndex:(cols*i+j)];
            [self.tweens insertObject:tween atIndex:(cols*i+j)];
            
            phi = phi + eachPhi;
            u = u + eachWidthT;
            x = x + eachWidth;
            
            index = 6*(cols*i+j);
            for(int t =0; t < 6; t++){
                self.planes[index+t].positionCoords = plane.vertices[t];
                self.planes[index+t].textureCoords = plane.texCoord[t];
                self.planes[index+t].colorCoords = plane.colors[t];
                
            }
        }
        v = v + eachHeightT;
        y = y + eachHeight;
        theta = theta - eachTheta;
    }
    
    
}

-(void) changeView:(ViewType)viewType{
    pickingMode=NO;
    self.viewType = viewType;
    self.viewChanged=YES;
    totalTimeElapsed=0.0;
    durationRemaining = _duration;
    NSDate* currentTime = [NSDate date];
    
    for(int i=0; i< rows; i++){
        for(int j =0; j < cols; j++) {
            int index = (cols*i+j);
            TexImgTween* tween = [self.tweens objectAtIndex:index];
            tween.startTime = currentTime;
            if(self.viewType==GLOBE){
                [[self.tweens objectAtIndex:index] setTargetCenter: tween.globeCenter];
                [[self.tweens objectAtIndex:index] setSourceCenter: tween.wallCenter];
            } else if(self.viewType==WALL){
                [[self.tweens objectAtIndex:index] setTargetCenter: tween.wallCenter];
                [[self.tweens objectAtIndex:index] setSourceCenter: tween.globeCenter];
            } else if(self.viewType==RESET){
                [self resetView];
                return;
            }
        }
    }
    
}

-(void) setDuration:(float) val {
    _duration = val;
    self.viewChanged=NO;
    
    for(int i=0; i< rows; i++){
        for(int j =0; j < cols; j++) {
            int index = (cols*i+j);
            TexImgTween* tween = [self.tweens objectAtIndex:index];
            tween.duration = _duration;
        }
    }
    self.viewChanged = YES;
}

/*
 This is dynamic part
 */

-(void) makeGlobe{
    
    GLKVector3 vrtx;
    //the first plane is on the BL corner of the screen
    for(int i=0; i< rows; i++){ // fixed phi
        int j;
        for( j =0; j < cols; j++) { // fixed theta
            TexImgPlane* plane = [self.allPlanes objectAtIndex:(cols*i+j)];
            
            GLfloat x = radius*sin(plane.theta)*cos(plane.phi);
            GLfloat y = radius*sin(plane.theta)*sin(plane.phi);
            GLfloat z = radius*cos(plane.theta);
            
            GLKMatrix3 rot = GLKMatrix3MakeXRotation((M_PI+ M_PI_2 + plane.theta ) );
            rot = GLKMatrix3Multiply(GLKMatrix3MakeYRotation( plane.phi), rot);
            
            plane.center = GLKVector3Make( y, z, x );
            GLKVector3 c = GLKVector3Make( 0, 0, 0 );
            
            //BL
            vrtx = GLKVector3Make(c.x - plane.width/2,  c.y- plane.height/2 ,  c.z );
            vrtx =  GLKMatrix3MultiplyVector3(rot, vrtx);
            vrtx = GLKVector3Add(vrtx, plane.center);
            plane.vertices[0] = vrtx;
            
            //BR
            vrtx = GLKVector3Make(c.x + plane.width/2,  c.y- plane.height/2 ,  c.z );
            vrtx =  GLKMatrix3MultiplyVector3(rot, vrtx);
            vrtx = GLKVector3Add(vrtx, plane.center);
            plane.vertices[1] = vrtx;
            
            //TL
            vrtx = GLKVector3Make(c.x - plane.width/2,  c.y + plane.height/2 ,  c.z);
            vrtx =  GLKMatrix3MultiplyVector3(rot, vrtx);
            vrtx = GLKVector3Add(vrtx, plane.center);
            plane.vertices[2] = vrtx;
            
            //TR
            vrtx = GLKVector3Make(c.x + plane.width/2,  c.y + plane.height/2 ,  c.z );
            vrtx =  GLKMatrix3MultiplyVector3(rot, vrtx);
            vrtx = GLKVector3Add(vrtx, plane.center);
            plane.vertices[3] = vrtx;
            
            ///two more
            //BR
            vrtx = GLKVector3Make( c.x + plane.width/2,  c.y - plane.height/2 ,  c.z );
            vrtx = GLKMatrix3MultiplyVector3(rot, vrtx);
            vrtx = GLKVector3Add(vrtx, plane.center);
            plane.vertices[4] = vrtx;
            
            //TL
            vrtx = GLKVector3Make(c.x - plane.width/2,  c.y + plane.height/2 ,  c.z ) ;
            vrtx =  GLKMatrix3MultiplyVector3(rot, vrtx);
            vrtx = GLKVector3Add(vrtx, plane.center);
            plane.vertices[5] = vrtx;
        }
    }
    
    
    for(int i=0; i< rows; i++){
        for(int j =0; j < cols; j++) {
            int index = (cols*i+j);
            TexImgPlane* plane = [self.allPlanes objectAtIndex:index];
            index = 6*(cols*i+j);
            for(int t =0; t < 6; t++){
                self.planes[index+t].positionCoords = plane.vertices[t];
                self.planes[index+t].textureCoords = plane.texCoord[t];
                self.planes[index+t].colorCoords = plane.colors[t];
                
            }
        }
        
    }
    
}

-(void) setTweenFunction:(NSString*) function{
//    NSLog(@"%@", function);
    tweenFunction.selectedFunction=function;
    
}

-(void) tweenView{
    
    if(currentTween<0){
        return;
    }
    //first deal with prev tween, take it back to the wall
    if(prevTween>-1){
        NSTimeInterval timeElapsed = [self timeSinceLastUpdate];
        
        int index = prevTween;
        TexImgPlane* plane = [self.allPlanes objectAtIndex:index];
        TexImgTween* tween = [self.tweens objectAtIndex:index];
        durationRemaining = tween.duration - totalTimeElapsed;
        float ratio = timeElapsed/durationRemaining;
        ratio = [tweenFunction calculateTweenWithTime:timeElapsed duration:durationRemaining];
        
        
        [plane updateVerticesWithTween:tween
                                  mode:self.viewType
                  timeElapsed:timeElapsed
                     duration:durationRemaining
                        ratio:ratio];
        index = index*6;
        for(int t =0; t < 6; t++){
            self.planes[index+t].positionCoords = plane.vertices[t];
        }
        
        
    }
    //then deal with current tween
    NSTimeInterval timeElapsed = [self timeSinceLastUpdate];
    int index = currentTween;
    TexImgPlane* plane = [self.allPlanes objectAtIndex:index];
    TexImgTween* tween = [self.tweens objectAtIndex:index];
    durationRemaining = tween.duration - totalTimeElapsed;
    float ratio = timeElapsed/durationRemaining;
    ratio = [tweenFunction calculateTweenWithTime:timeElapsed duration:durationRemaining];
    
    [plane updateVerticesWithTween:tween
                     mode:self.viewType
              timeElapsed:timeElapsed
                 duration:durationRemaining
                    ratio:ratio];
    index = index*6;
    for(int t =0; t < 6; t++){
        self.planes[index+t].positionCoords = plane.vertices[t];
    }
    totalTimeElapsed  += timeElapsed;
}


//call animate from the update function

-(void) animateView{
    if(self.viewChanged==NO){
        return;
    }
    
    NSTimeInterval timeElapsed = [self timeSinceLastUpdate];
    
    for(int i=0; i< rows; i++) {
        for(int j =0; j < cols; j++) {
            int index = (cols*i+j);
            TexImgPlane* plane = [self.allPlanes objectAtIndex:index];
            TexImgTween* tween = [self.tweens objectAtIndex:index];
            durationRemaining = tween.duration - totalTimeElapsed;
            float ratio = timeElapsed/durationRemaining;
            ratio = [tweenFunction calculateTweenWithTime:timeElapsed duration:durationRemaining];
            float timePassed = -[tween.startTime timeIntervalSinceNow];
            
            if(timePassed> tween.delay){
                
                [plane updateVertices:tween.targetCenter
                         sourceCEnter:tween.sourceCenter
                                 mode:self.viewType
                          timeElapsed:timeElapsed
                             duration:durationRemaining
                                ratio:ratio];
                
                index = 6*(cols*i+j);
                for(int t =0; t < 6; t++){
                    self.planes[index+t].positionCoords = plane.vertices[t];
                }
            }
            
        }
    }
    totalTimeElapsed  += timeElapsed;
}


-(void)setupGL{
    
    /** All the local setup for the ViewController */
    
    self.effect = [[GLKBaseEffect alloc] init];
    zTranslation = 3.0f;
    taps=0;
    zoomscale = 1;
    modelTranslation = GLKVector3Make(0.0, 0.0, zTranslation);
    modelrotation = GLKVector3Make(0, 0, 0);
    currentRotation = GLKVector3Make(0, 0, 0);

    glEnable(GL_DEPTH_TEST);
    
    NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES],
                              GLKTextureLoaderOriginBottomLeft,
                              nil];
    NSError * error;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"canvas1" ofType:@"png"];
    
    info = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if (info == nil) {
        NSLog(@"Error loading file: %@", [error localizedDescription]);
    }
    self.effect.texture2d0.name = info.name;
    self.shapes = [NSMutableArray array];
    
    if(self.viewType==WALL){
        [self makePlanes];}
    else if (self.viewType==GLOBE){
       [self makeGlobe];
    }
    
	GLK2DrawCall* drawObject = [[GLK2DrawCall alloc] init ];
    drawObject.mode = GL_TRIANGLES;
    
    drawObject.numOfVerticesToDraw = rows*cols*6;
    drawObject.VAO = [[GLKVAObject alloc] init];
    
    [drawObject.VAO addVBOForAttribute:GLKVertexAttribPosition
                        filledWithData:self.planes //addres of the bytes to copy
                           numVertices:drawObject.numOfVerticesToDraw
                           numOfFloats:3 //floats in GLKVector3
                                stride:sizeof(CustomPlane)
                                offset:(void *)offsetof(CustomPlane, positionCoords)];
    
    
    [drawObject.VAO addVBOForAttribute:GLKVertexAttribTexCoord0
                        filledWithData:self.planes //addres of the bytes to copy
                           numVertices:drawObject.numOfVerticesToDraw
                           numOfFloats:2
                                stride:sizeof(CustomPlane)
                                offset:(void *)offsetof(CustomPlane, textureCoords) ];

    [drawObject.VAO addVBOForAttribute:GLKVertexAttribColor
                        filledWithData:self.planes //addres of the bytes to copy
                           numVertices:drawObject.numOfVerticesToDraw
                           numOfFloats:2
                                stride:sizeof(CustomPlane)
                                offset:(void *)offsetof(CustomPlane, colorCoords) ];

    NSString *bufferType = [NSString stringWithFormat:@"%d",GLKVertexAttribPosition];
    vertexBuffer = [(GLK2BufferObject*)[drawObject.VAO.VBOs objectForKey:bufferType] glName];
    NSLog(@"vertex %d", vertexBuffer);
    
    bufferType = [NSString stringWithFormat:@"%d",GLKVertexAttribColor];
    colorBuffer = [(GLK2BufferObject*)[drawObject.VAO.VBOs objectForKey:bufferType] glName];
    NSLog(@"vertex %d", colorBuffer);
    
    [self.shapes addObject: drawObject];
    
}


-(void) setDelay:(float) val {
    
    delay = val;
    
    for(int i=0; i< rows; i++){
        for(int j =0; j < cols; j++) {
            int index = (cols*i+j);
            TexImgTween* tween = [self.tweens objectAtIndex:index];
            tween.delay = index*delay;
        }
    }
    
    
}

-(void) resetView{
    
//    resetCalled = YES;
    modelTranslation.z = zTranslation;
    modelrotation = GLKVector3Make(0, 0, 0);
    velocity = GLKVector3Make(0, 0, 0);
    touchEnded = YES;
    totalTimeElapsed = _duration;
    
}

/*called after update loop
 */

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(0.1, 0.1, 0.1, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.001f, 100.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;

// example code
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(0.0f), 0.0f, 0.0f, 1.0f);
    baseModelViewMatrix = GLKMatrix4Translate(baseModelViewMatrix, modelTranslation.x, -modelTranslation.y, -modelTranslation.z);
	GLKMatrix4 rotymatrix   = GLKMatrix4MakeYRotation(modelrotation.y);
	GLKMatrix4 rotxmatrix  = GLKMatrix4MakeXRotation(modelrotation.x);
	GLKMatrix4 modelViewMatrix = rotxmatrix;
	modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotymatrix);
	modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    
	self.effect.transform.modelviewMatrix = modelViewMatrix;


    //my code
    
//    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -modelTranslation.z);
    
    
//    GLKMatrix4 xRot = GLKMatrix4MakeXRotation(modelrotation.x);
//    
//    GLKMatrix4 yRot = GLKMatrix4MakeXRotation(modelrotation.y);
//    
//    GLKMatrix4 baseRot = GLKMatrix4Multiply(xRot, yRot);
//    
//    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, baseRot);
    
// mtrix method
    
//    GLKMatrix4 rotMatrix = GLKMatrix4Identity;
//    bool isInvertible;
//    
//    GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(rotMatrix, &isInvertible),
//                                                 GLKVector3Make(1, 0, 0));
//    rotMatrix = GLKMatrix4Rotate(rotMatrix, modelrotation.x, xAxis.x, xAxis.y, xAxis.z);
//    GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(rotMatrix, &isInvertible),
//                                                 GLKVector3Make(0, 1, 0));
//    rotMatrix = GLKMatrix4Rotate(rotMatrix, modelrotation.y, yAxis.x, yAxis.y, yAxis.z);
//    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotMatrix);
//    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    self.effect.texture2d0.enabled = YES;
    [self renderSingleFrame];
//    [self   drawInBackBuffer];
}

-(void) update {
    
    float velocityLength = GLKVector3Length(velocity);
    //change the vertex positions here for animation
    GLK2DrawCall* drawObject = [self.shapes objectAtIndex:0];
    
    if(self.viewChanged) {
        if(pickingMode) {
            [self tweenView];
        } else {
            [self animateView];
        }
        
        [drawObject.VAO updateVBOForAttribute:GLKVertexAttribPosition
                               filledWithData:self.planes //addres of the bytes to copy
                                  numVertices:drawObject.numOfVerticesToDraw
                                  numOfFloats:3 //floats in GLKVector3
                                       stride:sizeof(CustomPlane)
                                       offset:(void *)offsetof(CustomPlane, positionCoords)];
        
    }
    if(touchEnded && velocityLength>0.0001){
        
        NSLog(@" updateing rotation with velocity ");
        
        modelrotation.x += velocity.x;
        modelrotation.y += velocity.y;

        velocity.y = velocity.y * friction;
        velocity.x = velocity.x * friction;
        
    }
    
//    if (modelrotation.x>M_PI) modelrotation.x -= M_PI*2;
//	else if (modelrotation.x<-M_PI) modelrotation.x += M_PI*2;
//	if (modelrotation.y>M_PI) modelrotation.y -= M_PI*2;
//	else if (modelrotation.y<-M_PI) modelrotation.y += M_PI*2;

}

-(void) renderSingleFrame {
    
	if( [EAGLContext currentContext] == nil ) // skip until we have a context
    {
		NSLog(@"We have no gl context; skipping all frame rendering");
		return;
	}
    if( self.shapes == nil || self.shapes.count < 1 ){
		NSLog(@"no drawcalls specified; rendering nothing");
        return;
    }
    //        [self.drawCalls makeObjectsPerformSelector:@selector(renderInScene:) withObject:self];
    
    for( GLK2DrawCall* drawCall in self.shapes ){
        //loop throug the different images
        
        if( drawCall.VAO != nil ){
            [self.effect prepareToDraw];
            [drawCall drawWithMode:GL_TRIANGLES];
        }
        else {
            NSLog(@"not available");
        }
    }
}


-(void) zoomWithPinchGesture:(UIPinchGestureRecognizer*) sender{
    
    GLfloat scale;
	
    if (sender.state==UIGestureRecognizerStateBegan) {
		
	}
	else if (sender.state==UIGestureRecognizerStateChanged) {
		scale = zoomscale * sender.scale;
		if (scale>4.0) scale = 4.0;
		else if (scale<0.25) scale = 0.25;
		modelTranslation.z = zTranslation/scale;
	}
	else if (sender.state==UIGestureRecognizerStateEnded){
		zoomscale *= sender.scale;
		if (zoomscale<0.25) zoomscale = 0.25;
		else if (zoomscale>4) zoomscale = 4;
	}
    
    
}



-(void) rotateWithPanGesture:(UIPanGestureRecognizer*) recognizer {
    
    CGPoint velo = [recognizer velocityInView:self.view];
    CGPoint diff = [recognizer translationInView:self.view];
    
    if( [recognizer numberOfTouches]==1){
   
    if (recognizer.state==UIGestureRecognizerStateBegan) {
        touchEnded = NO;
        velocity.x = 0;
        velocity.y = 0;
        startPoint = [recognizer locationInView:self.view];

        NSLog(@"start  %f, %f", startPoint.x, startPoint.y);

        currentRotation.x = modelrotation.x;
        currentRotation.y = modelrotation.y;

    } else if (recognizer.state==UIGestureRecognizerStateChanged) {
        //For every pixel the user drags, we rotate the cube 1/2 degree.
        //when the user drags from left to right, we actually want to rotate around the y axis (rotY)
        NSLog(@"Touch drag ");
        if(touchEnded) return;
//        
//        velocity.x = 0;
//        velocity.y = 0;
//        
        moveToPoint = [recognizer locationInView:self.view];
        NSLog(@"move %F, %f", moveToPoint.x, moveToPoint.y);
//        
//        diff.x = moveToPoint.x - startPoint.x;
//        diff.y = moveToPoint.y - startPoint.y;

        NSLog(@"%f, %f", diff.x, diff.y);
        modelrotation.x +=  (diff.y * 0.01);
        modelrotation.y +=  (diff.x * 0.01);

        
    }
    else if (recognizer.state==UIGestureRecognizerStateEnded) {
        touchEnded = YES;
       
        
    }
    }else if (recognizer.state==UIGestureRecognizerStateEnded)  {
    
        velocity.x = velo.y*0.005;
        velocity.y = velo.x*0.005;
        NSLog(@"Touch ended ");
        touchEnded = YES;
    
    }
    
}




- (void)renderBackBuffer {
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
	GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.001f, 100.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -modelTranslation.z);
//    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, _rotMatrix);
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    self.effect.transform.modelviewMatrix = modelViewMatrix;
	
    self.effect.texture2d0.enabled = GL_FALSE;
    [self.effect prepareToDraw];
	
	glDisable(GL_BLEND);
	glDepthMask(GL_TRUE);
    
    //preparing attributes
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(
                          GLKVertexAttribPosition,
                          3,
                          GL_FLOAT,
                          GL_FALSE,
                          sizeof(CustomPlane),
                          (void *)offsetof(CustomPlane, positionCoords)
                          );
    
    
	glBindBuffer(GL_ARRAY_BUFFER, colorBuffer);
	glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(
                          GLKVertexAttribColor,
                          4,
                          GL_FLOAT,
                          GL_FALSE,
                          sizeof(CustomPlane),
                          (void *)offsetof(CustomPlane, colorCoords)
                          );

//    glBindFramebuffer(GL_FRAMEBUFFER, pickFBO);
    glDrawArrays(GL_TRIANGLES, 0, rows*cols*6);

}

/////////////////////////////////////////////////////////////////
- (void)pickPlaneAtViewLocation: (CGPoint)aViewLocation {
    
    //    NSLog(@"inside picking by location");
    GLKView *glView = (GLKView *)self.view;
    NSAssert([glView isKindOfClass:[GLKView class]],
             @"View controller's view is not a GLKView");
    
    // Make the view's context current
//    [EAGLContext setCurrentContext:glView.context];
    
    
    const GLfloat width = [glView drawableWidth];
    const GLfloat height = [glView drawableHeight];
    GLuint colorRenderbuffer;
    GLuint depthRenderbuffer;

    
    NSAssert(0 < width && 0 < height, @"Invalid drawble size");
    
    glBindVertexArrayOES(0);
    //generate frame buffer
//    if(0 == pickFBO) // just create the frame buffer rather than creating everything, so other creation will be there every time
    
    {
        NSInteger height = ((GLKView *)self.view).drawableHeight;
        NSInteger width = ((GLKView *)self.view).drawableWidth;
        
        //create framebuffer and bind it
        GLuint framebuffer;
        glGenFramebuffers(1, &framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        
        //  Create a color renderbuffer, allocate storage for it, and attach it to the framebuffer’s color attachment point.
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, width, height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER, colorRenderbuffer);
        
        
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, width, height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER) ;
        if(status != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"failed to make complete framebuffer object %x", status);
        }
        
#ifdef DEBUG
        {  // Report any errors
            GLenum error = glGetError();
            if(GL_NO_ERROR != error) {
                NSLog(@"GL Error: 0x%x", error);
            }
        }
#endif
        pickFBO = framebuffer;
    }

    
#ifdef DEBUG
    {  // Report any errors
        GLenum error = glGetError();
        if(GL_NO_ERROR != error)
        {
            NSLog(@"GL Error: 0x%x", error);
        }
    }
#endif
    
    
    [self renderBackBuffer];
    
    
    Byte pixelColor[4] = {0,};
    CGFloat scale = UIScreen.mainScreen.scale;
    glReadPixels(aViewLocation.x*scale, height- aViewLocation.y*scale, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixelColor);
    NSLog(@"R:%hhu,G:%hhu,B:%hhu", pixelColor[0], pixelColor[1], pixelColor[2]);

    self.effect.texture2d0.enabled = YES;
    
    glDisableVertexAttribArray(GLKVertexAttribColor);
    
//    glDeleteRenderbuffers(1, &colorRenderbuffer);
//	glDeleteRenderbuffers(1, &depthRenderbuffer);

    glBindVertexArrayOES(0); //unbind the vertex array, as a precaution against accidental changes by other classes
    // Restore OpenGL state that picking changed
    glBindFramebuffer(GL_FRAMEBUFFER, 0); // default frame buffer
    
    int ind = (pixelColor[0] + pixelColor[1]*255 + pixelColor[2] * 255 * 255);// (row*cols)+col;
    if(ind==0) return;
    ind -=1;
    
    NSLog(@"%d ", ind);
    if(currentTween>-1){
        //current becomes prev and goes back to its original position
        prevTween = currentTween;
        TexImgTween* tweenp = [self.tweens objectAtIndex:prevTween];
        TexImgPlane* planep = [self.allPlanes objectAtIndex:prevTween];

        if(self.viewType==WALL)
            tweenp.targetCenter = tweenp.wallCenter;
        else if (self.viewType==GLOBE){
            tweenp.targetCenter = tweenp.globeCenter;
            tweenp.targetPhi = planep.phi;
            tweenp.targetTheta = planep.theta;
        }

    }
    //now deal with the new one
    currentTween = ind;
    TexImgTween* tween = [self.tweens objectAtIndex:ind];
    TexImgPlane* plane = [self.allPlanes objectAtIndex:ind];
    if(currentTween==prevTween){ // go back to the wall or to the globe
        
        if(self.viewType==WALL)
            tween.targetCenter = tween.wallCenter;
        else if (self.viewType==GLOBE){
            tween.targetCenter = tween.globeCenter;
            tween.targetTheta = plane.theta;
            tween.targetPhi = plane.phi;
        }
    }
    else { //come to the front
        if(self.viewType==WALL)
            tween.targetCenter = GLKVector3Make(0, 0, 2.0);
        else if (self.viewType==GLOBE){
            NSLog(@"GLOBE TYPE VIEW");
            tween.targetCenter = GLKVector3Make(0, 0, 0.0); // ??
            tween.targetPhi = 0;
            tween.targetTheta = GLKMathDegreesToRadians(90);
        }

    }
    
}


- (void)doubleTap:(UITapGestureRecognizer *)tap {
    
    CGPoint loc = [tap locationInView:[self view]];
    pickingMode = YES;
    [self pickPlaneAtViewLocation:loc];
    self.viewChanged = YES;
    totalTimeElapsed=0.0;
    durationRemaining = _duration;
    
    
}


-(IBAction) openFunctionMenu:(id) sender {
    
    UIButton* button = sender;

    
    if(!self.popOverController){
        
        CustomCollectionViewController* content = self.collectionViewController;
        self.popOverController = [[UIPopoverController alloc]
                                  initWithContentViewController:content];
        self.popOverController.delegate = self;
        self.popOverController.backgroundColor=[UIColor colorWithRed:0.2 green:0.2 blue:0.22 alpha:0.8];
    }
    
    [self.popOverController presentPopoverFromRect: button.frame
                                            inView: self.view
                          permittedArrowDirections:UIPopoverArrowDirectionAny
                                          animated:YES];
}

//may not be needed anymore
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
//    NSLog(@"popover closed");
    [self setTweenFunction:[[self collectionViewController] selectedFunction]];
}

-(void)handleEasing:(NSNotification *)note
{   if (self.popOverController) {
    [self setTweenFunction:[[self collectionViewController] selectedFunction]];
    [self.popOverController dismissPopoverAnimated:YES];
}
}

-(IBAction) changeDuration:(id)sender{
    float val=  [(UISlider*)sender value];
    //    NSLog(@"%f", val);
    [self setDuration: val];
}



-(IBAction) addDelay:(id)sender {
    float val=  [(UISlider*)sender value];
    [self setDelay: val];
}

-(IBAction)segmentValueChanged:(id)sender {
    int i = [sender selectedSegmentIndex];
    if (i== GLOBE){
        [self changeView: GLOBE];
    }
    else if(i== WALL) {
        [self changeView: WALL];
    }else if(i==RESET) {
        [self changeView:RESET];
    };
}


@end
