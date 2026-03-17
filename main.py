from fastapi import FastAPI, HTTPException, Header  # 1. 导入FastAPI工具
from dotenv import load_dotenv  # 新增
import os

# ====== 新增：导入和配置AI ======
import anthropic

# ====== 加载 .env 文件（新增）======
load_dotenv()

# Railway 会自动提供 PORT 环境变量
PORT = int(os.getenv("PORT", 8000))

API_KEY = os.getenv("API_KEY")
BASE_URL = os.getenv("BASE_URL")
API_PASSWORD = os.getenv("API_PASSWORD")  # 新增
API_KEYS = ["user1_key", "user2_key", "Qq987654321."]


# 创建AI客户端
client = anthropic.Anthropic(api_key=API_KEY, base_url=BASE_URL)
app = FastAPI()  # 2. 创建一个应用实例
# 这是一个列表，用来存对话历史
chat_history = []


@app.get("/")  # 3. 装饰器：告诉程序"/"这个网址归我管
def root():  # 4. 定义一个函数
    return {"message": "AI聊天服务运行中"}  # 5. 返回JSON数据


# ====== 新增：密码验证函数 ======
def verify_password(authorization: str = Header(None)):
    """验证密码"""
    if authorization not in API_KEYS:
        raise HTTPException(status_code=401, detail="无效的API Key")
    # if authorization != API_PASSWORD:
    #     raise HTTPException(status_code=401, detail="密码错误")


@app.post("/chat")
def chat(request: dict, authorization: str = Header(None)):
    # 1. 验证密码
    # if authorization != API_PASSWORD:
    #     return {"error": "密码错误"}

    # 1. 获取用户的新消息
    user_message = request.get("message", "")

    # 2. 把用户消息加入历史
    chat_history.append(
        {"role": "user", "content": [{"type": "text", "text": user_message}]}
    )

    # 3. 调用AI（把历史消息一起发送）
    response = client.messages.create(
        model="MiniMax-M2.5",
        max_tokens=1000,
        system="你是一个有帮助的助手",
        messages=chat_history,  # 关键：传入历史！
    )

    # 4. 提取AI回复
    reply = ""
    for block in response.content:
        if block.type == "text":
            reply = block.text
            break

    # 5. 把AI回复也加入历史
    chat_history.append(
        {"role": "assistant", "content": [{"type": "text", "text": reply}]}
    )

    # 6. 返回
    return {"reply": reply}


@app.post("/clear")
def clear_history():
    """清空对话历史"""
    global chat_history
    chat_history = []
    return {"message": "历史已清空"}


# 在启动时使用
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=PORT)
