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
#include "config.h"

#ifdef HAVE_SYS_CDEFS_H
#include <sys/cdefs.h>
#endif

#if defined(__NetBSD__)
__COPYRIGHT("@(#) Copyright (c) 2009 The NetBSD Foundation, Inc. All rights reserved.");
__RCSID("$NetBSD: signature.c,v 1.32 2010/08/15 16:36:24 agc Exp $");
#endif

#include <sys/types.h>
#include <sys/param.h>

#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif

#include <string.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#ifdef HAVE_OPENSSL_DSA_H
#include <openssl/dsa.h>
#endif

#include "signature.h"
#include "crypto.h"
#include "create.h"
#include "netpgpsdk.h"
#include "readerwriter.h"
#include "validate.h"
#include "netpgpdefs.h"
#include "netpgpdigest.h"


/** \ingroup Core_Create
 * needed for signature creation
 */
struct __ops_create_sig_t {
	__ops_hash_t		 hash;
	__ops_sig_t		 sig;
	__ops_memory_t		*mem;
	__ops_output_t		*output;	/* how to do the writing */
	unsigned		 hashoff;	/* hashed count offset */
	unsigned		 hashlen;
	unsigned 		 unhashoff;
};

/**
   \ingroup Core_Signature
   Creates new __ops_create_sig_t
   \return new __ops_create_sig_t
   \note It is the caller's responsibility to call __ops_create_sig_delete()
   \sa __ops_create_sig_delete()
*/
__ops_create_sig_t *
__ops_create_sig_new(void)
{
	return calloc(1, sizeof(__ops_create_sig_t));
}

/**
   \ingroup Core_Signature
   Free signature and memory associated with it
   \param sig struct to free
   \sa __ops_create_sig_new()
*/
void 
__ops_create_sig_delete(__ops_create_sig_t *sig)
{
	__ops_output_delete(sig->output);
	sig->output = NULL;
	free(sig);
}

#if 0
void
__ops_dump_sig(__ops_sig_t *sig)
{
}
#endif

static uint8_t prefix_md5[] = {
	0x30, 0x20, 0x30, 0x0C, 0x06, 0x08, 0x2A, 0x86, 0x48, 0x86,
	0xF7, 0x0D, 0x02, 0x05, 0x05, 0x00, 0x04, 0x10
};

static uint8_t prefix_sha1[] = {
	0x30, 0x21, 0x30, 0x09, 0x06, 0x05, 0x2b, 0x0E, 0x03, 0x02,
	0x1A, 0x05, 0x00, 0x04, 0x14
};

static uint8_t prefix_sha256[] = {
	0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01,
	0x65, 0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20
};


/* XXX: both this and verify would be clearer if the signature were */
/* treated as an MPI. */
static int 
rsa_sign(__ops_hash_t *hash,
	const __ops_rsa_pubkey_t *pubrsa,
	const __ops_rsa_seckey_t *secrsa,
	__ops_output_t *out)
{
	unsigned        prefixsize;
	unsigned        expected;
	unsigned        hashsize;
	unsigned        keysize;
	unsigned        n;
	unsigned        t;
	uint8_t		hashbuf[NETPGP_BUFSIZ];
	uint8_t		sigbuf[NETPGP_BUFSIZ];
	uint8_t		*prefix;
	BIGNUM         *bn;

	if (strcmp(hash->name, "SHA1") == 0) {
		hashsize = OPS_SHA1_HASH_SIZE + sizeof(prefix_sha1);
		prefix = prefix_sha1;
		prefixsize = sizeof(prefix_sha1);
		expected = OPS_SHA1_HASH_SIZE;
	} else {
		hashsize = OPS_SHA256_HASH_SIZE + sizeof(prefix_sha256);
		prefix = prefix_sha256;
		prefixsize = sizeof(prefix_sha256);
		expected = OPS_SHA256_HASH_SIZE;
	}
	keysize = (BN_num_bits(pubrsa->n) + 7) / 8;
	if (keysize > sizeof(hashbuf)) {
		(void) fprintf(stderr, "rsa_sign: keysize too big\n");
		return 0;
	}
	if (10 + hashsize > keysize) {
		(void) fprintf(stderr, "rsa_sign: hashsize too big\n");
		return 0;
	}

	hashbuf[0] = 0;
	hashbuf[1] = 1;
	if (__ops_get_debug_level(__FILE__)) {
		printf("rsa_sign: PS is %d\n", keysize - hashsize - 1 - 2);
	}
	for (n = 2; n < keysize - hashsize - 1; ++n) {
		hashbuf[n] = 0xff;
	}
	hashbuf[n++] = 0;

	(void) memcpy(&hashbuf[n], prefix, prefixsize);
	n += prefixsize;
	if ((t = hash->finish(hash, &hashbuf[n])) != expected) {
		(void) fprintf(stderr, "rsa_sign: short %s hash\n", hash->name);
		return 0;
	}

	__ops_write(out, &hashbuf[n], 2);

	n += t;
	if (n != keysize) {
		(void) fprintf(stderr, "rsa_sign: n != keysize\n");
		return 0;
	}

	t = __ops_rsa_private_encrypt(sigbuf, hashbuf, keysize, secrsa, pubrsa);
	bn = BN_bin2bn(sigbuf, (int)t, NULL);
	__ops_write_mpi(out, bn);
	BN_free(bn);
	return 1;
}

