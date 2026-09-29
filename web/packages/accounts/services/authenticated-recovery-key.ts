interface EncryptedBox {
    encryptedData: string;
    nonce: string;
}

export const createAuthenticatedRecoveryKeyOps = <Session>({
    ensureSession,
    generateKey,
    encryptBox,
    getMnemonic,
}: {
    ensureSession: () => Promise<Session>;
    generateKey: () => Promise<string>;
    getMnemonic: (session: Session) => Promise<string>;
    encryptBox: (session: Session, data: string) => Promise<EncryptedBox>;
}) => {
    const recoveryKeyMnemonic = async () => getMnemonic(await ensureSession());

    const encryptWithRecoveryKey = async (data: string) => {
        const session = await ensureSession();
        return encryptBox(session, data);
    };

    const generatePasskeyRecovery = async () => {
        const session = await ensureSession();
        const secret = await generateKey();
        return { secret, ...(await encryptBox(session, secret)) };
    };

    return {
        encryptWithRecoveryKey,
        generatePasskeyRecovery,
        recoveryKeyMnemonic,
    };
};
