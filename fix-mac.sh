#!/bin/bash
# macOS compatible - uses sed -i ''
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[FIX]${NC} $1"; }
warn() { echo -e "${YELLOW}[SKIP]${NC} $1"; }
err()  { echo -e "${RED}[ERR]${NC} $1"; }

if [ ! -f "angular.json" ]; then
  err "Run from Angular project root (where angular.json is)."
  exit 1
fi

# ── 1. Fix rxjs import ──────────────────────────────────────────────────────
echo -e "\n${GREEN}━━━ STEP 1: Fix rxjs imports ━━━${NC}"
grep -rl "rxjs/internal/operators" src/ --include="*.ts" | while read f; do
  sed -i '' "s|from 'rxjs/internal/operators'|from 'rxjs/operators'|g" "$f"
  log "Patched: $f"
done

# ── 2. Fix all .module.ts: declarations → imports ───────────────────────────
echo -e "\n${GREEN}━━━ STEP 2: Fix NgModule declarations → imports ━━━${NC}"
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

# Remove declarations block
src = re.sub(r',?\s*declarations\s*:\s*\[.*?\]', '', src, flags=re.DOTALL)
src = re.sub(r'declarations\s*:\s*\[.*?\],?', '', src, flags=re.DOTALL)

# Add items to imports block or create one
add = ',\n    '.join(items)
im = re.search(r'(imports\s*:\s*\[)(.*?)(\])', src, re.DOTALL)
if im:
    existing = im.group(2).strip().rstrip(',')
    new_block = 'imports: [\n    ' + (existing + ',\n    ' if existing else '') + add + '\n  ]'
    src = src[:im.start()] + new_block + src[im.end():]
else:
    src = re.sub(r'(@NgModule\s*\(\s*\{)', r'\1\n  imports: [\n    ' + add + r'\n  ],', src, count=1)

# Clean up double commas / stray commas
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

# ── 3. Fix CyptolandingComponent ────────────────────────────────────────────
echo -e "\n${GREEN}━━━ STEP 3: Fix CyptolandingComponent ━━━${NC}"
CYPTO=$(find src -name "cyptolanding.component.ts" | head -1)
if [ -n "$CYPTO" ]; then
  python3 - "$CYPTO" << 'PYEOF'
import re, sys
path = sys.argv[1]
with open(path) as f: src = f.read()
orig = src

# Import statements to add
new_stmts = [
    "import { CommonModule } from '@angular/common';",
    "import { NgbNavModule, NgbAccordionModule } from '@ng-bootstrap/ng-bootstrap';",
    "import { CarouselModule } from 'ngx-owl-carousel-o';",
    "import { ScrollToModule } from '@nicky-lenaers/ngx-scroll-to';",
]
last_imp = list(re.finditer(r'^import\s.+;$', src, re.MULTILINE))
pos = last_imp[-1].end() if last_imp else 0
to_add = [s for s in new_stmts if s.split("'")[1] not in src]
if to_add:
    src = src[:pos] + '\n' + '\n'.join(to_add) + src[pos:]

# Modules to add to @Component imports array
required = ['CommonModule','NgbNavModule','NgbAccordionModule','CarouselModule','ScrollToModule']
comp_m = re.search(r'(@Component\s*\(\s*\{.*?imports\s*:\s*\[)(.*?)(\])', src, re.DOTALL)
if comp_m:
    block = comp_m.group(2)
    to_add_m = [r for r in required if r not in block]
    if to_add_m:
        new_block = block.rstrip().rstrip(',') + ',\n    ' + ',\n    '.join(to_add_m) + '\n  '
        src = src[:comp_m.start(2)] + new_block + src[comp_m.end(2):]
else:
    src = re.sub(
        r'(standalone\s*:\s*true)',
        'standalone: true,\n  imports: [\n    ' + ',\n    '.join(required) + '\n  ]',
        src, count=1
    )

if src != orig:
    with open(path,'w') as f: f.write(src)
    print(f"  ✔ Updated: {path}")
else:
    print(f"  (no changes needed)")
PYEOF
else
  warn "cyptolanding.component.ts not found"
fi

# ── 4. Fix DashboardComponent ───────────────────────────────────────────────
echo -e "\n${GREEN}━━━ STEP 4: Fix DashboardComponent ━━━${NC}"
DASH=$(find src -name "dashboard.component.ts" | head -1)
if [ -n "$DASH" ]; then
  python3 - "$DASH" << 'PYEOF'
import re, sys
path = sys.argv[1]
with open(path) as f: src = f.read()
orig = src

new_stmts = [
    "import { CommonModule } from '@angular/common';",
    "import { RouterModule } from '@angular/router';",
    "import { NgApexchartsModule } from 'ng-apexcharts';",
]
last_imp = list(re.finditer(r'^import\s.+;$', src, re.MULTILINE))
pos = last_imp[-1].end() if last_imp else 0
to_add = [s for s in new_stmts if s.split("'")[1] not in src]
if to_add:
    src = src[:pos] + '\n' + '\n'.join(to_add) + src[pos:]

required = ['CommonModule','RouterModule','NgApexchartsModule']
comp_m = re.search(r'(@Component\s*\(\s*\{.*?imports\s*:\s*\[)(.*?)(\])', src, re.DOTALL)
if comp_m:
    block = comp_m.group(2)
    to_add_m = [r for r in required if r not in block]
    if to_add_m:
        new_block = block.rstrip().rstrip(',') + ',\n    ' + ',\n    '.join(to_add_m) + '\n  '
        src = src[:comp_m.start(2)] + new_block + src[comp_m.end(2):]
else:
    src = re.sub(
        r'(standalone\s*:\s*true)',
        'standalone: true,\n  imports: [\n    ' + ',\n    '.join(required) + '\n  ]',
        src, count=1
    )

if src != orig:
    with open(path,'w') as f: f.write(src)
    print(f"  ✔ Updated: {path}")
else:
    print(f"  (no changes needed)")
PYEOF
else
  warn "dashboard.component.ts not found"
fi

# ── 5. Install missing npm packages ─────────────────────────────────────────
echo -e "\n${GREEN}━━━ STEP 5: Check & install missing packages ━━━${NC}"
missing=()
node -e "require('ngx-owl-carousel-o')"          2>/dev/null || missing+=("ngx-owl-carousel-o")
node -e "require('@nicky-lenaers/ngx-scroll-to')" 2>/dev/null || missing+=("@nicky-lenaers/ngx-scroll-to")
node -e "require('@ng-bootstrap/ng-bootstrap')"   2>/dev/null || missing+=("@ng-bootstrap/ng-bootstrap")
node -e "require('ng-apexcharts')"               2>/dev/null || missing+=("ng-apexcharts apexcharts")

if [ ${#missing[@]} -gt 0 ]; then
  log "Installing: ${missing[*]}"
  npm install "${missing[@]}" --legacy-peer-deps
else
  log "All packages already installed ✔"
fi

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} All done! Run: ng serve${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
