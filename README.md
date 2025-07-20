# compose
Composes two Unicode characters into a single precomposed character if possible.
```
compose('a', '\u{0301}') =>  Some('á')

compose('e', '\u{0300}') =>  Some('è')

compose('가', 'ᆨ')       => Some('각')
```