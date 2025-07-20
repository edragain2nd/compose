# compose
Composes two Unicode characters into a single precomposed character if possible.
rewrite rust's `char::compose()`
```
compose('a', '\u{0301}') =>  Some('á')

compose('e', '\u{0300}') =>  Some('è')

compose('가', 'ᆨ')       => Some('각')
```