static int 
dsa_sign(__ops_hash_t *hash,
	 const __ops_dsa_pubkey_t *dsa,
	 const __ops_dsa_seckey_t *sdsa,
	 __ops_output_t *output)
{
	unsigned        hashsize;
	unsigned        t;
	uint8_t		hashbuf[NETPGP_BUFSIZ];
	DSA_SIG        *dsasig;

	/* hashsize must be "equal in size to the number of bits of q,  */
	/* the group generated by the DSA key's generator value */
	/* 160/8 = 20 */

	hashsize = 20;

	/* finalise hash */
	t = hash->finish(hash, &hashbuf[0]);
	if (t != 20) {
		(void) fprintf(stderr, "dsa_sign: hashfinish not 20\n");
		return 0;
	}

	__ops_write(output, &hashbuf[0], 2);

	/* write signature to buf */
	dsasig = __ops_dsa_sign(hashbuf, hashsize, sdsa, dsa);

	/* convert and write the sig out to memory */
	__ops_write_mpi(output, dsasig->r);
	__ops_write_mpi(output, dsasig->s);
	DSA_SIG_free(dsasig);
	return 1;
}

static unsigned 
rsa_verify(__ops_hash_alg_t type,
	   const uint8_t *hash,
	   size_t hash_length,
	   const __ops_rsa_sig_t *sig,
	   const __ops_rsa_pubkey_t *pubrsa)
{
	const uint8_t	*prefix;
	unsigned       	 n;
	unsigned       	 keysize;
	unsigned	 plen;
	unsigned	 debug_len_decrypted;
	uint8_t   	 sigbuf[NETPGP_BUFSIZ];
	uint8_t   	 hashbuf_from_sig[NETPGP_BUFSIZ];

	plen = 0;
	prefix = (const uint8_t *) "";
	keysize = BN_num_bytes(pubrsa->n);
	/* RSA key can't be bigger than 65535 bits, so... */
	if (keysize > sizeof(hashbuf_from_sig)) {
		(void) fprintf(stderr, "rsa_verify: keysize too big\n");
		return 0;
	}
	if ((unsigned) BN_num_bits(sig->sig) > 8 * sizeof(sigbuf)) {
		(void) fprintf(stderr, "rsa_verify: BN_numbits too big\n");
		return 0;
	}
	BN_bn2bin(sig->sig, sigbuf);

	n = __ops_rsa_public_decrypt(hashbuf_from_sig, sigbuf,
		(unsigned)(BN_num_bits(sig->sig) + 7) / 8, pubrsa);
	debug_len_decrypted = n;

	if (n != keysize) {
		/* obviously, this includes error returns */
		return 0;
	}

	/* XXX: why is there a leading 0? The first byte should be 1... */
	/* XXX: because the decrypt should use keysize and not sigsize? */
	if (hashbuf_from_sig[0] != 0 || hashbuf_from_sig[1] != 1) {
		return 0;
	}

	switch (type) {
	case OPS_HASH_MD5:
		prefix = prefix_md5;
		plen = sizeof(prefix_md5);
		break;
	case OPS_HASH_SHA1:
		prefix = prefix_sha1;
		plen = sizeof(prefix_sha1);
		break;
	case OPS_HASH_SHA256:
		prefix = prefix_sha256;
		plen = sizeof(prefix_sha256);
		break;
	default:
		(void) fprintf(stderr, "Unknown hash algorithm: %d\n", type);
		return 0;
	}

	if (keysize - plen - hash_length < 10) {
		return 0;
	}

	for (n = 2; n < keysize - plen - hash_length - 1; ++n) {
		if (hashbuf_from_sig[n] != 0xff) {
			return 0;
		}
	}

	if (hashbuf_from_sig[n++] != 0) {
		return 0;
	}

	if (__ops_get_debug_level(__FILE__)) {
		hexdump(stderr, "sig hashbuf", hashbuf_from_sig, debug_len_decrypted);
		hexdump(stderr, "prefix", prefix, plen);
		hexdump(stderr, "sig hash", &hashbuf_from_sig[n + plen], hash_length);
		hexdump(stderr, "input hash", hash, hash_length);
	}
	return (memcmp(&hashbuf_from_sig[n], prefix, plen) == 0 &&
	        memcmp(&hashbuf_from_sig[n + plen], hash, hash_length) == 0);
}

