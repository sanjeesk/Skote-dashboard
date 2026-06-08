#!/usr/bin/env python3
"""
Run from Angular project root:  python3 fix-all.py
"""
import re, os, sys, glob

def read(p):
    with open(p) as f: return f.read()

def write(p, s):
    with open(p, 'w') as f: f.write(s)

def log(msg):   print(f"\033[32m[FIX]\033[0m {msg}")
def warn(msg):  print(f"\033[33m[SKIP]\033[0m {msg}")
def err(msg):   print(f"\033[31m[ERR]\033[0m {msg}")

if not os.path.exists('angular.json'):
    err("Run from Angular project root!")
    sys.exit(1)

# ── 1. Fix duplicate imports: key in modules ─────────────────────────────────
# The previous script added a second imports:[] instead of merging.
# Strategy: collapse all imports:[] blocks into one clean one.
print("\n\033[32m━━━ STEP 1: Fix duplicate imports: keys in modules ━━━\033[0m")

def fix_duplicate_imports(src):
    """Find all imports:[...] blocks and merge them into one."""
    pattern = re.compile(r'imports\s*:\s*\[(.*?)\]', re.DOTALL)
    matches = list(pattern.finditer(src))
    if len(matches) <= 1:
        return src  # nothing to fix

    # Collect all items from all imports blocks
    all_items = []
    seen = set()
    for m in matches:
        for item in m.group(1).split(','):
            item = item.strip()
            if item and item not in seen:
                seen.add(item)
                all_items.append(item)

    # Build one clean imports block
    items_str = ',\n    '.join(all_items)
    new_block = f"imports: [\n    {items_str}\n  ]"

    # Remove all imports blocks
    src = pattern.sub('__IMPORTS_PLACEHOLDER__', src)
    # Replace only first placeholder, remove rest
    src = src.replace('__IMPORTS_PLACEHOLDER__', new_block, 1)
    src = re.sub(r',?\s*__IMPORTS_PLACEHOLDER__', '', src)
    return src

for modfile in glob.glob('src/**/*.module.ts', recursive=True):
    orig = read(modfile)
    fixed = fix_duplicate_imports(orig)
    if fixed != orig:
        write(modfile, fixed)
        log(f"Fixed duplicate imports: {modfile}")

# ── 2. Fix layouts.module.ts — add missing modules ───────────────────────────
print("\n\033[32m━━━ STEP 2: Fix layouts.module.ts ━━━\033[0m")
layouts_mod = 'src/app/layouts/layouts.module.ts'
if os.path.exists(layouts_mod):
    src = read(layouts_mod)
    orig = src

    needed_imports = {
        'RouterModule':    "import { RouterModule } from '@angular/router';",
        'CommonModule':    "import { CommonModule } from '@angular/common';",
        'TranslateModule': "import { TranslateModule } from '@ngx-translate/core';",
        'SimplebarAngularModule': "import { SimplebarAngularModule } from 'simplebar-angular';",
    }

    # Add missing import statements
    last_imp = list(re.finditer(r'^import\s.+;$', src, re.MULTILINE))
    pos = last_imp[-1].end() if last_imp else 0
    to_add = [stmt for sym, stmt in needed_imports.items() if sym not in src]
    if to_add:
        src = src[:pos] + '\n' + '\n'.join(to_add) + src[pos:]

    # Add to imports array
    required = ['RouterModule', 'CommonModule', 'TranslateModule', 'SimplebarAngularModule']
    im = re.search(r'(imports\s*:\s*\[)(.*?)(\])', src, re.DOTALL)
    if im:
        block = im.group(2)
        to_add_m = [r for r in required if r not in block]
        if to_add_m:
            new_block = 'imports: [\n    ' + block.strip().rstrip(',') + ',\n    ' + ',\n    '.join(to_add_m) + '\n  ]'
            src = src[:im.start()] + new_block + src[im.end():]

    if src != orig:
        write(layouts_mod, src)
        log(f"Updated: {layouts_mod}")
    else:
        log(f"No changes needed: {layouts_mod}")

# ── 3. Fix cyptolanding module ───────────────────────────────────────────────
print("\n\033[32m━━━ STEP 3: Fix cyptolanding module ━━━\033[0m")
cypto_mods = glob.glob('src/**/cyptolanding*.module.ts', recursive=True) + \
             glob.glob('src/**/cyptolanding/**/*.module.ts', recursive=True)

