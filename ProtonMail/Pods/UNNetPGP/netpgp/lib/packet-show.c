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
 *
 * Creates printable text strings from packet contents
 *
 */
#include "config.h"

#ifdef HAVE_SYS_CDEFS_H
#include <sys/cdefs.h>
#endif

#if defined(__NetBSD__)
__COPYRIGHT("@(#) Copyright (c) 2009 The NetBSD Foundation, Inc. All rights reserved.");
__RCSID("$NetBSD: packet-show.c,v 1.18 2010/11/04 06:45:28 agc Exp $");
#endif

#include <stdlib.h>
#include <string.h>

#include "packet-show.h"

#include "netpgpsdk.h"
#include "netpgpdefs.h"


/*
 * Arrays of value->text maps
 */

static __ops_map_t packet_tag_map[] =
{
	{OPS_PTAG_CT_RESERVED, "Reserved"},
	{OPS_PTAG_CT_PK_SESSION_KEY, "Public-Key Encrypted Session Key"},
	{OPS_PTAG_CT_SIGNATURE, "Signature"},
	{OPS_PTAG_CT_SK_SESSION_KEY, "Symmetric-Key Encrypted Session Key"},
	{OPS_PTAG_CT_1_PASS_SIG, "One-Pass Signature"},
	{OPS_PTAG_CT_SECRET_KEY, "Secret Key"},
	{OPS_PTAG_CT_PUBLIC_KEY, "Public Key"},
	{OPS_PTAG_CT_SECRET_SUBKEY, "Secret Subkey"},
	{OPS_PTAG_CT_COMPRESSED, "Compressed Data"},
	{OPS_PTAG_CT_SE_DATA, "Symmetrically Encrypted Data"},
	{OPS_PTAG_CT_MARKER, "Marker"},
	{OPS_PTAG_CT_LITDATA, "Literal Data"},
	{OPS_PTAG_CT_TRUST, "Trust"},
	{OPS_PTAG_CT_USER_ID, "User ID"},
	{OPS_PTAG_CT_PUBLIC_SUBKEY, "Public Subkey"},
	{OPS_PTAG_CT_RESERVED2, "reserved2"},
	{OPS_PTAG_CT_RESERVED3, "reserved3"},
	{OPS_PTAG_CT_USER_ATTR, "User Attribute"},
	{OPS_PTAG_CT_SE_IP_DATA,
		"Symmetric Encrypted and Integrity Protected Data"},
	{OPS_PTAG_CT_MDC, "Modification Detection Code"},
	{OPS_PARSER_PTAG, "OPS_PARSER_PTAG"},
	{OPS_PTAG_RAW_SS, "OPS_PTAG_RAW_SS"},
	{OPS_PTAG_SS_ALL, "OPS_PTAG_SS_ALL"},
	{OPS_PARSER_PACKET_END, "OPS_PARSER_PACKET_END"},
	{OPS_PTAG_SIG_SUBPKT_BASE, "OPS_PTAG_SIG_SUBPKT_BASE"},
	{OPS_PTAG_SS_CREATION_TIME, "SS: Signature Creation Time"},
	{OPS_PTAG_SS_EXPIRATION_TIME, "SS: Signature Expiration Time"},
	{OPS_PTAG_SS_EXPORT_CERT, "SS: Exportable Certification"},
	{OPS_PTAG_SS_TRUST, "SS: Trust Signature"},
	{OPS_PTAG_SS_REGEXP, "SS: Regular Expression"},
	{OPS_PTAG_SS_REVOCABLE, "SS: Revocable"},
	{OPS_PTAG_SS_KEY_EXPIRY, "SS: Key Expiration Time"},
	{OPS_PTAG_SS_RESERVED, "SS: Reserved"},
	{OPS_PTAG_SS_PREFERRED_SKA, "SS: Preferred Secret Key Algorithm"},
	{OPS_PTAG_SS_REVOCATION_KEY, "SS: Revocation Key"},
	{OPS_PTAG_SS_ISSUER_KEY_ID, "SS: Issuer Key Id"},
	{OPS_PTAG_SS_NOTATION_DATA, "SS: Notation Data"},
	{OPS_PTAG_SS_PREFERRED_HASH, "SS: Preferred Hash Algorithm"},
	{OPS_PTAG_SS_PREF_COMPRESS, "SS: Preferred Compression Algorithm"},
	{OPS_PTAG_SS_KEYSERV_PREFS, "SS: Key Server Preferences"},
	{OPS_PTAG_SS_PREF_KEYSERV, "SS: Preferred Key Server"},
	{OPS_PTAG_SS_PRIMARY_USER_ID, "SS: Primary User ID"},
	{OPS_PTAG_SS_POLICY_URI, "SS: Policy URI"},
	{OPS_PTAG_SS_KEY_FLAGS, "SS: Key Flags"},
	{OPS_PTAG_SS_SIGNERS_USER_ID, "SS: Signer's User ID"},
	{OPS_PTAG_SS_REVOCATION_REASON, "SS: Reason for Revocation"},
	{OPS_PTAG_SS_FEATURES, "SS: Features"},
	{OPS_PTAG_SS_SIGNATURE_TARGET, "SS: Signature Target"},
	{OPS_PTAG_SS_EMBEDDED_SIGNATURE, "SS: Embedded Signature"},

	{OPS_PTAG_CT_LITDATA_HEADER, "CT: Literal Data Header"},
	{OPS_PTAG_CT_LITDATA_BODY, "CT: Literal Data Body"},
	{OPS_PTAG_CT_SIGNATURE_HEADER, "CT: Signature Header"},
	{OPS_PTAG_CT_SIGNATURE_FOOTER, "CT: Signature Footer"},
	{OPS_PTAG_CT_ARMOUR_HEADER, "CT: Armour Header"},
	{OPS_PTAG_CT_ARMOUR_TRAILER, "CT: Armour Trailer"},
	{OPS_PTAG_CT_SIGNED_CLEARTEXT_HEADER, "CT: Signed Cleartext Header"},
	{OPS_PTAG_CT_SIGNED_CLEARTEXT_BODY, "CT: Signed Cleartext Body"},
	{OPS_PTAG_CT_SIGNED_CLEARTEXT_TRAILER, "CT: Signed Cleartext Trailer"},
	{OPS_PTAG_CT_UNARMOURED_TEXT, "CT: Unarmoured Text"},
	{OPS_PTAG_CT_ENCRYPTED_SECRET_KEY, "CT: Encrypted Secret Key"},
	{OPS_PTAG_CT_SE_DATA_HEADER, "CT: Sym Encrypted Data Header"},
	{OPS_PTAG_CT_SE_DATA_BODY, "CT: Sym Encrypted Data Body"},
	{OPS_PTAG_CT_SE_IP_DATA_HEADER, "CT: Sym Encrypted IP Data Header"},
	{OPS_PTAG_CT_SE_IP_DATA_BODY, "CT: Sym Encrypted IP Data Body"},
	{OPS_PTAG_CT_ENCRYPTED_PK_SESSION_KEY, "CT: Encrypted PK Session Key"},
	{OPS_GET_PASSPHRASE, "CMD: Get Secret Key Passphrase"},
	{OPS_GET_SECKEY, "CMD: Get Secret Key"},
	{OPS_PARSER_ERROR, "OPS_PARSER_ERROR"},
	{OPS_PARSER_ERRCODE, "OPS_PARSER_ERRCODE"},

	{0x00, NULL},		/* this is the end-of-array marker */
};

