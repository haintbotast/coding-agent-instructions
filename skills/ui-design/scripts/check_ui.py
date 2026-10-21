#!/usr/bin/env python3
"""check_ui.py — static HTML/CSS scan for "AI-default interface" signs and measurable quality-floor violations.

Usage: python3 check_ui.py <file.html|file.css> [...]     exit code 0 clean · 2 findings · 1 argument error
       python3 check_ui.py --self-test                    prove it can fail: the bad sample must trigger every code, the good sample must be clean
Standard library only, no network, no browser. Rules that need measuring on the rendered page (text overflow,
text occlusion, contrast over background images) are NOT here: use the chrome-devtools MCP or `playwright-cli` to inspect.
Codes and thresholds paraphrased from pbakaus/impeccable @e103efe `crates/live/assets/antipatterns.json` (Apache-2.0)
— see references/anti-patterns.md. The low-contrast rule only catches color pairs written directly in the SAME rule;
to check each color pair you supply, use scripts/contrast_check.py.
"""
import colorsys
import re
import sys

OVERUSED_FONTS = {'inter', 'roboto', 'fraunces', 'geist', 'plus jakarta sans', 'space grotesk'}
BUZZ = re.compile(r'\b(streamline[sd]?|empower(s|ing)?|supercharge[sd]?|world-class|enterprise-grade|'
                  r'next-generation|cutting-edge|seamless(ly)?|revolutioni[sz]e[sd]?)\b', re.I)
BODY_SEL = re.compile(r'(^|[\s,>+~])(body|p|li|article|main|\.prose|blockquote|dd)\b', re.I)
RULE = re.compile(r'([^{}]+)\{([^{}]*)\}', re.S)


def lineno(text, pos):
    return text.count('\n', 0, pos) + 1


def parse_color(s):
    s = s.strip().lower()
    m = re.fullmatch(r'#([0-9a-f]{3}|[0-9a-f]{6})', s)
    if m:
        h = m.group(1)
        if len(h) == 3:
            h = ''.join(c * 2 for c in h)
        return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    m = re.fullmatch(r'rgba?\(\s*(\d+)[\s,]+(\d+)[\s,]+(\d+)(?:[\s,/]+[\d.]+%?)?\s*\)', s)
    if m:
        return tuple(int(x) for x in m.groups())
    named = {'white': (255, 255, 255), 'black': (0, 0, 0)}
    return named.get(s)


def first_color(s):
    m = re.search(r'#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b|rgba?\([^)]*\)|\b(white|black)\b', s)
    return parse_color(m.group(0)) if m else None


def lum(c):
    def ch(v):
        v /= 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (ch(x) for x in c)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def neutral(c):
    return max(c) - min(c) < 16


def hue_deg(c):
    h, _, s = colorsys.rgb_to_hls(*(x / 255 for x in c))
    return h * 360, s


def decls(body):
    out = {}
    for d in body.split(';'):
        if ':' in d:
            k, v = d.split(':', 1)
            out.setdefault(k.strip().lower(), []).append(v.strip())
    return out


def to_px(v):
    m = re.match(r'(-?[\d.]+)(px|rem|em)?', v.strip())
    if not m:
        return None
    n = float(m.group(1))
    return n * 16 if m.group(2) in ('rem', 'em') else n


