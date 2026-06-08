#!/bin/bash
set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[FIX]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERR]${NC} $1"; }

# ─── Guard: must run from Angular project root ───────────────────────────────
if [ ! -f "angular.json" ]; then
  err "Run this script from your Angular project root (where angular.json lives)."
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════════════
# FIX 1 — rxjs/internal/operators → rxjs/operators
# ══════════════════════════════════════════════════════════════════════════════
log "FIX 1: Patching rxjs import paths..."
find src -name "*.ts" | xargs grep -l "rxjs/internal/operators" 2>/dev/null | while read f; do
  sed -i "s|from 'rxjs/internal/operators'|from 'rxjs/operators'|g" "$f"
  log "  Patched: $f"
done

# ══════════════════════════════════════════════════════════════════════════════
# FIX 2 — NgModules: move standalone components from declarations[] to imports[]
#          Targets: extrapages, layouts, and all single-feature modules
# ══════════════════════════════════════════════════════════════════════════════
log "FIX 2: Fixing NgModules that declare standalone components..."

fix_module_declarations() {
  local file="$1"
  if [ ! -f "$file" ]; then warn "  Not found, skipping: $file"; return; fi

  python3 - "$file" <<'PYEOF'
import re, sys

path = sys.argv[1]
with open(path, 'r') as f:
    src = f.read()

original = src

# Move all items from declarations:[...] to imports:[]
# Strategy:
#   1. Capture the declarations block content
#   2. Remove the declarations block
#   3. Merge its content into the imports block (or create one)

decl_pattern = re.compile(
    r'declarations\s*:\s*\[(.*?)\]',
    re.DOTALL
)
m = decl_pattern.search(src)
if not m:
    print(f"  No declarations[] found in {path}, skipping.")
    sys.exit(0)

decl_items_raw = m.group(1)
# Clean up whitespace/newlines in items list but preserve names
decl_items = [x.strip() for x in decl_items_raw.split(',') if x.strip()]

# Remove the declarations block entirely
src = decl_pattern.sub('', src)
# Clean up any double-commas or leading/trailing commas left in @NgModule({...})
src = re.sub(r',\s*,', ',', src)
src = re.sub(r'\(\s*,', '(', src)
src = re.sub(r',\s*\)', ')', src)

# Merge into imports block if it exists, else create one
imports_pattern = re.compile(r'imports\s*:\s*\[([^\[\]]*)\]', re.DOTALL)
im = imports_pattern.search(src)

items_str = ',\n    '.join(decl_items)

if im:
    existing = im.group(1).strip().rstrip(',')
    new_imports = f"imports: [\n    {existing},\n    {items_str}\n  ]"
    src = imports_pattern.sub(new_imports, src, count=1)
else:
    # Insert imports block after the opening of @NgModule({
    src = re.sub(
        r'(@NgModule\(\s*\{)',
        rf'\1\n  imports: [\n    {items_str}\n  ],',
        src, count=1
    )

# Fix exports: replace declarations items in exports with same items
# (they were already exported, keep them)

if src != original:
    with open(path, 'w') as f:
        f.write(src)
    print(f"  Fixed declarations->imports in: {path}")
else:
    print(f"  No changes needed in: {path}")
PYEOF
}

# Layouts module
fix_module_declarations "src/app/layouts/layouts.module.ts"

# Extrapages module
fix_module_declarations "src/app/extrapages/extrapages.module.ts"

# Single-feature modules
for mod in affiliate brands campaigns categories creators discovery finance opportunity roles tags users; do
  fix_module_declarations "src/app/pages/${mod}/${mod}.module.ts"
done

# ══════════════════════════════════════════════════════════════════════════════
# FIX 3 — shared.module.ts: ScrollspyDirective declarations → imports
# ══════════════════════════════════════════════════════════════════════════════
log "FIX 3: Fixing shared.module.ts ScrollspyDirective..."
fix_module_declarations "src/app/cyptolanding/shared/shared.module.ts"

# ══════════════════════════════════════════════════════════════════════════════
# FIX 4 — CyptolandingComponent: add missing imports to @Component decorator
# ══════════════════════════════════════════════════════════════════════════════
log "FIX 4: Adding missing imports to CyptolandingComponent..."

CYPTO_TS="src/app/cyptolanding/cyptolanding.component.ts"
if [ -f "$CYPTO_TS" ]; then

python3 - "$CYPTO_TS" <<'PYEOF'
import re, sys

path = sys.argv[1]
with open(path) as f:
    src = f.read()

original = src

new_imports = """\
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { NgbNavModule, NgbAccordionModule } from '@ng-bootstrap/ng-bootstrap';
import { CarouselModule } from 'ngx-owl-carousel-o';
import { ScrollToModule } from '@nicky-lenaers/ngx-scroll-to';
"""

