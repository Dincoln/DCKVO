//
//  AppDelegate.h
//  DCKVO
//
//  Created by Dincoln on 2017/11/3.
//  Copyright © 2017年 Dincoln. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