static __ops_map_t ss_type_map[] =
{
	{OPS_PTAG_SS_CREATION_TIME, "Signature Creation Time"},
	{OPS_PTAG_SS_EXPIRATION_TIME, "Signature Expiration Time"},
	{OPS_PTAG_SS_TRUST, "Trust Signature"},
	{OPS_PTAG_SS_REGEXP, "Regular Expression"},
	{OPS_PTAG_SS_REVOCABLE, "Revocable"},
	{OPS_PTAG_SS_KEY_EXPIRY, "Key Expiration Time"},
	{OPS_PTAG_SS_PREFERRED_SKA, "Preferred Symmetric Algorithms"},
	{OPS_PTAG_SS_REVOCATION_KEY, "Revocation Key"},
	{OPS_PTAG_SS_ISSUER_KEY_ID, "Issuer key ID"},
	{OPS_PTAG_SS_NOTATION_DATA, "Notation Data"},
	{OPS_PTAG_SS_PREFERRED_HASH, "Preferred Hash Algorithms"},
	{OPS_PTAG_SS_PREF_COMPRESS, "Preferred Compression Algorithms"},
	{OPS_PTAG_SS_KEYSERV_PREFS, "Key Server Preferences"},
	{OPS_PTAG_SS_PREF_KEYSERV, "Preferred Key Server"},
	{OPS_PTAG_SS_PRIMARY_USER_ID, "Primary User ID"},
	{OPS_PTAG_SS_POLICY_URI, "Policy URI"},
	{OPS_PTAG_SS_KEY_FLAGS, "Key Flags"},
	{OPS_PTAG_SS_REVOCATION_REASON, "Reason for Revocation"},
	{OPS_PTAG_SS_FEATURES, "Features"},
	{0x00, NULL},		/* this is the end-of-array marker */
};


