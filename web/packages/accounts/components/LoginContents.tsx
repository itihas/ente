import { LoginForm } from "ente-accounts/components/auth/LoginForm";
import {
    replaceSavedLocalUser,
    saveSRPAttributes,
} from "ente-accounts/services/accounts-db";
import { getSRPAttributes } from "ente-accounts/services/srp";
import { sendOTT } from "ente-accounts/services/user";
import { appName } from "ente-base/app";
import { HTTPError } from "ente-base/http";
import { JOIN_ALBUM_CONTEXT_KEY } from "ente-base/join-album";
import log from "ente-base/log";
import { useFormik } from "formik";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useState } from "react";
import { z } from "zod";

interface LoginContentsProps {
    host: string | undefined;
    onSignUp: () => void;
}

export interface LoginPresentationProps {
    email: string;
    emailError: string | undefined;
    host: string | undefined;
    isSubmitting: boolean;
    isJoinAlbumContext: boolean;
    isEnsu: boolean;
    onEmailChange: React.ChangeEventHandler<
        HTMLInputElement | HTMLTextAreaElement
    >;
    onSubmit: React.SubmitEventHandler<HTMLFormElement>;
    onSignUp: () => void;
    onCancel: () => void;
}

export const LoginContents: React.FC<LoginContentsProps> = ({
    onSignUp,
    host,
}) => {
    const router = useRouter();
    const [isJoinAlbumContext, setIsJoinAlbumContext] = useState(false);
    const isEnsu = appName === "ensu";

    useEffect(() => {
        const joinAlbumContext = sessionStorage.getItem(JOIN_ALBUM_CONTEXT_KEY);
        setIsJoinAlbumContext(!!joinAlbumContext);
    }, []);

    const loginUser = useCallback(
        async (email: string, setFieldError: (message: string) => void) => {
            const srpAttributes = await getSRPAttributes(email);
            if (!srpAttributes || srpAttributes.isEmailMFAEnabled) {
                try {
                    await sendOTT(email, "login");
                } catch (e) {
                    if (e instanceof HTTPError && e.res.status === 404) {
                        let errorCode: string | undefined;
                        try {
                            errorCode = z
                                .object({ code: z.string() })
                                .parse(await e.res.json()).code;
                        } catch (parseErr) {
                            log.warn(
                                "Ignoring error when parsing error payload",
                                parseErr,
                            );
                        }
                        if (errorCode === "USER_NOT_REGISTERED") {
                            setFieldError(t("email_not_registered"));
                            return;
                        }
                        if (errorCode === "USER_SIGNUP_INCOMPLETE") {
                            setFieldError(
                                t("account_setup_incomplete_create_account"),
                            );
                            return;
                        }
                    }
                    throw e;
                }
                replaceSavedLocalUser({ email });
                void router.push("/verify");
            } else {
                replaceSavedLocalUser({ email });
                saveSRPAttributes(srpAttributes);
                void router.push("/credentials");
            }
        },
        [router],
    );

    const formik = useFormik({
        initialValues: { email: "" },
        onSubmit: async ({ email }, { setFieldError }) => {
            const setEmailFieldError = (message: string) =>
                setFieldError("email", message);

            if (!email) {
                setEmailFieldError(t("required"));
                return;
            }

            if (!z.email().safeParse(email).success) {
                setEmailFieldError(t("invalid_email_error"));
                return;
            }

            try {
                await loginUser(email, setEmailFieldError);
            } catch (e) {
                log.error("Failed to login", e);
                setEmailFieldError(t("generic_error"));
            }
        },
    });

    function handleCancel() {
        void router.push("/chat");
    }

    return (
        <LoginForm
            email={formik.values.email}
            emailError={formik.errors.email}
            host={host}
            isSubmitting={formik.isSubmitting}
            isJoinAlbumContext={isJoinAlbumContext}
            isEnsu={isEnsu}
            onEmailChange={formik.handleChange}
            onSubmit={formik.handleSubmit}
            onSignUp={onSignUp}
            onCancel={handleCancel}
        />
    );
};