static void 
hash_add_key(__ops_hash_t *hash, const __ops_pubkey_t *key)
{
	__ops_memory_t	*mem = __ops_memory_new();
	const unsigned 	 dontmakepacket = 0;
	size_t		 len;

	__ops_build_pubkey(mem, key, dontmakepacket);
	len = __ops_mem_len(mem);
	__ops_hash_add_int(hash, 0x99, 1);
	__ops_hash_add_int(hash, (unsigned)len, 2);
	hash->add(hash, __ops_mem_data(mem), (unsigned)len);
	__ops_memory_free(mem);
}

static void 
initialise_hash(__ops_hash_t *hash, const __ops_sig_t *sig)
{
	__ops_hash_any(hash, sig->info.hash_alg);
	if (!hash->init(hash)) {
		(void) fprintf(stderr,
			"initialise_hash: bad hash init\n");
		/* just continue and die */
		/* XXX - agc - no way to return failure */
	}
}

static void 
init_key_sig(__ops_hash_t *hash, const __ops_sig_t *sig,
		   const __ops_pubkey_t *key)
{
	initialise_hash(hash, sig);
	hash_add_key(hash, key);
}

static void 
hash_add_trailer(__ops_hash_t *hash, const __ops_sig_t *sig,
		 const uint8_t *raw_packet)
{
	if (sig->info.version == OPS_V4) {
		if (raw_packet) {
			hash->add(hash, raw_packet + sig->v4_hashstart,
				  (unsigned)sig->info.v4_hashlen);
		}
		__ops_hash_add_int(hash, (unsigned)sig->info.version, 1);
		__ops_hash_add_int(hash, 0xff, 1);
		__ops_hash_add_int(hash, (unsigned)sig->info.v4_hashlen, 4);
	} else {
		__ops_hash_add_int(hash, (unsigned)sig->info.type, 1);
		__ops_hash_add_int(hash, (unsigned)sig->info.birthtime, 4);
	}
}

/**
   \ingroup Core_Signature
   \brief Checks a signature
   \param hash Signature Hash to be checked
   \param length Signature Length
   \param sig The Signature to be checked
   \param signer The signer's public key
   \return 1 if good; else 0
*/
unsigned 
__ops_check_sig(const uint8_t *hash, unsigned length,
		    const __ops_sig_t * sig,
		    const __ops_pubkey_t * signer)
{
	unsigned   ret;

	if (__ops_get_debug_level(__FILE__)) {
		hexdump(stdout, "hash", hash, length);
	}
	ret = 0;
	switch (sig->info.key_alg) {
	case OPS_PKA_DSA:
		ret = __ops_dsa_verify(hash, length, &sig->info.sig.dsa,
				&signer->key.dsa);
		break;

	case OPS_PKA_RSA:
		ret = rsa_verify(sig->info.hash_alg, hash, length,
				&sig->info.sig.rsa,
				&signer->key.rsa);
		break;

	default:
		(void) fprintf(stderr, "__ops_check_sig: unusual alg\n");
		ret = 0;
	}

	return ret;
}

static unsigned 
hash_and_check_sig(__ops_hash_t *hash,
			 const __ops_sig_t *sig,
			 const __ops_pubkey_t *signer)
{
	uint8_t   hashout[OPS_MAX_HASH_SIZE];
	unsigned	n;

	n = hash->finish(hash, hashout);
	return __ops_check_sig(hashout, n, sig, signer);
}

static unsigned 
finalise_sig(__ops_hash_t *hash,
		   const __ops_sig_t *sig,
		   const __ops_pubkey_t *signer,
		   const uint8_t *raw_packet)
{
	hash_add_trailer(hash, sig, raw_packet);
	return hash_and_check_sig(hash, sig, signer);
}

/**
 * \ingroup Core_Signature
 *
 * \brief Verify a certification signature.
 *
 * \param key The public key that was signed.
 * \param id The user ID that was signed
 * \param sig The signature.
 * \param signer The public key of the signer.
 * \param raw_packet The raw signature packet.
 * \return 1 if OK; else 0
 */
unsigned
__ops_check_useridcert_sig(const __ops_pubkey_t *key,
			  const uint8_t *id,
			  const __ops_sig_t *sig,
			  const __ops_pubkey_t *signer,
			  const uint8_t *raw_packet)
{
	__ops_hash_t	hash;
	size_t          userid_len;

	userid_len = strlen((const char *) id);
	init_key_sig(&hash, sig, key);
	if (sig->info.version == OPS_V4) {
		__ops_hash_add_int(&hash, 0xb4, 1);
		__ops_hash_add_int(&hash, (unsigned)userid_len, 4);
	}
	hash.add(&hash, id, (unsigned)userid_len);
	return finalise_sig(&hash, sig, signer, raw_packet);
}

/**
 * \ingroup Core_Signature
 *
 * Verify a certification signature.
 *
 * \param key The public key that was signed.
 * \param attribute The user attribute that was signed
 * \param sig The signature.
 * \param signer The public key of the signer.
 * \param raw_packet The raw signature packet.
 * \return 1 if OK; else 0
 */
