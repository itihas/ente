import { useAuthPageConfig } from "ente-accounts/components/auth/AuthPageProvider";
import { RecoverAccountForm } from "ente-accounts/components/auth/RecoveryForm";
import {
    savedKeyAttributes,
    savedPartialLocalUser,
} from "ente-accounts/services/accounts-db";
import { decryptBox } from "ente-accounts/services/crypto";
import { saveMasterKeyInSessionAndSafeStore } from "ente-accounts/services/prelogin-session";
import { recoveryKeyFromMnemonic } from "ente-accounts/services/recovery-key";
import { appHomeRoute, stashRedirect } from "ente-accounts/services/redirect";
import type { KeyAttributes } from "ente-accounts/services/user";
import {
    decryptAndStoreTokenIfNeeded,
    sendOTT,
} from "ente-accounts/services/user";
import type { SingleInputFormProps } from "ente-base/components/SingleInputForm";
import log from "ente-base/log";
import { haveMasterKeyInSession } from "ente-base/session-storage";
import { t } from "i18next";
import { useRouter } from "next/router";
import { useCallback, useEffect, useState } from "react";

export interface RecoverAccountPresentationProps {
    onSubmit: SingleInputFormProps["onSubmit"];
    onBack: () => void;
}

const Page: React.FC = () => {
    const { Shell } = useAuthPageConfig();

    const [keyAttributes, setKeyAttributes] = useState<
        KeyAttributes | undefined
    >(undefined);

    const router = useRouter();

    useEffect(() => {
        void (async () => {
            const user = savedPartialLocalUser();
            if (!user?.email) {
                await router.replace("/");
                return;
            }

            if (!user.encryptedToken && !user.token) {
                await sendOTT(user.email, undefined);
                stashRedirect("/recover");
                await router.replace("/verify");
                return;
            }

            const keyAttributes = savedKeyAttributes();
            if (!keyAttributes) {
                await router.replace("/generate");
            } else if (haveMasterKeyInSession()) {
                await router.replace(appHomeRoute);
            } else {
                setKeyAttributes(keyAttributes);
            }
        })();
    }, [router]);

    const handleSubmit: SingleInputFormProps["onSubmit"] = useCallback(
        async (recoveryKeyMnemonic: string, setFieldError) => {
            try {
                const keyAttr = keyAttributes!;
                const masterKey = await decryptBox(
                    {
                        encryptedData:
                            keyAttr.masterKeyEncryptedWithRecoveryKey!,
                        nonce: keyAttr.masterKeyDecryptionNonce!,
                    },
                    await recoveryKeyFromMnemonic(recoveryKeyMnemonic),
                );
                await saveMasterKeyInSessionAndSafeStore(masterKey);
                await decryptAndStoreTokenIfNeeded(keyAttr, masterKey);

                void router.push("/change-password?op=reset");
            } catch (e) {
                log.error("Master key recovery failed", e);
                setFieldError(t("incorrect_recovery_key"));
            }
        },
        [router, keyAttributes],
    );

    return (
        <Shell contentWidth={420}>
            <RecoverAccountForm onSubmit={handleSubmit} onBack={router.back} />
        </Shell>
    );
};

export default Page;
