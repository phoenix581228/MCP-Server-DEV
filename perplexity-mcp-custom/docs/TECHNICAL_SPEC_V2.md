# Perplexity MCP Custom Server 2.0 技術規格

## 1. Streamable HTTP Transport 實作細節

### 1.1 Transport 介面實作

完整實作 MCP Transport 介面：

```typescript
interface Transport {
  // 生命週期方法
  start(): Promise<void>;
  send(message: JSONRPCMessage): Promise<void>;
  close(): Promise<void>;
  
  // 事件回調
  onmessage?: (message: JSONRPCMessage) => void;
  onerror?: (error: Error) => void;
  onclose?: () => void;
}

class HTTPServerTransport implements Transport {
  private server: http.Server;
  private app: express.Application;
  private isStarted = false;
  
  async start(): Promise<void> {
    if (this.isStarted) {
      throw new Error('Transport already started');
    }
    
    return new Promise((resolve, reject) => {
      this.server = this.app.listen(this.options.port, this.options.host, () => {
        this.isStarted = true;
        console.log(`MCP Server listening on ${this.options.host}:${this.options.port}`);
        resolve();
      });
      
      this.server.on('error', reject);
    });
  }
  
  async send(message: JSONRPCMessage): Promise<void> {
    // 根據訊息類型決定發送策略
    if (this.isRequest(message)) {
      // 請求需要等待響應
      return this.sendRequest(message);
    } else if (this.isNotification(message)) {
      // 通知不需要響應
      return this.sendNotification(message);
    } else if (this.isResponse(message)) {
      // 響應需要匹配原始請求
      return this.sendResponse(message);
    }
  }
  
  async close(): Promise<void> {
    // 優雅關閉
    await this.closeAllConnections();
    await this.shutdownServer();
    this.isStarted = false;
  }
}
```

### 1.2 JSON-RPC 訊息處理

完整的 JSON-RPC 2.0 實作：

```typescript
interface JSONRPCMessage {
  jsonrpc: '2.0';
}

interface JSONRPCRequest extends JSONRPCMessage {
  id: string | number;
  method: string;
  params?: unknown;
}

interface JSONRPCNotification extends JSONRPCMessage {
  method: string;
  params?: unknown;
}

interface JSONRPCResponse extends JSONRPCMessage {
  id: string | number;
  result?: unknown;
  error?: JSONRPCError;
}

interface JSONRPCError {
  code: number;
  message: string;
  data?: unknown;
}

class JSONRPCProcessor {
  // 訊息類型判斷
  isRequest(msg: JSONRPCMessage): msg is JSONRPCRequest {
    return 'method' in msg && 'id' in msg;
  }
  
  isNotification(msg: JSONRPCMessage): msg is JSONRPCNotification {
    return 'method' in msg && !('id' in msg);
  }
  
  isResponse(msg: JSONRPCMessage): msg is JSONRPCResponse {
    return 'id' in msg && ('result' in msg || 'error' in msg);
  }
  
  // 批次處理支援
  async processBatch(messages: JSONRPCMessage[]): Promise<JSONRPCMessage[]> {
    const results = await Promise.allSettled(
      messages.map(msg => this.processMessage(msg))
    );
    
    return results
      .filter(r => r.status === 'fulfilled' && r.value !== null)
      .map(r => (r as PromiseFulfilledResult<JSONRPCMessage>).value);
  }
  
  // 錯誤處理
  createError(code: number, message: string, data?: unknown): JSONRPCError {
    return { code, message, data };
  }
  
  // 標準錯誤碼
  static readonly ErrorCodes = {
    PARSE_ERROR: -32700,
    INVALID_REQUEST: -32600,
    METHOD_NOT_FOUND: -32601,
    INVALID_PARAMS: -32602,
    INTERNAL_ERROR: -32603,
    // MCP 特定錯誤碼
    SESSION_NOT_FOUND: -32000,
    SESSION_EXPIRED: -32001,
    UNAUTHORIZED: -32002,
  };
}
```

### 1.3 HTTP 端點處理

統一的 MCP 端點實作：

