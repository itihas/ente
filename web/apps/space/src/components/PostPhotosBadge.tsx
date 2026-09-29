import { Box } from "@mui/material";

export const SpacePostPhotosBadge = ({
    count,
    inset = 10,
}: {
    count: number;
    inset?: number;
}) =>
    count > 1 ? (
        <Box
            component="span"
            aria-label={`${count} photos`}
            sx={{
                alignItems: "center",
                color: "#FFFFFF",
                display: "flex",
                filter: "drop-shadow(0 1px 2px rgba(0, 0, 0, 0.5))",
                height: 24,
                justifyContent: "center",
                pointerEvents: "none",
                position: "absolute",
                right: inset,
                top: inset,
                width: 24,
                zIndex: 2,
            }}
        >
            <svg
                aria-hidden
                width={18}
                height={18}
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth={1.6}
                strokeLinecap="round"
                strokeLinejoin="round"
                style={{ transform: "scaleX(-1)" }}
            >
                <path
                    d="M13 3H15C17.8284 3 19.2426 3 20.1213 3.87868C21 4.75736 21 6.17157 21 9V11C21 13.8284 21 15.2426 20.1213 16.1213C19.2426 17 17.8284 17 15 17H13C10.1716 17 8.75736 17 7.87868 16.1213C7 15.2426 7 13.8284 7 11V9C7 6.17157 7 4.75736 7.87868 3.87868C8.75736 3 10.1716 3 13 3Z"
                    fill="currentColor"
                />
                <path d="M16 20.1213C15.1213 21 13.7071 21 10.8787 21H9C6.17157 21 4.75736 21 3.87868 20.1213C3 19.2426 3 17.8284 3 15V13.1213C3 10.2929 3 8.87868 3.87868 8" />
            </svg>
        </Box>
    ) : null;