def check_css(css, base, F):
    for m in RULE.finditer(css):
        sel, body = m.group(1).strip(), m.group(2)
        ln = lineno(css, base + m.start())
        d = decls(body)
        get = lambda k: d.get(k, [])
        for side in ('border-left', 'border-right'):
            for v in get(side):
                w = re.match(r'([\d.]+)px\s+solid\s+(.+)', v)
                if w and float(w.group(1)) >= 3 and 'transparent' not in w.group(2):
                    F.append((ln, 'side-tab', f'{side}: {v} — thick colored border on one side of a card'))
        if any('text' in v for v in get('background-clip') + get('-webkit-background-clip')):
            F.append((ln, 'gradient-text', 'background-clip:text — gradient text is decoration, use a solid color'))
        for v in get('font-family'):
            fam = v.split(',')[0].strip().strip('\'"').lower()
            if fam in OVERUSED_FONTS:
                F.append((ln, 'overused-font', f'primary font "{fam}" is overused and creates no identity'))
        for v in get('transition') + get('transition-timing-function') + get('animation') + get('animation-timing-function'):
            for cb in re.findall(r'cubic-bezier\(([^)]*)\)', v):
                nums = [float(x) for x in re.findall(r'-?[\d.]+', cb)]
                if len(nums) == 4 and (not 0 <= nums[1] <= 1 or not 0 <= nums[3] <= 1):
                    F.append((ln, 'bounce-easing', f'cubic-bezier({cb}) goes outside [0,1] = bouncy/elastic'))
        for k in ('box-shadow', 'text-shadow'):
            for v in get(k):
                for sh in re.finditer(r'(?:^|,)\s*0(?:px)?\s+0(?:px)?\s+(\d+)px[^,]*', v):
                    c = first_color(sh.group(0))
                    if int(sh.group(1)) > 0 and c and not neutral(c):
                        F.append((ln, 'dark-glow', f'{k} non-offset colored glow (0 0 {sh.group(1)}px) is decoration'))
                        break
        for v in get('letter-spacing'):
            m2 = re.match(r'(-?[\d.]+)em', v)
            if m2 and float(m2.group(1)) < -0.04:
                F.append((ln, 'extreme-negative-tracking', f'letter-spacing {v} tighter than -0.04em'))
        if BODY_SEL.search(sel):
            for v in get('line-height'):
                try:
                    if float(v) < 1.3:
                        F.append((ln, 'tight-leading', f'{sel}: line-height {v} < 1.3 (body text should be 1.5–1.7)'))
                except ValueError:
                    pass
        for v in get('font-size'):
            px = to_px(v)
            if px is not None and 0 < px < 12:
                F.append((ln, 'tiny-text', f'font-size {v} < 12px (body ≥14px, ideally 16px)'))
        if any(v.startswith('justify') for v in get('text-align')) and not any('auto' in v for v in get('hyphens')):
            F.append((ln, 'justified-text', 'text-align: justify without hyphens: auto'))
        for v in get('transition') + get('transition-property'):
            if re.search(r'\b(width|height|padding|margin)\b', v):
                F.append((ln, 'layout-transition', f'transition on a layout property ({v}); use transform/opacity'))
        if re.search(r'repeating-(linear|radial)-gradient', body):
            F.append((ln, 'repeating-stripes-gradient', 'repeating-gradient stripes as surface decoration'))
        thin = any(re.match(r'1px\b', v) for v in get('border'))
        wide = any(int(b) >= 24 for v in get('box-shadow')
                   for b in re.findall(r'(?:^|[\s,])-?\d+(?:px)?\s+-?\d+(?:px)?\s+(\d+)px', v))
        if thin and wide:
            F.append((ln, 'gpt-thin-border-wide-shadow', '1px border + wide shadow: pick one (border or shadow)'))
        if re.search(r'img:hover|:hover\s+img', sel) and any(re.search(r'scale|rotate', v) for v in get('transform')):
            F.append((ln, 'image-hover-transform', 'image zoom/rotate on hover'))
        for v in get('background') + get('background-image'):
            if 'gradient' in v:
                hues = [hue_deg(parse_color(c)) for c in re.findall(r'#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b', v)]
                if any(250 <= h <= 300 and s > 0.35 for h, s in hues):
                    F.append((ln, 'ai-color-palette', 'purple/violet gradient — sign of an AI color palette'))
        fg = next((first_color(v) for v in get('color') if first_color(v)), None)
        bg = next((first_color(v) for v in get('background-color') + get('background') if first_color(v)), None)
        if fg and bg:
            r = contrast(fg, bg)
            if r < 4.5:
                F.append((ln, 'low-contrast', f'contrast {r:.2f}:1 < 4.5:1 (WCAG AA body text)'))


