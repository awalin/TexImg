/**
 Version 1: c.f. http://t-machine.org/index.php/2013/09/08/opengl-es-2-basic-drawing/
 Part 3: ... not published yet ...
 */
#import "ViewController.h"
#import "GLK2DrawCall.h"
#import "GLKVAObject.h"
#import "GLK2BufferObject.h"
#import "TexImgPlane.h"


@implementation ViewController {
    
    float _rotation;
    GLKMatrix4 _rotMatrix;
    GLKVector3 _anchor_position;
    GLKVector3 _current_position;
    
    GLKQuaternion _quatStart;
    GLKQuaternion _quat;
    GLfloat zTranslation;
    int taps;
    GLKTextureInfo * info ;
    
    GLKVector3 velocity;
    GLKVector3 touchStart;
    NSDate *startTime;
    
    BOOL touchEnded;
}




@synthesize effect;



-(void) viewDidLoad
{
	[super viewDidLoad];
    
    touchEnded = NO;
	
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
    self.shapes = [[NSMutableArray alloc] init];
    
    
    velocity = GLKVector3Make(0,0,0);
    /////////rotation and jesture //////
    _rotMatrix = GLKMatrix4Identity;
    _quat = GLKQuaternionMake(0, 0, 0, 1);
    _quatStart = GLKQuaternionMake(0, 0, 0, 1);
    
    UITapGestureRecognizer * dtRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    dtRec.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:dtRec];

    [self setupGL];
   
}


-(void) makePlanes{
    
    GLfloat s=0.0,t=0.0;
    GLfloat u=0.0,v=0.0;

    int rows = 20;
    int cols = 25;
    
//    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    
    float spanX = 2.0; ///aspect ; //rect.size.width;//2.0*5/4;
    float offsetX = -1.0;
    
    float spanY = 2.0f;//rect.size.height;// 2.0;
    float offsetY = -1.0f;

    
    float spanTX = 1.0; //rect.size.width;//2.0;
    float offsetTX = 0.0;
    
    float spanTY = 1.0f;//rect.size.height;// 2.0;
    float offsetTY = 0.0f;

    // (u, v) is the centre of the texture
    GLfloat eachWidth = spanX/cols;
    GLfloat eachHeight = spanY/rows;
    
    GLfloat eachWidthT = spanTX/cols;
    GLfloat eachHeightT = spanTY/rows;
    
      // centre point for each plane
  
    GLfloat y = offsetY+ eachHeight/2;
    v = offsetTY+ eachHeightT/2;
    
  //the first plane is on the BL corner of the screen
    for(int i=0; i< rows; i++){ // fixed phi
    
      GLfloat x = offsetX + eachWidth/2;
        
      u = offsetTX + eachWidthT/2;
        
      for(int j =0; j < cols; j++) { // fixed theta
            
         int index = 6*(cols*i+j); // index of the TL corner of the plane, 4 = # of vertices on the plane
 
         TexImgPlane* plane = [[TexImgPlane alloc] init];    //Position
          
         //BL
          s =  x - eachWidth/2 ;
          t =  y - eachHeight/2;
          GLKVector3 vrtx = GLKVector3Make(s, t, 0); // base
          plane.bottomLeft = vrtx;
          plane.vertices[0] = vrtx;
          
          //BR
          s =  x+ eachWidth/2 ;//s+eachRow;
          t =  y - eachHeight/2;  //t;
          vrtx = GLKVector3Make(s, t, 0); // base
            
            plane.bottomRight = vrtx;
//            vrtx = [self projectOntoSurface:vrtx];

            
            plane.vertices[1] = vrtx;
          
            
            //TL
          
          s =  x -  eachWidth/2 ;//s+eachRow;
          t =  y +  eachHeight/2;  //t;
            vrtx = GLKVector3Make(s, t, 0); // base
            plane.topLeft = vrtx;
            
//            vrtx = [self projectOntoSurface:vrtx];

            plane.vertices[2] = vrtx;
            
            
            //TR
          
          s =  x+ eachWidth/2 ;//s+eachRow;
          t =  y+ eachHeight/2;  //t;
          
            vrtx =  GLKVector3Make(s, t, 0); // base
            
            plane.topRight = vrtx;
            
//            vrtx = [self projectOntoSurface:vrtx];

            plane.vertices[3] = vrtx;
            
            ///two more
            //BR
          
          s =  x+ eachWidth/2 ;//s+eachRow;
          t = y - eachHeight/2;  //t;
          

            vrtx = GLKVector3Make(s, t, 0); // base
//            vrtx = [self projectOntoSurface:vrtx];

            plane.vertices[4] = vrtx;
            
            //TL
          
          s =  x - eachWidth/2 ;//s+eachRow;
          t = y + eachHeight/2;  //t;
          
          
            vrtx = GLKVector3Make(s, t, 0); // base
//            vrtx = [self projectOntoSurface:vrtx];

            plane.vertices[5] = vrtx;
            
    //Texture
            //BL (0,0)
          
          s = u - eachWidthT/2;
          t = v - eachHeightT/2;
          
            GLKVector2 txtr = GLKVector2Make(s, t); // BL (0,0)
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
            

    //Colors
            self.planes[index+0].colorCoords = GLKVector4Make(1.0, 1.0, 1.0, 1.0);//white color
            self.planes[index+1].colorCoords = GLKVector4Make(1.0, 1.0, 1.0, 1.0);//white color
            self.planes[index+2].colorCoords = GLKVector4Make(1.0, 1.0, 1.0, 1.0);//white color
            self.planes[index+3].colorCoords = GLKVector4Make(1.0, 1.0, 1.0, 1.0);//white color
            self.planes[index+4].colorCoords = GLKVector4Make(1.0, 1.0, 1.0, 1.0);//white color
            self.planes[index+5].colorCoords = GLKVector4Make(1.0, 1.0, 1.0, 1.0);//white color

      
            [self.allPlanes insertObject:plane atIndex:((cols*i)+j)];
          
          
          x = x + eachWidth;
          u = u + eachWidthT;
        }
        y = y + eachHeight;
        v = v + eachHeightT;
    }
    
    
    for(int i=0; i< rows; i++){
        
        for(int j =0; j < cols; j++) {
            
        int index = (cols*i+j);
        TexImgPlane* plane = [self.allPlanes objectAtIndex:index];
            
        NSLog(@"%d", index);
            
//            NSLog(@"%d, %f,%f,%f", index, self.planes[index].positionCoords.x, self.planes[index].positionCoords.y, self.planes[index].positionCoords.z  );
        index = 6*(cols*i+j);
            
        for(int t =0; t < 6; t++){
            self.planes[index+t].positionCoords = plane.vertices[t];
            self.planes[index+t].textureCoords = plane.texCoord[t];
            self.planes[index+t].colorCoords = plane.colors[t];
            
        
        }
      }
        
    
    }
    
    
}



