import { deriveKey } from "ente-base/crypto";
import {
    authenticatedPublicAlbumsDeviceLimitRequestHeaders,
    authenticatedPublicAlbumsInfoRequestHeaders,
    authenticatedPublicAlbumsRequestHeaders,
    ensureOk,
    linkDeviceTokenFromResponse,
    type PublicAlbumsCredentials,
} from "ente-base/http";
import { apiURL } from "ente-base/origins";
import {
    decryptRemoteCollection,
    RemoteCollection,
    type Collection,
    type PublicURL,
} from "ente-media/collection";
import {
    decryptRemoteFile,
    FileDiffResponse,
    type EnteFile,
} from "ente-media/file";
import { z } from "zod";
import {
    removePublicCollectionAccessTokenJWT,
    removePublicCollectionFiles,
    removePublicCollectionLastSyncTime,
    savedPublicCollectionFiles,
    savedPublicCollectionLastSyncTime,
    saveLastPublicCollectionReferralCode,
    savePublicCollection,
    savePublicCollectionFiles,
    savePublicCollectionLastSyncTime,
} from "../storage/public-albums-fdb";

export const verifyPublicAlbumPassword = async (
    publicURL: PublicURL,
    password: string,
    accessToken: string,
) => {
    const passwordHash = await deriveKey(
        password,
        // TODO: Fix the types to not require the bang.
        publicURL.nonce!,
        publicURL.opsLimit!,
        publicURL.memLimit!,
    );

    const res = await fetch(
        await apiURL("/public-collection/verify-password"),
        {
            method: "POST",
            headers: authenticatedPublicAlbumsRequestHeaders({ accessToken }),
            body: JSON.stringify({ passHash: passwordHash }),
        },
    );
    ensureOk(res);
    return z.object({ jwtToken: z.string() }).parse(await res.json()).jwtToken;
};

export const pullCollection = async (
    credentials: PublicAlbumsCredentials,
    collectionKey: string,
): Promise<{
    collection: Collection;
    referralCode: string;
    linkDeviceToken?: string;
}> => {
    // The collection key comes from the URL fragment. Never send it to remote.
    const {
        collection: remoteCollection,
        referralCode,
        linkDeviceToken,
    } = await getPublicCollectionInfo(credentials);

    const collection = await decryptRemoteCollection(
        remoteCollection,
        collectionKey,
    );

    await savePublicCollection(collection);
    await saveLastPublicCollectionReferralCode(referralCode);

    return { collection, referralCode, linkDeviceToken };
};

const PublicCollectionInfo = z.object({
    collection: RemoteCollection,
    referralCode: z.string(),
});

const getPublicCollectionInfo = async (
    credentials: PublicAlbumsCredentials,
) => {
    const res = await fetch(await apiURL("/public-collection/info"), {
        headers: authenticatedPublicAlbumsInfoRequestHeaders(credentials),
    });
    ensureOk(res);
    const info = PublicCollectionInfo.parse(await res.json());
    return { ...info, linkDeviceToken: linkDeviceTokenFromResponse(res) };
};

export const pullPublicCollectionFiles = async (
    credentials: PublicAlbumsCredentials,
    collection: Collection,
    // Files passed here have no defined order.
    onSetFiles: (files: EnteFile[]) => void,
) => {
    const { accessToken } = credentials;

    let sinceTime = (await savedPublicCollectionLastSyncTime(accessToken)) ?? 0;

    // Remote advances collection.updationTime whenever a file changes.
    if (sinceTime == collection.updationTime) return;

    const files = await savedPublicCollectionFiles(accessToken);
    const filesByID = new Map(files.map((f) => [f.id, f]));
    let callbackInvoked = false;

    while (true) {
        const { diff, hasMore } = await getPublicCollectionDiff(
            credentials,
            sinceTime,
        );
        if (!diff.length) {
            // An empty first page must still publish the cached files.
            if (!callbackInvoked) {
                onSetFiles(files);
            }
            break;
        }
        for (const change of diff) {
            sinceTime = Math.max(sinceTime, change.updationTime);
            if (change.isDeleted) {
                filesByID.delete(change.id);
            } else {
                filesByID.set(
                    change.id,
                    await decryptRemoteFile(change, collection.key),
                );
            }
        }

        const updatedFiles = [...filesByID.values()];
        await savePublicCollectionFiles(accessToken, updatedFiles);
        await savePublicCollectionLastSyncTime(accessToken, sinceTime);
        onSetFiles(updatedFiles);
        callbackInvoked = true;

        if (!hasMore) break;
    }
};

const getPublicCollectionDiff = async (
    credentials: PublicAlbumsCredentials,
    sinceTime: number,
) => {
    const res = await fetch(
        await apiURL("/public-collection/diff", { sinceTime }),
        {
            headers:
                authenticatedPublicAlbumsDeviceLimitRequestHeaders(credentials),
        },
    );
    ensureOk(res);
    return FileDiffResponse.parse(await res.json());
};

export const removePublicCollectionFileData = async (accessToken: string) => {
    await Promise.all([
        removePublicCollectionAccessTokenJWT(accessToken),
        removePublicCollectionLastSyncTime(accessToken),
        removePublicCollectionFiles(accessToken),
    ]);
};
