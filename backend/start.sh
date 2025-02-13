#!/bin/bash

# 加载环境变量
export BACKEND_PORT=${BACKEND_PORT:-5001}

# 启动 Uvicorn
uvicorn app:app --host 0.0.0.0 --port $BACKEND_PORT