//
//  GLKVAObject.m
//  map3d
//
//  Created by Sopan, Awalin on 5/14/14.
//  Copyright (c) 2014 __mstr__. All rights reserved.
//

#import "GLKVAObject.h"
#import "GLK2BufferObject.h"

@implementation GLKVAObject

@synthesize glName;

//add VBO for one attribute


- (id)init
{
    self = [super init];
    if (self) {
        glGenVertexArraysOES( 1, &glName );
		self.VBOs = [NSMutableArray array];
        
//        NSLog(@"name= %d", glName);
    }
    return self;
}


-(GLK2BufferObject*) addVBOForAttribute:(GLuint) targetAttribute
                         filledWithData:(void*) data
                            numVertices:(int) numDataItems
                            numOfFloats:(int) numFloatsForItem
                                 stride:(int) strideInByte
                                 offset:(GLvoid*) offsetPosition
{
	/** Create a VBO on the GPU, to store data */
    
	GLK2BufferObject* newVBO = [GLK2BufferObject vertexBufferObject];
    
    newVBO.totalBytesPerItem = strideInByte; //   // newVBO.totalBytesPerItem = sizeof(GLKVector3);
    
	[self.VBOs addObject:newVBO]; // so we can auto-release it when this class deallocs
	
	/** Send the vertex data to the new VBO */
	
    [newVBO upload:data numItems:numDataItems usageHint:GL_STATIC_DRAW];
	
	/** Configure the VAO (state) */
	glBindVertexArrayOES( self.glName );
	
    
    glEnableVertexAttribArray( targetAttribute); // Target attr = Position/Color/ Ect
    //the final param may not be zero , it is an offset
    
    
    glVertexAttribPointer( targetAttribute, numFloatsForItem, GL_FLOAT, GL_FALSE, newVBO.totalBytesPerItem, offsetPosition); // cast needed because GL API
	
	glBindVertexArrayOES(0); //unbind the vertex array, as a precaution against accidental changes by other classes
	
	return newVBO;
}


@end
