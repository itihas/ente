import { encryptBoxWithRecoveryKey } from "ente-auth-wasm";
import { ensureAuthenticatedSession } from "./authenticated-session";

export const encryptWithRecoveryKey = async (data: string) =>
    encryptBoxWithRecoveryKey(await ensureAuthenticatedSession(), data);