unsigned
__ops_check_userattrcert_sig(const __ops_pubkey_t *key,
				const __ops_data_t *attribute,
				const __ops_sig_t *sig,
				const __ops_pubkey_t *signer,
				const uint8_t *raw_packet)
{
	__ops_hash_t      hash;

	init_key_sig(&hash, sig, key);
	if (sig->info.version == OPS_V4) {
		__ops_hash_add_int(&hash, 0xd1, 1);
		__ops_hash_add_int(&hash, (unsigned)attribute->len, 4);
	}
	hash.add(&hash, attribute->contents, (unsigned)attribute->len);
	return finalise_sig(&hash, sig, signer, raw_packet);
}

/**
 * \ingroup Core_Signature
 *
 * Verify a subkey signature.
 *
 * \param key The public key whose subkey was signed.
 * \param subkey The subkey of the public key that was signed.
 * \param sig The signature.
 * \param signer The public key of the signer.
 * \param raw_packet The raw signature packet.
 * \return 1 if OK; else 0
 */
unsigned
__ops_check_subkey_sig(const __ops_pubkey_t *key,
			   const __ops_pubkey_t *subkey,
			   const __ops_sig_t *sig,
			   const __ops_pubkey_t *signer,
			   const uint8_t *raw_packet)
{
	__ops_hash_t	hash;
	unsigned	ret;

	init_key_sig(&hash, sig, key);
	hash_add_key(&hash, subkey);
	ret = finalise_sig(&hash, sig, signer, raw_packet);
	return ret;
}

/**
 * \ingroup Core_Signature
 *
 * Verify a direct signature.
 *
 * \param key The public key which was signed.
 * \param sig The signature.
 * \param signer The public key of the signer.
 * \param raw_packet The raw signature packet.
 * \return 1 if OK; else 0
 */
unsigned
__ops_check_direct_sig(const __ops_pubkey_t *key,
			   const __ops_sig_t *sig,
			   const __ops_pubkey_t *signer,
			   const uint8_t *raw_packet)
{
	__ops_hash_t	hash;
	unsigned	ret;

	init_key_sig(&hash, sig, key);
	ret = finalise_sig(&hash, sig, signer, raw_packet);
	return ret;
}

/**
 * \ingroup Core_Signature
 *
 * Verify a signature on a hash (the hash will have already been fed
 * the material that was being signed, for example signed cleartext).
 *
 * \param hash A hash structure of appropriate type that has been fed
 * the material to be signed. This MUST NOT have been finalised.
 * \param sig The signature to be verified.
 * \param signer The public key of the signer.
 * \return 1 if OK; else 0
 */
unsigned
__ops_check_hash_sig(__ops_hash_t *hash,
			 const __ops_sig_t *sig,
			 const __ops_pubkey_t *signer)
{
	return (sig->info.hash_alg == hash->alg) ?
		finalise_sig(hash, sig, signer, NULL) :
		0;
}

static void 
start_sig_in_mem(__ops_create_sig_t *sig)
{
	/* since this has subpackets and stuff, we have to buffer the whole */
	/* thing to get counts before writing. */
	sig->mem = __ops_memory_new();
	__ops_memory_init(sig->mem, 100);
	__ops_writer_set_memory(sig->output, sig->mem);

	/* write nearly up to the first subpacket */
	__ops_write_scalar(sig->output, (unsigned)sig->sig.info.version, 1);
	__ops_write_scalar(sig->output, (unsigned)sig->sig.info.type, 1);
	__ops_write_scalar(sig->output, (unsigned)sig->sig.info.key_alg, 1);
	__ops_write_scalar(sig->output, (unsigned)sig->sig.info.hash_alg, 1);

	/* dummy hashed subpacket count */
	sig->hashoff = (unsigned)__ops_mem_len(sig->mem);
	__ops_write_scalar(sig->output, 0, 2);
}

/**
 * \ingroup Core_Signature
 *
 * __ops_sig_start() creates a V4 public key signature with a SHA1 hash.
 *
 * \param sig The signature structure to initialise
 * \param key The public key to be signed
 * \param id The user ID being bound to the key
 * \param type Signature type
 */
void 
__ops_sig_start_key_sig(__ops_create_sig_t *sig,
				  const __ops_pubkey_t *key,
				  const uint8_t *id,
				  __ops_sig_type_t type)
{
	sig->output = __ops_output_new();

	/* XXX:  refactor with check (in several ways - check should
	 * probably use the buffered writer to construct packets
	 * (done), and also should share code for hash calculation) */
	sig->sig.info.version = OPS_V4;
	sig->sig.info.hash_alg = OPS_HASH_SHA1;
	sig->sig.info.key_alg = key->alg;
	sig->sig.info.type = type;
	sig->hashlen = (unsigned)-1;
	init_key_sig(&sig->hash, &sig->sig, key);
	__ops_hash_add_int(&sig->hash, 0xb4, 1);
	__ops_hash_add_int(&sig->hash, (unsigned)strlen((const char *) id), 4);
	sig->hash.add(&sig->hash, id, (unsigned)strlen((const char *) id));
	start_sig_in_mem(sig);
}

