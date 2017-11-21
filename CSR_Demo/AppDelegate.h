//
//  AppDelegate.h
//  CSR_Demo
//
//  Created by Sunil on 11/11/17.
//  Copyright © 2017 Sunil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

