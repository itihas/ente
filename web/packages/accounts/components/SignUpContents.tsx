import { SignUpForm } from "ente-accounts/components/auth/SignUpForm";
import {
    replaceSavedLocalUser,
    saveJustSignedUp,
    saveOriginalKeyAttributes,
    stashReferralSource,
    stashSRPSetupAttributes,
} from "ente-accounts/services/accounts-db";
import { saveMasterKeyInSessionAndSafeStore } from "ente-accounts/services/prelogin-session";
import { generateSRPSetupAttributes } from "ente-accounts/services/srp";
import {
    generateAndSaveInteractiveKeyAttributes,
    generateKeysAndAttributes,
    sendOTT,
    type GenerateKeysAndAttributesResult,
} from "ente-accounts/services/user";
import {
    estimatePasswordStrength,
    type PasswordStrength,
} from "ente-accounts/utils/password";
import { isNamedError } from "ente-base/error";
import { isMuseumHTTPError } from "ente-base/http";
import { JOIN_ALBUM_CONTEXT_KEY } from "ente-base/join-album";
import log from "ente-base/log";
import { useFormik } from "formik";
import { t } from "i18next";
import type { NextRouter } from "next/router";
import React, { useEffect, useMemo, useState } from "react";
import { z } from "zod";

interface SignUpContentsProps {
    router: NextRouter;
    onLogin: () => void;
    host: string | undefined;
}

export interface SignUpPresentationProps {
    email: string;
    password: string;
    confirmPassword: string;
    referral: string;
    acceptedTerms: boolean;
    emailError: string | undefined;
    passwordError: string | undefined;
    confirmPasswordError: string | undefined;
    passwordStrength: PasswordStrength | undefined;
    isSubmitting: boolean;
    isSubmitDisabled: boolean;
    isJoinAlbumContext: boolean;
    host: string | undefined;
    onEmailChange: React.ChangeEventHandler<
        HTMLInputElement | HTMLTextAreaElement
    >;
    onPasswordChange: React.ChangeEventHandler<
        HTMLInputElement | HTMLTextAreaElement
    >;
    onConfirmPasswordChange: React.ChangeEventHandler<
        HTMLInputElement | HTMLTextAreaElement
    >;
    onReferralChange: React.ChangeEventHandler<
        HTMLInputElement | HTMLTextAreaElement
    >;
    onAcceptedTermsChange: (acceptedTerms: boolean) => void;
    onSubmit: React.SubmitEventHandler<HTMLFormElement>;
    onLogin: () => void;
}

export const SignUpContents: React.FC<SignUpContentsProps> = ({
    router,
    onLogin,
    host,
}) => {
    const [isJoinAlbumContext, setIsJoinAlbumContext] = useState(false);

    useEffect(() => {
        const joinAlbumContext = sessionStorage.getItem(JOIN_ALBUM_CONTEXT_KEY);
        setIsJoinAlbumContext(!!joinAlbumContext);
    }, []);

    const formik = useFormik({
        initialValues: {
            email: "",
            password: "",
            confirmPassword: "",
            referral: "",
            acceptedTerms: false,
        },
        onSubmit: async (
            { email, password, confirmPassword, referral },
            { setFieldError },
        ) => {
            if (!email) {
                setFieldError("email", t("required"));
                return;
            }

            if (!z.email().safeParse(email).success) {
                setFieldError("email", t("invalid_email_error"));
                return;
            }

            if (!password) {
                setFieldError("password", t("required"));
                return;
            }

            if (!confirmPassword) {
                setFieldError("confirmPassword", t("required"));
                return;
            }

            if (password != confirmPassword) {
                setFieldError("confirmPassword", t("password_mismatch_error"));
                return;
            }

            try {
                const cleanedReferral = referral.trim();
                if (cleanedReferral) stashReferralSource(cleanedReferral);

                try {
                    await sendOTT(email, "signup");
                } catch (e) {
                    if (
                        await isMuseumHTTPError(
                            e,
                            409,
                            "USER_ALREADY_REGISTERED",
                        )
                    ) {
                        setFieldError("email", t("email_already_registered"));
                        return;
                    }
                    throw e;
                }

                replaceSavedLocalUser({ email });

                let gkResult: GenerateKeysAndAttributesResult;
                try {
                    gkResult = await generateKeysAndAttributes(password);
                } catch (e) {
                    if (isNamedError(e, "insufficient_memory")) {
                        setFieldError(
                            "confirmPassword",
                            t("password_generation_failed"),
                        );
                        return;
                    }
                    throw e;
                }

                const { masterKey, kek, keyAttributes } = gkResult;
                saveOriginalKeyAttributes(keyAttributes);
                stashSRPSetupAttributes(await generateSRPSetupAttributes(kek));
                await generateAndSaveInteractiveKeyAttributes(
                    password,
                    keyAttributes,
                    masterKey,
                );
                await saveMasterKeyInSessionAndSafeStore(masterKey);

                saveJustSignedUp();
                void router.push("/verify");
            } catch (e) {
                log.error("Signup failed", e);
                setFieldError("confirmPassword", t("generic_error"));
            }
        },
    });

    const passwordStrength = useMemo(
        () =>
            formik.values.password
                ? estimatePasswordStrength(formik.values.password)
                : undefined,
        [formik.values.password],
    );

    function handleAcceptedTermsChange(acceptedTerms: boolean) {
        void formik.setFieldValue("acceptedTerms", acceptedTerms);
    }

    return (
        <SignUpForm
            email={formik.values.email}
            password={formik.values.password}
            confirmPassword={formik.values.confirmPassword}
            referral={formik.values.referral}
            acceptedTerms={formik.values.acceptedTerms}
            emailError={formik.errors.email}
            passwordError={formik.errors.password}
            confirmPasswordError={formik.errors.confirmPassword}
            passwordStrength={passwordStrength}
            isSubmitting={formik.isSubmitting}
            isSubmitDisabled={
                !formik.values.acceptedTerms ||
                !passwordStrength ||
                passwordStrength === "weak"
            }
            isJoinAlbumContext={isJoinAlbumContext}
            host={host}
            onEmailChange={formik.handleChange}
            onPasswordChange={formik.handleChange}
            onConfirmPasswordChange={formik.handleChange}
            onReferralChange={formik.handleChange}
            onAcceptedTermsChange={handleAcceptedTermsChange}
            onSubmit={formik.handleSubmit}
            onLogin={onLogin}
        />
    );
};
