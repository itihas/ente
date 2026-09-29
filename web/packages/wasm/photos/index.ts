import type {
    EncryptedBox,
    OpenSessionInput,
    Session,
    WrappedRootContactKey,
} from "./pkg/ente_photos_wasm";

export type { OpenSessionInput, Session } from "./pkg/ente_photos_wasm";

const wasm = () => import("./pkg/ente_photos_wasm");

export const openSession = async (input: OpenSessionInput): Promise<Session> =>
    (await wasm()).openSession(input);

export const recoveryKeyMnemonic = async (session: Session) =>
    (await wasm()).authRecoveryKeyMnemonic(session);

export const encryptBoxWithRecoveryKey = async (
    session: Session,
    dataB64: string,
) => (await wasm()).authEncryptWithRecoveryKey(session, dataB64);

export const generateKey = async () => (await wasm()).cryptoGenerateKey();

export const encryptBox = async (dataB64: string, keyB64: string) =>
    (await wasm()).cryptoEncryptBox(dataB64, keyB64);

export const decryptBox = async (box: EncryptedBox, keyB64: string) =>
    (await wasm()).cryptoDecryptBox(box.encryptedData, box.nonce, keyB64);

export const contactsGetDiff = async (
    session: Session,
    wrappedRootContactKey: WrappedRootContactKey | undefined,
    sinceTime: number,
    limit: number,
) =>
    (await wasm()).contactsGetDiff(
        session,
        wrappedRootContactKey?.encryptedKey,
        wrappedRootContactKey?.header,
        BigInt(sinceTime),
        limit,
    );

export const contactsGetProfilePicture = async (
    session: Session,
    wrappedRootContactKey: WrappedRootContactKey | undefined,
    contactID: string,
) =>
    (await wasm()).contactsGetProfilePicture(
        session,
        wrappedRootContactKey?.encryptedKey,
        wrappedRootContactKey?.header,
        contactID,
    );

export const openCollectionKey = async (
    session: Session,
    ownerID: number,
    encryptedKey: string,
    keyDecryptionNonce?: string,
) =>
    (await wasm()).collectionsOpenKey(
        session,
        BigInt(ownerID),
        encryptedKey,
        keyDecryptionNonce,
    );

export const prepareCastPayload = async (
    publicKey: string,
    pqPublicKey: string | undefined,
    collectionID: number,
    collectionKey: string,
) =>
    (await wasm()).castPreparePayload(
        publicKey,
        pqPublicKey,
        BigInt(collectionID),
        collectionKey,
    );
