/**
 Version 1: c.f. http://t-machine.org/index.php/2013/09/08/opengl-es-2-basic-drawing/
 Part 3: ... not published yet ...
 */
#import "ViewController.h"
#import "GLK2DrawCall.h"
#import "GLKVAObject.h"
#import "GLK2BufferObject.h"
#import "TexImgPlane.h"
#import "TexImgTween.h"
#import "TexImgTweenFunction.h"
#import "TexImgFrameBuffer.h"


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
    GLKMatrix4 _rotMatrix;
    GLfloat zTranslation;
    NSTimeInterval _duration;
    NSTimeInterval delay;
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
    BOOL pickingMode;
    
    NSTimeInterval totalTimeElapsed;
    NSTimeInterval durationRemaining;
    TexImgTweenFunction* tweenFunction;
    
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
	
	/** Enable GL rendering by enabling the GLKView (enable it by giving it an EAGLContext to render to) */
	GLKView *view = (GLKView *)self.view;
	view.context = self.localContext;
	view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    //To enable multisamle, it needs to be compiled as iPad, not univresal device.
    view.drawableMultisample = GLKViewDrawableMultisample4X;

    
	[view bindDrawable];
	
    int total =500*6;
    self.planes = (CustomPlane*) malloc(total*sizeof(CustomPlane));
    self.allPlanes = [[NSMutableArray alloc] initWithCapacity:500];
    self.tweens = [[NSMutableArray alloc] initWithCapacity:500];
    self.shapes = [[NSMutableArray alloc] init];
    delay=0.2;
    touchEnded = NO;
    friction = 0.90;
    _duration = 2.0;
    durationRemaining = _duration;
    velocity = GLKVector3Make(0,0,0);
    zoomscale = 1.0;
    rows=20;
    cols=25;
    radius = 1;
    resetCalled = NO;
    tweenFunction= [[TexImgTweenFunction alloc] init];
    
    spanX = 2.0*5/4;
    offsetX = -1.0;
    
    spanY = 2.0f;//rect.size.height;// 2.0;
    offsetY = -1.0f;
    // (u, v) is the centre of the texture
    eachWidth = spanX/cols;
    eachHeight = spanY/rows;
    /////////rotation and jesture //////
    _rotMatrix = GLKMatrix4Identity;
    
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
    
    GLfloat s=0.0,t=0.0;
    GLfloat u=0.0,v=0.0;
    GLKVector2 txtr;
    float spanTX = 1.0; //rect.size.width;//2.0;
    float offsetTX = 0.0;
    
    float spanTY = 1.0f;//rect.size.height;// 2.0;
    float offsetTY = 0.0f;
    GLfloat eachWidthT = spanTX/cols;
    GLfloat eachHeightT = spanTY/rows;
    delay=0.001;
    
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
           
        plane.colorId = index;
        //Colors
        GLKVector4 colorV =  GLKVector4Make((i+0.0f)/rows, (j+0.0f)/cols, 0.0, 1.0);//white color
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

-(void) changeView:(ViewType*)viewType{
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
                tween.targetPhi = 0 ;
                tween.targetTheta = 0;
            } else if(self.viewType==RESET){
                [self resetView];
                self.viewChanged=NO;
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
            vrtx = GLKVector3Make(c.x - plane.width/2,  c.y + eachHeight/2 ,  c.z ) ;
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
    NSLog(@"%@", function);
    tweenFunction.selectedFunction=function;

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
   
   [self makePlanes];
//     [self makeGlobe];
    
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
    
 
    [self.shapes addObject: drawObject];
   
}


-(void) setDelay:(float) val {

    delay = val;
}

-(void) resetView{
    
    resetCalled = YES;
    zTranslation = 3.0;
    _rotMatrix = GLKMatrix4Identity;
    velocity = GLKVector3Make(0, 0, 0);
    touchEnded = YES;
//    self.viewChanged = NO;
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
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -modelTranslation.z);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, _rotMatrix);
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    self.effect.texture2d0.enabled = YES;
    [self renderSingleFrame];
}