static __ops_map_t ss_rr_code_map[] =
{
	{0x00, "No reason specified"},
	{0x01, "Key is superseded"},
	{0x02, "Key material has been compromised"},
	{0x03, "Key is retired and no longer used"},
	{0x20, "User ID information is no longer valid"},
	{0x00, NULL},		/* this is the end-of-array marker */
};

static __ops_map_t sig_type_map[] =
{
	{OPS_SIG_BINARY, "Signature of a binary document"},
	{OPS_SIG_TEXT, "Signature of a canonical text document"},
	{OPS_SIG_STANDALONE, "Standalone signature"},
	{OPS_CERT_GENERIC, "Generic certification of a User ID and Public Key packet"},
	{OPS_CERT_PERSONA, "Personal certification of a User ID and Public Key packet"},
	{OPS_CERT_CASUAL, "Casual certification of a User ID and Public Key packet"},
	{OPS_CERT_POSITIVE, "Positive certification of a User ID and Public Key packet"},
	{OPS_SIG_SUBKEY, "Subkey Binding Signature"},
	{OPS_SIG_PRIMARY, "Primary Key Binding Signature"},
	{OPS_SIG_DIRECT, "Signature directly on a key"},
	{OPS_SIG_REV_KEY, "Key revocation signature"},
	{OPS_SIG_REV_SUBKEY, "Subkey revocation signature"},
	{OPS_SIG_REV_CERT, "Certification revocation signature"},
	{OPS_SIG_TIMESTAMP, "Timestamp signature"},
	{OPS_SIG_3RD_PARTY, "Third-Party Confirmation signature"},
	{0x00, NULL},		/* this is the end-of-array marker */
};

static __ops_map_t pubkey_alg_map[] =
{
	{OPS_PKA_RSA, "RSA (Encrypt or Sign)"},
	{OPS_PKA_RSA_ENCRYPT_ONLY, "RSA Encrypt-Only"},
	{OPS_PKA_RSA_SIGN_ONLY, "RSA Sign-Only"},
	{OPS_PKA_ELGAMAL, "Elgamal (Encrypt-Only)"},
	{OPS_PKA_DSA, "DSA"},
	{OPS_PKA_RESERVED_ELLIPTIC_CURVE, "Reserved for Elliptic Curve"},
	{OPS_PKA_RESERVED_ECDSA, "Reserved for ECDSA"},
	{OPS_PKA_ELGAMAL_ENCRYPT_OR_SIGN, "Reserved (formerly Elgamal Encrypt or Sign"},
	{OPS_PKA_RESERVED_DH, "Reserved for Diffie-Hellman (X9.42)"},
	{OPS_PKA_PRIVATE00, "Private/Experimental"},
	{OPS_PKA_PRIVATE01, "Private/Experimental"},
	{OPS_PKA_PRIVATE02, "Private/Experimental"},
	{OPS_PKA_PRIVATE03, "Private/Experimental"},
	{OPS_PKA_PRIVATE04, "Private/Experimental"},
	{OPS_PKA_PRIVATE05, "Private/Experimental"},
	{OPS_PKA_PRIVATE06, "Private/Experimental"},
	{OPS_PKA_PRIVATE07, "Private/Experimental"},
	{OPS_PKA_PRIVATE08, "Private/Experimental"},
	{OPS_PKA_PRIVATE09, "Private/Experimental"},
	{OPS_PKA_PRIVATE10, "Private/Experimental"},
	{0x00, NULL},		/* this is the end-of-array marker */
};

