/*-
 * Copyright (c) 2009,2010 The NetBSD Foundation, Inc.
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
#ifndef NETPGPSDK_H_
#define NETPGPSDK_H_

#include "keyring.h"
#include "crypto.h"
#include "signature.h"
#include "packet-show.h"

typedef struct __ops_validation_t {
	unsigned		 validc;
	__ops_sig_info_t	*valid_sigs;
	unsigned		 invalidc;
	__ops_sig_info_t	*invalid_sigs;
	unsigned		 unknownc;
	__ops_sig_info_t	*unknown_sigs;
	time_t			 birthtime;
	time_t			 duration;
} __ops_validation_t;

void            __ops_validate_result_free(__ops_validation_t *);

unsigned 
__ops_validate_key_sigs(__ops_validation_t *,
		const __ops_key_t *,
		const __ops_keyring_t *,
		__ops_cb_ret_t cb(const __ops_packet_t *, __ops_cbdata_t *));

unsigned
__ops_validate_all_sigs(__ops_validation_t *,
		const __ops_keyring_t *,
		__ops_cb_ret_t cb(const __ops_packet_t *, __ops_cbdata_t *));

unsigned   __ops_check_sig(const uint8_t *,
		unsigned, const __ops_sig_t *, const __ops_pubkey_t *);

const char     *__ops_get_info(const char *type);

int __ops_asprintf(char **, const char *, ...);

void netpgp_log(const char *, ...);

int netpgp_strcasecmp(const char *, const char *);
char *netpgp_strdup(const char *);


#endif