# Also search by content
for f in glob.glob('src/**/*.module.ts', recursive=True):
    if 'CyptolandingComponent' in read(f) and f not in cypto_mods:
        cypto_mods.append(f)

for modfile in set(cypto_mods):
    src = read(modfile)
    orig = src

    needed_imports = {
        'CommonModule':       "import { CommonModule } from '@angular/common';",
        'NgbNavModule':       "import { NgbNavModule, NgbAccordionModule } from '@ng-bootstrap/ng-bootstrap';",
        'NgbAccordionModule': "import { NgbNavModule, NgbAccordionModule } from '@ng-bootstrap/ng-bootstrap';",
        'CarouselModule':     "import { CarouselModule } from 'ngx-owl-carousel-o';",
        'ScrollToModule':     "import { ScrollToModule } from '@nicky-lenaers/ngx-scroll-to';",
        'RouterModule':       "import { RouterModule } from '@angular/router';",
    }

    last_imp = list(re.finditer(r'^import\s.+;$', src, re.MULTILINE))
    pos = last_imp[-1].end() if last_imp else 0
    seen_stmts = set()
    to_add = []
    for sym, stmt in needed_imports.items():
        if sym not in src and stmt not in seen_stmts:
            to_add.append(stmt)
            seen_stmts.add(stmt)
    if to_add:
        src = src[:pos] + '\n' + '\n'.join(to_add) + src[pos:]

    required = ['CommonModule','RouterModule','NgbNavModule','NgbAccordionModule','CarouselModule','ScrollToModule']
    im = re.search(r'(imports\s*:\s*\[)(.*?)(\])', src, re.DOTALL)
    if im:
        block = im.group(2)
        to_add_m = [r for r in required if r not in block]
        if to_add_m:
            new_block = 'imports: [\n    ' + block.strip().rstrip(',') + ',\n    ' + ',\n    '.join(to_add_m) + '\n  ]'
            src = src[:im.start()] + new_block + src[im.end():]

    if src != orig:
        write(modfile, src)
        log(f"Updated: {modfile}")

# ── 4. Fix dashboard module ──────────────────────────────────────────────────
print("\n\033[32m━━━ STEP 4: Fix dashboard module ━━━\033[0m")
dash_mods = []
for f in glob.glob('src/**/*.module.ts', recursive=True):
    if 'DashboardComponent' in read(f):
        dash_mods.append(f)

for modfile in set(dash_mods):
    src = read(modfile)
    orig = src

    needed_imports = {
        'NgApexchartsModule': "import { NgApexchartsModule } from 'ng-apexcharts';",
        'RouterModule':       "import { RouterModule } from '@angular/router';",
        'CommonModule':       "import { CommonModule } from '@angular/common';",
    }

    last_imp = list(re.finditer(r'^import\s.+;$', src, re.MULTILINE))
    pos = last_imp[-1].end() if last_imp else 0
    to_add = [stmt for sym, stmt in needed_imports.items() if sym not in src]
    if to_add:
        src = src[:pos] + '\n' + '\n'.join(dict.fromkeys(to_add)) + src[pos:]

    required = ['CommonModule','RouterModule','NgApexchartsModule']
    im = re.search(r'(imports\s*:\s*\[)(.*?)(\])', src, re.DOTALL)
    if im:
        block = im.group(2)
        to_add_m = [r for r in required if r not in block]
        if to_add_m:
            new_block = 'imports: [\n    ' + block.strip().rstrip(',') + ',\n    ' + ',\n    '.join(to_add_m) + '\n  ]'
            src = src[:im.start()] + new_block + src[im.end():]

    if src != orig:
        write(modfile, src)
        log(f"Updated: {modfile}")

# ── 5. Fix rxjs ──────────────────────────────────────────────────────────────
print("\n\033[32m━━━ STEP 5: Fix rxjs imports ━━━\033[0m")
for f in glob.glob('src/**/*.ts', recursive=True):
    src = read(f)
    if 'rxjs/internal/operators' in src:
        fixed = src.replace("from 'rxjs/internal/operators'", "from 'rxjs/operators'")
        write(f, fixed)
        log(f"Patched rxjs: {f}")

print("\n\033[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m")
print("\033[32m Done! Now run: ng serve\033[0m")
print("\033[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m")
print()
print(" If translate pipe still errors, run:")
print("   npm install @ngx-translate/core @ngx-translate/http-loader --legacy-peer-deps")
print(" If simplebar still errors, run:")
print("   npm install simplebar-angular --legacy-peer-deps")