```typescript
class MCPEndpoint {
  private readonly path = '/mcp';
  private processor: JSONRPCProcessor;
  private sessionManager: SessionManager;
  private sseManager: SSEManager;
  
  setupRoutes(app: express.Application): void {
    // 主要 MCP 端點
    app.all(this.path, this.handleMCPRequest.bind(this));
    
    // 健康檢查
    app.get('/health', this.handleHealth.bind(this));
    
    // 指標端點（可選）
    app.get('/metrics', this.handleMetrics.bind(this));
  }
  
  private async handleMCPRequest(req: Request, res: Response): Promise<void> {
    try {
      // 協議版本檢查
      const protocolVersion = req.headers['mcp-protocol-version'];
      if (protocolVersion && !this.isValidProtocolVersion(protocolVersion)) {
        return res.status(400).json({
          jsonrpc: '2.0',
          error: {
            code: -32600,
            message: `Unsupported protocol version: ${protocolVersion}`
          }
        });
      }
      
      // 路由到對應處理器
      switch (req.method) {
        case 'POST':
          await this.handlePost(req, res);
          break;
        case 'GET':
          await this.handleGet(req, res);
          break;
        case 'DELETE':
          await this.handleDelete(req, res);
          break;
        default:
          res.status(405).send('Method Not Allowed');
      }
    } catch (error) {
      this.handleError(error, res);
    }
  }
  
  private async handlePost(req: Request, res: Response): Promise<void> {
    // 驗證內容類型
    if (!req.is('application/json')) {
      return res.status(415).send('Unsupported Media Type');
    }
    
    // 驗證 Accept header
    const acceptsJSON = req.accepts('application/json');
    const acceptsSSE = req.accepts('text/event-stream');
    
    if (!acceptsJSON && !acceptsSSE) {
      return res.status(406).send('Not Acceptable');
    }
    
    // 處理訊息
    const message = req.body;
    
    if (Array.isArray(message)) {
      // 批次請求
      await this.handleBatchRequest(message, req, res);
    } else {
      // 單一請求
      await this.handleSingleRequest(message, req, res);
    }
  }
  
  private async handleSingleRequest(
    message: JSONRPCMessage,
    req: Request,
    res: Response
  ): Promise<void> {
    const sessionId = req.headers['mcp-session-id'] as string;
    
    // 處理不同類型的訊息
    if (this.processor.isResponse(message) || this.processor.isNotification(message)) {
      // 響應和通知返回 202
      if (sessionId && !this.sessionManager.validateSession(sessionId)) {
        return res.status(404).json({
          jsonrpc: '2.0',
          error: {
            code: JSONRPCProcessor.ErrorCodes.SESSION_NOT_FOUND,
            message: 'Session not found'
          }
        });
      }
      
      // 轉發給對應的處理器
      await this.forwardMessage(message, sessionId);
      res.status(202).end();
      
    } else if (this.processor.isRequest(message)) {
      // 處理請求
      const needsStreaming = await this.checkNeedsStreaming(message);
      
      if (needsStreaming && req.accepts('text/event-stream')) {
        // 初始化 SSE 流
        await this.initializeSSEResponse(message, req, res);
      } else {
        // 返回單一 JSON 響應
        const response = await this.processRequest(message, sessionId);
        res.json(response);
      }
    }
  }
}
```

## 2. 會話管理實作

### 2.1 會話生命週期

```typescript
interface SessionOptions {
  timeout?: number;              // 預設: 1 小時
  maxConnectionsPerSession?: number;  // 預設: 5
  enableResumption?: boolean;    // 預設: true
}

class SessionLifecycle {
  private sessions = new Map<string, Session>();
  private timers = new Map<string, NodeJS.Timeout>();
  
  createSession(request: InitializeRequest): Session {
    const sessionId = this.generateSecureId();
    
    const session: Session = {
      id: sessionId,
      clientInfo: request.params.clientInfo,
      capabilities: request.params.capabilities,
      protocolVersion: request.params.protocolVersion,
      createdAt: Date.now(),
      lastActivity: Date.now(),
      state: 'active',
      connections: new Set(),
      messageQueue: [],
      metadata: {}
    };
    
    this.sessions.set(sessionId, session);
    this.scheduleExpiration(sessionId);
    
    return session;
  }
  
  private scheduleExpiration(sessionId: string): void {
    const timeout = this.options.timeout || 3600000; // 1 小時
    
    const timer = setTimeout(() => {
      this.expireSession(sessionId);
    }, timeout);
    
    // 清理舊的計時器
    const oldTimer = this.timers.get(sessionId);
    if (oldTimer) {
      clearTimeout(oldTimer);
    }
    
    this.timers.set(sessionId, timer);
  }
  
  touchSession(sessionId: string): void {
    const session = this.sessions.get(sessionId);
    if (session && session.state === 'active') {
      session.lastActivity = Date.now();
      this.scheduleExpiration(sessionId);
    }
  }
  
  private expireSession(sessionId: string): void {
    const session = this.sessions.get(sessionId);
    if (session) {
      session.state = 'expired';
      
      // 通知所有連接
      this.notifyConnections(sessionId, {
        jsonrpc: '2.0',
        method: 'session/expired',
        params: { sessionId }
      });
      
      // 清理資源
      setTimeout(() => {
        this.cleanupSession(sessionId);
      }, 30000); // 30 秒後清理
    }
  }
}
```

