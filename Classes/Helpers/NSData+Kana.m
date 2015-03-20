// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "NSData+Kana.h"


#define ESC     0x1B
#define SO      0x0E
#define SI      0x0F


typedef NS_ENUM(NSInteger, KanaEncoding) {
    ENC_OTHER,
    ENC_JIS_ROMAN,
    ENC_JIS_KANA,
} ;


@implementation NSData (Kana)

- (NSData*)convertKanaFromISO2022ToNative
{
    int len = self.length;
    NSMutableData* dest = [NSMutableData dataWithLength:len];
    const unsigned char* src = [self bytes];
    unsigned char* buf = [dest mutableBytes];
    int n = 0;

    KanaEncoding enc = ENC_OTHER;

    for (int i=0; i<len; ++i) {
        unsigned char c = src[i];
        if (c == ESC) {
            BOOL seq = NO;
            if (i+2 < len) {
                unsigned char d = src[i+1];
                unsigned char e = src[i+2];

                switch (d) {
                    case '$':
                        switch (e){
                            case 'B':
                            case 'b':
                            case '@':
                                enc = ENC_OTHER;
                                break;
                        }
                        break;
                    case '(':
                        switch (e) {
                            case 'B':
                            case 'b':
                                enc = ENC_OTHER;
                                break;
                            case 'I':
                            case 'i':
                                enc = ENC_JIS_ROMAN;
                                seq = YES;
                                buf[n++] = ESC;
                                buf[n++] = '(';
                                buf[n++] = 'J';
                                break;
                        }
                        break;
                }

                if (seq) {
                    i += 2;
                    continue;
                }
            }
        }

        if (enc == ENC_JIS_ROMAN) {
            if (0x21 <= c && c <= 0x5F) {
                c |= 0x80;
            }
        }

        buf[n++] = c;
    }

    [dest setLength:n];
    return dest;
}

- (NSData*)convertKanaFromNativeToISO2022
{
    int len = self.length;
    NSMutableData* dest = [NSMutableData dataWithLength:len];
    const unsigned char* src = [self bytes];
    unsigned char* buf = [dest mutableBytes];
    int n = 0;

    KanaEncoding enc = ENC_OTHER;

    for (int i=0; i<len; ++i) {
        unsigned char c = src[i];
        if (c == ESC) {
            BOOL seq = NO;
            if (i+2 < len) {
                unsigned char d = src[i+1];
                unsigned char e = src[i+2];

                switch (d) {
                    case '$':
                        switch (e){
                            case 'B':
                            case 'b':
                            case '@':
                                enc = ENC_OTHER;
                                break;
                        }
                        break;
                    case '(':
                        switch (e) {
                            case 'B':
                            case 'b':
                                enc = ENC_OTHER;
                                break;
                            case 'J':
                            case 'j':
                                enc = ENC_JIS_ROMAN;
                                seq = YES;
                                buf[n++] = ESC;
                                buf[n++] = '(';
                                buf[n++] = 'I';
                                break;
                            case 'I':
                            case 'i':
                                enc = ENC_JIS_KANA;
                                break;
                        }
                        break;
                }

                if (seq) {
                    i += 2;
                    continue;
                }
            }
        }

        if (enc == ENC_JIS_ROMAN) {
            if (c == SO) {
                enc = ENC_JIS_KANA;
                continue;
            }
        }
        else if (enc == ENC_JIS_KANA) {
            if (c == SI) {
                enc = ENC_JIS_ROMAN;
                continue;
            }
        }

        if (enc == ENC_JIS_ROMAN) {
            if (0xa1 <= c && c <= 0xDF) {
                c &= 0x7F;
            }
        }

        buf[n++] = c;
    }

    [dest setLength:n];
    return dest;
}

@end
