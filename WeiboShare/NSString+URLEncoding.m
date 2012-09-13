//
//  NSString+URLEncoding.m
//
//  Created by teng looyao on 12-9-4.
//
//

#import "NSString+URLEncoding.h"

@implementation NSString (URLEncoding)

- (NSString *)URLEncodedString
{
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
    
	return [result autorelease];
}

- (NSString*)URLDecodedString
{
	NSString *result = (NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)self, CFSTR(""), kCFStringEncodingUTF8);
    
	return [result autorelease];
}

@end
