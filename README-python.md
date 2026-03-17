创建：python3 -m venv venv（macOS/Linux）/ python -m venv venv（Windows）；
进入：source venv/bin/activate（macOS/Linux）/ venv\Scripts\activate.bat（Windows）；
退出：deactivate（所有系统通用）。
优先级：优先使用内置 venv，无需额外安装，兼容性足够；仅旧版本 Python 才用 virtualenv。
关键标识：激活后终端前缀出现 (venv)，说明已进入虚拟环境，此时 pip 操作仅对该环境生效。

requirements.txt 是依赖文件