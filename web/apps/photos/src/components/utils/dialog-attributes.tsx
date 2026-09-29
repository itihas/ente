import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import { t } from "i18next";

export const notifyOthersFilesDialogAttributes = () => ({
    title: t("note"),
    icon: <InfoOutlinedIcon />,
    message: t("unowned_files_not_processed"),
    cancel: t("ok"),
});

export const notifyUnsupportedSharedFavoritesDialogAttributes = () => ({
    title: t("note"),
    icon: <InfoOutlinedIcon />,
    message: t("unsupported_shared_favorites_not_processed"),
    cancel: t("ok"),
});