-(void) makeGlobe{
    
    GLfloat s=0.0,t=0.0;
    GLfloat u=0.0,v=0.0;
    GLKVector2 txtr;
    GLKVector3 vrtx;
    
    float radius = 1;
    int rows = 20;
    int cols = 25;
    
    //    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    
    float spanX = 2.0*cols/rows;
//    float offsetX = -1.0;
    
    float spanY = 2.0f;//rect.size.height;// 2.0;
//    float offsetY = -1.0f;
    
    
    float spanTX = 1.0; //rect.size.width;//2.0;
    float offsetTX = 0.0;
    
    float spanTY = 1.0f;//rect.size.height;// 2.0;
    float offsetTY = 0.0f;
    
    // (u, v) is the centre of the texture
    GLfloat eachWidth = spanX/cols;
    GLfloat eachHeight = spanY/rows;
    
    GLfloat eachWidthT = spanTX/cols;
    GLfloat eachHeightT = spanTY/rows;
    
    // centre point for each plane
    
    v = offsetTY+ eachHeightT/2;
    
    GLfloat eachTheta = GLKMathDegreesToRadians(180.0f/rows); // 0 to 180, inclination, 9.0
    GLfloat eachPhi = GLKMathDegreesToRadians(360.0f/cols); // 0 to 360, azimuthal, 14.4
    
    //Points for the TRIANGLE STRIP
    rows = 20;
    
    float theta = GLKMathDegreesToRadians(180.0f) + eachTheta/2;
    //the first plane is on the BL corner of the screen
    for(int i=0; i< rows; i++){ // fixed phi
        
        float phi = GLKMathDegreesToRadians(-90.0f); // j*eachPhi;
        
        u = offsetTX + eachWidthT/2; // center x of texture
        int j;
        for( j =0; j < cols; j++) { // fixed theta
            
            int index = 6*(cols*i+j); // index of the TL corner of the plane, 4 = # of vertices on the plane
            TexImgPlane* plane = [[TexImgPlane alloc] init];
            
            plane.theta = theta;
            plane.phi = phi;
            radius = 1;
            
            GLfloat x = radius*sin(plane.theta)*cos(plane.phi);
            GLfloat y = radius*sin(plane.theta)*sin(plane.phi);
            GLfloat z = radius*cos(plane.theta);
            
           
            GLKMatrix3 rot = GLKMatrix3MakeXRotation((plane.theta - M_PI_2 + M_PI) );
            rot = GLKMatrix3Multiply(GLKMatrix3MakeYRotation( plane.phi), rot);
            
            plane.center = GLKVector3Make( y, z, x );
            
            GLKVector3 c = GLKVector3Make( 0, 0, 0 );
            
            //BL
            vrtx = GLKVector3Make(c.x - eachWidth/2,  c.y- eachHeight/2 ,  c.z );
            vrtx =  GLKMatrix3MultiplyVector3(rot, vrtx);
            vrtx = GLKVector3Add(vrtx, plane.center);
            plane.vertices[0] = vrtx;
            
            //BR
            vrtx = GLKVector3Make(c.x + eachWidth/2,  c.y- eachHeight/2 ,  c.z );
            vrtx =  GLKMatrix3MultiplyVector3(rot, vrtx);
            vrtx = GLKVector3Add(vrtx, plane.center);
            plane.vertices[1] = vrtx;
            
            
            //TL
        
            vrtx = GLKVector3Make(c.x - eachWidth/2,  c.y + eachHeight/2 ,  c.z);
            vrtx =  GLKMatrix3MultiplyVector3(rot, vrtx);
            vrtx = GLKVector3Add(vrtx, plane.center);
            plane.vertices[2] = vrtx;
            
            
            //TR
            vrtx = GLKVector3Make(c.x + eachWidth/2,  c.y +  eachHeight/2 ,  c.z );
            vrtx =  GLKMatrix3MultiplyVector3(rot, vrtx);
            vrtx = GLKVector3Add(vrtx, plane.center);
            plane.vertices[3] = vrtx;
            
            ///two more
            //BR
         
            vrtx = GLKVector3Make( c.x + eachWidth/2,  c.y - eachHeight/2 ,  c.z );
            vrtx = GLKMatrix3MultiplyVector3(rot, vrtx);
            vrtx = GLKVector3Add(vrtx, plane.center);
            plane.vertices[4] = vrtx;
            
            //TL
         
            vrtx = GLKVector3Make(c.x - eachWidth/2,  c.y + eachHeight/2 ,  c.z ) ;
            vrtx =  GLKMatrix3MultiplyVector3(rot, vrtx);
            vrtx = GLKVector3Add(vrtx, plane.center);
            plane.vertices[5] = vrtx;
            
          
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
            
            //Colors
            self.planes[index+0].colorCoords = GLKVector4Make(1.0, 1.0, 1.0, 1.0);//white color
            self.planes[index+1].colorCoords = GLKVector4Make(1.0, 1.0, 1.0, 1.0);//white color
            self.planes[index+2].colorCoords = GLKVector4Make(1.0, 1.0, 1.0, 1.0);//white color
            self.planes[index+3].colorCoords = GLKVector4Make(1.0, 1.0, 1.0, 1.0);//white color
            self.planes[index+4].colorCoords = GLKVector4Make(1.0, 1.0, 1.0, 1.0);//white color
            self.planes[index+5].colorCoords = GLKVector4Make(1.0, 1.0, 1.0, 1.0);//white color
            
            
            [self.allPlanes insertObject:plane atIndex:(cols*i+j)];
            
            phi = phi + eachPhi;
            u = u + eachWidthT;
            
        }
        
//       NSLog(@"%d, %d",i, j);
       v = v + eachHeightT;
       theta = theta + eachTheta;
    }
    
    
    for(int i=0; i< rows; i++){
        for(int j =0; j < cols; j++) {
            
            int index = (cols*i+j);
//            NSLog(@"%d", index);
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


-(void)setupGL{
    
    /** All the local setup for the ViewController */
    
    self.effect = [[GLKBaseEffect alloc] init];
    zTranslation = -4.0f;
    taps=0;
    
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 1.0f, 100.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;

//    glClear(GL_COLOR_BUFFER_BIT);
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
    
//  [self makePlanes];
     [self makeGlobe];
    
	GLK2DrawCall* drawObject = [[GLK2DrawCall alloc] init ];
    drawObject.mode = GL_TRIANGLES;
    NSLog(@"%lu", sizeof(CustomPlane));
    drawObject.numOfVerticesToDraw = 25*20*6;
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

    
//        [drawObject.VAO addVBOForAttribute:GLKVertexAttribColor
//                            filledWithData:self.planes //addres of the bytes to copy
//                               numVertices:drawObject.numOfVerticesToDraw
//                               numOfFloats:4
//                                    stride:sizeof(CustomPlane)
//                                    offset:(void *)offsetof(CustomPlane, colorCoords) ];

    
	
	[self.shapes addObject: drawObject];


  
    
    
}



/*called after update loop
 */

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(0.1, 0.1, 0.1, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self renderSingleFrame];
    
}

-(void) update {
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, zTranslation);
    
    GLKMatrix4 rotation = _rotMatrix; //GLKMatrix4MakeWithQuaternion(_quat);
    
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotation);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
   
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

            self.effect.texture2d0.enabled = true;
            
//            self.effect.useConstantColor = YES;
//            self.effect.constantColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
        
            if( drawCall.VAO != nil ){
                [self.effect prepareToDraw];
                [drawCall drawWithMode:GL_TRIANGLES];
                }
            else {
                NSLog(@"not available");
                }
     
    }
}



