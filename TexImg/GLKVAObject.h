//
//  GLKVAObject.h
//  map3d
//
//  Created by Sopan, Awalin on 5/14/14.
//  Copyright (c) 2014 __mstr__. All rights reserved.
//This is the vertex array objects for each drawable object, it consolidates all the buffer objects
//

#import <Foundation/Foundation.h>
@class GLK2BufferObject;


@interface GLKVAObject : NSObject


@property(nonatomic, readonly) GLuint glName;
@property(nonatomic,retain) NSMutableArray* VBOs;

-(GLK2BufferObject*) addVBOForAttribute:(GLuint) targetAttribute
                         filledWithData:(void*) data // address of the data to upload
                            numVertices:(int) numDataItems
                            numOfFloats:(int) numFloatsForItem
                                 stride:(int) strideInByte
                                 offset:(GLvoid*) offsetPosition ;
@end
