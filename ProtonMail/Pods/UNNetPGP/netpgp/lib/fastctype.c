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
#include <stdint.h>

#include "fastctype.h"

#define UPPER		0x01
#define LOWER		0x02
#define OCTAL		0x04
#define DEC		0x08
#define HEX		0x10
#define SPACE		0x20
#define PUNCT		0x40

static const uint8_t fastctypes[] = {
	0,		/* 0 */
	0,		/* 1 */
	0,		/* 2 */
	0,		/* 3 */
	0,		/* 4 */
	0,		/* 5 */
	0,		/* 6 */
	0,		/* 7 */
	0,		/* 8 */
	SPACE,		/* 9 */
	SPACE,		/* 10 */
	0,		/* 11 */
	0,		/* 12 */
	SPACE,		/* 13 */
	0,		/* 14 */
	0,		/* 15 */
	0,		/* 16 */
	0,		/* 17 */
	0,		/* 18 */
	0,		/* 19 */
	0,		/* 20 */
	0,		/* 21 */
	0,		/* 22 */
	0,		/* 23 */
	0,		/* 24 */
	0,		/* 25 */
	0,		/* 26 */
	0,		/* 27 */
	0,		/* 28 */
	0,		/* 29 */
	0,		/* 30 */
	0,		/* 31 */
	SPACE,		/* 32 */
	PUNCT,		/* 33 */
	PUNCT,		/* 34 */
	PUNCT,		/* 35 */
	PUNCT,		/* 36 */
	PUNCT,		/* 37 */
	PUNCT,		/* 38 */
	PUNCT,		/* 39 */
	PUNCT,		/* 40 */
	PUNCT,		/* 41 */
	PUNCT,		/* 42 */
	PUNCT,		/* 43 */
	PUNCT,		/* 44 */
	PUNCT,		/* 45 */
	PUNCT,		/* 46 */
	PUNCT,		/* 47 */
	OCTAL | DEC | HEX,		/* 48 */
	OCTAL | DEC | HEX,		/* 49 */
	OCTAL | DEC | HEX,		/* 50 */
	OCTAL | DEC | HEX,		/* 51 */
	OCTAL | DEC | HEX,		/* 52 */
	OCTAL | DEC | HEX,		/* 53 */
	OCTAL | DEC | HEX,		/* 54 */
	OCTAL | DEC | HEX,		/* 55 */
	DEC | HEX,		/* 56 */
	DEC | HEX,		/* 57 */
	PUNCT,		/* 58 */
	PUNCT,		/* 59 */
	PUNCT,		/* 60 */
	PUNCT,		/* 61 */
	PUNCT,		/* 62 */
	PUNCT,		/* 63 */
	PUNCT,		/* 64 */
	HEX | UPPER,		/* 65 */
	HEX | UPPER,		/* 66 */
	HEX | UPPER,		/* 67 */
	HEX | UPPER,		/* 68 */
	HEX | UPPER,		/* 69 */
	HEX | UPPER,		/* 70 */
	UPPER,		/* 71 */
	UPPER,		/* 72 */
	UPPER,		/* 73 */
	UPPER,		/* 74 */
	UPPER,		/* 75 */
	UPPER,		/* 76 */
	UPPER,		/* 77 */
	UPPER,		/* 78 */
	UPPER,		/* 79 */
	UPPER,		/* 80 */
	UPPER,		/* 81 */
	UPPER,		/* 82 */
	UPPER,		/* 83 */
	UPPER,		/* 84 */
	UPPER,		/* 85 */
	UPPER,		/* 86 */
	UPPER,		/* 87 */
	UPPER,		/* 88 */
	UPPER,		/* 89 */
	UPPER,		/* 90 */
	PUNCT,		/* 91 */
	PUNCT,		/* 92 */
	PUNCT,		/* 93 */
	PUNCT,		/* 94 */
	PUNCT,		/* 95 */
	PUNCT,		/* 96 */
	HEX | LOWER,		/* 97 */
	HEX | LOWER,		/* 98 */
	HEX | LOWER,		/* 99 */
	HEX | LOWER,		/* 100 */
	HEX | LOWER,		/* 101 */
	HEX | LOWER,		/* 102 */
	LOWER,		/* 103 */
	LOWER,		/* 104 */
	LOWER,		/* 105 */
	LOWER,		/* 106 */
	LOWER,		/* 107 */
	LOWER,		/* 108 */
	LOWER,		/* 109 */
	LOWER,		/* 110 */
	LOWER,		/* 111 */
	LOWER,		/* 112 */
	LOWER,		/* 113 */
	LOWER,		/* 114 */
	LOWER,		/* 115 */
	LOWER,		/* 116 */
	LOWER,		/* 117 */
	LOWER,		/* 118 */
	LOWER,		/* 119 */
	LOWER,		/* 120 */
	LOWER,		/* 121 */
	LOWER,		/* 122 */
	PUNCT,		/* 123 */
	PUNCT,		/* 124 */
	PUNCT,		/* 125 */
	PUNCT,		/* 126 */
	PUNCT,		/* 127 */
	0,		/* 128 */
	0,		/* 129 */
	0,		/* 130 */
	0,		/* 131 */
	0,		/* 132 */
	0,		/* 133 */
	0,		/* 134 */
	0,		/* 135 */
	0,		/* 136 */
	0,		/* 137 */
	0,		/* 138 */
	0,		/* 139 */
	0,		/* 140 */
	0,		/* 141 */
	0,		/* 142 */
	0,		/* 143 */
	0,		/* 144 */
	0,		/* 145 */
	0,		/* 146 */
	0,		/* 147 */
	0,		/* 148 */
	0,		/* 149 */
	0,		/* 150 */
	0,		/* 151 */
	0,		/* 152 */
	0,		/* 153 */
	0,		/* 154 */
	0,		/* 155 */
	0,		/* 156 */
	0,		/* 157 */
	0,		/* 158 */
	0,		/* 159 */
	0,		/* 160 */
	0,		/* 161 */
	0,		/* 162 */
	0,		/* 163 */
	0,		/* 164 */
	0,		/* 165 */
	0,		/* 166 */
	0,		/* 167 */
	0,		/* 168 */
	0,		/* 169 */
	0,		/* 170 */
	0,		/* 171 */
	0,		/* 172 */
	0,		/* 173 */
	0,		/* 174 */
	0,		/* 175 */
	0,		/* 176 */
	0,		/* 177 */
	0,		/* 178 */
	0,		/* 179 */
	0,		/* 180 */
	0,		/* 181 */
	0,		/* 182 */
	0,		/* 183 */
	0,		/* 184 */
	0,		/* 185 */
	0,		/* 186 */
	0,		/* 187 */
	0,		/* 188 */
	0,		/* 189 */
	0,		/* 190 */
	0,		/* 191 */
	0,		/* 192 */
	0,		/* 193 */
	0,		/* 194 */
	0,		/* 195 */
	0,		/* 196 */
	0,		/* 197 */
	0,		/* 198 */
	0,		/* 199 */
	0,		/* 200 */
	0,		/* 201 */
	0,		/* 202 */
	0,		/* 203 */
	0,		/* 204 */
	0,		/* 205 */
	0,		/* 206 */
	0,		/* 207 */
	0,		/* 208 */
	0,		/* 209 */
	0,		/* 210 */
	0,		/* 211 */
	0,		/* 212 */
	0,		/* 213 */
	0,		/* 214 */
	0,		/* 215 */
	0,		/* 216 */
	0,		/* 217 */
	0,		/* 218 */
	0,		/* 219 */
	0,		/* 220 */
	0,		/* 221 */
	0,		/* 222 */
	0,		/* 223 */
	0,		/* 224 */
	0,		/* 225 */
	0,		/* 226 */
	0,		/* 227 */
	0,		/* 228 */
	0,		/* 229 */
	0,		/* 230 */
	0,		/* 231 */
	0,		/* 232 */
	0,		/* 233 */
	0,		/* 234 */
	0,		/* 235 */
	0,		/* 236 */
	0,		/* 237 */
	0,		/* 238 */
	0,		/* 239 */
	0,		/* 240 */
	0,		/* 241 */
	0,		/* 242 */
	0,		/* 243 */
	0,		/* 244 */
	0,		/* 245 */
	0,		/* 246 */
	0,		/* 247 */
	0,		/* 248 */
	0,		/* 249 */
	0,		/* 250 */
	0,		/* 251 */
	0,		/* 252 */
	0,		/* 253 */
	0,		/* 254 */
	0		/* 255 */
};

