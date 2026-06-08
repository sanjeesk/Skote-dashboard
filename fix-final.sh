#!/bin/bash
# macOS compatible fix script
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[FIX]${NC} $1"; }
warn() { echo -e "${YELLOW}[SKIP]${NC} $1"; }
err()  { echo -e "${RED}[ERR]${NC} $1"; }

if [ ! -f "angular.json" ]; then
  err "Run from Angular project root (where angular.json is)."
  exit 1
fi

# ── 1. Fix rxjs ──────────────────────────────────────────────────────────────
echo -e "\n${GREEN}━━━ STEP 1: Fix rxjs imports ━━━${NC}"
grep -rl "rxjs/internal/operators" src/ --include="*.ts" | while read f; do
  sed -i '' "s|from 'rxjs/internal/operators'|from 'rxjs/operators'|g" "$f"
  log "Patched: $f"
done

# ── 2. Fix all .module.ts: move declarations[] → imports[] ──────────────────
echo -e "\n${GREEN}━━━ STEP 2: Fix NgModules declarations→imports ━━━${NC}"
find src -name "*.module.ts" | while read modfile; do
  if grep -q "declarations" "$modfile" 2>/dev/null; then
    python3 - "$modfile" << 'PYEOF'
import re, sys
path = sys.argv[1]
with open(path) as f: src = f.read()
orig = src

dm = re.search(r'declarations\s*:\s*\[(.*?)\]', src, re.DOTALL)
if not dm:
    sys.exit(0)
items = [x.strip() for x in dm.group(1).split(',') if x.strip()]
if not items:
    sys.exit(0)

src = re.sub(r',?\s*declarations\s*:\s*\[.*?\]', '', src, flags=re.DOTALL)
src = re.sub(r'declarations\s*:\s*\[.*?\],?', '', src, flags=re.DOTALL)

add = ',\n    '.join(items)
im = re.search(r'(imports\s*:\s*\[)(.*?)(\])', src, re.DOTALL)
if im:
    existing = im.group(2).strip().rstrip(',')
    new_block = 'imports: [\n    ' + (existing + ',\n    ' if existing else '') + add + '\n  ]'
    src = src[:im.start()] + new_block + src[im.end():]
else:
    src = re.sub(r'(@NgModule\s*\(\s*\{)', r'\1\n  imports: [\n    ' + add + r'\n  ],', src, count=1)

src = re.sub(r',(\s*,)+', ',', src)
src = re.sub(r'\(\s*,', '(', src)
src = re.sub(r',\s*\)', ')', src)
src = re.sub(r'\{\s*,', '{', src)

if src != orig:
    with open(path, 'w') as f: f.write(src)
    print(f"  ✔ Fixed: {path}")
PYEOF
  fi
done

# ── 3. Fix cyptolanding module — add missing module imports ─────────────────
# Since CyptolandingComponent is NOT standalone, we fix its NgModule instead
echo -e "\n${GREEN}━━━ STEP 3: Fix CyptolandingComponent's NgModule ━━━${NC}"

# Find the module that declares CyptolandingComponent
CYPTO_MOD=$(grep -rl "CyptolandingComponent" src/ --include="*.module.ts" | head -1)
if [ -z "$CYPTO_MOD" ]; then
  # might be in a routing module or app module
  CYPTO_MOD=$(grep -rl "CyptolandingComponent" src/ --include="*.ts" | grep -v "component.ts" | head -1)
fi

if [ -n "$CYPTO_MOD" ]; then
  log "Found cyptolanding module: $CYPTO_MOD"
  python3 - "$CYPTO_MOD" << 'PYEOF'
import re, sys
path = sys.argv[1]
with open(path) as f: src = f.read()
orig = src