/**
 * \ingroup Core_Signature
 *
 * Create a V4 public key signature over some cleartext.
 *
 * \param sig The signature structure to initialise
 * \param id
 * \param type
 * \todo Expand description. Allow other hashes.
 */

void 
__ops_start_sig(__ops_create_sig_t *sig,
	      const __ops_seckey_t *key,
	      const __ops_hash_alg_t hash,
	      const __ops_sig_type_t type)
{
	sig->output = __ops_output_new();

	/* XXX:  refactor with check (in several ways - check should
	 * probably use the buffered writer to construct packets
	 * (done), and also should share code for hash calculation) */
	sig->sig.info.version = OPS_V4;
	sig->sig.info.key_alg = key->pubkey.alg;
	sig->sig.info.hash_alg = hash;
	sig->sig.info.type = type;

	sig->hashlen = (unsigned)-1;

	if (__ops_get_debug_level(__FILE__)) {
		fprintf(stderr, "initialising hash for sig in mem\n");
	}
	initialise_hash(&sig->hash, &sig->sig);
	start_sig_in_mem(sig);
}

/**
 * \ingroup Core_Signature
 *
 * Add plaintext data to a signature-to-be.
 *
 * \param sig The signature-to-be.
 * \param buf The plaintext data.
 * \param length The amount of plaintext data.
 */
void 
__ops_sig_add_data(__ops_create_sig_t *sig, const void *buf, size_t length)
{
	sig->hash.add(&sig->hash, buf, (unsigned)length);
}

/**
 * \ingroup Core_Signature
 *
 * Mark the end of the hashed subpackets in the signature
 *
 * \param sig
 */

unsigned 
__ops_end_hashed_subpkts(__ops_create_sig_t *sig)
{
	sig->hashlen = (unsigned)(__ops_mem_len(sig->mem) - sig->hashoff - 2);
	__ops_memory_place_int(sig->mem, sig->hashoff, sig->hashlen, 2);
	/* dummy unhashed subpacket count */
	sig->unhashoff = (unsigned)__ops_mem_len(sig->mem);
	return __ops_write_scalar(sig->output, 0, 2);
}

/**
 * \ingroup Core_Signature
 *
 * Write out a signature
 *
 * \param sig
 * \param key
 * \param seckey
 * \param info
 *
 */

unsigned 
__ops_write_sig(__ops_output_t *output, 
			__ops_create_sig_t *sig,
			const __ops_pubkey_t *key,
			const __ops_seckey_t *seckey)
{
	unsigned	ret = 0;
	size_t		len = __ops_mem_len(sig->mem);

	/* check key not decrypted */
	switch (seckey->pubkey.alg) {
	case OPS_PKA_RSA:
	case OPS_PKA_RSA_ENCRYPT_ONLY:
	case OPS_PKA_RSA_SIGN_ONLY:
		if (seckey->key.rsa.d == NULL) {
			(void) fprintf(stderr, "__ops_write_sig: null rsa.d\n");
			return 0;
		}
		break;

	case OPS_PKA_DSA:
		if (seckey->key.dsa.x == NULL) {
			(void) fprintf(stderr, "__ops_write_sig: null dsa.x\n");
			return 0;
		}
		break;

	default:
		(void) fprintf(stderr, "Unsupported algorithm %d\n",
				seckey->pubkey.alg);
		return 0;
	}

	if (sig->hashlen == (unsigned) -1) {
		(void) fprintf(stderr,
				"ops_write_sig: bad hashed data len\n");
		return 0;
	}

	__ops_memory_place_int(sig->mem, sig->unhashoff,
			     (unsigned)(len - sig->unhashoff - 2), 2);

	/* add the packet from version number to end of hashed subpackets */
	if (__ops_get_debug_level(__FILE__)) {
		(void) fprintf(stderr, "ops_write_sig: hashed packet info\n");
	}
	sig->hash.add(&sig->hash, __ops_mem_data(sig->mem), sig->unhashoff);

	/* add final trailer */
	__ops_hash_add_int(&sig->hash, (unsigned)sig->sig.info.version, 1);
	__ops_hash_add_int(&sig->hash, 0xff, 1);
	/* +6 for version, type, pk alg, hash alg, hashed subpacket length */
	__ops_hash_add_int(&sig->hash, sig->hashlen + 6, 4);

	if (__ops_get_debug_level(__FILE__)) {
		(void) fprintf(stderr, "ops_write_sig: done writing hashed\n");
	}
	/* XXX: technically, we could figure out how big the signature is */
	/* and write it directly to the output instead of via memory. */
	switch (seckey->pubkey.alg) {
	case OPS_PKA_RSA:
	case OPS_PKA_RSA_ENCRYPT_ONLY:
	case OPS_PKA_RSA_SIGN_ONLY:
		if (!rsa_sign(&sig->hash, &key->key.rsa, &seckey->key.rsa,
				sig->output)) {
			(void) fprintf(stderr,
				"__ops_write_sig: rsa_sign failure\n");
			return 0;
		}
		break;

	case OPS_PKA_DSA:
		if (!dsa_sign(&sig->hash, &key->key.dsa, &seckey->key.dsa,
				sig->output)) {
			(void) fprintf(stderr,
				"__ops_write_sig: dsa_sign failure\n");
			return 0;
		}
		break;

	default:
		(void) fprintf(stderr, "Unsupported algorithm %d\n",
					seckey->pubkey.alg);
		return 0;
	}

	ret = __ops_write_ptag(output, OPS_PTAG_CT_SIGNATURE);
	if (ret) {
		len = __ops_mem_len(sig->mem);
		ret = __ops_write_length(output, (unsigned)len) &&
			__ops_write(output, __ops_mem_data(sig->mem), (unsigned)len);
	}
	__ops_memory_free(sig->mem);

	if (ret == 0) {
		OPS_ERROR(&output->errors, OPS_E_W, "Cannot write signature");
	}
	return ret;
}

