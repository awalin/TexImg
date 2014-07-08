//
//  TexImgMainUIController.m
//  TexImg
//
//  Created by Sopan, Awalin on 6/10/14.
//  Copyright (c) 2014 __mstr__. All rights reserved.
//

#import "TexImgMainUIController.h"
#import "ViewController.h"
#import "GLK2DrawCall.h"
#import "GLKVAObject.h"
#import "GLK2BufferObject.h"
#import <GLKit/GLKit.h>
#import "CustomCollectionViewController.h"

@implementation TexImgMainUIController

-(void) viewDidLoad
{
	[super viewDidLoad];
    
    UIStoryboard *myStoryboard = [UIStoryboard storyboardWithName:@"main"
                                                           bundle:[NSBundle mainBundle]];
    CGPoint origin = self.view.bounds.origin;
    // setup the opengl controller
    // first get an instance from storyboard
    self.glkViewController = [myStoryboard instantiateViewControllerWithIdentifier:@"glkviewcontroller"];
   // then add the glkview as the subview of the parent view
    [self.view addSubview: self.glkViewController.view];
    // add the glkViewController as the child of self
    [self addChildViewController: self.glkViewController];
    
    [self.glkViewController didMoveToParentViewController:self];
    self.collectionViewController = [myStoryboard instantiateViewControllerWithIdentifier:@"collectionViewController"];
    self.collectionViewController.clearsSelectionOnViewWillAppear = NO;

    // if you want to set the glkView to the same size as the parent view,
    // or you can do stuff like this inside myGlkViewController
    CGSize size =   self.view.bounds.size;
    float height = size.height - 30;
    float width = size.width;
    self.glkViewController.view.bounds = CGRectMake(origin.x, origin.y, width, height) ;
    [self changeDuration:self.durationSlider];
    [self addDelay:self.delaySlider];
    [self.glkViewController changeView: WALL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEasing:) name:@"Easing" object:nil];
}



@end