### 2.2 會話恢復機制

```typescript
interface ResumableSession extends Session {
  resumptionToken?: string;
  messageHistory: MessageHistoryEntry[];
  lastEventId?: string;
}

class SessionResumption {
  async resumeSession(
    sessionId: string,
    resumptionToken: string,
    lastEventId?: string
  ): Promise<ResumableSession | null> {
    const session = await this.loadSession(sessionId);
    
    if (!session || session.resumptionToken !== resumptionToken) {
      return null;
    }
    
    // 恢復會話狀態
    session.state = 'active';
    session.lastActivity = Date.now();
    
    // 如果提供了 lastEventId，重播遺失的訊息
    if (lastEventId && session.messageHistory) {
      const missedMessages = this.findMissedMessages(
        session.messageHistory,
        lastEventId
      );
      
      // 將遺失的訊息加入佇列
      session.messageQueue.push(...missedMessages);
    }
    
    return session;
  }
  
  private findMissedMessages(
    history: MessageHistoryEntry[],
    lastEventId: string
  ): JSONRPCMessage[] {
    const lastIndex = history.findIndex(entry => entry.eventId === lastEventId);
    
    if (lastIndex === -1) {
      // 找不到 lastEventId，返回所有訊息
      return history.map(entry => entry.message);
    }
    
    // 返回 lastEventId 之後的所有訊息
    return history
      .slice(lastIndex + 1)
      .map(entry => entry.message);
  }
}
```

## 3. SSE 流管理實作

### 3.1 連接管理

```typescript
interface SSEConnectionOptions {
  heartbeatInterval?: number;    // 預設: 30 秒
  compressionLevel?: number;     // 預設: 6
  enableCompression?: boolean;   // 預設: true
}

class SSEConnectionManager {
  private connections = new Map<string, SSEConnection>();
  private heartbeats = new Map<string, NodeJS.Interval>();
  
  async establish(
    sessionId: string,
    req: Request,
    res: Response
  ): Promise<SSEConnection> {
    // 設置 SSE headers
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache, no-transform',
      'Connection': 'keep-alive',
      'X-Accel-Buffering': 'no',
      // 支援 CORS
      'Access-Control-Allow-Origin': req.headers.origin || '*',
      'Access-Control-Allow-Credentials': 'true',
      // 壓縮
      ...(this.options.enableCompression && {
        'Content-Encoding': 'gzip'
      })
    });
    
    const connectionId = this.generateConnectionId();
    const lastEventId = req.headers['last-event-id'] as string;
    
    const connection: SSEConnection = {
      id: connectionId,
      sessionId,
      response: res,
      request: req,
      established: Date.now(),
      lastActivity: Date.now(),
      lastEventId,
      eventIdCounter: 0,
      state: 'connected',
      metadata: {
        userAgent: req.headers['user-agent'],
        ip: req.ip,
        protocol: req.protocol
      }
    };
    
    // 處理斷開
    req.on('close', () => {
      this.handleDisconnect(connectionId);
    });
    
    req.on('error', (error) => {
      this.handleError(connectionId, error);
    });
    
    // 啟動心跳
    this.startHeartbeat(connectionId);
    
    this.connections.set(connectionId, connection);
    
    // 發送初始化事件
    await this.sendEvent(connectionId, {
      event: 'connected',
      data: {
        sessionId,
        connectionId,
        resumption: !!lastEventId
      }
    });
    
    return connection;
  }
  
  private startHeartbeat(connectionId: string): void {
    const interval = this.options.heartbeatInterval || 30000;
    
    const heartbeat = setInterval(() => {
      const conn = this.connections.get(connectionId);
      if (conn && conn.state === 'connected') {
        // 發送心跳
        conn.response.write(':heartbeat\n\n');
        
        // 檢查連接健康
        if (Date.now() - conn.lastActivity > interval * 3) {
          // 連接可能已死
          this.handleDisconnect(connectionId);
        }
      }
    }, interval);
    
    this.heartbeats.set(connectionId, heartbeat);
  }
}
```