- (GLKVector3) projectOntoSurface:(GLKVector3) cartesianPoint
{
    
    float radius = self.view.bounds.size.width/3;
    
    GLKVector3 center = GLKVector3Make(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0);
    
    GLKVector3 P = GLKVector3Subtract(cartesianPoint, center);
    
    // Flip the y-axis because pixel coords increase toward the bottom.
    P = GLKVector3Make(P.x, P.y * -1, P.z);
    
    float radius2 = radius * radius;
    float length2 = P.x*P.x + P.y*P.y;
    
    if (length2 <= radius2)
        P.z = sqrt(radius2 - length2);
    else {
        
        // If user clicks outside the imaginary sphere
        P.z = radius2 / (2.0 * sqrt(length2));
        float length = sqrt(length2 + P.z * P.z);
        P = GLKVector3DivideScalar(P, length);
    }
    
    return GLKVector3Normalize(P);
}

- (void)computeIncremental {
    
    GLKVector3 axis = GLKVector3CrossProduct(_anchor_position, _current_position);
    float dot = GLKVector3DotProduct(_anchor_position, _current_position);
    float angle = acosf(dot);
    
    GLKQuaternion Q_rot = GLKQuaternionMakeWithAngleAndVector3Axis(angle * 2, axis);
    Q_rot = GLKQuaternionNormalize(Q_rot);
    _quat = GLKQuaternionMultiply(Q_rot, _quatStart);
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    touchEnded = NO;
    
    UITouch * touch = [touches anyObject];
    startTime = [NSDate date];
    
    CGPoint location = [touch locationInView:self.view];
    
    _anchor_position = GLKVector3Make(location.x, location.y, 0);
    touchStart = _anchor_position;
    
    _anchor_position = [self projectOntoSurface:_anchor_position];
    
    _current_position = _anchor_position;
    _quatStart = _quat;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

    touchEnded = YES;
    NSLog(@"touch ended");
  //For every pixel the user drags, we rotate the cube 1/2 degree.
    float rotX =  GLKMathDegreesToRadians(velocity.y);
    
    //     when the user drags from left to right, we actually want to rotate around the y axis (rotY)
    float rotY =  GLKMathDegreesToRadians(velocity.x );
    
    //rotate around X
    
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, 1, 0, 0);
    
    //rotate around y
    
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, 0, 1, 0);
    
    //This part is more advanced, need to understand this
    //    bool isInvertible;
    //    GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible), GLKVector3Make(1, 0, 0));
    //    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, xAxis.x, xAxis.y, xAxis.z);
    //
    //    GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible), GLKVector3Make(0, 1, 0));
    //    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, yAxis.x, yAxis.y, yAxis.z);
    
