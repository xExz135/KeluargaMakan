/**
 * Structured logs. Fields are limited to scalar values chosen by the caller,
 * and callers log only request IDs, route patterns, status codes and error
 * codes or class names: never bodies, headers, contact details, codes,
 * tokens or health data (T-016 L2, DAT-08).
 */
export type LogFields = Readonly<Record<string, string | number | boolean | null>>;

export interface ApiLogger {
  info(event: string, fields?: LogFields): void;
  error(event: string, fields?: LogFields): void;
}

export const jsonLogger: ApiLogger = {
  info(event, fields = {}) {
    process.stdout.write(`${JSON.stringify({ level: "info", event, ...fields })}\n`);
  },
  error(event, fields = {}) {
    process.stderr.write(`${JSON.stringify({ level: "error", event, ...fields })}\n`);
  },
};

export const silentLogger: ApiLogger = { info: () => undefined, error: () => undefined };
