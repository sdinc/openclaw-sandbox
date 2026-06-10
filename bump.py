#!/usr/bin/env python3

##### requires github auth
###################################
# import subprocess
# import base64
# import json
#
# BRANCH = "dependabot/docker/docker-d2aca8dafa"
# REPO = "sdinc/openclaw-sandbox"
# OLD = "2026.5.27"
# NEW = "2026.6.1"
#
# def gh(method, endpoint, **fields):
#     cmd = ["gh", "api", "-X", method, endpoint]
#     for k, v in fields.items():
#         cmd += ["-f", f"{k}={v}"]
#     result = subprocess.run(cmd, capture_output=True, text=True, check=True)
#     return json.loads(result.stdout)
#
# for filename in ["Makefile", "pyproject.toml", "package.json"]:
#     print(f"Updating {filename}...")
#     data = gh("GET", f"repos/{REPO}/contents/{filename}?ref={BRANCH}")
#     sha = data["sha"]
#     content = base64.b64decode(data["content"]).decode().replace(OLD, NEW)
#     encoded = base64.b64encode(content.encode()).decode()
#     gh("PUT", f"repos/{REPO}/contents/{filename}",
#        message=f"chore: bump openclaw_version to {NEW}",
#        content=encoded,
#        sha=sha,
#        branch=BRANCH)
#     print(f"✅ {filename} updated")
#
# print("🎉 All files updated — CI should pass now!")
###################################

##### very simple version
###################################
# from pathlib import Path
#
# OLD = "2026.5.27"
# NEW = "2026.6.1"
#
# for filename in ["Makefile", "pyproject.toml", "package.json"]:
#     print(f"Updating {filename}...")
#     p = Path(filename)
#     p.write_text(p.read_text().replace(OLD, NEW))
#     print(f"✅ {filename} updated")
#
# print("🎉 Done! Run: git add Makefile pyproject.toml package.json && git commit -m 'chore: bump openclaw_version to 2026.6.1'")

#!/usr/bin/env python3
import re
import urllib.request
import json
from pathlib import Path

def get_dockerfile_version():
    content = Path("Dockerfile").read_text()
    match = re.search(r'FROM ghcr\.io/openclaw/openclaw:(\d+\.\d+\.\d+)-amd64', content)
    return match.group(1) if match else None

def get_file_version(filename, pattern):
    try:
        content = Path(filename).read_text()
        match = re.search(pattern, content)
        return match.group(1) if match else None
    except FileNotFoundError:
        return None

def get_latest_release():
    url = "https://api.github.com/repos/openclaw/openclaw/releases/latest"
    req = urllib.request.Request(url, headers={"Accept": "application/vnd.github+json"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())
    tag = data["tag_name"]  # e.g. "2026.6.1-beta.1" or "2026.6.1"
    match = re.search(r'(\d+\.\d+\.\d+)', tag)
    return match.group(1) if match else tag

files = {
    "Dockerfile":     r'FROM ghcr\.io/openclaw/openclaw:(\d+\.\d+\.\d+)-amd64',
    "Makefile":       r'OPENCLAW_VERSION \?= (\d+\.\d+\.\d+)',
    "package.json":   r'"openclaw_version":\s*"(\d+\.\d+\.\d+)"',
    "pyproject.toml": r'openclaw_version = "(\d+\.\d+\.\d+)"',
}

print("📋 Current versions found in files:")
for filename, pattern in files.items():
    version = get_file_version(filename, pattern)
    print(f"  {filename:<20} {version or '❌ not found'}")

current = get_dockerfile_version()
print(f"\n🔍 Dockerfile version (source of truth): {current}")

print("\n🌐 Checking latest openclaw release...")
try:
    latest = get_latest_release()
    print(f"🏷️  Latest release: {latest}")
except Exception as e:
    print(f"⚠️  Could not fetch latest release: {e}")
    latest = None

if latest and latest == current:
    print("\n✅ Already on the latest version!")
elif latest:
    print(f"\n⬆️  New version available: {current} → {latest}")
    answer = input("Would you like to update all files to the latest version? [y/N] ").strip().lower()
    if answer == "y":
        for filename, pattern in files.items():
            p = Path(filename)
            updated = p.read_text().replace(current, latest)
            p.write_text(updated)
            print(f"  ✅ {filename} updated")
        print(f"\n🎉 Done! Run: git add Makefile pyproject.toml package.json Dockerfile && git commit -m 'chore: bump openclaw_version to {latest}'")
    else:
        print("👋 No changes made.")