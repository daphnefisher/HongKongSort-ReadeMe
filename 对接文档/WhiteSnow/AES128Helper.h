#import <Foundation/Foundation.h>

@interface AES128Helper : NSObject

+(NSString *)AES128EncryptText:(NSString *)plainText key:(NSString *)key;

+(NSString *)AES128DecryptText:(NSString *)encryptText key:(NSString *)key;

+(NSData *)AES128Encrypt:(NSData *)plainData key:(NSString *)key;

+(NSData *)AES128Decrypt:(NSData *)encryptData key:(NSString *)key;


@end
