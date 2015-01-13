/*-
 * Copyright (c) 2010 Alistair Crooks <agc@NetBSD.org>
 * All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#ifndef MJ_H_
#define MJ_H_	20100718

enum {
	MJ_NULL		= 1,
	MJ_FALSE	= 2,
	MJ_TRUE		= 3,
	MJ_NUMBER	= 4,
	MJ_STRING	= 5,
	MJ_ARRAY	= 6,
	MJ_OBJECT	= 7
};

/* a minimalist JSON node */
typedef struct mj_t {
	unsigned	type;		/* type of JSON node */
	unsigned	c;		/* # of chars */
	unsigned	size;		/* size of array */
	union {
		struct mj_t	*v;	/* sub-objects */
		char		*s;	/* string value */
	} value;
} mj_t;

/* creation and deletion */
int mj_create(mj_t *, const char *, ...);
int mj_parse(mj_t *, const char *, int *, int *, int *);
int mj_append(mj_t *, const char *, ...);
int mj_append_field(mj_t *, const char *, const char *, ...);
int mj_deepcopy(mj_t *, mj_t *);
void mj_delete(mj_t *);

/* JSON object access */
int mj_arraycount(mj_t *);
int mj_object_find(mj_t *, const char *, const unsigned, const unsigned);
mj_t *mj_get_atom(mj_t *, ...);
int mj_lint(mj_t *);

/* textual output */
int mj_snprint(char *, size_t, mj_t *);
int mj_asprint(char **, mj_t *);
int mj_string_size(mj_t *);
int mj_pretty(mj_t *, void *, unsigned, const char *);

#endif