### 3.2 事件發送優化

```typescript
interface SSEEvent {
  id?: string;
  event?: string;
  data: unknown;
  retry?: number;
}

class SSEEventSender {
  private encoder = new TextEncoder();
  private compressionStream?: CompressionStream;
  
  async sendEvent(
    connection: SSEConnection,
    event: SSEEvent
  ): Promise<void> {
    if (connection.state !== 'connected') {
      throw new Error('Connection is not active');
    }
    
    // 生成事件 ID
    const eventId = event.id || this.generateEventId(connection);
    
    // 構建事件字串
    let eventString = '';
    
    if (eventId) {
      eventString += `id: ${eventId}\n`;
      connection.lastEventId = eventId;
    }
    
    if (event.event) {
      eventString += `event: ${event.event}\n`;
    }
    
    if (event.retry) {
      eventString += `retry: ${event.retry}\n`;
    }
    
    // 序列化資料
    const dataString = JSON.stringify(event.data);
    
    // 處理多行資料
    const dataLines = dataString.split('\n');
    for (const line of dataLines) {
      eventString += `data: ${line}\n`;
    }
    
    eventString += '\n';
    
    // 寫入響應
    try {
      if (this.options.enableCompression && connection.compressionStream) {
        // 使用壓縮
        const compressed = await this.compress(eventString);
        connection.response.write(compressed);
      } else {
        // 直接寫入
        connection.response.write(eventString);
      }
      
      connection.lastActivity = Date.now();
      
      // 記錄到歷史（用於恢復）
      if (connection.session?.enableResumption) {
        this.recordToHistory(connection.sessionId, {
          eventId,
          message: event.data as JSONRPCMessage,
          timestamp: Date.now()
        });
      }
    } catch (error) {
      connection.state = 'error';
      throw error;
    }
  }
  
  private generateEventId(connection: SSEConnection): string {
    // 使用時間戳 + 計數器確保唯一性
    const timestamp = Date.now().toString(36);
    const counter = (++connection.eventIdCounter).toString(36);
    return `${timestamp}-${counter}`;
  }
}
```

## 4. 效能優化實作

### 4.1 連接池管理

```typescript
interface PoolOptions {
  maxConnections: number;
  maxConnectionsPerIP: number;
  maxConnectionsPerSession: number;
  connectionTimeout: number;
  queueTimeout: number;
}

class ConnectionPool {
  private pool = new Map<string, PooledConnection>();
  private queue: QueuedRequest[] = [];
  private ipCounts = new Map<string, number>();
  private sessionCounts = new Map<string, number>();
  
  async acquire(request: PoolRequest): Promise<PooledConnection> {
    // 檢查限制
    if (!this.checkLimits(request)) {
      throw new Error('Connection limit exceeded');
    }
    
    // 嘗試獲取可用連接
    const available = this.findAvailable(request);
    if (available) {
      return this.checkout(available);
    }
    
    // 檢查是否可以創建新連接
    if (this.pool.size < this.options.maxConnections) {
      return this.createConnection(request);
    }
    
    // 加入佇列
    return this.enqueue(request);
  }
  
  private checkLimits(request: PoolRequest): boolean {
    // IP 限制
    const ipCount = this.ipCounts.get(request.ip) || 0;
    if (ipCount >= this.options.maxConnectionsPerIP) {
      return false;
    }
    
    // 會話限制
    if (request.sessionId) {
      const sessionCount = this.sessionCounts.get(request.sessionId) || 0;
      if (sessionCount >= this.options.maxConnectionsPerSession) {
        return false;
      }
    }
    
    return true;
  }
  
  release(connection: PooledConnection): void {
    if (connection.state === 'active') {
      connection.state = 'idle';
      connection.lastActivity = Date.now();
      
      // 檢查佇列
      this.processQueue();
    } else {
      // 移除損壞的連接
      this.removeConnection(connection);
    }
  }
}
```

