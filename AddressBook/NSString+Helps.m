//
//  NSString+Helps.m
//  XiaoXiDemo
//
//  Created by shenhongbang on 16/4/1.
//  Copyright © 2016年 shenhongbang. All rights reserved.
//

#import "NSString+Helps.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Helps)
- (NSString *)MD5 {
    const char *str = [self UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    
    NSMutableString *hash = [[NSMutableString alloc] initWithCapacity:0];
    for (int i = 0; i < 16; i++) {
        [hash appendString:[NSString stringWithFormat:@"%02x", r[i]]];
    }
    
    return [hash lowercaseString];
}

- (NSString *)formatterPhoneNum {
    
    NSString *phone = self;
    
    if ([phone hasPrefix:@"+"]) {
        phone = [phone substringFromIndex:3];
    }
    
    NSArray *array = [phone componentsSeparatedByString:@"-"];
    phone = [array componentsJoinedByString:@""];
    
    NSString *phoneRegex = @"^((13[0-9])|(15[^4,\\D])|(18[0,0-9])|(17[0,0-9]))\\d{8}$";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",phoneRegex];
     BOOL flag = [phoneTest evaluateWithObject:phone];
    
    NSMutableString *string = [[NSMutableString alloc] initWithString:phone];
    if (!flag) {
        [string insertString:@"-" atIndex:4];
        
        return string;
    }
    
    [string insertString:@" " atIndex:0];
    phone = string;
    
    NSString *tempPhone = @"";
    
    while (phone.length >= 4) {
        NSString *temp = [phone substringToIndex:MIN(phone.length, 4)];
        tempPhone = [tempPhone stringByAppendingString:temp];
        phone = [phone substringFromIndex:MIN(phone.length, 4)];
        if (temp.length == 4 && phone.length >= 4) {
            tempPhone = [tempPhone stringByAppendingString:@"-"];
        }
    }
    return tempPhone;
}

@end