-(void) update {
    
   float velocityLength = GLKVector3Length(velocity);
    //change the vertex positions here for animation
    GLK2DrawCall* drawObject = [self.shapes objectAtIndex:0];
   
    if(resetCalled){
        _rotMatrix = GLKMatrix4Identity;
        resetCalled = NO;
        return;
    }

    if(self.viewChanged) {
        [self animateView];
        
        [drawObject.VAO updateVBOForAttribute:GLKVertexAttribPosition
                               filledWithData:self.planes //addres of the bytes to copy
                                  numVertices:drawObject.numOfVerticesToDraw
                                  numOfFloats:3 //floats in GLKVector3
                                       stride:sizeof(CustomPlane)
                                       offset:(void *)offsetof(CustomPlane, positionCoords)];
      
    }
    if(touchEnded && velocityLength>0.01){
        float rotX = GLKMathDegreesToRadians(velocity.y );
        float rotY = GLKMathDegreesToRadians(velocity.x );
        bool isInvertible;
        //inverting to get the world coordinate in order to get the correct axis of rotation
        GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible),
                                                 GLKVector3Make(1, 0, 0));
        _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, xAxis.x, xAxis.y, xAxis.z);
    
    
        GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible),
                                                 GLKVector3Make(0, 1, 0));
        _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, yAxis.x, yAxis.y, yAxis.z);
    
        velocity.y = velocity.y * friction;
        velocity.x = velocity.x * friction;

    }
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


-(void) zoomWithPinchGesture:(UIPinchGestureRecognizer*) recognizer{
    NSLog(@"pinch ");
//    recognizer.velocity;
    if (recognizer.state==UIGestureRecognizerStateChanged) {
        if( (zTranslation/(recognizer.scale))<=1.0){
             zTranslation = 1.0;
//              NSLog(@"scale %f, z=%f", recognizer.scale, zTranslation);
        }else if ( (zTranslation/(recognizer.scale))>=100.0) {
             zTranslation = 100.0;
//              NSLog(@"scale %f, z=%f", recognizer.scale, zTranslation);
        }
       else {
           zTranslation = zTranslation/(recognizer.scale);
//           NSLog(@"scale %f, z=%f", recognizer.scale, zTranslation);
        }

	}
}

-(void) rotateWithPanGesture:(UIPanGestureRecognizer*) recognizer{

   //    NSLog(@"velocity %f",  velocity.x);
    if (recognizer.state==UIGestureRecognizerStateBegan) {
        touchEnded = NO;
        velocity.x=0;
        velocity.y=0;
    } else if (recognizer.state==UIGestureRecognizerStateChanged) {
        //For every pixel the user drags, we rotate the cube 1/2 degree.
        //when the user drags from left to right, we actually want to rotate around the y axis (rotY)
        CGPoint diff = [recognizer translationInView:self.view];
        float rotX = GLKMathDegreesToRadians(diff.y * 0.01);
        float rotY = GLKMathDegreesToRadians(diff.x * 0.01);

        bool isInvertible;
        GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible),
        GLKVector3Make(1, 0, 0));
        _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, xAxis.x, xAxis.y, xAxis.z);
            
        GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible),
        GLKVector3Make(0, 1, 0));
        _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, yAxis.x, yAxis.y, yAxis.z);
      
    } else if (recognizer.state==UIGestureRecognizerStateEnded) {
        touchEnded = YES;
        CGPoint velo = [recognizer velocityInView:self.view];
        
        velocity.x = velo.x*0.01;
        velocity.y = velo.y*0.01;
        
    }
}



- (void)doubleTap:(UITapGestureRecognizer *)tap {
    
    taps++;
    if(taps%2){
        zTranslation = 7.0f;
    }else{
         zTranslation = 4.0f;
    }
}

@end