static __ops_map_t symm_alg_map[] =
{
	{OPS_SA_PLAINTEXT, "Plaintext or unencrypted data"},
	{OPS_SA_IDEA, "IDEA"},
	{OPS_SA_TRIPLEDES, "TripleDES"},
	{OPS_SA_CAST5, "CAST5"},
	{OPS_SA_BLOWFISH, "Blowfish"},
	{OPS_SA_AES_128, "AES (128-bit key)"},
	{OPS_SA_AES_192, "AES (192-bit key)"},
	{OPS_SA_AES_256, "AES (256-bit key)"},
	{OPS_SA_TWOFISH, "Twofish(256-bit key)"},
	{OPS_SA_CAMELLIA_128, "Camellia (128-bit key)"},
	{OPS_SA_CAMELLIA_192, "Camellia (192-bit key)"},
	{OPS_SA_CAMELLIA_256, "Camellia (256-bit key)"},
	{0x00, NULL},		/* this is the end-of-array marker */
};

static __ops_map_t hash_alg_map[] =
{
	{OPS_HASH_MD5, "MD5"},
	{OPS_HASH_SHA1, "SHA1"},
	{OPS_HASH_RIPEMD, "RIPEMD160"},
	{OPS_HASH_SHA256, "SHA256"},
	{OPS_HASH_SHA384, "SHA384"},
	{OPS_HASH_SHA512, "SHA512"},
	{OPS_HASH_SHA224, "SHA224"},
	{0x00, NULL},		/* this is the end-of-array marker */
};

static __ops_map_t compression_alg_map[] =
{
	{OPS_C_NONE, "Uncompressed"},
	{OPS_C_ZIP, "ZIP(RFC1951)"},
	{OPS_C_ZLIB, "ZLIB(RFC1950)"},
	{OPS_C_BZIP2, "Bzip2(BZ2)"},
	{0x00, NULL},		/* this is the end-of-array marker */
};

static __ops_bit_map_t ss_notation_map_byte0[] =
{
	{0x80, "Human-readable"},
	{0x00, NULL},
};

static __ops_bit_map_t *ss_notation_map[] =
{
	ss_notation_map_byte0,
};

static __ops_bit_map_t ss_feature_map_byte0[] =
{
	{0x01, "Modification Detection"},
	{0x00, NULL},
};

static __ops_bit_map_t *ss_feature_map[] =
{
	ss_feature_map_byte0,
};

static __ops_bit_map_t ss_key_flags_map[] =
{
	{0x01, "May be used to certify other keys"},
	{0x02, "May be used to sign data"},
	{0x04, "May be used to encrypt communications"},
	{0x08, "May be used to encrypt storage"},
	{0x10, "Private component may have been split by a secret-sharing mechanism"},
	{0x80, "Private component may be in possession of more than one person"},
	{0x00, NULL},
};

static __ops_bit_map_t ss_key_server_prefs_map[] =
{
	{0x80, "Key holder requests that this key only be modified or updated by the key holder or an administrator of the key server"},
	{0x00, NULL},
};

/*
 * Private functions
 */

static void 
list_init(__ops_list_t *list)
{
	list->size = 0;
	list->used = 0;
	list->strings = NULL;
}