/* add a time stamp to the output */
unsigned 
__ops_add_time(__ops_create_sig_t *sig, int64_t when, const char *type)
{
	__ops_content_enum	tag;

	tag = (strcmp(type, "birth") == 0) ?
		OPS_PTAG_SS_CREATION_TIME : OPS_PTAG_SS_EXPIRATION_TIME;
	/* just do 32-bit timestamps for just now - it's in the protocol */
	return __ops_write_ss_header(sig->output, 5, tag) &&
		__ops_write_scalar(sig->output, (uint32_t)when, (unsigned)sizeof(uint32_t));
}

/**
 * \ingroup Core_Signature
 *
 * Adds issuer's key ID to the signature
 *
 * \param sig
 * \param keyid
 */

unsigned 
__ops_add_issuer_keyid(__ops_create_sig_t *sig,
				const uint8_t keyid[OPS_KEY_ID_SIZE])
{
	return __ops_write_ss_header(sig->output, OPS_KEY_ID_SIZE + 1,
				OPS_PTAG_SS_ISSUER_KEY_ID) &&
		__ops_write(sig->output, keyid, OPS_KEY_ID_SIZE);
}

/**
 * \ingroup Core_Signature
 *
 * Adds primary user ID to the signature
 *
 * \param sig
 * \param primary
 */
void 
__ops_add_primary_userid(__ops_create_sig_t *sig, unsigned primary)
{
	__ops_write_ss_header(sig->output, 2, OPS_PTAG_SS_PRIMARY_USER_ID);
	__ops_write_scalar(sig->output, primary, 1);
}

/**
 * \ingroup Core_Signature
 *
 * Get the hash structure in use for the signature.
 *
 * \param sig The signature structure.
 * \return The hash structure.
 */
__ops_hash_t     *
__ops_sig_get_hash(__ops_create_sig_t *sig)
{
	return &sig->hash;
}

/* open up an output file */
static int 
open_output_file(__ops_output_t **output,
			const char *inname,
			const char *outname,
			const char *suffix,
			const unsigned overwrite)
{
	int             fd;

	/* setup output file */
	if (outname) {
		fd = __ops_setup_file_write(output, outname, overwrite);
	} else {
		unsigned        flen = (unsigned)(strlen(inname) + 4 + 1);
		char           *f = NULL;

		if ((f = calloc(1, flen)) == NULL) {
			(void) fprintf(stderr, "open_output_file: bad alloc\n");
			fd = -1;
		} else {
			(void) snprintf(f, flen, "%s.%s", inname, suffix);
			fd = __ops_setup_file_write(output, f, overwrite);
			free(f);
		}
	}
	return fd;
}

