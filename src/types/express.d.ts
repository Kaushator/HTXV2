/**
 * Интерфейс для расширений Express для работы с TypeScript
 */
declare module "express" {
  export function express(): Express;

  export interface Express {
    use(middleware: any): this;
    use(path: string, middleware: any): this;
    get(path: string, handler: (req: Request, res: Response) => void): this;
    post(path: string, handler: (req: Request, res: Response) => void): this;
    put(path: string, handler: (req: Request, res: Response) => void): this;
    delete(path: string, handler: (req: Request, res: Response) => void): this;
    json(): any;
  }

  export interface Request {
    body: any;
    params: any;
    query: any;
    headers: any;
  }

  export interface Response {
    status(code: number): this;
    json(data: any): void;
    send(data: any): void;
  }

  export default function (): Express;
}