static void 
list_free_strings(__ops_list_t *list)
{
	unsigned        i;

	for (i = 0; i < list->used; i++) {
		free(list->strings[i]);
		list->strings[i] = NULL;
	}
}

static void 
list_free(__ops_list_t *list)
{
	if (list->strings)
		free(list->strings);
	list_init(list);
}

static unsigned 
list_resize(__ops_list_t *list)
{
	/*
	 * We only resize in one direction - upwards. Algorithm used : double
	 * the current size then add 1
	 */
	char	**newstrings;
	int	  newsize;

	newsize = (list->size * 2) + 1;
	newstrings = realloc(list->strings, newsize * sizeof(char *));
	if (newstrings) {
		list->strings = newstrings;
		list->size = newsize;
		return 1;
	}
	(void) fprintf(stderr, "list_resize - bad alloc\n");
	return 0;
}

static unsigned 
add_str(__ops_list_t *list, const char *str)
{
	if (list->size == list->used && !list_resize(list)) {
		return 0;
	}
	list->strings[list->used++] = __UNCONST(str);
	return 1;
}

/* find a bitfield in a map - serial search */
static const char *
find_bitfield(__ops_bit_map_t *map, uint8_t octet)
{
	__ops_bit_map_t  *row;

	for (row = map; row->string != NULL && row->mask != octet ; row++) {
	}
	return (row->string) ? row->string : "Unknown";
}

/* ! generic function to initialise __ops_text_t structure */
void 
__ops_text_init(__ops_text_t *text)
{
	list_init(&text->known);
	list_init(&text->unknown);
}

/**
 * \ingroup Core_Print
 *
 * __ops_text_free() frees the memory used by an __ops_text_t structure
 *
 * \param text Pointer to a previously allocated structure. This structure and its contents will be freed.
 */
void 
__ops_text_free(__ops_text_t *text)
{
	/* Strings in "known" array will be constants, so don't free them */
	list_free(&text->known);

	/*
	 * Strings in "unknown" array will be dynamically allocated, so do
	 * free them
	 */
	list_free_strings(&text->unknown);
	list_free(&text->unknown);

	free(text);
}

/* XXX: should this (and many others) be unsigned? */
/* ! generic function which adds text derived from single octet map to text */
static unsigned
add_str_from_octet_map(__ops_text_t *map, char *str, uint8_t octet)
{
	if (str && !add_str(&map->known, str)) {
		/*
		 * value recognised, but there was a problem adding it to the
		 * list
		 */
		/* XXX - should print out error msg here, Ben? - rachel */
		return 0;
	} else if (!str) {
		/*
		 * value not recognised and there was a problem adding it to
		 * the unknown list
		 */
		unsigned        len = 2 + 2 + 1;	/* 2 for "0x", 2 for
							 * single octet in hex
							 * format, 1 for NUL */
		if ((str = calloc(1, len)) == NULL) {
			(void) fprintf(stderr, "add_str_from_octet_map: bad alloc\n");
			return 0;
		}
		(void) snprintf(str, len, "0x%x", octet);
		if (!add_str(&map->unknown, str)) {
			return 0;
		}
		free(str);
	}
	return 1;
}

/* ! generic function which adds text derived from single bit map to text */
static unsigned 
add_bitmap_entry(__ops_text_t *map, const char *str, uint8_t bit)
{
	const char     *fmt_unknown = "Unknown bit(0x%x)";

	if (str && !add_str(&map->known, str)) {
		/*
		 * value recognised, but there was a problem adding it to the
		 * list
		 */
		/* XXX - should print out error msg here, Ben? - rachel */
		return 0;
	} else if (!str) {
		/*
		 * value not recognised and there was a problem adding it to
		 * the unknown list
		 * 2 chars of the string are the format definition, this will
		 * be replaced in the output by 2 chars of hex, so the length
		 * will be correct
		 */
		unsigned         len = (unsigned)(strlen(fmt_unknown) + 1);
		char		*newstr;

		if ((newstr = calloc(1, len)) == NULL) {
			(void) fprintf(stderr, "add_bitmap_entry: bad alloc\n");
			return 0;
		}
		(void) snprintf(newstr, len, fmt_unknown, bit);
		if (!add_str(&map->unknown, newstr)) {
			return 0;
		}
		free(newstr);
	}
	return 1;
}