//    [self computeIncremental];
    


}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch * touch = [touches anyObject];
    
    CGPoint location = [touch locationInView:self.view];

    NSTimeInterval timeInterval = [startTime timeIntervalSinceNow];
    
    CGPoint lastLoc = [touch previousLocationInView:self.view];
    
    CGPoint diff = CGPointMake(lastLoc.x - location.x, lastLoc.y - location.y);
    
    
    GLfloat velocityX = (-touchStart.x + location.x)/fabs(timeInterval);
    GLfloat velocityY = (-touchStart.y + location.y)/fabs(timeInterval);
    
    velocity.x = velocityX*.001;
    velocity.y = velocityY*.001;
    
    NSLog(@"Interval %f, %f", fabs(timeInterval), velocity.x);

    
    //For every pixel the user drags, we rotate the cube 1/2 degree.
    float rotX = -1 * GLKMathDegreesToRadians(diff.y / 2.0);
    
//     when the user drags from left to right, we actually want to rotate around the y axis (rotY)
    float rotY = -1 * GLKMathDegreesToRadians(diff.x / 2.0);
    
//rotate around X
    
//    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, 1, 0, 0);
    
//rotate around y
    
//    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, 0, 1, 0);

    //This part is more advanced, need to understand this
//    bool isInvertible;
//    GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible), GLKVector3Make(1, 0, 0));
//    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, xAxis.x, xAxis.y, xAxis.z);
//    
//    GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible), GLKVector3Make(0, 1, 0));
//    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, yAxis.x, yAxis.y, yAxis.z);
    
    _current_position = GLKVector3Make(location.x, location.y, 0);
    _current_position = [self projectOntoSurface:_current_position];
    
    [self computeIncremental];
    
}

- (void)doubleTap:(UITapGestureRecognizer *)tap {
    
    taps++;
    if(taps%2){
        zTranslation = -7.0f;
    }else{
         zTranslation = -5.0f;
    }
   

    
}

@end