/**
\ingroup HighLevel_Sign
\brief Sign a file
\param inname Input filename
\param outname Output filename. If NULL, a name is constructed from the input filename.
\param seckey Secret Key to use for signing
\param armored Write armoured text, if set.
\param overwrite May overwrite existing file, if set.
\return 1 if OK; else 0;

*/
unsigned 
__ops_sign_file(__ops_io_t *io,
		const char *inname,
		const char *outname,
		const __ops_seckey_t *seckey,
		const char *hashname,
		const int64_t from,
		const uint64_t duration,
		const unsigned armored,
		const unsigned cleartext,
		const unsigned overwrite)
{
	__ops_create_sig_t	*sig;
	__ops_sig_type_t	 sig_type;
	__ops_hash_alg_t	 hash_alg;
	__ops_memory_t		*infile;
	__ops_output_t		*output;
	__ops_hash_t		*hash;
	unsigned		 ret;
	uint8_t			 keyid[OPS_KEY_ID_SIZE];
	int			 fd_out;

	sig = NULL;
	sig_type = OPS_SIG_BINARY;
	infile = NULL;
	output = NULL;
	hash = NULL;
	fd_out = 0;

	/* find the hash algorithm */
	hash_alg = __ops_str_to_hash_alg(hashname);
	if (hash_alg == OPS_HASH_UNKNOWN) {
		(void) fprintf(io->errs,
			"__ops_sign_file: unknown hash algorithm: \"%s\"\n",
			hashname);
		return 0;
	}

	/* read input file into buf */
	infile = __ops_memory_new();
	if (!__ops_mem_readfile(infile, inname)) {
		return 0;
	}

	/* setup output file */
	fd_out = open_output_file(&output, inname, outname,
				(armored) ? "asc" : "gpg", overwrite);
	if (fd_out < 0) {
		__ops_memory_free(infile);
		return 0;
	}

	/* set up signature */
	sig = __ops_create_sig_new();
	if (!sig) {
		__ops_memory_free(infile);
		__ops_teardown_file_write(output, fd_out);
		return 0;
	}

	__ops_start_sig(sig, seckey, hash_alg, sig_type);

	if (cleartext) {
		if (__ops_writer_push_clearsigned(output, sig) != 1) {
			return 0;
		}

		/* Do the signing */
		__ops_write(output, __ops_mem_data(infile), (unsigned)__ops_mem_len(infile));
		__ops_memory_free(infile);

		/* add signature with subpackets: */
		/* - creation time */
		/* - key id */
		ret = __ops_writer_use_armored_sig(output) &&
				__ops_add_time(sig, (int64_t)from, "birth") &&
				__ops_add_time(sig, (int64_t)duration, "expiration");
		if (ret == 0) {
			__ops_teardown_file_write(output, fd_out);
			return 0;
		}

		__ops_keyid(keyid, OPS_KEY_ID_SIZE, &seckey->pubkey, hash_alg);
		ret = __ops_add_issuer_keyid(sig, keyid) &&
			__ops_end_hashed_subpkts(sig) &&
			__ops_write_sig(output, sig, &seckey->pubkey, seckey);

		__ops_teardown_file_write(output, fd_out);

		if (ret == 0) {
			OPS_ERROR(&output->errors, OPS_E_W,
					"Cannot sign file as cleartext");
		}
	} else {
		/* set armoured/not armoured here */
		if (armored) {
			__ops_writer_push_armor_msg(output);
		}

		/* write one_pass_sig */
		__ops_write_one_pass_sig(output, seckey, hash_alg, sig_type);

		/* hash file contents */
		hash = __ops_sig_get_hash(sig);
		hash->add(hash, __ops_mem_data(infile), (unsigned)__ops_mem_len(infile));

#if 1
		/* output file contents as Literal Data packet */
		__ops_write_litdata(output, __ops_mem_data(infile),
			(const int)__ops_mem_len(infile),
			OPS_LDT_BINARY);
#else
		/* XXX - agc - sync with writer.c 1094 for ops_writez */
		__ops_setup_memory_write(&litoutput, &litmem, bufsz);
		__ops_setup_memory_write(&zoutput, &zmem, bufsz);
		__ops_write_litdata(litoutput,
			__ops_mem_data(__ops_mem_data(infile),
			(const int)__ops_mem_len(infile), OPS_LDT_BINARY);
		__ops_writez(zoutput, __ops_mem_data(litmem), __ops_mem_len(litmem));
#endif

		/* add creation time to signature */
		__ops_add_time(sig, (int64_t)from, "birth");
		__ops_add_time(sig, (int64_t)duration, "expiration");
		/* add key id to signature */
		__ops_keyid(keyid, OPS_KEY_ID_SIZE, &seckey->pubkey, hash_alg);
		__ops_add_issuer_keyid(sig, keyid);
		__ops_end_hashed_subpkts(sig);
		__ops_write_sig(output, sig, &seckey->pubkey, seckey);

		/* tidy up */
		__ops_teardown_file_write(output, fd_out);

		__ops_create_sig_delete(sig);
		__ops_memory_free(infile);

		ret = 1;
	}

	return ret;
}

/**
\ingroup HighLevel_Sign
\brief Signs a buffer
\param input Input text to be signed
\param input_len Length of input text
\param sig_type Signature type
\param seckey Secret Key
\param armored Write armoured text, if set
\return New __ops_memory_t struct containing signed text
\note It is the caller's responsibility to call __ops_memory_free(me)

*/
__ops_memory_t *
__ops_sign_buf(__ops_io_t *io,
		const void *input,
		const size_t insize,
		const __ops_seckey_t *seckey,
		const int64_t from,
		const uint64_t duration,
		const char *hashname,
		const unsigned armored,
		const unsigned cleartext)
{
	__ops_litdata_enum	 ld_type;
	__ops_create_sig_t	*sig;
	__ops_sig_type_t	 sig_type;
	__ops_hash_alg_t	 hash_alg;
	__ops_output_t		*output;
	__ops_memory_t		*mem;
	uint8_t			 keyid[OPS_KEY_ID_SIZE];
	__ops_hash_t		*hash;
	unsigned		 ret;

	sig = NULL;
	sig_type = OPS_SIG_BINARY;
	output = NULL;
	mem = __ops_memory_new();
	hash = NULL;
	ret = 0;

	hash_alg = __ops_str_to_hash_alg(hashname);
	if (hash_alg == OPS_HASH_UNKNOWN) {
		(void) fprintf(io->errs,
			"__ops_sign_buf: unknown hash algorithm: \"%s\"\n",
			hashname);
		return NULL;
	}

	/* setup literal data packet type */
	ld_type = (cleartext) ? OPS_LDT_TEXT : OPS_LDT_BINARY;

	if (input == NULL) {
		(void) fprintf(io->errs,
			"__ops_sign_buf: null input\n");
		return NULL;
	}

	/* set up signature */
	if ((sig = __ops_create_sig_new()) == NULL) {
		return NULL;
	}
	__ops_start_sig(sig, seckey, hash_alg, sig_type);

	/* setup writer */
	__ops_setup_memory_write(&output, &mem, insize);

	if (cleartext) {
		/* Do the signing */
		/* add signature with subpackets: */
		/* - creation time */
		/* - key id */
		ret = __ops_writer_push_clearsigned(output, sig) &&
			__ops_write(output, input, (unsigned)insize) &&
			__ops_writer_use_armored_sig(output) &&
			__ops_add_time(sig, from, "birth") &&
			__ops_add_time(sig, (int64_t)duration, "expiration");
		if (ret == 0) {
			return NULL;
		}
		__ops_output_delete(output);
	} else {
		/* set armoured/not armoured here */
		if (armored) {
			__ops_writer_push_armor_msg(output);
		}
		if (__ops_get_debug_level(__FILE__)) {
			fprintf(io->errs, "** Writing out one pass sig\n");
		}
		/* write one_pass_sig */
		__ops_write_one_pass_sig(output, seckey, hash_alg, sig_type);

		/* hash memory */
		hash = __ops_sig_get_hash(sig);
		hash->add(hash, input, (unsigned)insize);

		/* output file contents as Literal Data packet */
		if (__ops_get_debug_level(__FILE__)) {
			(void) fprintf(stderr, "** Writing out data now\n");
		}
		__ops_write_litdata(output, input, (const int)insize, ld_type);
		if (__ops_get_debug_level(__FILE__)) {
			fprintf(stderr, "** After Writing out data now\n");
		}

		/* add creation time to signature */
		__ops_add_time(sig, from, "birth");
		__ops_add_time(sig, (int64_t)duration, "expiration");
		/* add key id to signature */
		__ops_keyid(keyid, OPS_KEY_ID_SIZE, &seckey->pubkey, hash_alg);
		__ops_add_issuer_keyid(sig, keyid);
		__ops_end_hashed_subpkts(sig);

		/* write out sig */
		__ops_write_sig(output, sig, &seckey->pubkey, seckey);

		/* tidy up */
		__ops_writer_close(output);
		__ops_create_sig_delete(sig);
	}
	return mem;
}

/* sign a file, and put the signature in a separate file */
int
__ops_sign_detached(__ops_io_t *io,
			const char *f,
			char *sigfile,
			__ops_seckey_t *seckey,
			const char *hash,
			const int64_t from,
			const uint64_t duration,
			const unsigned armored, const unsigned overwrite)
{
	__ops_create_sig_t	*sig;
	__ops_hash_alg_t	 hash_alg;
	__ops_output_t		*output;
	__ops_memory_t		*mem;
	uint8_t	 	 	 keyid[OPS_KEY_ID_SIZE];
	int			 fd;

	/* find out which hash algorithm to use */
	hash_alg = __ops_str_to_hash_alg(hash);
	if (hash_alg == OPS_HASH_UNKNOWN) {
		(void) fprintf(io->errs,"Unknown hash algorithm: %s\n", hash);
		return 0;
	}

	/* setup output file */
	fd = open_output_file(&output, f, sigfile,
				(armored) ? "asc" : "sig", overwrite);
	if (fd < 0) {
		(void) fprintf(io->errs,"Can't open output file: %s\n", f);
		return 0;
	}

	/* create a new signature */
	sig = __ops_create_sig_new();
	__ops_start_sig(sig, seckey, hash_alg, OPS_SIG_BINARY);

	/* read the contents of 'f', and add that to the signature */
	mem = __ops_memory_new();
	if (!__ops_mem_readfile(mem, f)) {
		__ops_teardown_file_write(output, fd);
		return 0;
	}
	/* set armoured/not armoured here */
	if (armored) {
		__ops_writer_push_armor_msg(output);
	}
	__ops_sig_add_data(sig, __ops_mem_data(mem), __ops_mem_len(mem));
	__ops_memory_free(mem);

	/* calculate the signature */
	__ops_add_time(sig, from, "birth");
	__ops_add_time(sig, (int64_t)duration, "expiration");
	__ops_keyid(keyid, sizeof(keyid), &seckey->pubkey, hash_alg);
	__ops_add_issuer_keyid(sig, keyid);
	__ops_end_hashed_subpkts(sig);
	__ops_write_sig(output, sig, &seckey->pubkey, seckey);
	__ops_teardown_file_write(output, fd);
	__ops_seckey_free(seckey);

	return 1;
}
