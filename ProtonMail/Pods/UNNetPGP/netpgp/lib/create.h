/*-
 * Copyright (c) 2009 The NetBSD Foundation, Inc.
 * All rights reserved.
 *
 * This code is derived from software contributed to The NetBSD Foundation
 * by Alistair Crooks (agc@NetBSD.org)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE NETBSD FOUNDATION, INC. AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
/*
 * Copyright (c) 2005-2008 Nominet UK (www.nic.uk)
 * All rights reserved.
 * Contributors: Ben Laurie, Rachel Willmer. The Contributors have asserted
 * their moral rights under the UK Copyright Design and Patents Act 1988 to
 * be recorded as the authors of this copyright work.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License.
 *
 * You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/** \file
 */
#ifndef CREATE_H_
#define CREATE_H_

#include "types.h"
#include "packet.h"
#include "crypto.h"
#include "errors.h"
#include "keyring.h"
#include "writer.h"
#include "memory.h"

/**
 * \ingroup Create
 * This struct contains the required information about how to write this stream
 */
struct __ops_output_t {
	__ops_writer_t	 writer;
	__ops_error_t	*errors;	/* error stack */
};

__ops_output_t *__ops_output_new(void);
void __ops_output_delete(__ops_output_t *);

int __ops_filewrite(const char *, const char *, const size_t, const unsigned);

void __ops_build_pubkey(__ops_memory_t *, const __ops_pubkey_t *, unsigned);

unsigned __ops_calc_sesskey_checksum(__ops_pk_sesskey_t *, uint8_t *);
unsigned __ops_write_struct_userid(__ops_output_t *, const uint8_t *);
unsigned __ops_write_ss_header(__ops_output_t *, unsigned, __ops_content_enum);
unsigned __ops_write_struct_seckey(const __ops_seckey_t *,
			    const uint8_t *,
			    const size_t,
			    __ops_output_t *);
unsigned __ops_write_one_pass_sig(__ops_output_t *,
				const __ops_seckey_t *,
				const __ops_hash_alg_t,
				const __ops_sig_type_t);
unsigned __ops_write_litdata(__ops_output_t *, 
				const uint8_t *,
				const int,
				const __ops_litdata_enum);
__ops_pk_sesskey_t *__ops_create_pk_sesskey(const __ops_key_t *, const char *, int);
unsigned __ops_write_pk_sesskey(__ops_output_t *, __ops_pk_sesskey_t *);
unsigned __ops_write_xfer_pubkey(__ops_output_t *,
				const __ops_key_t *, const unsigned);
unsigned   __ops_write_xfer_seckey(__ops_output_t *,
				const __ops_key_t *,
				const uint8_t *,
				const size_t,
				const unsigned);

void __ops_fast_create_userid(uint8_t **, uint8_t *);
unsigned __ops_write_userid(const uint8_t *, __ops_output_t *);
void __ops_fast_create_rsa_pubkey(__ops_pubkey_t *, time_t, BIGNUM *, BIGNUM *);
unsigned __ops_write_rsa_pubkey(time_t, const BIGNUM *, const BIGNUM *,
				__ops_output_t *);
void __ops_fast_create_rsa_seckey(__ops_seckey_t *, time_t, BIGNUM *,
				BIGNUM *, BIGNUM *, BIGNUM *,
				BIGNUM *, BIGNUM *);
unsigned encode_m_buf(const uint8_t *, size_t, const __ops_pubkey_t *,
				uint8_t *);
unsigned __ops_fileread_litdata(const char *, const __ops_litdata_enum,
				__ops_output_t *);
unsigned __ops_write_symm_enc_data(const uint8_t *, const int,
				__ops_output_t *);

#endif /* CREATE_H_ */