/**
 * Produce a structure containing human-readable textstrings
 * representing the recognised and unrecognised contents
 * of this byte array. text_fn() will be called on each octet in turn.
 * Each octet will generate one string representing the whole byte.
 *
 */

static __ops_text_t *
text_from_bytemapped_octets(const __ops_data_t *data,
			    const char *(*text_fn)(uint8_t octet))
{
	__ops_text_t	*text;
	const char	*str;
	unsigned	 i;

	/*
	 * ! allocate and initialise __ops_text_t structure to store derived
	 * strings
	 */
	if ((text = calloc(1, sizeof(*text))) == NULL) {
		return NULL;
	}

	__ops_text_init(text);

	/* ! for each octet in field ... */
	for (i = 0; i < data->len; i++) {
		/* ! derive string from octet */
		str = (*text_fn) (data->contents[i]);

		/* ! and add to text */
		if (!add_str_from_octet_map(text, netpgp_strdup(str),
						data->contents[i])) {
			__ops_text_free(text);
			return NULL;
		}
	}
	/*
	 * ! All values have been added to either the known or the unknown
	 * list
	 */
	return text;
}

/**
 * Produce a structure containing human-readable textstrings
 * representing the recognised and unrecognised contents
 * of this byte array, derived from each bit of each octet.
 *
 */
static __ops_text_t *
showall_octets_bits(__ops_data_t *data, __ops_bit_map_t **map, size_t nmap)
{
	__ops_text_t	*text;
	const char	*str;
	unsigned         i;
	uint8_t		 mask, bit;
	int              j = 0;

	/*
	 * ! allocate and initialise __ops_text_t structure to store derived
	 * strings
	 */
	if ((text = calloc(1, sizeof(__ops_text_t))) == NULL) {
		return NULL;
	}

	__ops_text_init(text);

	/* ! for each octet in field ... */
	for (i = 0; i < data->len; i++) {
		/* ! for each bit in octet ... */
		mask = 0x80;
		for (j = 0; j < 8; j++, mask = (unsigned)mask >> 1) {
			bit = data->contents[i] & mask;
			if (bit) {
				str = (i >= nmap) ? "Unknown" :
					find_bitfield(map[i], bit);
				if (!add_bitmap_entry(text, str, bit)) {
					__ops_text_free(text);
					return NULL;
				}
			}
		}
	}
	return text;
}

/*
 * Public Functions
 */

/**
 * \ingroup Core_Print
 * returns description of the Packet Tag
 * \param packet_tag
 * \return string or "Unknown"
*/
const char     *
__ops_show_packet_tag(__ops_content_enum packet_tag)
{
	const char     *ret;

	ret = __ops_str_from_map(packet_tag, packet_tag_map);
	if (!ret) {
		ret = "Unknown Tag";
	}
	return ret;
}

/**
 * \ingroup Core_Print
 *
 * returns description of the Signature Sub-Packet type
 * \param ss_type Signature Sub-Packet type
 * \return string or "Unknown"
 */
const char     *
__ops_show_ss_type(__ops_content_enum ss_type)
{
	return __ops_str_from_map(ss_type, ss_type_map);
}

/**
 * \ingroup Core_Print
 *
 * returns description of the Revocation Reason code
 * \param ss_rr_code Revocation Reason code
 * \return string or "Unknown"
 */
const char     *
__ops_show_ss_rr_code(__ops_ss_rr_code_t ss_rr_code)
{
	return __ops_str_from_map(ss_rr_code, ss_rr_code_map);
}

/**
 * \ingroup Core_Print
 *
 * returns description of the given Signature type
 * \param sig_type Signature type
 * \return string or "Unknown"
 */
