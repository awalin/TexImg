#import "GLK2DrawCall.h"
#import "GLKVAObject.h"
#import "TexImgFrameBuffer.h"

@implementation GLK2DrawCall
{
	float clearColour[4];
}

-(void)dealloc
{
//	[super dealloc];
}

- (id)init
{
	self = [super init];
	if (self) {
		[self setClearColourRed:1.0f green:0 blue:1.0f alpha:1.0f];
	}
	return self;
}

-(float*) clearColourArray
{
	return &clearColour[0];
}

-(void)addVertices:(GLKVector3*)vertex{
    self.vertices = vertex;
    
}

-(void) drawWithMode:(GLuint) mode{
    
    glBindVertexArrayOES( self.VAO.glName );
   glDisableVertexAttribArray(GLKVertexAttribColor);
    glDrawArrays(mode, 0, self.numOfVerticesToDraw);
    }


-(void) setClearColourRed:(float) r green:(float) g blue:(float) b alpha:(float) a
{
	clearColour[0] = r;
	clearColour[1] = g;
	clearColour[2] = b;
	clearColour[3] = a;
}

@end
