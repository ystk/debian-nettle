C nettle, low-level cryptographics library
C 
C Copyright (C) 2013 Niels Möller
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

	.file "umac-nh.asm"
	.fpu	neon

define(<KEY>, <r0>)
define(<LENGTH>, <r1>)
define(<MSG>, <r2>)
define(<SHIFT>, <r3>)

define(<QA>, <q0>)
define(<QB>, <q1>)
define(<DM>, <d16>)
define(<QLEFT>, <q9>)
define(<QRIGHT>, <q10>)
define(<QY>, <q11>)
define(<QT0>, <q12>)
define(<QT1>, <q13>)
define(<QK0>, <q14>)
define(<QK1>, <q15>)

	.text
	.align	3
	
PROLOGUE(_nettle_umac_nh)
	C Setup for 64-bit aligned reads
	ands	SHIFT, MSG, #7
	and	MSG, MSG, #-8
	vld1.8	{DM}, [MSG :64]
	addne	MSG, MSG, #8
	addeq	SHIFT, SHIFT, #8

	C FIXME: Combine as rsb ?
	lsl	SHIFT, SHIFT, #3
	neg	SHIFT, SHIFT

	C Right shift in QRIGHT (both halves)
	vmov.i32 D0REG(QRIGHT)[0], SHIFT
	vmov.32	 D1REG(QRIGHT), D0REG(QRIGHT)
	add	SHIFT, SHIFT, #64
	
	vmov.i32 D0REG(QLEFT)[0], SHIFT
	vmov.32	 D1REG(QLEFT), D0REG(QLEFT)

	vmov.i64 QY, #0

	vshl.u64 DM, DM, D0REG(QRIGHT)
.Loop:
	C Set m[i] <-- m[i-1] >> RSHIFT + m[i] << LSHIFT
	vld1.8 {QA, QB}, [MSG :64]!
	vshl.u64 QT0, QA, QRIGHT
	vshl.u64 QT1, QB, QRIGHT
	vshl.u64 QA, QA, QLEFT
	vshl.u64 QB, QB, QLEFT
	veor	D0REG(QA), D0REG(QA), DM
	veor	D1REG(QA), D1REG(QA), D0REG(QT0)
	veor	D0REG(QB), D0REG(QB), D1REG(QT0)
	veor	D1REG(QB), D1REG(QB), D0REG(QT1)
	vmov	DM, D1REG(QT1)

	vld1.i32 {QK0, QK1}, [KEY]!
	vadd.i32 QA, QA, QK0
	vadd.i32 QB, QB, QK1
	subs	LENGTH, LENGTH, #32
	vmlal.u32 QY, D0REG(QA), D0REG(QB)
	vmlal.u32 QY, D1REG(QA), D1REG(QB)
	bhi	.Loop

	vadd.i64 D0REG(QY), D0REG(QY), D1REG(QY)
	vmov	r0, r1, D0REG(QY)
	bx	lr
EPILOGUE(_nettle_umac_nh)
