import type { PeopleSortBy } from "@/utils/people-sort";
import { ArrowDown02Icon, ArrowUp02Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import SortIcon from "@mui/icons-material/Sort";
import {
    IconButton,
    MenuItem,
    Stack,
    Typography,
    styled,
    type IconButtonProps,
    type PaperProps,
    type Theme,
} from "@mui/material";
import Menu, { type MenuProps } from "@mui/material/Menu";
import { t } from "i18next";
import React, { useRef, useState } from "react";

interface PeopleSortOptionsProps {
    activeSortBy: PeopleSortBy;
    onChangeSortBy: (by: PeopleSortBy) => void;
    variant?: "default" | "v2";
    nestedInDialog?: boolean;
    transparentTriggerButtonBackground?: boolean;
}

type PeopleSortCategory = "name" | "count";

const getPeopleSortCategory = (sortBy: PeopleSortBy): PeopleSortCategory =>
    sortBy.startsWith("name") ? "name" : "count";

const isPeopleSortAscending = (sortBy: PeopleSortBy) => sortBy.endsWith("asc");

const getPeopleSortBy = (
    category: PeopleSortCategory,
    ascending: boolean,
): PeopleSortBy => `${category}-${ascending ? "asc" : "desc"}`;

export const PeopleSortOptions: React.FC<PeopleSortOptionsProps> = ({
    activeSortBy,
    onChangeSortBy,
    variant = "default",
    nestedInDialog,
    transparentTriggerButtonBackground,
}) => {
    const [anchorEl, setAnchorEl] = useState<MenuProps["anchorEl"]>();

    // Apply sort changes after the menu closes to avoid flicker.
    const pendingSortByRef = useRef<PeopleSortBy | undefined>(undefined);
    const ariaID = "people-sort";

    const activeCategory = getPeopleSortCategory(activeSortBy);
    const activeAscending = isPeopleSortAscending(activeSortBy);

    const handleCategoryClick = (category: PeopleSortCategory) => {
        let nextSortBy: PeopleSortBy;
        if (category === activeCategory) {
            nextSortBy = getPeopleSortBy(category, !activeAscending);
        } else {
            nextSortBy = getPeopleSortBy(category, category === "name");
        }
        pendingSortByRef.current = nextSortBy;
        setAnchorEl(undefined);
    };

    const isV2 = variant === "v2";

    const triggerButtonSxProps: IconButtonProps["sx"] = isV2
        ? v2TriggerButtonSx
        : [
              transparentTriggerButtonBackground
                  ? {}
                  : { backgroundColor: "fill.faint" },
          ];

    const menuPaperSxProps: PaperProps["sx"] | undefined =
        !isV2 && nestedInDialog
            ? { backgroundColor: "background.paper2" }
            : undefined;

    return (
        <>
            <IconButton
                onClick={(event) => setAnchorEl(event.currentTarget)}
                aria-controls={anchorEl ? ariaID : undefined}
                aria-haspopup="true"
                aria-expanded={anchorEl ? "true" : undefined}
                aria-label={isV2 ? t("sort_by") : undefined}
                sx={triggerButtonSxProps}
            >
                <SortIcon sx={isV2 ? { fontSize: 20 } : undefined} />
            </IconButton>
            <StyledMenu
                id={ariaID}
                sx={isV2 ? v2MenuSx : undefined}
                {...(anchorEl && { anchorEl })}
                open={!!anchorEl}
                onClose={() => setAnchorEl(undefined)}
                slotProps={{
                    paper: menuPaperSxProps ? { sx: menuPaperSxProps } : {},
                    list: { disablePadding: true, "aria-labelledby": ariaID },
                    transition: {
                        onExited: () => {
                            const nextSortBy = pendingSortByRef.current;
                            if (nextSortBy) {
                                pendingSortByRef.current = undefined;
                                onChangeSortBy(nextSortBy);
                            }
                        },
                    },
                }}
                anchorOrigin={{ vertical: "bottom", horizontal: "right" }}
                transformOrigin={{ vertical: "top", horizontal: "right" }}
            >
                <PeopleSortCategoryOption
                    category="name"
                    activeCategory={activeCategory}
                    activeAscending={activeAscending}
                    onClick={handleCategoryClick}
                    label={t("name")}
                    directionLabel={
                        activeAscending
                            ? t("sort_asc_indicator")
                            : t("sort_desc_indicator")
                    }
                />
                <PeopleSortCategoryOption
                    category="count"
                    activeCategory={activeCategory}
                    activeAscending={activeAscending}
                    onClick={handleCategoryClick}
                    label={t("photos")}
                />
            </StyledMenu>
        </>
    );
};

interface PeopleSortCategoryOptionProps {
    category: PeopleSortCategory;
    activeCategory: PeopleSortCategory;
    activeAscending: boolean;
    onClick: (category: PeopleSortCategory) => void;
    label: string;
    directionLabel?: string;
}

const PeopleSortCategoryOption: React.FC<PeopleSortCategoryOptionProps> = ({
    category,
    activeCategory,
    activeAscending,
    onClick,
    label,
    directionLabel,
}) => {
    const isSelected = category === activeCategory;
    const arrowIcon = activeAscending ? ArrowUp02Icon : ArrowDown02Icon;

    return (
        <StyledMenuItem onClick={() => onClick(category)}>
            <Stack direction="row" sx={{ alignItems: "center" }}>
                <Typography
                    sx={{
                        color: isSelected ? "text.primary" : "text.secondary",
                    }}
                >
                    {label}
                </Typography>
                {isSelected && (
                    <Stack
                        direction="row"
                        sx={{
                            alignItems: "center",
                            ml: 1,
                            gap: 0.75,
                            color: "text.muted",
                        }}
                    >
                        {directionLabel && <Typography>•</Typography>}
                        {directionLabel && (
                            <Typography sx={{ fontSize: "0.9rem" }}>
                                {directionLabel}
                            </Typography>
                        )}
                        <HugeiconsIcon
                            icon={arrowIcon}
                            size={19}
                            color="currentColor"
                        />
                    </Stack>
                )}
            </Stack>
        </StyledMenuItem>
    );
};

const StyledMenu = styled(Menu)(({ theme }) => ({
    "& .MuiPaper-root": {
        backgroundColor: theme.vars.palette.background.elevatedPaper,
        minWidth: 220,
        width: 220,
        borderRadius: 12,
        boxShadow: theme.vars.palette.boxShadow.menu,
        marginTop: 6,
    },
    "& .MuiList-root": { padding: theme.spacing(1) },
}));

const StyledMenuItem = styled(MenuItem)(({ theme }) => ({
    display: "flex",
    alignItems: "center",
    gap: 12,
    padding: theme.spacing(1.5, 2),
    borderRadius: 8,
    color: theme.vars.palette.text.base,
    fontSize: 15,
    "&:hover": { backgroundColor: theme.vars.palette.fill.faintHover },
    "& .MuiListItemIcon-root": { minWidth: 0, color: "inherit" },
    "& .MuiListItemText-root": { margin: 0 },
    "& .MuiListItemText-primary": { color: "inherit", fontSize: "inherit" },
}));

const v2TriggerButtonSx = (theme: Theme) => ({
    width: 38,
    height: 38,
    p: 0,
    color: "text.base",
    backgroundColor: "background.paper",
    "&:hover": { backgroundColor: "fill.faintHover" },
    ...theme.applyStyles("dark", {
        backgroundColor: "rgba(255 255 255 / 0.12)",
    }),
});

const v2MenuSx = (theme: Theme) => ({
    "& .MuiPaper-root": {
        width: 238,
        minWidth: 238,
        border: "1px solid #ececec",
        borderRadius: "16px",
        backgroundColor: "background.paper",
        boxShadow: "0 4px 4px rgba(0 0 0 / 0.16)",
        ...theme.applyStyles("dark", {
            borderColor: "rgba(255 255 255 / 0.12)",
            backgroundColor: "#282828",
            boxShadow: "0 4px 4px rgba(0 0 0 / 0.40)",
        }),
    },
    "& .MuiMenuItem-root": {
        minHeight: 44,
        height: 44,
        boxSizing: "border-box",
        py: "12px",
        px: "16px",
    },
    "& .MuiTypography-root": {
        fontSize: 14,
        lineHeight: "20px",
        fontWeight: 500,
    },
});
