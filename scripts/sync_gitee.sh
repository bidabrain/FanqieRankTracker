#!/usr/bin/env bash
# 把最新数据接口（api/lastest.json 和 api/lastest/）强推到 Gitee 镜像仓库，供国内设备用 raw 地址取榜单。
# 每次只推一个只含这些文件的新提交（不带 data/ 和历史），Gitee 仓库始终只有几 MB。
# all.json 超过 1 MB，Gitee raw 要登录才能下，不推。
# 需要：Secret GITEE_TOKEN（Gitee 私人令牌）、Variable GITEE_REPO（如 用户名/FanqieRankTracker）；
# 可选 Variable GITEE_USER（令牌所属用户名，默认取 GITEE_REPO 的前半段）。没配就跳过。
set -euo pipefail

if [ -z "${GITEE_TOKEN:-}" ] || [ -z "${GITEE_REPO:-}" ]; then
  echo "未配置 GITEE_TOKEN / GITEE_REPO，跳过 Gitee 同步"
  exit 0
fi
if [ ! -f api/lastest/index.json ]; then
  echo "::error::api/lastest/index.json 不存在，不同步"
  exit 1
fi

user="${GITEE_USER:-${GITEE_REPO%%/*}}"
date=$(python3 -c 'import json;print(json.load(open("api/lastest/index.json")).get("date",""))')
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/api"
cp api/lastest.json "$tmp/api/" 2>/dev/null || true
cp -R api/lastest "$tmp/api/"
rm -f "$tmp/api/lastest/all.json"
cat > "$tmp/README.md" <<EOF
# FanqieRankTracker 数据镜像

由 GitHub 仓库 ${GITHUB_REPOSITORY:-FanqieRankTracker} 每天自动同步，只含最新数据接口，不含历史和全量 all.json。
数据日期：${date}
EOF

cd "$tmp"
git init -q -b main
git add -A
git -c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
  commit -q -m "Sync ranks ${date}"
git push -q --force "https://${user}:${GITEE_TOKEN}@gitee.com/${GITEE_REPO}.git" main
echo "✅ 已同步 ${date} 到 gitee.com/${GITEE_REPO}"
