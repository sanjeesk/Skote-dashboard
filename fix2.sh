#!/bin/bash
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[FIX]${NC} $1"; }
warn() { echo -e "${YELLOW}[SKIP]${NC} $1"; }
err()  { echo -e "${RED}[ERR]${NC} $1"; }

if [ ! -f "angular.json" ]; then
  err "Run from Angular project root (where angular.json is)."
  exit 1
fi

echo -e "${GREEN}━━━ STEP 1: Fix rxjs/internal/operators ━━━${NC}"
while IFS= read -r -d '' file; do
  sed -i "s|from 'rxjs/internal/operators'|from 'rxjs/operators'|g" "$file"
  log "Patched rxjs: $file"
done < <(grep -rl "rxjs/internal/operators" src/ --include="*.ts" -Z 2>/dev/null)

echo ""
echo -e "${GREEN}━━━ STEP 2: Fix NgModules — declarations→imports ━━━${NC}"
# For every .module.ts that has declarations:[], move items to imports:[]
while IFS= read -r -d '' modfile; do
  if grep -q "declarations\s*:" "$modfile" 2>/dev/null; then
    python3 - "$modfile" << 'PYEOF'
import re, sys
path = sys.argv[1]
with open(path) as f: src = f.read()
orig = src

# Extract declarations block
dm = re.search(r'declarations\s*:\s*\[(.*?)\]', src, re.DOTALL)
if not dm:
    sys.exit(0)

items = [x.strip() for x in dm.group(1).split(',') if x.strip()]
if not items:
    sys.exit(0)

# Remove declarations block + any trailing comma
src = re.sub(r',?\s*declarations\s*:\s*\[.*?\]', '', src, flags=re.DOTALL)
src = re.sub(r'declarations\s*:\s*\[.*?\],?', '', src, flags=re.DOTALL)

# Add to imports block or create one
im = re.search(r'(imports\s*:\s*\[)(.*?)(\])', src, re.DOTALL)
add = ',\n    '.join(items)
if im:
    existing = im.group(2).strip().rstrip(',')
    new_block = f"imports: [\n    {existing + (',' if existing else '')}\n    {add}\n  ]"
    src = src[:im.start()] + new_block + src[im.end():]
else:
    src = re.sub(r'(@NgModule\s*\(\s*\{)', r'\1\n  imports: [\n    ' + add + r'\n  ],', src, count=1)

# Clean up artefacts
src = re.sub(r',(\s*,)+', ',', src)
src = re.sub(r'\(\s*,', '(', src)
src = re.sub(r',\s*\)', ')', src)
src = re.sub(r'\{\s*,', '{', src)
src = re.sub(r',\s*\}', '}', src)

if src != orig:
    with open(path, 'w') as f: f.write(src)
    print(f"  ✔ Fixed: {path}")
PYEOF
  fi
done < <(find src -name "*.module.ts" -Z 2>/dev/null)

echo ""
echo -e "${GREEN}━━━ STEP 3: Fix CyptolandingComponent imports ━━━${NC}"
CYPTO=$(find src -path "*/cyptolanding/cyptolanding.component.ts" 2>/dev/null | head -1)
if [ -z "$CYPTO" ]; then
  CYPTO=$(find src -name "cyptolanding.component.ts" 2>/dev/null | head -1)
fi

if [ -n "$CYPTO" ]; then
  python3 - "$CYPTO" << 'PYEOF'
import re, sys
path = sys.argv[1]
with open(path) as f: src = f.read()
orig = src

needed_imports = {
    'CommonModule':      "import { CommonModule } from '@angular/common';",
    'NgbNavModule':      "import { NgbNavModule, NgbAccordionModule } from '@ng-bootstrap/ng-bootstrap';",
    'NgbAccordionModule':"import { NgbNavModule, NgbAccordionModule } from '@ng-bootstrap/ng-bootstrap';",
    'CarouselModule':    "import { CarouselModule } from 'ngx-owl-carousel-o';",
    'ScrollToModule':    "import { ScrollToModule } from '@nicky-lenaers/ngx-scroll-to';",
}

# Add missing import statements
last_imp = list(re.finditer(r'^import\s.+;$', src, re.MULTILINE))
insert_pos = last_imp[-1].end() if last_imp else 0
lines_to_add = []
for symbol, stmt in needed_imports.items():
    if symbol not in src and stmt.split("'")[1] not in src:
        lines_to_add.append(stmt)

