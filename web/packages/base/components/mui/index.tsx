import { IconButton, styled } from "@mui/material";

export interface ButtonishProps {
    onClick: () => void;
}

export const FilledIconButton = styled(IconButton)(({ theme }) => ({
    backgroundColor: theme.vars.palette.fill.faint,
}));
