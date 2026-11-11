import { isDevelopmentEnv, resolveAppEnv } from "../app-env.js";

/**
 * ACC-01, INT-13: the code-sending provider sits behind this adapter. No SMS or
 * email vendor is chosen yet (QUESTIONS #16): no personal data goes to a third
 * party until the owner approves one and its terms. Until then:
 *
 * - `DevCodeSender` keeps codes in memory for local development and tests. It
 *   is refused outside `APP_ENV` local and test.
 * - `UnavailableCodeSender` (the default everywhere else) refuses to send, so
 *   phone and email sign-in answer 503 `sign_in_method_unavailable`.
 *
 * A real vendor adapter implements `SignInCodeSender`. It receives only what
 * the message needs: never a name, household data or health data.
 */
export interface SignInCodeMessage {
  readonly challengeId: string;
  readonly channel: "phone" | "email";
  readonly destination: string;
  readonly code: string;
  readonly language: "id" | "en";
  readonly expiresAt: Date;
}

export interface SignInCodeSender {
  /** Throws `CodeSenderUnavailableError` when the code cannot be sent. */
  send(message: SignInCodeMessage): Promise<void>;
}

export class CodeSenderUnavailableError extends Error {
  constructor(options?: { cause?: unknown }) {
    // Fixed text: never the destination or the code.
    super("The sign-in code could not be sent", options);
    this.name = "CodeSenderUnavailableError";
  }
}

export class UnavailableCodeSender implements SignInCodeSender {
  send(): Promise<void> {
    return Promise.reject(new CodeSenderUnavailableError());
  }
}

/** Development mock. Codes stay in this process; nothing is sent anywhere. */
export class DevCodeSender implements SignInCodeSender {
  readonly #outbox: SignInCodeMessage[] = [];
  readonly #onSend: ((message: SignInCodeMessage) => void) | null;

  constructor(options: {
    readonly appEnv: string | undefined;
    /** Local development hook, for example to print the code (never the destination). */
    readonly onSend?: (message: SignInCodeMessage) => void;
  }) {
    if (!isDevelopmentEnv(options.appEnv)) {
      throw new Error(
        `The development code sender is refused in APP_ENV ${resolveAppEnv(options.appEnv)}`,
      );
    }
    this.#onSend = options.onSend ?? null;
  }

  send(message: SignInCodeMessage): Promise<void> {
    this.#outbox.push(message);
    this.#onSend?.(message);
    return Promise.resolve();
  }

  /** The latest code sent to `destination`, for tests and local sign-in. */
  latestCode(destination: string): string | null {
    for (let i = this.#outbox.length - 1; i >= 0; i -= 1) {
      const message = this.#outbox[i];
      if (message?.destination === destination) return message.code;
    }
    return null;
  }

  get sentCount(): number {
    return this.#outbox.length;
  }
}

/**
 * `CODE_SENDER=dev` selects the development mock (local and test only); any
 * other value, or none, gives the unavailable sender.
 */
export function createCodeSender(
  env: Readonly<Record<string, string | undefined>>,
  onSend?: (message: SignInCodeMessage) => void,
): SignInCodeSender {
  const kind = env["CODE_SENDER"]?.trim() ?? "";
  if (kind === "dev") {
    return new DevCodeSender({
      appEnv: env["APP_ENV"],
      ...(onSend === undefined ? {} : { onSend }),
    });
  }
  if (kind !== "" && kind !== "none") throw new Error("CODE_SENDER must be dev or none");
  return new UnavailableCodeSender();
}
