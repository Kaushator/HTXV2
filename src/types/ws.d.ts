/**
 * Интерфейс для расширений WSS для работы с TypeScript
 */
declare module "ws" {
  export class WebSocketServer {
    constructor(options: WebSocketServerOptions);
    on(event: "connection", listener: (socket: WebSocket) => void): this;
    close(callback?: () => void): void;
  }

  export interface WebSocketServerOptions {
    server?: any;
    port?: number;
  }

  export class WebSocket {
    on(event: "message", listener: (data: any) => void): this;
    on(event: "close", listener: () => void): this;
    send(data: string | Buffer): void;
    close(): void;
    readyState: number;
    static readonly OPEN: number;
  }

  export default WebSocketServer;
}
