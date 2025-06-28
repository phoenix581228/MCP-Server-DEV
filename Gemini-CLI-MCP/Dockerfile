FROM python:3.12-slim

# 設置工作目錄
WORKDIR /app

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 複製需求文件並安裝 Python 依賴
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 複製源代碼
COPY src/ ./src/
COPY docker/ ./docker/

# 設置權限
RUN chmod +x docker/docker-entrypoint.sh docker/healthcheck.sh

# 建立非 root 用戶
RUN useradd -m -u 1000 mcpuser && chown -R mcpuser:mcpuser /app
USER mcpuser

# 暴露端口（如果需要 HTTP 模式）
EXPOSE 8080

# 設置入口點
ENTRYPOINT ["docker/docker-entrypoint.sh"]

# 預設命令
CMD ["python", "src/gemini_mcp_server.py"]