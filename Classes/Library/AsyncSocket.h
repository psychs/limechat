//
//  AsyncSocket.h
//
//  Created by Dustin Voss on Wed Jan 29 2003.
//  This class is in the public domain.
//  If used, I'd appreciate it if you credit me.
//
//  E-Mail: d-j-v@earthlink.net
//

/*
 * Make sure to include /System/Library/Frameworks/CoreServices.framework in the project.
 */

#import <Foundation/Foundation.h>

@class AsyncSocket;
@class AsyncReadPacket;
@class AsyncWritePacket;

extern NSString *const AsyncSocketException;
extern NSString *const AsyncSocketErrorDomain;

enum AsyncSocketError
{
	AsyncSocketCFSocketError = kCFSocketError,	// From CFSocketError enum.
	AsyncSocketNoError = 0,						// Never used.
	AsyncSocketCanceledError,					// onSocketWillConnect: returned NO.
	AsyncSocketReadTimeoutError,
	AsyncSocketWriteTimeoutError
};
typedef enum AsyncSocketError AsyncSocketError;


@interface NSObject ( AsyncSocketDelegate )

/* In the event of an error, the socket is closed. You may call "readDataWithTimeout:tag:" during this call-back to get the last bit of data off the socket. When connecting, this delegate method may be called before "onSocket:didAcceptNewSocket:" or "onSocket:didConnectToHost:". */
-(void) onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err;

/* Called when a socket disconnects with or without error. If you want to release a socket after it disconnects, do so here. It is not safe to do that during "onSocket:willDisconnectWithError:". */
-(void) onSocketDidDisconnect:(AsyncSocket *)sock;

/* Called when a socket accepts a connection. Another socket is spawned to handle it. The new socket will have the same delegate and will call "onSocket:didConnectToHost:port:". */
-(void) onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket;

/* Called when a new socket is spawned to handle a connection. This method should return the run-loop of the thread on which the new socket and its delegate should operate. If omitted, [NSRunLoop currentRunLoop] is used. */
-(NSRunLoop *) onSocket:(AsyncSocket *)sock wantsRunLoopForNewSocket:(AsyncSocket *)newSocket;

/* Called when a socket is about to connect. This method should return YES to continue, or NO to abort. If aborted, will result in AsyncSocketCanceledError. */
-(BOOL) onSocketWillConnect:(AsyncSocket *)sock;

/* Called when a socket connects and is ready for reading and writing. "host" will be an IP address, not a DNS name. */
-(void) onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port;

/* Called when a socket has completed reading the requested data. Not called if there is an error. */
-(void) onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(NSInteger)tag;

/* Called when a socket has completed writing the requested data. Not called if there is an error. */
-(void) onSocket:(AsyncSocket *)sock didWriteDataWithTag:(NSInteger)tag;

@end


@interface AsyncSocket : NSObject

- (id) init;
- (id) initWithDelegate:(id)delegate;
- (id) initWithDelegate:(id)delegate userData:(long)userData;
- (void) dealloc;

/* String representation is long but has no "\n". */
- (NSString *) description;

/* Use "canSafelySetDelegate" to see if there is any pending business (reads and writes) with the current delegate before changing it. It is, of course, safe to change the delegate before connecting or accepting connections. */
- (id) delegate;
- (BOOL) canSafelySetDelegate;
- (void) setDelegate:(id)delegate;

/* User data can be a long, or an id or void * cast to a long. */
- (long) userData;
- (void) setUserData:(long)userData;

/* Don't use these to read or write. And don't close them, either! */
- (CFSocketRef) getCFSocket;
- (CFReadStreamRef) getCFReadStream;
- (CFWriteStreamRef) getCFWriteStream;

/* Once one of these methods is called, the AsyncSocket instance is locked in, and the rest can't be called without disconnecting the socket first. If the attempt times out or fails, these methods either return NO or call "onSocket:willDisconnectWithError:" and "onSockedDidDisconnect:". */
- (BOOL) acceptOnPort:(UInt16)port error:(NSError **)errPtr;
- (BOOL) acceptOnAddress:(NSString *)hostaddr port:(UInt16)port error:(NSError **)errPtr;
- (BOOL) connectToHost:(NSString*)hostname onPort:(UInt16)port error:(NSError **)errPtr;

/* Disconnects immediately. Any pending reads or writes are dropped. */
- (void) disconnect;

/* Disconnects after all pending writes have completed. After calling this, the read and write methods (including "readDataWithTimeout:tag:") will do nothing. The socket will disconnect even if there are still pending reads. */
- (void) disconnectAfterWriting;

/* Returns YES if the socket and streams are open, connected, and ready for reading and writing. */
- (BOOL) isConnected;

/* Returns the local or remote host and port to which this socket is connected, or nil and 0 if not connected. The host will be an IP address. */
- (NSString *) connectedHost;
- (UInt16) connectedPort;

- (NSString *) localHost;
- (UInt16) localPort;

/* The following methods won't block. To not time out, use a negative time interval. If they time out, "onSocket:disconnectWithError:" is called. The tag is for your convenience. You can use it as an array index, step number, state id, pointer, etc., just like the socket's user data. */

/* This will read a certain number of bytes, and call the delegate method when those bytes have been read. If there is an error, partially read data is lost. If the length is 0, this method does nothing and the delegate is not called. */
- (void) readDataToLength:(CFIndex)length withTimeout:(NSTimeInterval)timeout tag:(long)tag;

/* This reads bytes until (and including) the passed "data" parameter, which acts as a separator. The bytes and the separator are returned by the delegate method. If you pass nil or 0-length data as the "data" parameter, the method will do nothing, and the delegate will not be called. To read a line from the socket, use the line separator (e.g. CRLF for HTTP, see below) as the "data" parameter. Note that this method is not character-set aware, so if a separator can occur naturally as part of the encoding for a character, the read will prematurely end. */
- (void) readDataToData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag;

/* This reads the first available bytes. */
- (void) readDataWithTimeout:(NSTimeInterval)timeout tag:(long)tag;

/* Writes data. If you pass in nil or 0-length data, this method does nothing and the delegate will not be called. */
- (void) writeData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag;

/* Returns progress of current read or write, from 0.0 to 1.0, or NaN if no read/write (use isnan() to check). "tag", "done" and "total" will be filled in if they aren't NULL. */
- (float) progressOfReadReturningTag:(long *)tag bytesDone:(CFIndex *)done total:(CFIndex *)total;
- (float) progressOfWriteReturningTag:(long *)tag bytesDone:(CFIndex *)done total:(CFIndex *)total;

/* SSL support */
- (void)useSSLWithHost:(NSString *)host validatesCertificateChain:(BOOL)validatesCertificateChain;

/* Proxy support */
- (void)useSystemSocksProxy;
- (void)useSocksProxyVersion:(int)version host:(NSString*)host port:(int)port user:(NSString*)user password:(NSString*)password;

/* POSIX error */
+ (NSString*)posixErrorStringFromErrno:(int)code;

@end
