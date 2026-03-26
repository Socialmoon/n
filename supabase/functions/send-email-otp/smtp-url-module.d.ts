declare module "https://deno.land/x/smtp/mod.ts" {
  export interface ConnectTLSOptions {
    hostname: string;
    port: number;
    username: string;
    password: string;
  }

  export interface SendOptions {
    from: string;
    to: string;
    subject: string;
    content?: string;
    html?: string;
  }

  export class SmtpClient {
    connectTLS(options: ConnectTLSOptions): Promise<void>;
    send(options: SendOptions): Promise<void>;
    close(): Promise<void>;
  }
}
