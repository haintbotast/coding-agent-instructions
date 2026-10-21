#!/usr/bin/env python3
"""Check WCAG 2.x contrast ratios for color pairs. Standard library only.

Usage:
  python3 contrast_check.py "#0B2C51:#FFFFFF" "#64748B:#FFFFFF:3" ...
    each argument is  foreground:background[:threshold]  (threshold defaults to 4.5;
    use 3 for large text and non-text components: input borders, focus rings, icons)
  python3 contrast_check.py --file pairs.txt  # one pair per line, '#' starts a comment (alias: --tep)

Exit 0 if every pair passes, 1 if any pair fails, 2 if the input is invalid.
"""
import re
import sys


def _channel(c):
    c = c / 255
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4


def luminance(hex_):
    h = hex_.lstrip('#')
    if len(h) == 3:
        h = ''.join(ch * 2 for ch in h)
    if not re.fullmatch(r'[0-9a-fA-F]{6}', h):
        raise ValueError(f'invalid color code: {hex_}')
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return 0.2126 * _channel(r) + 0.7152 * _channel(g) + 0.0722 * _channel(b)


def ratio(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def main(argv):
    pairs = []
    if argv[:1] in (['--file'], ['--tep']) and len(argv) == 2:
        for line in open(argv[1], encoding='utf-8'):
            # A comment is a line starting with '#' that is not a colour pair ('#fff:#000'),
            # or a trailing ' # ...' after whitespace.
            if re.match(r'\s*#(?![0-9A-Fa-f]{3,8}:)', line):
                continue
            line = re.split(r'\s+#\s', line, maxsplit=1)[0].strip()
            if line:
                pairs.append(line)
    else:
        pairs = argv
    if not pairs:
        print(__doc__)
        return 2
    failed = 0
    for c in pairs:
        parts = c.split(':')
        if len(parts) not in (2, 3):
            print(f'INVALID input: {c}')
            return 2
        try:
            r = ratio(parts[0], parts[1])
        except ValueError as e:
            print(f'INVALID input: {e}')
            return 2
        threshold = float(parts[2]) if len(parts) == 3 else 4.5
        ok = r >= threshold
        failed += not ok
        print(f"{'PASS ' if ok else 'FAIL '} {parts[0]} on {parts[1]}: {r:.2f}:1 (need {threshold:g})")
    print('RESULT:', 'PASS' if failed == 0 else f'{failed} pair(s) failed')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