### 4.2 請求批次處理

```typescript
interface BatchProcessor {
  maxBatchSize: number;
  batchTimeout: number;
  maxConcurrency: number;
}

class RequestBatcher implements BatchProcessor {
  private batch: BatchedRequest[] = [];
  private batchTimer?: NodeJS.Timeout;
  private processing = false;
  
  async add(request: JSONRPCRequest): Promise<JSONRPCResponse> {
    return new Promise((resolve, reject) => {
      this.batch.push({
        request,
        resolve,
        reject,
        timestamp: Date.now()
      });
      
      // 檢查是否需要立即處理
      if (this.batch.length >= this.maxBatchSize) {
        this.processBatch();
      } else if (!this.batchTimer) {
        // 設置批次計時器
        this.batchTimer = setTimeout(() => {
          this.processBatch();
        }, this.batchTimeout);
      }
    });
  }
  
  private async processBatch(): Promise<void> {
    if (this.processing || this.batch.length === 0) {
      return;
    }
    
    this.processing = true;
    
    // 清除計時器
    if (this.batchTimer) {
      clearTimeout(this.batchTimer);
      this.batchTimer = undefined;
    }
    
    // 取出當前批次
    const currentBatch = this.batch.splice(0, this.maxBatchSize);
    
    try {
      // 並行處理
      const results = await this.executeInParallel(
        currentBatch.map(b => b.request)
      );
      
      // 分發結果
      currentBatch.forEach((item, index) => {
        const result = results[index];
        if (result.status === 'fulfilled') {
          item.resolve(result.value);
        } else {
          item.reject(result.reason);
        }
      });
    } catch (error) {
      // 批次失敗，全部拒絕
      currentBatch.forEach(item => {
        item.reject(error);
      });
    } finally {
      this.processing = false;
      
      // 如果還有待處理的請求，繼續處理
      if (this.batch.length > 0) {
        setImmediate(() => this.processBatch());
      }
    }
  }
  
  private async executeInParallel(
    requests: JSONRPCRequest[]
  ): Promise<PromiseSettledResult<JSONRPCResponse>[]> {
    // 使用 p-limit 限制並發
    const limit = pLimit(this.maxConcurrency);
    
    const promises = requests.map(request =>
      limit(() => this.processRequest(request))
    );
    
    return Promise.allSettled(promises);
  }
}
```

### 4.3 記憶體管理

```typescript
class MemoryManager {
  private heapUsageThreshold = 0.8; // 80% 堆使用率
  private gcInterval = 60000; // 1 分鐘
  private lastGC = Date.now();
  
  startMonitoring(): void {
    setInterval(() => {
      this.checkMemoryUsage();
    }, 10000); // 每 10 秒檢查
  }
  
  private checkMemoryUsage(): void {
    const usage = process.memoryUsage();
    const heapUsed = usage.heapUsed / usage.heapTotal;
    
    if (heapUsed > this.heapUsageThreshold) {
      this.performCleanup();
    }
    
    // 定期 GC
    if (Date.now() - this.lastGC > this.gcInterval) {
      if (global.gc) {
        global.gc();
        this.lastGC = Date.now();
      }
    }
  }
  
  private performCleanup(): void {
    // 清理過期會話
    this.cleanupExpiredSessions();
    
    // 清理快取
    this.reduceCacheSize();
    
    // 清理連接池
    this.cleanupIdleConnections();
    
    // 強制 GC
    if (global.gc) {
      global.gc();
    }
  }
}
```

## 5. 錯誤處理與恢復

### 5.1 錯誤分類與處理

