// SSLStream.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDINbG BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import COpenSSL
import Stream

public final class SSLStream: StreamType {
    let rawStream: StreamType
	private let ctx: UnsafeMutablePointer<SSL_CTX>
	private let ssl: UnsafeMutablePointer<SSL>
	private let rbio: UnsafeMutablePointer<BIO>
	private let wbio: UnsafeMutablePointer<BIO>

    init(ctx: UnsafeMutablePointer<SSL_CTX>, rawStream: StreamType) {
        self.rawStream = rawStream

		self.ctx = ctx
		self.ssl = SSL_new(ctx)
		self.rbio = BIO_new(BIO_s_mem())
		self.wbio = BIO_new(BIO_s_mem())
		SSL_set_bio(ssl, rbio, wbio)
		SSL_set_accept_state(ssl)
    }

    func receive(completion: (Void throws -> [Int8]) -> Void) {
		self.rawStream.receive { result in
		    do {
				var data = try result()
				let written = BIO_write(self.rbio, &data, Int32(data.count))
			    if written > 0 {
					if SSL_state(self.ssl) != SSL_ST_OK {
						SSL_do_handshake(self.ssl)
						self.checkSslOutput()
					} else {
						var buffer: [Int8] = Array(count: DEFAULT_BUFFER_SIZE, repeatedValue: 0)
						let readSize = SSL_read(self.ssl, &buffer, Int32(buffer.count))
						if readSize > 0 {
							completion({ Array(buffer.prefix(Int(readSize))) })
						}
					}
			    }
		    } catch {
		        //self.rawStream.close()
				completion({ throw error })
		    }
		}
    }

    func send(data: [Int8], completion: (Void throws -> Void) -> Void) {
		var data = data
		SSL_write(self.ssl, &data, Int32(data.count))
		self.checkSslOutput(completion)
    }

    func close() {
		self.rawStream.close()
    }

    func pipe() -> StreamType {
		return SSLStream(ctx: ctx, rawStream: rawStream.pipe())
    }

	private func checkSslOutput(completion: ((Void throws -> Void) -> Void)? = nil) {
		var buffer: [Int8] = Array(count: DEFAULT_BUFFER_SIZE, repeatedValue: 0)
		let readSize = BIO_read(self.wbio, &buffer, Int32(buffer.count))
		if readSize > 0 {
			self.rawStream.send(Array(buffer.prefix(Int(readSize)))) { serializeResult in
	            do {
	                try serializeResult()
					completion?({})
	            } catch {
	                //self.rawStream.close()
					//self.receiveHandler?({ throw error })
					completion?({ throw error })
	            }
			}
		}
	}
}