if lines_to_add:
    src = src[:insert_pos] + '\n' + '\n'.join(lines_to_add) + src[insert_pos:]

# Add to @Component imports array
required = ['CommonModule','NgbNavModule','NgbAccordionModule','CarouselModule','ScrollToModule']
comp_m = re.search(r'(@Component\s*\({.*?imports\s*:\s*\[)(.*?)(\])', src, re.DOTALL)
if comp_m:
    block = comp_m.group(2)
    to_add = [r for r in required if r not in block]
    if to_add:
        new_block = block.rstrip().rstrip(',') + ',\n    ' + ',\n    '.join(to_add) + '\n  '
        src = src[:comp_m.start(2)] + new_block + src[comp_m.end(2):]
else:
    # standalone: true exists but no imports array
    src = re.sub(
        r'(standalone\s*:\s*true)',
        r'\1,\n  imports: [\n    ' + ',\n    '.join(required) + '\n  ]',
        src, count=1
    )

if src != orig:
    with open(path,'w') as f: f.write(src)
    print(f"  ✔ Updated: {path}")
else:
    print(f"  ✔ Already OK: {path}")
PYEOF
else
  warn "cyptolanding.component.ts not found"
fi

echo ""
echo -e "${GREEN}━━━ STEP 4: Fix DashboardComponent imports ━━━${NC}"
DASH=$(find src -name "dashboard.component.ts" 2>/dev/null | head -1)
if [ -n "$DASH" ]; then
  python3 - "$DASH" << 'PYEOF'
import re, sys
path = sys.argv[1]
with open(path) as f: src = f.read()
orig = src

needed_imports = {
    'CommonModule':      "import { CommonModule } from '@angular/common';",
    'RouterModule':      "import { RouterModule } from '@angular/router';",
    'NgApexchartsModule':"import { NgApexchartsModule } from 'ng-apexcharts';",
}
last_imp = list(re.finditer(r'^import\s.+;$', src, re.MULTILINE))
insert_pos = last_imp[-1].end() if last_imp else 0
lines_to_add = []
for symbol, stmt in needed_imports.items():
    if symbol not in src:
        lines_to_add.append(stmt)
if lines_to_add:
    src = src[:insert_pos] + '\n' + '\n'.join(lines_to_add) + src[insert_pos:]

required = ['CommonModule','RouterModule','NgApexchartsModule']
comp_m = re.search(r'(@Component\s*\({.*?imports\s*:\s*\[)(.*?)(\])', src, re.DOTALL)
if comp_m:
    block = comp_m.group(2)
    to_add = [r for r in required if r not in block]
    if to_add:
        new_block = block.rstrip().rstrip(',') + ',\n    ' + ',\n    '.join(to_add) + '\n  '
        src = src[:comp_m.start(2)] + new_block + src[comp_m.end(2):]
else:
    src = re.sub(
        r'(standalone\s*:\s*true)',
        r'\1,\n  imports: [\n    ' + ',\n    '.join(required) + '\n  ]',
        src, count=1
    )

if src != orig:
    with open(path,'w') as f: f.write(src)
    print(f"  ✔ Updated: {path}")
else:
    print(f"  ✔ Already OK: {path}")
PYEOF
else
  warn "dashboard.component.ts not found"
fi

echo ""
echo -e "${GREEN}━━━ STEP 5: Verify packages installed ━━━${NC}"
missing=()
node -e "require('ngx-owl-carousel-o')" 2>/dev/null || missing+=("ngx-owl-carousel-o")
node -e "require('@nicky-lenaers/ngx-scroll-to')" 2>/dev/null || missing+=("@nicky-lenaers/ngx-scroll-to")
node -e "require('@ng-bootstrap/ng-bootstrap')" 2>/dev/null || missing+=("@ng-bootstrap/ng-bootstrap")
node -e "require('ng-apexcharts')" 2>/dev/null || missing+=("ng-apexcharts apexcharts")

if [ ${#missing[@]} -gt 0 ]; then
  echo -e "${YELLOW}⚠ Missing packages — installing now...${NC}"
  npm install "${missing[@]}" --legacy-peer-deps
else
  log "All packages already installed."
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} Done! Now run: ng serve${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
