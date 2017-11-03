//
//  NSObject+DCKVO.m
//  Demo
//
//  Created by Dincoln on 2017/11/3.
//  Copyright © 2017年 Dincoln. All rights reserved.
//

#import "NSObject+DCKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *kDCKVOControllerKey = @"kDCKVOControllerKey";

static NSString *kKVOClassPrefix = @"_dc_kvo_";
@interface DCKVOController: NSObject

@property (nonatomic, strong) NSMapTable *targetMapTable;

@property (nonatomic, strong) NSMapTable *keyPathMapTable;

@end

@implementation DCKVOController
- (instancetype)init
{
    self = [super init];
    if (self) {
        _targetMapTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
        _keyPathMapTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];

    }
    return self;
}

- (void)addTarget:(NSObject *)target observedKey:(NSString *)observedKey forKeyPath:(NSString *)keyPath{
    
    [_targetMapTable setObject:target forKey:observedKey];
    [_keyPathMapTable setObject:keyPath forKey:observedKey];

}


@end

@implementation NSObject (DCKVO)
- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context{
    return ;
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath{
    return;
}

- (void)dc_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
}

- (void)dc_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    NSMutableArray<NSString *> *keys = [[keyPath componentsSeparatedByString:@"."] mutableCopy];
    if (!observer || !keys || keys.count == 0) {
        return;
    }
    NSString *key = keys.lastObject;
    [keys removeLastObject];
    id pathObject;
    if (!keys || keys.count == 0) {
        pathObject = self;
    }else{
        NSString *path = [keys componentsJoinedByString:@"."];
        pathObject = [self valueForKey:path];
    }
    
    if (!pathObject) {
        return;
    }
    [self dc_addObserver:observer observedObject:pathObject forObservedKey:key keyPath:keyPath];
}

- (void)dc_addObserver:(NSObject *)observer observedObject:(id)object forObservedKey:(NSString *)observedKey keyPath:(NSString *)keyPath{
    Class originClass = object_getClass(object);
    Class kvoClass = originClass;
    NSString *kvoClassName = NSStringFromClass(originClass);
    if (![kvoClassName hasPrefix:kKVOClassPrefix]) {
        kvoClassName = [NSString stringWithFormat:@"%@%@",kKVOClassPrefix,kvoClassName];
        kvoClass = NSClassFromString(kvoClassName);
        if (!kvoClass) {
            kvoClass = objc_allocateClassPair(originClass, [kvoClassName UTF8String], 0);
            NSAssert(kvoClass != nil, @"Create KVO class fail");
            objc_registerClassPair(kvoClass);
            object_setClass(object, kvoClass);
        }
    }
    SEL originSetter = NSSelectorFromString([self setterNameWithKey:observedKey]);
    Method originMethod = class_getInstanceMethod(originClass, originSetter);
    class_addMethod(kvoClass, originSetter, (IMP)dc_setter, method_getTypeEncoding(originMethod));
    
    DCKVOController *controller = objc_getAssociatedObject(object, &kDCKVOControllerKey);
    if (!controller) {
        controller = [[DCKVOController alloc] init];
        objc_setAssociatedObject(object, &kDCKVOControllerKey, controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [controller addTarget:observer observedKey:observedKey forKeyPath:keyPath];
}

- (NSString *)setterNameWithKey:(NSString *)key{
    if (!key || key.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"set%@%@:",[[key substringToIndex:1] uppercaseString], [key substringFromIndex:1]];
}

- (NSString *)keyWithSetterSelector:(SEL)sel{
    NSString *setter = NSStringFromSelector(sel);
    setter = [setter substringFromIndex:3];
    setter = [setter substringToIndex:setter.length - 1];
    return [NSString stringWithFormat:@"%@%@",[setter substringToIndex:1].lowercaseString,[setter substringFromIndex:1]];
}


static void dc_setter(id self, SEL _cmd, void * value){
    NSString *key = [self keyWithSetterSelector:_cmd];
    id oldValue = [self valueForKey:key];
    struct objc_super superClass = {
        .receiver = self,
        .super_class = class_getSuperclass([self class])
    };

    [self willChangeValueForKey:key];
    ((void (*)(struct objc_super *superclass, SEL sel, void * value))objc_msgSendSuper)(&superClass, _cmd, value);
    
    DCKVOController *controller = objc_getAssociatedObject(self, &kDCKVOControllerKey);
    if (controller) {
        NSObject *target = [controller.targetMapTable objectForKey:key];
        NSString *keyPath = [controller.keyPathMapTable objectForKey:key];
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        id newValue = (__bridge id)value;
//        [dic setValue:newValue forKey:@"new"];
        [dic setValue:oldValue forKey:@"old"];
        [target dc_observeValueForKeyPath:keyPath ofObject:nil change:dic context:nil];
    }
    [self didChangeValueForKey:key];

}





@end
