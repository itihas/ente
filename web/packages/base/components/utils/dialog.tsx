import ErrorOutlinedIcon from "@mui/icons-material/ErrorOutlined";
import { t } from "i18next";
import { useCallback, useState } from "react";
import type { MiniDialogAttributes } from "../MiniDialog";

export const useAttributedMiniDialog = () => {
    const [attributes, setAttributes] = useState<
        MiniDialogAttributes | undefined
    >(undefined);

    const [open, setOpen] = useState(false);

    const showMiniDialog = useCallback(
        (newAttributes: MiniDialogAttributes) => {
            setAttributes((attributes) =>
                attributes?.nonReplaceable ? attributes : newAttributes,
            );
            setOpen(true);
        },
        [],
    );

    const handleClose = useCallback(() => setOpen(false), []);

    return {
        showMiniDialog,
        miniDialogProps: { open, onClose: handleClose, attributes },
    };
};

export const errorDialogAttributes = (
    messageOrTitle: string,
    optionalMessage?: string,
): MiniDialogAttributes => {
    const title = optionalMessage ? messageOrTitle : t("error");
    const message = optionalMessage ?? messageOrTitle;

    return {
        title,
        icon: <ErrorOutlinedIcon />,
        message,
        continue: { color: "critical" },
        cancel: false,
    };
};

export const genericErrorDialogAttributes = () =>
    errorDialogAttributes(t("generic_error"));

export const genericRetriableErrorDialogAttributes = () =>
    errorDialogAttributes(t("generic_error_retry"));
