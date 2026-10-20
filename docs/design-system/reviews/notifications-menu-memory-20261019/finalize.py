"""Freeze the verified sources and record the exact limits of the local review."""

import difflib
import hashlib
import json
import os
from pathlib import Path
import subprocess

ART = Path(__file__).resolve().parent
ROOT = ART.parents[3]


def read_json(name):
    return json.loads((ART / name).read_text())


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


reports = {phase: read_json(f"browser-{phase}.json") for phase in ["layout", "memory", "regression"]}
assert all(report["passed"] for report in reports.values()), "Finish the browser phases before freezing results"
assert read_json("lint-status.json")["exit_code"] == 0
assert read_json("lint-focus-status.json")["exit_code"] == 0
compilation = read_json("compilation.json")
assert all(entry["compiled"] for entry in compilation)
for entry in compilation:
    assert hashlib.sha256((ROOT / entry["file"]).read_bytes()).hexdigest() == entry["sha256"]
style = read_json("style-compilation.json")
assert style["passed"]
assert hashlib.sha256((ROOT / "themes/isbf-campus-feed/common/common.scss").read_bytes()).hexdigest() == style["common_scss_sha256"]
native = read_json("native-test-attempts.json")
for suite in ["rspec", "qunit"]:
    result = native[suite]
    assert result["exit_code"] == 0 or (
        result.get("tests_executed") == 0 and result.get("blocked_reason")
    ), f"Resolve the {suite} failure before freezing the implementation"

source_dir = ART / "source"
source_dir.mkdir(exist_ok=True)
entries = []
for name in sorted(read_json("changed-files.json")):
    data = (ROOT / name).read_bytes()
    snapshot = "source/" + name.replace("/", "__") + ".txt"
    (ART / snapshot).write_bytes(data)
    entries.append({"path": name, "sha256": hashlib.sha256(data).hexdigest(), "snapshot": snapshot})
source_version = hashlib.sha256(json.dumps([{key: entry[key] for key in ["path", "sha256"]} for entry in entries], sort_keys=True).encode()).hexdigest()
write_json(ART / "source-manifest.json", {
    "source_version": source_version,
    "scope": "Notification menu intrinsic width and account-persisted unread filtering; A05/C06/C18/C19 refinement",
    "design_status": "design_confirmed_final_visual_pending",
    "deployed": False,
    "files": entries,
})
patch = []
for entry in read_json("before-manifest.json"):
    before = (ART / entry["snapshot"]).read_bytes()
    assert hashlib.sha256(before).hexdigest() == entry["sha256"]
    after = (ROOT / entry["file"]).read_bytes()
    patch.extend(difflib.unified_diff(before.decode().splitlines(keepends=True), after.decode().splitlines(keepends=True), fromfile="before/" + entry["file"], tofile="after/" + entry["file"]))
(ART / "implementation.patch").write_text("".join(patch))

environment = dict(os.environ)
for key in ["DOCKER_HOST", "DOCKER_CONTEXT", "DOCKER_TLS", "DOCKER_TLS_VERIFY", "DOCKER_CERT_PATH"]:
    environment.pop(key, None)
docker = ["docker", "--host=unix:///var/run/docker.sock"]
tools = subprocess.run(docker + ["ps", "--all", "--format={{.Names}}"], env=environment, capture_output=True, text=True, check=True)
preview = subprocess.run(docker + ["inspect", "--format={{.State.Status}}", "isbf_frontend_preview_20261012"], env=environment, capture_output=True, text=True, check=True)
assert "isbf_notifications_menu_memory_tools_20261019" not in tools.stdout.splitlines() and preview.stdout.strip() == "exited"
cleanup = {"task_tool_removed": True, "preview_forum_state": "exited", "production_backend_used": False}
write_json(ART / "cleanup.json", cleanup)
executions = [json.loads(line) for line in (ART / "tool-executions.jsonl").read_text().splitlines()]
write_json(ART / "verification-summary.json", {
    "implementation_checks_passed": True,
    "source_version": source_version,
    "source_snapshots": len(entries),
    "source_hashes_match_compiled_inputs": True,
    "lint_passed": True,
    "javascript_compilation_files": len(compilation),
    "style_compilation": style,
    "browser_assertions": sum(len(report["checks"]) for report in reports.values()),
    "browser_phases": {phase: {"passed": report["passed"], "assertions": len(report["checks"]), "harness_sha256": report["harness_sha256"]} for phase, report in reports.items()},
    "responsive_layouts": len(reports["layout"]["layouts"]),
    "menu_widths": sorted({item["width"] for item in reports["layout"]["layouts"]}),
    "native_test_attempts": native,
    "tool_runs": len(executions),
    "successful_runs": sum(item["exit_code"] == 0 for item in executions),
    "minimum_host_available_bytes": min(item["minimum_host_available_bytes"] for item in executions),
    "cleanup": cleanup,
    "deployed": False,
    "final_visual_acceptance": "Pending user review of the confirmed local menu refinement",
})

manifest_path = ROOT / "docs/design-system/references/manifest.json"
manifest = json.loads(manifest_path.read_text())
supplement = {
    "id": "notifications-menu-memory-20261019",
    "change_date": "2026-10-19",
    "status": "design_confirmed_final_visual_pending",
    "scope": "A05/C06/C18/C19 notification menu content width and account-persisted unread filter",
    "evidence": "../reviews/notifications-menu-memory-20261019/README.md",
    "source_manifest": "../reviews/notifications-menu-memory-20261019/source-manifest.json",
    "source_version": source_version,
    "excluded": ["notification delivery", "other menus", "production deployment"],
}
manifest["supplements"] = [item for item in manifest["supplements"] if item.get("id") != supplement["id"]] + [supplement]
write_json(manifest_path, manifest)
assertions = sum(len(report["checks"]) for report in reports.values())
readme_path = ART / "README.md"
readme = readme_path.read_text().split("\n## 最终验证结果\n", 1)[0]
readme += f"""
## 最终验证结果

- 实际来源版本`{source_version}`，保存{len(entries)}份源码及测试附件；编译输入摘要与最终工作区一致。
- 定向`bin/lint --fix`通过ESLint、Prettier、Stylelint、RuboCop和Syntax Tree；重试焦点修复后再次通过受影响文件的lint。
  只读`.git`使钩子自动同步被跳过，实际源码检查全部通过，仓库钩子及CI门禁未改动。
- {len(compilation)}份JavaScript/Glimmer源码及测试编译通过，完整公共SCSS及导入、明暗色板和中英文翻译编译/解析通过。
- 三个完成的离线客户端阶段共{assertions}项断言通过，包含8组菜单布局、账号选择的保存/失败/重试/刷新/新手机客户端/账号切换/空态/旧请求竞态，以及两端原生整行点击、键盘与角标偏好。
- 原生RSpec和QUnit的实际执行状态见`native-test-attempts.json`；本机缺少Ruby测试依赖及隔离Rails测试服务，执行0项，不计作通过。新增请求及组件测试保存供完整测试环境运行。
- 早期资源时限、RTL夹具上下文及重试焦点问题保留于`attempts/`和工具记录；最终阶段全部重跑通过。
  浏览器报告中的500来自合成保存失败，外部域名由离线规则阻止；没有JavaScript运行异常或缺失本地脚本/样式。
- 工具容器已移除，完整预览论坛保持停止；仅完成实现及本地验证，尚未上线。
"""
readme_path.write_text(readme)
print(json.dumps({"source_version": source_version, "source_snapshots": len(entries), "browser_checks": sum(len(report["checks"]) for report in reports.values()), "cleanup": cleanup}))