def check_html(html, F):
    for m in re.finditer(r'<style[^>]*>(.*?)</style>', html, re.S | re.I):
        check_css(m.group(1), m.start(1), F)
    for m in re.finditer(r'\sstyle="([^"]*)"', html):
        check_css('x{' + m.group(1) + '}', m.start(1) - 2, F)
    last = 0
    for m in re.finditer(r'<h([1-6])\b', html, re.I):
        lv = int(m.group(1))
        if last and lv > last + 1:
            F.append((lineno(html, m.start()), 'skipped-heading', f'heading level skipped h{last} → h{lv}'))
        last = lv
    text = re.sub(r'<(script|style)[^>]*>.*?</\1>', ' ', html, flags=re.S | re.I)
    text = re.sub(r'<[^>]+>', lambda t: ' ' * len(t.group(0)), text)
    for m in BUZZ.finditer(text):
        F.append((lineno(html, m.start()), 'marketing-buzzword', f'"{m.group(0)}" — generic SaaS wording, say what the product actually does'))
    for m in re.finditer(r'<img\b(?![^>]*\bsrc="[^"]+")[^>]*>', html, re.I):
        F.append((lineno(html, m.start()), 'broken-image', '<img> tag missing src'))


def scan(path, text):
    F = []
    if path.lower().endswith(('.css', '.scss')):
        check_css(text, 0, F)
    else:
        check_html(text, F)
    return sorted(set(F))


BAD = """<html><head><style>
.card{border-left:4px solid #7c3aed;border:1px solid #eee;box-shadow:0 10px 40px rgba(0,0,0,.08)}
h1{background:linear-gradient(90deg,#7c3aed,#06b6d4);-webkit-background-clip:text;letter-spacing:-0.06em}
body{font-family:Inter,sans-serif;line-height:1.2;text-align:justify}
.btn{transition:width .3s cubic-bezier(.68,-0.55,.27,1.55);box-shadow:0 0 24px #22d3ee}
.small{font-size:10px} .bg{background-image:repeating-linear-gradient(45deg,#eee 0 2px,#fff 2px 8px)}
.gallery img:hover{transform:scale(1.1)} .muted{color:#999;background-color:#aaa}
</style></head><body><h1>Supercharge your workflow</h1><h3>x</h3><img alt="x"></body></html>"""
GOOD = """<html><head><style>
body{font-family:"Source Serif 4",serif;line-height:1.6;color:#1a1a1a;background-color:#ffffff}
h1{letter-spacing:-0.02em} .card{border:1px solid #ddd;border-radius:12px}
.btn{transition:transform .2s cubic-bezier(.22,1,.36,1),opacity .2s}
</style></head><body><h1>Equipment loan log</h1><h2>On loan</h2><img src="a.png" alt="a"></body></html>"""
EXPECT = {'side-tab', 'gradient-text', 'overused-font', 'bounce-easing', 'dark-glow', 'extreme-negative-tracking',
          'tight-leading', 'tiny-text', 'justified-text', 'layout-transition', 'repeating-stripes-gradient',
          'gpt-thin-border-wide-shadow', 'image-hover-transform', 'ai-color-palette', 'low-contrast',
          'skipped-heading', 'marketing-buzzword', 'broken-image'}


def self_test():
    got = {c for _, c, _ in scan('bad.html', BAD)}
    miss, clean = EXPECT - got, scan('good.html', GOOD)
    print('bad sample: caught %d/%d codes%s' % (len(EXPECT & got), len(EXPECT), (' — MISSING: ' + ' '.join(sorted(miss))) if miss else ''))
    print('good sample: %d findings%s' % (len(clean), ''.join('\n  %d %s %s' % f for f in clean)))
    ok = not miss and not clean
    print('SELF-TEST ' + ('PASS' if ok else 'FAIL'))
    return 0 if ok else 1


def main(argv):
    if argv == ['--self-test']:
        return self_test()
    if not argv:
        print(__doc__)
        return 1
    total = 0
    for p in argv:
        try:
            text = open(p, encoding='utf-8').read()
        except OSError as e:
            print(f'ERROR reading {p}: {e}')
            return 1
        for ln, code, msg in scan(p, text):
            print(f'{p}:{ln}  [{code}]  {msg}')
            total += 1
    print(f'{total} findings' if total else 'clean')
    return 2 if total else 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
