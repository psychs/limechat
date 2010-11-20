// LimeChat is copyrighted free software by Satoshi Nakagawa <psychs AT limechat DOT net>.
// You can redistribute it and/or modify it under the terms of the GPL version 2 (see the file GPL.txt).

#import "ImageURLParser.h"
#import "NSStringHelper.h"


@implementation ImageURLParser

+ (NSString*)imageURLForURL:(NSString*)url
{
	NSString* lowerUrl = [url lowercaseString];
	
	if ([lowerUrl hasSuffix:@".jpg"]
		|| [lowerUrl hasSuffix:@".jpeg"]
		|| [lowerUrl hasSuffix:@".png"]
		|| [lowerUrl hasSuffix:@".gif"]) {
		return url;
	}
	
	NSString* encodedUrl = [url encodeURIFragment];
	NSURL* u = [NSURL URLWithString:encodedUrl];
	NSString* host = [u.host lowercaseString];
	NSString* path = u.path;
	
	if ([host hasSuffix:@"twitpic.com"]) {
		if (path.length > 1) {
			NSString* s = [path substringFromIndex:1];
			if ([s hasSuffix:@"/full"]) {
				s = [s substringToIndex:s.length - 5];
			}
			if ([s isAlphaNumOnly]) {
				return [NSString stringWithFormat:@"http://twitpic.com/show/large/%@", s];
			}
		}
	}
	else if ([host hasSuffix:@"plixi.com"]) {
		if (path.length > 1) {
			return [NSString stringWithFormat:@"http://api.plixi.com/api/TPAPI.svc/imagefromurl?size=medium&url=%@", [url encodeURIComponent]];
		}
	}
	else if ([host hasSuffix:@"tweetphoto.com"]) {
		if (path.length > 1) {
			return [NSString stringWithFormat:@"http://TweetPhotoAPI.com/api/TPAPI.svc/imagefromurl?size=medium&url=%@", [url encodeURIComponent]];
		}
	}
	else if ([host hasSuffix:@"yfrog.com"]) {
		if (path.length > 1) {
			return [NSString stringWithFormat:@"%@:iphone", url];
		}
	}
	else if ([host hasSuffix:@"twitgoo.com"]) {
		if (path.length > 1) {
			NSString* s = [path substringFromIndex:1];
			if ([s isAlphaNumOnly]) {
				return [NSString stringWithFormat:@"http://twitgoo.com/show/Img/%@", s];
			}
		}
	}
	else if ([host isEqualToString:@"img.ly"]) {
		if (path.length > 1) {
			NSString* s = [path substringFromIndex:1];
			if ([s isAlphaNumOnly]) {
				return [NSString stringWithFormat:@"http://img.ly/show/large/%@", s];
			}
		}
	}
	else if ([host hasSuffix:@"movapic.com"]) {
		if ([path hasPrefix:@"/pic/"]) {
			NSString* s = [path substringFromIndex:5];
			if ([s isAlphaNumOnly]) {
				return [NSString stringWithFormat:@"http://image.movapic.com/pic/m_%@.jpeg", s];
			}
		}
	}
	else if ([host isEqualToString:@"imgur.com"]) {
		if ([path hasPrefix:@"/gallery/"]) {
			NSString* s = [path substringFromIndex:9];
			if ([s isAlphaNumOnly]) {
				return [NSString stringWithFormat:@"http://i.imgur.com/%@m.jpg", s];
			}
		}
		if (path.length > 1) {
			NSString* s = [path substringFromIndex:1];
			if ([s isAlphaNumOnly]) {
				return [NSString stringWithFormat:@"http://i.imgur.com/%@m.jpg", s];
			}
		}
	}
	else if ([host hasSuffix:@"f.hatena.ne.jp"]) {
		NSArray* ary = [path componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
		if (ary.count >= 3) {
			NSString* userId = [ary objectAtIndex:1];
			NSString* photoId = [ary objectAtIndex:2];
			if (userId.length && photoId.length > 8 && [photoId isNumericOnly]) {
				NSString* userIdHead = [userId substringToIndex:1];
				NSString* photoIdHead = [photoId substringToIndex:8];
				return [NSString stringWithFormat:@"http://img.f.hatena.ne.jp/images/fotolife/%@/%@/%@/%@.jpg", userIdHead, userId, photoIdHead, photoId];
			}
		}
	}
	else if ([host hasSuffix:@"youtube.com"] || [host isEqualToString:@"youtu.be"]) {
		NSString* vid = nil;
		
		if ([host isEqualToString:@"youtu.be"]) {
			NSString* path = u.path;
			if (path.length > 1) {
				vid = [path substringFromIndex:1];
			}
		}
		else {
			NSString* query = u.query;
			if (query.length) {
				NSArray* queries = [query componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
				if (queries.count) {
					NSCharacterSet* equal = [NSCharacterSet characterSetWithCharactersInString:@"="];
					for (NSString* e in queries) {
						NSArray* ary = [e componentsSeparatedByCharactersInSet:equal];
						if (ary.count >= 2) {
							NSString* key = [ary objectAtIndex:0];
							NSString* value = [ary objectAtIndex:1];
							if ([key isEqualToString:@"v"]) {
								vid = value;
								break;
							}
						}
					}
				}
			}
		}
		
		if (vid) {
			//return [NSString stringWithFormat:@"http://img.youtube.com/vi/%@/0.jpg", vid];
			return [NSString stringWithFormat:@"http://img.youtube.com/vi/%@/default.jpg", vid];
		}
	}
	else if ([host hasSuffix:@"twitvid.com"]) {
		NSString* path = u.path;
		if (path.length > 1) {
			NSString* s = [path substringFromIndex:1];
			if ([s isAlphaNumOnly]) {
				return [NSString stringWithFormat:@"http://images.twitvid.com/%@.jpg", s];
			}
		}
	}
	else if ([host hasSuffix:@"nicovideo.jp"] || [host isEqualToString:@"nico.ms"]) {
		NSString* vid = nil;
		
		if ([host isEqualToString:@"nico.ms"]) {
			NSString* path = u.path;
			if (path.length > 1) {
				path = [path substringFromIndex:1];
				if ([path hasPrefix:@"sm"] || [path hasPrefix:@"nm"]) {
					vid = path;
				}
			}
		}
		else {
			NSString* path = u.path;
			if ([path hasPrefix:@"/watch/"]) {
				path = [path substringFromIndex:7];
				if ([path hasPrefix:@"sm"] || [path hasPrefix:@"nm"]) {
					vid = path;
				}
			}
		}
		
		if (vid && vid.length > 2) {
			long long vidNum = [[vid substringFromIndex:2] longLongValue];
			return [NSString stringWithFormat:@"http://tn-skr%qi.smilevideo.jp/smile?i=%qi", (vidNum%4 + 1), vidNum];
		}
	}
	else if ([host hasSuffix:@"puu.sh"]) {
		if(path.length > 1) {
			return url;
		}
	}
	
	return nil;
}

@end
