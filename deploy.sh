#!/usr/bin/env bash
set -euo pipefail

# ===== 可配置项 =====
REMOTE_HOST="root@60.205.9.246"
REMOTE_DIR="/root/root/var/www/chatmanage/ai-chat-api"
BRANCH="main"
COMMIT_MSG="${1:-deploy: update}"

APP_PORT="8002"
APP_START_CMD="gunicorn main:app --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:${APP_PORT}"
HEALTH_URL="http://127.0.0.1:${APP_PORT}"

echo "开始部署..."
echo "远程: ${REMOTE_HOST}"
echo "目录: ${REMOTE_DIR}"
echo "分支: ${BRANCH}"

# ===== 本地提交并推送 =====
git add .

if git diff --cached --quiet; then
  echo "没有检测到需要提交的改动，跳过 commit。"
else
  git commit -m "${COMMIT_MSG}"
fi

git push origin "${BRANCH}"

# ===== 远程拉取并部署 =====
ssh "${REMOTE_HOST}" << EOF
set -euo pipefail
cd "${REMOTE_DIR}"

echo "停止旧服务(如果存在)..."
# 只匹配当前应用启动特征，避免误杀其他 gunicorn/uvicorn
OLD_PIDS=\$(pgrep -f "gunicorn main:app.*--bind 0.0.0.0:${APP_PORT}" || true)
if [ -n "\${OLD_PIDS}" ]; then
  echo "发现旧进程: \${OLD_PIDS}"
  kill \${OLD_PIDS} || true
  sleep 2

  # 如果还没退出，再强制杀掉
  STILL_PIDS=\$(pgrep -f "gunicorn main:app.*--bind 0.0.0.0:${APP_PORT}" || true)
  if [ -n "\${STILL_PIDS}" ]; then
    echo "旧进程未完全退出，执行强制停止: \${STILL_PIDS}"
    kill -9 \${STILL_PIDS} || true
  fi
else
  echo "未发现旧进程，跳过停止。"
fi

echo "拉取最新代码..."
git pull origin "${BRANCH}"

# 可选：安装依赖
# if [ -f requirements.txt ]; then
#   echo "安装 Python 依赖..."
#   pip3 install -r requirements.txt
# fi

echo "启动服务..."
nohup ${APP_START_CMD} > app.log 2>&1 &

echo "健康检查中..."
for i in \$(seq 1 15); do
  if curl -fsS "${HEALTH_URL}" > /dev/null; then
    echo "✅ 部署成功!"
    exit 0
  fi
  echo "等待服务启动... (\${i}/15)"
  sleep 1
done

echo "❌ 部署失败，最近日志如下："
tail -20 app.log
exit 1
EOF

echo "部署完成！"