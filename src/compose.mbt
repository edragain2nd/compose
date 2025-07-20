///|
/// Composes two Unicode characters into a single precomposed character if possible.
/// Examples:
///
/// ```moonbit
/// // Latin character with combining accent
/// inspect(@edragain2nd/compose.compose('a', '\u{0301}'), content="Some('á')")
///
/// // Hangul composition
/// inspect(@edragain2nd/compose.compose('ᄀ', 'ᅡ'), content="Some('가')")
///
/// // No valid composition
/// inspect(@edragain2nd/compose.compose('a', 'b'), content="None")
/// ```
///
pub fn compose(a : Char, b : Char) -> Char? {
  match compose_hangul(a, b) {
    Some(c) => Some(c)
    None =>
      match composition_table(a, b) {
        Some(c) => Some(c)
        None => None
      }
  }
}

///|
const S_BASE : UInt = 0xAC00

///|
const L_BASE : UInt = 0x1100

///|
const V_BASE : UInt = 0x1161

///|
const T_BASE : UInt = 0x11A7

///|
const L_COUNT : UInt = 19

///|
const V_COUNT : UInt = 21

///|
const T_COUNT : UInt = 28

///|
const N_COUNT : UInt = V_COUNT * T_COUNT

///|
const S_COUNT : UInt = L_COUNT * N_COUNT

///|
const S_LAST : UInt = S_BASE + S_COUNT - 1

///|
const L_LAST : UInt = L_BASE + L_COUNT - 1

///|
const V_LAST : UInt = V_BASE + V_COUNT - 1

///|
const T_LAST : UInt = T_BASE + T_COUNT - 1

///|
const T_FIRST : UInt = T_BASE + 1

///|
/// based on rust's char::compose hangul
fn compose_hangul(c1 : Char, c2 : Char) -> Char? {
  let (a, b) = (c1.to_uint(), c2.to_uint())
  match (a, b) {
    (L_BASE..=L_LAST, V_BASE..=V_LAST) => {
      let l_index = a - L_BASE
      let v_index = b - V_BASE
      let lv_index = l_index * N_COUNT + v_index * T_COUNT
      let s = S_BASE + lv_index
      Some(Int::unsafe_to_char(s.reinterpret_as_int()))
    }
    (S_BASE..=S_LAST, T_FIRST..=T_LAST) if (a - S_BASE) % T_COUNT == 0 =>
      Some(Int::unsafe_to_char((a + (b - T_BASE)).reinterpret_as_int()))
    _ => None
  }
}

///|
fn composition_table(c1 : Char, c2 : Char) -> Char? {
  if c1 < '\u{10000}' && c2 < '\u{10000}' {
    mph_lookup(
      (c1.to_uint() << 16) | c2.to_uint(),
      composition_table_salt,
      composition_table_kv,
      pair_lookup_fk,
      pair_lookup_fv_opt,
      None,
    )
  } else {
    composition_table_astral(c1, c2)
  }
}

///|
fn[KV, V] mph_lookup(
  x : UInt,
  salt : ArrayView[UInt16],
  kv : ArrayView[KV],
  fk : (KV) -> UInt,
  fv : (KV) -> V,
  default : V
) -> V {
  let s = salt[my_hash(x, 0, salt.length().reinterpret_as_uint()).reinterpret_as_int()].to_uint()
  let key_val = kv[my_hash(x, s, salt.length().reinterpret_as_uint()).reinterpret_as_int()]
  if x == fk(key_val) {
    fv(key_val)
  } else {
    default
  }
}

///|
fn my_hash(key : UInt, salt : UInt, n : UInt) -> UInt {
  let y : UInt = (key + salt) * 2654435769
  let y : UInt = y ^ (key * 0x31415926)
  let y = ((y.to_uint64() * n.to_uint64()) >> 32).to_uint()
  y
}

///|
fn[T] pair_lookup_fk(kv : (UInt, T)) -> UInt {
  kv.0
}

///|
fn[T] pair_lookup_fv_opt(kv : (UInt, T)) -> T? {
  Some(kv.1)
}

///|
test "test_hangul_composition" {
  assert_eq(compose_hangul('\u{c8e0}', '\u{11a7}'), None)
  assert_eq(compose_hangul('ᄀ', 'ᅡ'), Some('가'))
  assert_eq(compose_hangul('ᄂ', 'ᅵ'), Some('니'))
  assert_eq(compose_hangul('가', 'ᆨ'), Some('각'))
  assert_eq(compose_hangul('하', 'ᆫ'), Some('한'))
  assert_eq(compose_hangul('ᄒ', 'ᅡ'), Some('하'))
  assert_eq(compose_hangul('ᄀ', 'ᅳ'), Some('그'))
  assert_eq(compose_hangul('히', 'ᆼ'), Some('힝'))
  assert_eq(compose_hangul('가', 'ᆨ'), Some('각'))
  assert_eq(compose_hangul('A', 'ᅡ'), None)
  assert_eq(compose_hangul('ᄀ', 'a'), None)
  assert_eq(compose_hangul('가', 'A'), None)
  assert_eq(compose_hangul('A', 'ᆨ'), None)
  assert_eq(compose_hangul('갃', 'ᆨ'), None)
  assert_eq(compose_hangul('\u{D7A3}', '\u{11A8}'), None)
}

///|
test "test_composition" {
  assert_eq(compose('a', '\u{0301}'), Some('á'))
  assert_eq(compose('e', '\u{0300}'), Some('è'))
  assert_eq(compose('o', '\u{0308}'), Some('ö'))
  assert_eq(compose('c', '\u{0327}'), Some('ç'))
  assert_eq(compose('a', 'b'), None)
  assert_eq(compose('x', '\u{0301}'), None)
  assert_eq(compose('\u{1100}', 'x'), None)
  assert_eq(compose('\u{FFFF}', '\u{FFFF}'), None)
  assert_eq(compose('\u{0000}', '\u{0000}'), None)
  assert_eq(compose('á', '\u{0300}'), None)
  assert_eq(compose('가', '\u{11A8}'), Some('각'))
}
