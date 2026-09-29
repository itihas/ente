import CloseIcon from "@mui/icons-material/Close";
import InfoIcon from "@mui/icons-material/InfoOutlined";
import {
    IconButton,
    Snackbar,
    Stack,
    Typography,
    type ButtonProps,
    type SxProps,
    type Theme,
} from "@mui/material";
import { EllipsizedTypography } from "ente-base/components/Typography";
import { RippleDisabledButton } from "ente-base/components/mui/FocusVisibleButton";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import type {} from "ente-base/components/utils/mui-theme";
import { isSxArray } from "ente-base/components/utils/sx";
import React from "react";

export interface NotificationAttributes {
    captionFirst?: boolean;
    color: ButtonProps["color"];
    startIcon?: React.ReactNode;
    title: React.ReactNode;
    caption?: React.ReactNode;
    onClick?: () => void;
    endIcon?: React.ReactNode;
    showCloseButtonWithEndIcon?: boolean;
    onEndIconClick?: () => void;
}

type NotificationProps = ModalVisibilityProps & {
    attributes: NotificationAttributes | undefined;
    keepOpenOnClick?: boolean;
    horizontal?: "left" | "right";
    vertical?: "top" | "bottom";
    autoHideDuration?: number;
    sx?: SxProps<Theme>;
};

export const Notification: React.FC<NotificationProps> = ({
    open,
    onClose,
    horizontal,
    vertical,
    autoHideDuration,
    sx,
    attributes,
    keepOpenOnClick,
}) => {
    if (!attributes) return <></>;

    const {
        captionFirst,
        color,
        startIcon,
        title,
        caption,
        endIcon,
        showCloseButtonWithEndIcon,
        onClick,
        onEndIconClick,
    } = attributes;

    const handleClose: React.MouseEventHandler = (event) => {
        onClose();
        event.stopPropagation();
    };

    const handleClick = () => {
        onClick?.();
        if (!keepOpenOnClick) onClose();
    };

    const handleEndIconClick: React.MouseEventHandler = (event) => {
        event.stopPropagation();
        if (onEndIconClick) {
            onEndIconClick();
        } else {
            handleClick();
        }
    };

    // Inner IconButtons render as divs because the notification is a button.
    return (
        <Snackbar
            open={open}
            autoHideDuration={autoHideDuration}
            onClose={(_, reason) => {
                if (reason === "timeout") onClose();
            }}
            anchorOrigin={{
                horizontal: horizontal ?? "right",
                vertical: vertical ?? "bottom",
            }}
            sx={[
                (theme) => ({
                    width: "min(320px, 100vw)",
                    backgroundColor:
                        color && color != "inherit"
                            ? `${color}.main`
                            : "transparent",
                    boxShadow: theme.vars.palette.boxShadow.menu,
                }),
                ...(sx ? (isSxArray(sx) ? sx : [sx]) : []),
            ]}
        >
            <RippleDisabledButton
                color={color}
                onClick={handleClick}
                sx={{
                    flex: "1",
                    padding: "12px 8px 12px 14px",
                    borderRadius: "8px",
                }}
            >
                <Stack
                    direction="row"
                    sx={{
                        gap: 2,
                        alignItems: "center",
                        // Bounds the row so descendants can ellipsize.
                        width: "100%",
                    }}
                >
                    <Stack sx={{ svg: { fontSize: "36px" } }}>
                        {startIcon ?? <InfoIcon />}
                    </Stack>

                    <Stack
                        sx={{
                            flex: 1,
                            gap: 0.5,
                            textAlign: "left",
                            // Lets the caption shrink and ellipsize.
                            overflow: "hidden",
                        }}
                    >
                        {captionFirst ? (
                            <>
                                {caption && (
                                    <EllipsizedTypography variant="small">
                                        {caption}
                                    </EllipsizedTypography>
                                )}
                                <Typography sx={{ fontWeight: "medium" }}>
                                    {title}
                                </Typography>
                            </>
                        ) : (
                            <>
                                <Typography sx={{ fontWeight: "medium" }}>
                                    {title}
                                </Typography>
                                {caption && (
                                    <EllipsizedTypography variant="small">
                                        {caption}
                                    </EllipsizedTypography>
                                )}
                            </>
                        )}
                    </Stack>

                    {endIcon && (
                        <IconButton
                            component="div"
                            onClick={handleEndIconClick}
                            sx={{ fontSize: "36px", bgcolor: "fill.faint" }}
                        >
                            {endIcon}
                        </IconButton>
                    )}
                    {(!endIcon || showCloseButtonWithEndIcon) && (
                        <IconButton
                            component="div"
                            color="inherit"
                            onClick={handleClose}
                            sx={{ bgcolor: "fill.faint" }}
                        >
                            <CloseIcon />
                        </IconButton>
                    )}
                </Stack>
            </RippleDisabledButton>
        </Snackbar>
    );
};
