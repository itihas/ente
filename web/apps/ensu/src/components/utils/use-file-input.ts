import { useCallback, useRef } from "react";

interface UseFileInputParams {
    directory?: boolean;
    accept?: string;
    onSelect: (selectedFiles: File[]) => void;
    onCancel: () => void;
}

interface UseFileInputResult {
    getInputProps: () => React.HTMLAttributes<HTMLInputElement>;
    openSelector: () => void;
}

export const useFileInput = ({
    directory,
    accept,
    onSelect,
    onCancel,
}: UseFileInputParams): UseFileInputResult => {
    const inputRef = useRef<HTMLInputElement | null>(null);

    const handleInputRef = useCallback(
        (node: HTMLInputElement | null) => {
            if (inputRef.current) {
                inputRef.current.removeEventListener("cancel", onCancel);
            }

            inputRef.current = node;

            if (inputRef.current) {
                inputRef.current.addEventListener("cancel", onCancel);
            }
        },
        [onCancel],
    );

    const openSelector = useCallback(() => {
        const input = inputRef.current;
        if (!input) return;

        input.value = "";
        input.click();
    }, []);

    const handleChange: React.ChangeEventHandler<HTMLInputElement> = (
        event,
    ) => {
        const files = event.target.files;
        if (files?.length) {
            onSelect([...files]);
        } else {
            onCancel();
        }
    };

    const directoryOpts = directory
        ? { directory: "", webkitdirectory: "" }
        : {};

    const getInputProps = useCallback(
        () => ({
            type: "file",
            multiple: true,
            style: { display: "none" },
            ...directoryOpts,
            ref: handleInputRef,
            onChange: handleChange,
            ...(accept && { accept }),
        }),
        [directoryOpts, accept, handleChange, handleInputRef],
    );

    return { getInputProps, openSelector };
};