needed_stmts = [
    ("NgbNavModule",      "import { NgbNavModule, NgbAccordionModule } from '@ng-bootstrap/ng-bootstrap';"),
    ("NgbAccordionModule","import { NgbNavModule, NgbAccordionModule } from '@ng-bootstrap/ng-bootstrap';"),
    ("CarouselModule",    "import { CarouselModule } from 'ngx-owl-carousel-o';"),
    ("ScrollToModule",    "import { ScrollToModule } from '@nicky-lenaers/ngx-scroll-to';"),
    ("CommonModule",      "import { CommonModule } from '@angular/common';"),
]

last_imp = list(re.finditer(r'^import\s.+;$', src, re.MULTILINE))
pos = last_imp[-1].end() if last_imp else 0
to_add = []
seen_stmts = set()
for symbol, stmt in needed_stmts:
    if symbol not in src and stmt not in seen_stmts:
        to_add.append(stmt)
        seen_stmts.add(stmt)
if to_add:
    src = src[:pos] + '\n' + '\n'.join(to_add) + src[pos:]

required = ['CommonModule','NgbNavModule','NgbAccordionModule','CarouselModule','ScrollToModule']
im = re.search(r'(imports\s*:\s*\[)(.*?)(\])', src, re.DOTALL)
if im:
    block = im.group(2)
    to_add_m = [r for r in required if r not in block]
    if to_add_m:
        new_block = 'imports: [\n    ' + block.strip().rstrip(',') + ',\n    ' + ',\n    '.join(to_add_m) + '\n  ]'
        src = src[:im.start()] + new_block + src[im.end():]

if src != orig:
    with open(path,'w') as f: f.write(src)
    print(f"  ✔ Updated: {path}")
else:
    print(f"  (no changes needed in {path})")
PYEOF
else
  warn "Could not find cyptolanding module — checking for shared/cyptolanding module"
  find src -path "*/cyptolanding/*.module.ts" | while read f; do
    log "Found: $f"
  done
fi

# ── 4. Fix dashboard module — add NgApexchartsModule + RouterModule ──────────
echo -e "\n${GREEN}━━━ STEP 4: Fix DashboardComponent's NgModule ━━━${NC}"
DASH_MOD=$(grep -rl "DashboardComponent" src/ --include="*.module.ts" | head -1)

if [ -n "$DASH_MOD" ]; then
  log "Found dashboard module: $DASH_MOD"
  python3 - "$DASH_MOD" << 'PYEOF'
import re, sys
path = sys.argv[1]
with open(path) as f: src = f.read()
orig = src

needed_stmts = [
    ("NgApexchartsModule", "import { NgApexchartsModule } from 'ng-apexcharts';"),
    ("RouterModule",       "import { RouterModule } from '@angular/router';"),
    ("CommonModule",       "import { CommonModule } from '@angular/common';"),
]
last_imp = list(re.finditer(r'^import\s.+;$', src, re.MULTILINE))
pos = last_imp[-1].end() if last_imp else 0
to_add = [stmt for sym, stmt in needed_stmts if sym not in src]
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
    with open(path,'w') as f: f.write(src)
    print(f"  ✔ Updated: {path}")
else:
    print(f"  (no changes needed in {path})")
PYEOF
else
  warn "Could not find dashboard module"
fi

# ── 5. Install missing packages ──────────────────────────────────────────────
echo -e "\n${GREEN}━━━ STEP 5: Install missing packages ━━━${NC}"
missing=()
node -e "require('ngx-owl-carousel-o')"           2>/dev/null || missing+=("ngx-owl-carousel-o")
node -e "require('@nicky-lenaers/ngx-scroll-to')"  2>/dev/null || missing+=("@nicky-lenaers/ngx-scroll-to")
node -e "require('@ng-bootstrap/ng-bootstrap')"    2>/dev/null || missing+=("@ng-bootstrap/ng-bootstrap")
node -e "require('ng-apexcharts')"                2>/dev/null || missing+=("ng-apexcharts apexcharts")

if [ ${#missing[@]} -gt 0 ]; then
  log "Installing: ${missing[*]}"
  npm install "${missing[@]}" --legacy-peer-deps
else
  log "All packages already installed ✔"
fi

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} Done! Now run: ng serve${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
