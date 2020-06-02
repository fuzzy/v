// Copyright (c) 2019-2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module rand

// Ported from http://www.pcg-random.org/download.html,
// https://github.com/imneme/pcg-c-basic/blob/master/pcg_basic.c, and
// https://github.com/imneme/pcg-c-basic/blob/master/pcg_basic.h
pub struct PCG32RNG {
mut:
	state u64 = u64(0x853c49e6748fea9b) ^ time_seed_64()
	inc   u64 = u64(0xda3e39cb94b95bdb) ^ time_seed_64()
}

// TODO: Remove in Phase 2 of reorganizing Random
pub fn new_pcg32(init_state, init_seq u64) PCG32RNG {
	mut rng := PCG32RNG{}
	rng.seed([u32(init_state), u32(init_state >> 32), u32(init_seq), u32(init_seq >> 32)])
	return rng
}

pub fn (mut rng PCG32RNG) bounded_next(bound u32) u32 {
	return rng.u32n(bound)
}

// rng.seed(seed_data) - seed the PCG32RNG with 4 u32 values.
// The first 2 represent the 64-bit initial state as [lower 32 bits, higher 32 bits]
// The last 2 represent the 64-bit stream/step of the PRNG.
pub fn (mut rng PCG32RNG) seed(seed_data []u32) {
	if seed_data.len != 4 {
		eprintln('PCG32RNG needs 4 u32s to be seeded. First two the initial state and the last two the stream/step. Both in little endian format: [lower, higher]')
		exit(1)
	}
	init_state := u64(seed_data[0]) | (u64(seed_data[1]) << 32)
	init_seq := u64(seed_data[2]) | (u64(seed_data[3]) << 32)
	rng.state = u64(0)
	rng.inc = (init_seq << u64(1)) | u64(1)
	rng.u32()
	rng.state += init_state
	rng.u32()
}

// rng.u32() - return a pseudorandom 32 bit unsigned u32
[inline]
pub fn (mut rng PCG32RNG) u32() u32 {
	oldstate := rng.state
	rng.state = oldstate * (6364136223846793005) + rng.inc
	xorshifted := u32(((oldstate >> u64(18)) ^ oldstate) >> u64(27))
	rot := u32(oldstate >> u64(59))
	return ((xorshifted >> rot) | (xorshifted << ((-rot) & u32(31))))
}

// rng.u64() - return a pseudorandom 64 bit unsigned u64
[inline]
pub fn (mut rng PCG32RNG) u64() u64 {
	return u64(rng.u32()) | (u64(rng.u32()) << 32)
}

// rn.u32n(max) - return a pseudorandom 32 bit unsigned u32 in [0, max)
[inline]
pub fn (mut rng PCG32RNG) u32n(max u32) u32 {
	if max == 0 {
		eprintln('max must be positive')
		exit(1)
	}
	// To avoid bias, we need to make the range of the RNG a multiple of
	// max, which we do by dropping output less than a threshold.
	threshold := (-max % max)
	// Uniformity guarantees that loop below will terminate. In practice, it
	// should usually terminate quickly; on average (assuming all max's are
	// equally likely), 82.25% of the time, we can expect it to require just
	// one iteration. In practice, max's are typically small and only a
	// tiny amount of the range is eliminated.
	for {
		r := rng.u32()
		if r >= threshold {
			return (r % max)
		}
	}
	return u32(0)
}

// rn.u64n(max) - return a pseudorandom 64 bit unsigned u64 in [0, max)
[inline]
pub fn (mut rng PCG32RNG) u64n(max u64) u64 {
	if max == 0 {
		eprintln('max must be positive')
		exit(1)
	}
	threshold := (-max % max)
	for {
		r := rng.u64()
		if r >= threshold {
			return (r % max)
		}
	}
	return u64(0)
}

// rn.u32_in_range(min, max) - return a pseudorandom 32 bit unsigned u32 in [min, max)
[inline]
pub fn (mut rng PCG32RNG) u32_in_range(min, max u64) u64 {
	if max <= min {
		eprintln('max must be greater than min')
		exit(1)
	}
	return min + rng.u32n(u32(max - min))
}

