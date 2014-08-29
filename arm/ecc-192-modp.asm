C nettle, low-level cryptographics library
C
C Copyright (C) 2013, Niels Möller
C
C The nettle library is free software; you can redistribute it and/or modify
C it under the terms of the GNU Lesser General Public License as published by
C the Free Software Foundation; either version 2.1 of the License, or (at your
C option) any later version.
C
C The nettle library is distributed in the hope that it will be useful, but
C WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
C or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
C License for more details.
C
C You should have received a copy of the GNU Lesser General Public License
C along with the nettle library; see the file COPYING.LIB.  If not, write to
C the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
C MA 02111-1301, USA.

	.file "ecc-192-modp.asm"
	.arm

define(<HP>, <r0>) C Overlaps unused ecc argument
define(<RP>, <r1>)

define(<T0>, <r2>)
define(<T1>, <r3>)
define(<T2>, <r4>)
define(<T3>, <r5>)
define(<T4>, <r6>)
define(<T5>, <r7>)
define(<T6>, <r8>)
define(<T7>, <r10>)
define(<H0>, <T0>) C Overlaps T0 and T1
define(<H1>, <T1>)
define(<C2>, <HP>)
define(<C4>, <r12>)

	C ecc_192_modp (const struct ecc_curve *ecc, mp_limb_t *rp)
	.text
	.align 2

PROLOGUE(nettle_ecc_192_modp)
	push	{r4,r5,r6,r7,r8,r10}
	C Reduce two words at a time
	add	HP, RP, #48
	add	RP, RP, #8
	ldmdb	HP!, {H0,H1}
	ldm	RP, {T2,T3,T4,T5,T6,T7}
	mov	C4, #0
	adds	T4, T4, H0
	adcs	T5, T5, H1
	adcs	T6, T6, H0
	adcs	T7, T7, H1
	C Need to add carry to T2 and T4, do T4 later.
	adc	C4, C4, #0

	ldmdb	HP!, {H0,H1}
	mov	C2, #0
	adcs	T2, T2, H0
	adcs	T3, T3, H1
	adcs	T4, T4, H0
	adcs	T5, T5, H1
	C Need to add carry to T0 and T2, do T2 later
	adc	C2, C2, #0

	ldmdb	RP!, {T0, T1}
	adcs	T0, T0, T6
	adcs	T1, T1, T7
	adcs	T2, T2, T6
	adcs	T3, T3, T7
	adc	C4, C4, #0

	adds	T2, T2, C2
	adcs	T3, T3, #0
	adcs	T4, T4, C4
	adcs	T5, T5, #0
	mov	C2, #0
	adc	C2, C2, #0

	C Add in final carry
	adcs	T0, T0, #0
	adcs	T1, T1, #0
	adcs	T2, T2, C2
	adcs	T3, T3, #0
	adcs	T4, T4, #0
	adc	T5, T5, #0

	stm	RP, {T0,T1,T2,T3,T4,T5}

	pop	{r4,r5,r6,r7,r8,r10}
	bx	lr
EPILOGUE(nettle_ecc_192_modp)
