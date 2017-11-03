//
//  NSObject+DCKVO.h
//  Demo
//
//  Created by Dincoln on 2017/11/3.
//  Copyright © 2017年 Dincoln. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (DCKVO)
- (void)dc_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

- (void)dc_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context;
@end