```typescript
enum ErrorCategory {
  TRANSPORT = 'transport',
  PROTOCOL = 'protocol',
  SESSION = 'session',
  APPLICATION = 'application',
  SYSTEM = 'system'
}

class ErrorHandler {
  private errorStrategies = new Map<ErrorCategory, ErrorStrategy>();
  
  async handle(error: Error, context: ErrorContext): Promise<ErrorResponse> {
    const category = this.categorizeError(error);
    const strategy = this.errorStrategies.get(category);
    
    if (strategy) {
      return strategy.handle(error, context);
    }
    
    // 預設處理
    return this.defaultHandler(error, context);
  }
  
  private categorizeError(error: Error): ErrorCategory {
    if (error instanceof TransportError) {
      return ErrorCategory.TRANSPORT;
    } else if (error instanceof ProtocolError) {
      return ErrorCategory.PROTOCOL;
    } else if (error instanceof SessionError) {
      return ErrorCategory.SESSION;
    } else if (error instanceof ApplicationError) {
      return ErrorCategory.APPLICATION;
    } else {
      return ErrorCategory.SYSTEM;
    }
  }
}

// 錯誤恢復策略
class ErrorRecoveryStrategy {
  async recover(error: Error, context: ErrorContext): Promise<boolean> {
    switch (error.name) {
      case 'ConnectionLost':
        return this.recoverConnection(context);
      case 'SessionExpired':
        return this.recoverSession(context);
      case 'RateLimitExceeded':
        return this.handleRateLimit(context);
      default:
        return false;
    }
  }
  
  private async recoverConnection(context: ErrorContext): Promise<boolean> {
    const maxRetries = 3;
    const baseDelay = 1000;
    
    for (let i = 0; i < maxRetries; i++) {
      try {
        await this.reconnect(context);
        return true;
      } catch (error) {
        // 指數退避
        const delay = baseDelay * Math.pow(2, i);
        await this.sleep(delay);
      }
    }
    
    return false;
  }
}
```

### 5.2 斷線重連機制

```typescript
interface ReconnectionOptions {
  maxAttempts: number;
  initialDelay: number;
  maxDelay: number;
  backoffFactor: number;
  jitter: boolean;
}

class ReconnectionManager {
  private attempts = new Map<string, number>();
  private timers = new Map<string, NodeJS.Timeout>();
  
  async scheduleReconnection(
    connectionId: string,
    options: ReconnectionOptions
  ): Promise<void> {
    const attempt = this.attempts.get(connectionId) || 0;
    
    if (attempt >= options.maxAttempts) {
      // 放棄重連
      this.cleanup(connectionId);
      throw new Error('Max reconnection attempts exceeded');
    }
    
    // 計算延遲
    const delay = this.calculateDelay(attempt, options);
    
    return new Promise((resolve, reject) => {
      const timer = setTimeout(async () => {
        try {
          await this.attemptReconnection(connectionId);
          this.cleanup(connectionId);
          resolve();
        } catch (error) {
          this.attempts.set(connectionId, attempt + 1);
          // 遞迴排程下次重連
          this.scheduleReconnection(connectionId, options)
            .then(resolve)
            .catch(reject);
        }
      }, delay);
      
      this.timers.set(connectionId, timer);
    });
  }
  
  private calculateDelay(
    attempt: number,
    options: ReconnectionOptions
  ): number {
    // 指數退避
    let delay = options.initialDelay * Math.pow(options.backoffFactor, attempt);
    
    // 限制最大延遲
    delay = Math.min(delay, options.maxDelay);
    
    // 添加抖動
    if (options.jitter) {
      const jitter = delay * 0.2 * (Math.random() - 0.5);
      delay += jitter;
    }
    
    return Math.floor(delay);
  }
}
```

## 6. 監控與可觀測性

### 6.1 指標收集

```typescript
interface Metrics {
  // 連接指標
  activeConnections: number;
  totalConnections: number;
  connectionRate: number;
  
  // 會話指標
  activeSessions: number;
  sessionDuration: Histogram;
  
  // 請求指標
  requestRate: number;
  requestDuration: Histogram;
  errorRate: number;
  
  // 系統指標
  cpuUsage: number;
  memoryUsage: number;
  eventLoopDelay: number;
}

class MetricsCollector {
  private prometheus = new PrometheusClient();
  
  constructor() {
    this.setupMetrics();
    this.startCollection();
  }
  
  private setupMetrics(): void {
    // 連接指標
    this.activeConnections = new this.prometheus.Gauge({
      name: 'mcp_active_connections',
      help: 'Number of active connections'
    });
    
    // 請求持續時間直方圖
    this.requestDuration = new this.prometheus.Histogram({
      name: 'mcp_request_duration_seconds',
      help: 'Request duration in seconds',
      labelNames: ['method', 'status'],
      buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5]
    });
    
    // 錯誤計數器
    this.errorCounter = new this.prometheus.Counter({
      name: 'mcp_errors_total',
      help: 'Total number of errors',
      labelNames: ['type', 'category']
    });
  }
  
  recordRequest(method: string, duration: number, status: string): void {
    this.requestDuration.labels(method, status).observe(duration);
  }
  
  recordError(type: string, category: string): void {
    this.errorCounter.labels(type, category).inc();
  }
}
```