# Add import statements after the last existing import line if not already present
guards = ["CommonModule", "NgbNavModule", "CarouselModule", "ScrollToModule"]
if not all(g in src for g in guards):
    # Insert after last import statement
    last_import = list(re.finditer(r'^import .+;$', src, re.MULTILINE))
    if last_import:
        pos = last_import[-1].end()
        src = src[:pos] + '\n' + new_imports + src[pos:]

# Ensure the @Component imports array has the required modules
comp_imports_pattern = re.compile(
    r'(@Component\([^)]*imports\s*:\s*\[)([^\]]*?)(\])',
    re.DOTALL
)
m = comp_imports_pattern.search(src)

required = [
    'CommonModule',
    'RouterModule',
    'NgbNavModule',
    'NgbAccordionModule',
    'CarouselModule',
    'ScrollToModule',
]

if m:
    existing_block = m.group(2)
    to_add = [r for r in required if r not in existing_block]
    if to_add:
        new_block = existing_block.rstrip().rstrip(',') + ',\n    ' + ',\n    '.join(to_add) + '\n  '
        src = src[:m.start(2)] + new_block + src[m.end(2):]
else:
    # No imports array in @Component — add one
    src = re.sub(
        r'(standalone\s*:\s*true)',
        r'\1,\n  imports: [\n    ' + ',\n    '.join(required) + '\n  ]',
        src, count=1
    )

if src != original:
    with open(path, 'w') as f:
        f.write(src)
    print(f"  Updated: {path}")
else:
    print(f"  No changes needed in: {path}")
PYEOF

else
  warn "  CyptolandingComponent not found at expected path, skipping."
fi

# ══════════════════════════════════════════════════════════════════════════════
# FIX 5 — DashboardComponent: add NgApexchartsModule + RouterModule
# ══════════════════════════════════════════════════════════════════════════════
log "FIX 5: Adding missing imports to DashboardComponent..."

DASH_TS="src/app/pages/dashboard/dashboard.component.ts"
if [ -f "$DASH_TS" ]; then

python3 - "$DASH_TS" <<'PYEOF'
import re, sys

path = sys.argv[1]
with open(path) as f:
    src = f.read()

original = src

new_imports = """\
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { NgApexchartsModule } from 'ng-apexcharts';
"""

guards = ["NgApexchartsModule", "RouterModule"]
if not all(g in src for g in guards):
    last_import = list(re.finditer(r'^import .+;$', src, re.MULTILINE))
    if last_import:
        pos = last_import[-1].end()
        src = src[:pos] + '\n' + new_imports + src[pos:]

required = ['CommonModule', 'RouterModule', 'NgApexchartsModule']

comp_imports_pattern = re.compile(
    r'(@Component\([^)]*imports\s*:\s*\[)([^\]]*?)(\])',
    re.DOTALL
)
m = comp_imports_pattern.search(src)

if m:
    existing_block = m.group(2)
    to_add = [r for r in required if r not in existing_block]
    if to_add:
        new_block = existing_block.rstrip().rstrip(',') + ',\n    ' + ',\n    '.join(to_add) + '\n  '
        src = src[:m.start(2)] + new_block + src[m.end(2):]
else:
    src = re.sub(
        r'(standalone\s*:\s*true)',
        r'\1,\n  imports: [\n    ' + ',\n    '.join(required) + '\n  ]',
        src, count=1
    )

if src != original:
    with open(path, 'w') as f:
        f.write(src)
    print(f"  Updated: {path}")
else:
    print(f"  No changes needed in: {path}")
PYEOF

else
  warn "  DashboardComponent not found at expected path, skipping."
fi

# ══════════════════════════════════════════════════════════════════════════════
# FIX 6 — ComingsoonComponent: fix rxjs + add CommonModule if standalone
# ══════════════════════════════════════════════════════════════════════════════
log "FIX 6: Checking ComingsoonComponent..."
COMINGSOON="src/app/extrapages/comingsoon/comingsoon.component.ts"
if [ -f "$COMINGSOON" ]; then
  sed -i "s|from 'rxjs/internal/operators'|from 'rxjs/operators'|g" "$COMINGSOON"
  log "  Patched rxjs import in $COMINGSOON"
fi

# ══════════════════════════════════════════════════════════════════════════════
# DONE
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} All fixes applied. Now run:  ng build  or  ng serve${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo " If you still see errors after this, the most likely remaining issues are:"
echo "  1. ng-apexcharts not installed  →  npm install ng-apexcharts apexcharts"
echo "  2. ngx-owl-carousel-o missing   →  npm install ngx-owl-carousel-o"
echo "  3. @nicky-lenaers/ngx-scroll-to →  npm install @nicky-lenaers/ngx-scroll-to"
echo "  4. @ng-bootstrap/ng-bootstrap   →  npm install @ng-bootstrap/ng-bootstrap"
echo ""
