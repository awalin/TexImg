//
//  TexImgTweenFunction.m
//  TexImg
//
//  Created by Sopan, Awalin on 6/20/14.
//  Copyright (c) 2014 __mstr__. All rights reserved.
//

#import "TexImgTweenFunction.h"

@implementation TexImgTweenFunction {
    
    
    float duration;
    float time;
    float ratio;
    
}

@synthesize  functionNames;

-(TexImgTweenFunction*) init{
    
    self.selectedFunction = @"linear";
    return self;
    
}

-(float) quadin{
    
    //    NSLog(@"quadin");
    return  pow(ratio, 2.0);
    
    
}
-(float) quadout{
    
    return -ratio*(ratio-2);
    
}

-(float) quadInOut{
    
    ratio = ratio/2;
    
	if (ratio < 1){
        return 0.5*ratio*ratio ;
    }
    
	ratio--;
	return -0.5 * (ratio*(ratio-2) - 1);

    
}

-(float) sinein{
    
    return (1 - cos(ratio * (M_PI_2)));
}
-(float) sineout{
    
    return sin(ratio * (M_PI_2)); //ease out
}

// sinusoidal easing in/out - accelerating until halfway, then decelerating
-(float) sineInOut {
	return -0.5 * (cosf(M_PI*ratio) - 1) ;
}

-(float) linear{
    
    return ratio;
}



// Bounce easing in/out
-(float) bounceIn {
    
    time = duration-time;
    ratio= time/duration;
    
    return 1.0-[self bounceOut] ;
}

-(float) bounceOut {
    ratio = time/duration;
    
    if ((ratio) < (1/2.75)) {
        return (7.5625*ratio*ratio) ;
    }
    else if (ratio < (2/2.75)) {
        ratio -=(1.5/2.75);
        return (7.5625*ratio*ratio + .75) ;
    }
    else if (ratio < (2.5/2.75)) {
        ratio-=(2.25/2.75);
        return (7.5625*ratio*ratio+ .9375) ;
    }
    else {
        ratio-=(2.625/2.75);
        return (7.5625*ratio*ratio + .984375) ;
    }
}

-(float) bounceInOut{
    
    if (time < duration/2){
        time = time*2;
        return [self bounceIn] * .5;
    }
    else{
        time= time*2-duration;
        return  ([self bounceOut] +1)*0.5;
    }
}


-(float) calculateTweenWithTime:(float)mtime duration:(float)mduration{
    
    time = mtime;
    duration = mduration;
    ratio = time/duration;
    
    NSString* functionName= self.selectedFunction;
    //    NSLog(@"function %@", self.selectedFunction);
    
    if([functionName isEqualToString:@"linear"]){
        return [self linear];
    } else if ([functionName isEqualToString:@"quadin"]){
        return [self quadin];
    } else if ([functionName isEqualToString:@"quadout"]){
        return [self quadout];
    } else if ([functionName isEqualToString:@"quadinout"]){
        return [self quadInOut];
    }else if ([functionName isEqualToString:@"sinein"]){
        return [self sinein];
    } else if ([functionName isEqualToString:@"sineout"]){
        return [self sineout];
    } else if ([functionName isEqualToString:@"sineinout"]){
        return [self sineInOut];
    }else if ([functionName isEqualToString:@"bouncein"]){
        return [self bounceIn];
    } else if ([functionName isEqualToString:@"bounceout"]){
        return [self bounceOut];
    } else if ([functionName isEqualToString:@"bounceinout"]){
        return [self bounceInOut];
    }
    
    //   SEL selc = NSSelectorFromString(@"linear");
    ////    if(selc!=NULL){
    //        [self performSelector:selc];
    ////    }
    return ratio;//default linear
}




@end