### 6.2 結構化日誌

```typescript
interface LogContext {
  sessionId?: string;
  connectionId?: string;
  requestId?: string;
  method?: string;
  duration?: number;
  error?: Error;
  metadata?: Record<string, unknown>;
}

class StructuredLogger {
  private winston = createWinstonLogger({
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.errors({ stack: true }),
      winston.format.json()
    ),
    transports: [
      new winston.transports.Console(),
      new winston.transports.File({ filename: 'mcp-server.log' })
    ]
  });
  
  info(message: string, context?: LogContext): void {
    this.winston.info({
      message,
      ...this.enrichContext(context)
    });
  }
  
  error(message: string, error: Error, context?: LogContext): void {
    this.winston.error({
      message,
      error: {
        name: error.name,
        message: error.message,
        stack: error.stack
      },
      ...this.enrichContext(context)
    });
  }
  
  private enrichContext(context?: LogContext): Record<string, unknown> {
    return {
      timestamp: new Date().toISOString(),
      service: 'perplexity-mcp-server',
      version: process.env.npm_package_version,
      environment: process.env.NODE_ENV,
      ...context
    };
  }
}
```

## 7. 安全實作

### 7.1 認證與授權

```typescript
interface AuthConfig {
  type: 'none' | 'bearer' | 'oauth2';
  issuer?: string;
  audience?: string;
  algorithms?: string[];
}

class AuthenticationMiddleware {
  async authenticate(req: Request): Promise<AuthContext> {
    if (this.config.type === 'none') {
      return { authenticated: true };
    }
    
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      throw new UnauthorizedError('Missing authorization header');
    }
    
    const [scheme, token] = authHeader.split(' ');
    
    if (scheme !== 'Bearer') {
      throw new UnauthorizedError('Invalid authentication scheme');
    }
    
    return this.verifyToken(token);
  }
  
  private async verifyToken(token: string): Promise<AuthContext> {
    try {
      const decoded = await this.jwtVerifier.verify(token);
      
      return {
        authenticated: true,
        subject: decoded.sub,
        scopes: decoded.scope?.split(' ') || [],
        claims: decoded
      };
    } catch (error) {
      throw new UnauthorizedError('Invalid token');
    }
  }
}
```

### 7.2 速率限制

```typescript
interface RateLimitConfig {
  windowMs: number;
  maxRequests: number;
  keyGenerator: (req: Request) => string;
  skipSuccessfulRequests?: boolean;
}

class RateLimiter {
  private limits = new Map<string, RateLimitEntry>();
  
  async checkLimit(req: Request): Promise<RateLimitResult> {
    const key = this.config.keyGenerator(req);
    const now = Date.now();
    
    let entry = this.limits.get(key);
    
    if (!entry || now - entry.windowStart > this.config.windowMs) {
      // 新視窗
      entry = {
        windowStart: now,
        requests: 0
      };
      this.limits.set(key, entry);
    }
    
    entry.requests++;
    
    if (entry.requests > this.config.maxRequests) {
      const retryAfter = Math.ceil(
        (entry.windowStart + this.config.windowMs - now) / 1000
      );
      
      return {
        allowed: false,
        retryAfter,
        limit: this.config.maxRequests,
        remaining: 0,
        reset: new Date(entry.windowStart + this.config.windowMs)
      };
    }
    
    return {
      allowed: true,
      limit: this.config.maxRequests,
      remaining: this.config.maxRequests - entry.requests,
      reset: new Date(entry.windowStart + this.config.windowMs)
    };
  }
}
```

## 結論

Perplexity MCP Custom Server 2.0 的技術規格完整實作了 MCP Streamable HTTP Transport，提供了高效能、可擴展、安全的解決方案。通過漸進式遷移策略，確保現有用戶的平滑過渡，同時為未來的功能擴展奠定基礎。