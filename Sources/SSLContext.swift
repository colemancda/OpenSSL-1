// SSLContext.swift
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

public final class SSLContext {

	public ctx: UnsafeMutablePointer<SSL_CTX>

	public init?(certificatePath: String, privateKeyPath: String, certificateChainPath: String?) {
		self.ctx = SSL_CTX_new(SSLv23_method())
		if ctx == nil {
			return nil
		}
		SSL_CTX_set_verify(ctx, SSL_VERIFY_NONE, nil)
		SSL_CTX_set_ecdh_auto(ctx, 1)
		if let certificateChainPath = certificateChainPath {
			if (SSL_CTX_use_certificate_chain_file(ctx, certificateChainPath) < 0) {
				return nil
			}
		}
		if (SSL_CTX_use_certificate_file(ctx, certificatePath, SSL_FILETYPE_PEM) < 0) {
			return nil
		}
		if (SSL_CTX_use_PrivateKey_file(ctx, privateKeyPath, SSL_FILETYPE_PEM) < 0) {
			return nil
		}
	}

}
