#!/usr/bin/env bash
set -euo pipefail

# ===== 可配置项 =====
REMOTE_HOST="root@60.205.9.246"
REMOTE_DIR="/root/var/www/chatmanage/ai-chat-api"
BRANCH="main"
COMMIT_MSG="${1:-deploy: update}"

echo "开始部署..."
echo "远程: ${REMOTE_HOST}"
echo "目录: ${REMOTE_DIR}"
echo "分支: ${BRANCH}"

# ===== 本地提交并推送 =====
git add .

# 如果没有改动，避免 commit 报错
if git diff --cached --quiet; then
  echo "没有检测到需要提交的改动，跳过 commit。"
else
  git commit -m "${COMMIT_MSG}"
fi

git push origin "${BRANCH}"

# ===== 远程拉取并部署 =====
ssh "${REMOTE_HOST}" << EOF
set -e
cd "${REMOTE_DIR}"

echo "服务器正在拉取最新代码..."
git pull origin "${BRANCH}"

# 可选：安装依赖
if [ -f requirements.txt ]; then
  echo "安装 Python 依赖..."
  pip3 install -r requirements.txt
fi

# ===== 按你的实际启动方式，保留一种即可 =====
# 1) systemd 服务（推荐）
# sudo systemctl restart your_service_name

# 2) supervisor
# supervisorctl restart your_program_name

# 3) gunicorn 手动（示例，按实际命令改）
# pkill -f gunicorn || true
# nohup gunicorn -b 0.0.0.0:8000 main:app > /var/log/ai-chat-api.log 2>&1 &

echo "远程部署步骤完成。"
EOF

echo "部署完成！"