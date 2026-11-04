"""Thu gon sidebar cua Console v1.7.6 khi build, khong doi quyen API."""

import hashlib
import json
from pathlib import Path
import sys


console = Path(sys.argv[1])
build = console / "web-app/build"
bundle = build / "static/js/main.45669c2e.js"
expected = "142cb6656ad46616cae3c3b50867fd432353afeae472bbd3d433ccabecaa42ca"
if hashlib.sha256(bundle.read_bytes()).hexdigest() != expected:
    raise ValueError("Console asset changed; review the menu patch before building")

# Dong bo thay doi vao source de co the doc va tai lap ban tuy chinh.
source = console / "web-app/src/screens/Console/valid-routes.tsx"
text = source.read_text()
anchor = "  return consoleMenus.reduce((acc: IMenuItem[], item) => {"
if text.count(anchor) != 1:
    raise ValueError("Console menu source changed")
source.write_text(text.replace(anchor, '''  // N07: chi giu cac chuc nang Storage dang duoc su dung.
  consoleMenus = consoleMenus.flatMap((item): IMenuItem[] => {
    if (item.id === "identity" || item.id === "tools") {
      const childId = item.id === "identity" ? "users" : "monitorLogs";
      return (item.children ?? [])
        .filter((child) => child.id === childId)
        .map((child) => ({ ...child, name: child.name.trim(), group: "Administrator" }));
    }
    return ["object-browser", "buckets", "policies"].includes(item.id ?? "")
      ? [item]
      : [];
  });

''' + anchor))

# Dung assets chinh thuc da bien dich; khong can tai lai ca toolchain frontend cu.
text = bundle.read_text()
start = text.index('return[{group:"User",name:"Object Browser",id:"object-browser"')
end = text.index('].reduce(((e,t)=>{const n=_(t);', start) + 1
menu = text[start:end]
if any(menu.count('id:"' + name + '"') != 1 for name in ["identity", "users", "tools", "monitorLogs"]):
    raise ValueError("Expected Identity/Users and Monitoring/Logs menus")
filter_menu = (
    '.flatMap(item=>["identity","tools"].includes(item.id)?'
    '(item.children||[]).filter(child=>child.id===(item.id==="identity"?"users":"monitorLogs"))'
    '.map(child=>({...child,name:child.name.trim(),group:"Administrator"})):'
    '["object-browser","buckets","policies"].includes(item.id)?[item]:[])'
)
text = text[:end] + filter_menu + text[end:]

# Asset moi co ten theo noi dung de trinh duyet khong giu menu cu trong cache.
old_map = bundle.with_suffix(".js.map")
text = text.replace("//# sourceMappingURL=" + old_map.name, "")
new_name = "main." + hashlib.sha256(text.encode()).hexdigest()[:8] + ".js"
new_bundle = bundle.with_name(new_name)
new_bundle.write_text(text)
old_path = str(bundle.relative_to(build))
new_path = str(new_bundle.relative_to(build))
index = build / "index.html"
index.write_text(index.read_text().replace(old_path, new_path))
manifest_file = build / "asset-manifest.json"
manifest = json.loads(manifest_file.read_text())
manifest["files"] = {
    key: value.replace(old_path, new_path)
    for key, value in manifest["files"].items()
    if value.removeprefix("./").removeprefix("/") != str(old_map.relative_to(build))
}
manifest["entrypoints"] = [value.replace(old_path, new_path) for value in manifest["entrypoints"]]
manifest_file.write_text(json.dumps(manifest, indent=2) + "\n")
bundle.unlink()
old_map.unlink(missing_ok=True)
print("Console sidebar: Object Browser, Buckets, Policies, Users, Logs; native Sign Out retained")