// rn.u64_in_range(min, max) - return a pseudorandom 64 bit unsigned u64 in [min, max)
[inline]
pub fn (mut rng PCG32RNG) u64_in_range(min, max u64) u64 {
	if max <= min {
		eprintln('max must be greater than min')
		exit(1)
	}
	return min + rng.u64n(max - min)
}

// rng.int() - return a 32-bit signed (possibly negative) int
[inline]
pub fn (mut rng PCG32RNG) int() int {
	return int(rng.u32())
}

// rng.i64() - return a 64-bit signed (possibly negative) i64
[inline]
pub fn (mut rng PCG32RNG) i64() i64 {
	return i64(rng.u64())
}

// rng.int31() - return a 31bit positive pseudorandom integer
[inline]
pub fn (mut rng PCG32RNG) int31() int {
	return int(rng.u32() >> 1)
}

// rng.int63() - return a 63bit positive pseudorandom integer
[inline]
pub fn (mut rng PCG32RNG) int63() i64 {
	return i64(rng.u64() >> 1)
}

// rng.intn(max) - return a 32bit positive int in [0, max)
[inline]
pub fn (mut rng PCG32RNG) intn(max int) int {
	if max <= 0 {
		eprintln('max has to be positive.')
		exit(1)
	}
	return int(rng.u32n(u32(max)))
}

// rng.i64n(max) - return a 64bit positive i64 in [0, max)
[inline]
pub fn (mut rng PCG32RNG) i64n(max i64) i64 {
	if max <= 0 {
		eprintln('max has to be positive.')
		exit(1)
	}
	return i64(rng.u64n(u64(max)))
}

// rng.int_in_range(min, max) - return a 32bit positive int in [0, max)
[inline]
pub fn (mut rng PCG32RNG) int_in_range(min, max int) int {
	if max <= min {
		eprintln('max must be greater than min.')
		exit(1)
	}
	return min + rng.intn(max - min)
}

// rng.i64_in_range(min, max) - return a 64bit positive i64 in [0, max)
[inline]
pub fn (mut rng PCG32RNG) i64_in_range(min, max i64) i64 {
	if max <= min {
		eprintln('max must be greater than min.')
		exit(1)
	}
	return min + rng.i64n(max - min)
}

// rng.f32() returns a pseudorandom f32 value between 0.0 (inclusive) and 1.0 (exclusive) i.e [0, 1)
[inline]
pub fn (mut rng PCG32RNG) f32() f32 {
	return f32(rng.u32()) / max_u32_as_f32
}

// rng.f64() returns a pseudorandom f64 value between 0.0 (inclusive) and 1.0 (exclusive) i.e [0, 1)
[inline]
pub fn (mut rng PCG32RNG) f64() f64 {
	return f64(rng.u64()) / max_u64_as_f64
}

// rng.f32n() returns a pseudorandom f32 value in [0, max)
[inline]
pub fn (mut rng PCG32RNG) f32n(max f32) f32 {
	if max <= 0 {
		eprintln('max has to be positive.')
		exit(1)
	}
	return rng.f32() * max
}

// rng.f64n() returns a pseudorandom f64 value in [0, max)
[inline]
pub fn (mut rng PCG32RNG) f64n(max f64) f64 {
	if max <= 0 {
		eprintln('max has to be positive.')
		exit(1)
	}
	return rng.f64() * max
}

// rng.f32_in_range(min, max) returns a pseudorandom f32 that lies in [min, max)
[inline]
pub fn (mut rng PCG32RNG) f32_in_range(min, max f32) f32 {
	if max <= min {
		eprintln('max must be greater than min')
		exit(1)
	}
	return min + rng.f32n(max - min)
}

// rng.i64_in_range(min, max) returns a pseudorandom i64 that lies in [min, max)
[inline]
pub fn (mut rng PCG32RNG) f64_in_range(min, max f64) f64 {
	if max <= min {
		eprintln('max must be greater than min')
		exit(1)
	}
	return min + rng.f64n(max - min)
}
