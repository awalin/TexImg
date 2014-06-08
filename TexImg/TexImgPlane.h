//
//  TexImgPlane.h
//  TexImg
//
//  Created by Sopan, Awalin on 5/28/14.
//  Copyright (c) 2014 __mstr__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface TexImgPlane : NSObject


@property GLKVector3* vertices;
@property GLKVector2* texCoord;
@property GLKVector4* colors;
@property GLKVector3 center;
@property float theta;
@property float phi;
@property float radius;

@property GLKVector3 topRight;
@property GLKVector3 topLeft;
@property GLKVector3 bottomLeft;
@property GLKVector3 bottomRight;

-(TexImgPlane*) init;

@end