int
fast_isalnum(uint8_t c)
{
	return fastctypes[c] & (UPPER | LOWER | OCTAL | DEC | HEX);
}

int
fast_isalpha(uint8_t c)
{
	return fastctypes[c] & (UPPER | LOWER);
}

int
fast_isascii(uint8_t c)
{
	return (c > 0 && c <= 127);
}

int
fast_iscntrl(uint8_t c)
{
	return (c > 0 && c < 32) || c == 127;
}

int
fast_isprint(uint8_t c)
{
	return (c >= 32 && c < 127);
}

int
fast_isdigit(uint8_t c)
{
	return fastctypes[c] & DEC;
}

int
fast_islower(uint8_t c)
{
	return fastctypes[c] & LOWER;
}

int
fast_isupper(uint8_t c)
{
	return fastctypes[c] & UPPER;
}

int
fast_isspace(uint8_t c)
{
	return fastctypes[c] & SPACE;
}

int
fast_tolower(uint8_t c)
{
	return (fastctypes[c] & UPPER) ? 'a' + (c - 'A') : c;
}

int
fast_toupper(uint8_t c)
{
	return (fastctypes[c] & LOWER) ? 'A' + (c - 'a') : c;
}

int
fast_isxdigit(uint8_t c)
{
	return fastctypes[c] & HEX;
}