const char     *
__ops_show_sig_type(__ops_sig_type_t sig_type)
{
	return __ops_str_from_map(sig_type, sig_type_map);
}

/**
 * \ingroup Core_Print
 *
 * returns description of the given Public Key Algorithm
 * \param pka Public Key Algorithm type
 * \return string or "Unknown"
 */
const char     *
__ops_show_pka(__ops_pubkey_alg_t pka)
{
	return __ops_str_from_map(pka, pubkey_alg_map);
}

/**
 * \ingroup Core_Print
 * returns description of the Preferred Compression
 * \param octet Preferred Compression
 * \return string or "Unknown"
*/
const char     *
__ops_show_ss_zpref(uint8_t octet)
{
	return __ops_str_from_map(octet, compression_alg_map);
}

/**
 * \ingroup Core_Print
 *
 * returns set of descriptions of the given Preferred Compression Algorithms
 * \param ss_zpref Array of Preferred Compression Algorithms
 * \return NULL if cannot allocate memory or other error
 * \return pointer to structure, if no error
 */
__ops_text_t     *
__ops_showall_ss_zpref(const __ops_data_t *ss_zpref)
{
	return text_from_bytemapped_octets(ss_zpref,
					&__ops_show_ss_zpref);
}


/**
 * \ingroup Core_Print
 *
 * returns description of the Hash Algorithm type
 * \param hash Hash Algorithm type
 * \return string or "Unknown"
 */
const char     *
__ops_show_hash_alg(uint8_t hash)
{
	return __ops_str_from_map(hash, hash_alg_map);
}

/**
 * \ingroup Core_Print
 *
 * returns set of descriptions of the given Preferred Hash Algorithms
 * \param ss_hashpref Array of Preferred Hash Algorithms
 * \return NULL if cannot allocate memory or other error
 * \return pointer to structure, if no error
 */
__ops_text_t     *
__ops_showall_ss_hashpref(const __ops_data_t *ss_hashpref)
{
	return text_from_bytemapped_octets(ss_hashpref,
					   &__ops_show_hash_alg);
}

const char     *
__ops_show_symm_alg(uint8_t hash)
{
	return __ops_str_from_map(hash, symm_alg_map);
}

/**
 * \ingroup Core_Print
 * returns description of the given Preferred Symmetric Key Algorithm
 * \param octet
 * \return string or "Unknown"
*/
const char     *
__ops_show_ss_skapref(uint8_t octet)
{
	return __ops_str_from_map(octet, symm_alg_map);
}

/**
 * \ingroup Core_Print
 *
 * returns set of descriptions of the given Preferred Symmetric Key Algorithms
 * \param ss_skapref Array of Preferred Symmetric Key Algorithms
 * \return NULL if cannot allocate memory or other error
 * \return pointer to structure, if no error
 */
__ops_text_t     *
__ops_showall_ss_skapref(const __ops_data_t *ss_skapref)
{
	return text_from_bytemapped_octets(ss_skapref,
					   &__ops_show_ss_skapref);
}

/**
 * \ingroup Core_Print
 * returns description of one SS Feature
 * \param octet
 * \return string or "Unknown"
*/
static const char *
__ops_show_ss_feature(uint8_t octet, unsigned offset)
{
	if (offset >= OPS_ARRAY_SIZE(ss_feature_map)) {
		return "Unknown";
	}
	return find_bitfield(ss_feature_map[offset], octet);
}

/**
 * \ingroup Core_Print
 *
 * returns set of descriptions of the given SS Features
 * \param ss_features Signature Sub-Packet Features
 * \return NULL if cannot allocate memory or other error
 * \return pointer to structure, if no error
 */
