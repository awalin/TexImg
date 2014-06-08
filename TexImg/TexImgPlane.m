//
//  TexImgPlane.m
//  TexImg
//
//  Created by Sopan, Awalin on 5/28/14.
//  Copyright (c) 2014 __mstr__. All rights reserved.
//

#import "TexImgPlane.h"

@implementation TexImgPlane

-(TexImgPlane*) init{
    
    self = [super init];
    
    self.vertices = (GLKVector3*)malloc(6*sizeof(GLKVector3));
    self.texCoord = (GLKVector2*)malloc(6*sizeof(GLKVector2));
    self.colors = (GLKVector4*)malloc(6*sizeof(GLKVector4));

    return self;


}

@end