/* XXX: shouldn't this use show_all_octets_bits? */
__ops_text_t     *
__ops_showall_ss_features(__ops_data_t ss_features)
{
	__ops_text_t	*text;
	const char	*str;
	unsigned	 i;
	uint8_t		 mask, bit;
	int		 j;

	if ((text = calloc(1, sizeof(*text))) == NULL) {
		return NULL;
	}

	__ops_text_init(text);

	for (i = 0; i < ss_features.len; i++) {
		mask = 0x80;
		for (j = 0; j < 8; j++, mask = (unsigned)mask >> 1) {
			bit = ss_features.contents[i] & mask;
			if (bit) {
				str = __ops_show_ss_feature(bit, i);
				if (!add_bitmap_entry(text, str, bit)) {
					__ops_text_free(text);
					return NULL;
				}
			}
		}
	}
	return text;
}

/**
 * \ingroup Core_Print
 * returns description of SS Key Flag
 * \param octet
 * \param map
 * \return
*/
const char     *
__ops_show_ss_key_flag(uint8_t octet, __ops_bit_map_t *map)
{
	return find_bitfield(map, octet);
}

/**
 * \ingroup Core_Print
 *
 * returns set of descriptions of the given Preferred Key Flags
 * \param ss_key_flags Array of Key Flags
 * \return NULL if cannot allocate memory or other error
 * \return pointer to structure, if no error
 */
__ops_text_t     *
__ops_showall_ss_key_flags(const __ops_data_t *ss_key_flags)
{
	__ops_text_t	*text;
	const char	*str;
	uint8_t		 mask, bit;
	int              i;

	if ((text = calloc(1, sizeof(*text))) == NULL) {
		return NULL;
	}

	__ops_text_init(text);

	/* xxx - TBD: extend to handle multiple octets of bits - rachel */
	for (i = 0, mask = 0x80; i < 8; i++, mask = (unsigned)mask >> 1) {
		bit = ss_key_flags->contents[0] & mask;
		if (bit) {
			str = __ops_show_ss_key_flag(bit, ss_key_flags_map);
			if (!add_bitmap_entry(text, netpgp_strdup(str), bit)) {
				__ops_text_free(text);
				return NULL;
			}
		}
	}
	/*
	 * xxx - must add error text if more than one octet. Only one
	 * currently specified -- rachel
	 */
	return text;
}

/**
 * \ingroup Core_Print
 *
 * returns description of one given Key Server Preference
 *
 * \param prefs Byte containing bitfield of preferences
 * \param map
 * \return string or "Unknown"
 */
const char     *
__ops_show_keyserv_pref(uint8_t prefs, __ops_bit_map_t *map)
{
	return find_bitfield(map, prefs);
}

/**
 * \ingroup Core_Print
 * returns set of descriptions of given Key Server Preferences
 * \param ss_key_server_prefs
 * \return NULL if cannot allocate memory or other error
 * \return pointer to structure, if no error
 *
*/
__ops_text_t     *
__ops_show_keyserv_prefs(const __ops_data_t *prefs)
{
	__ops_text_t	*text;
	const char	*str;
	uint8_t		 mask, bit;
	int              i = 0;

	if ((text = calloc(1, sizeof(*text))) == NULL) {
		return NULL;
	}

	__ops_text_init(text);

	/* xxx - TBD: extend to handle multiple octets of bits - rachel */

	for (i = 0, mask = 0x80; i < 8; i++, mask = (unsigned)mask >> 1) {
		bit = prefs->contents[0] & mask;
		if (bit) {
			str = __ops_show_keyserv_pref(bit,
						ss_key_server_prefs_map);
			if (!add_bitmap_entry(text, netpgp_strdup(str), bit)) {
				__ops_text_free(text);
				return NULL;
			}
		}
	}
	/*
	 * xxx - must add error text if more than one octet. Only one
	 * currently specified -- rachel
	 */
	return text;
}

/**
 * \ingroup Core_Print
 *
 * returns set of descriptions of the given SS Notation Data Flags
 * \param ss_notation Signature Sub-Packet Notation Data
 * \return NULL if cannot allocate memory or other error
 * \return pointer to structure, if no error
 */
__ops_text_t     *
__ops_showall_notation(__ops_ss_notation_t ss_notation)
{
	return showall_octets_bits(&ss_notation.flags,
				ss_notation_map,
				OPS_ARRAY_SIZE(ss_notation_map));
}
