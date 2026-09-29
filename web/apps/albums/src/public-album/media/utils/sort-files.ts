import type { EnteFile } from "ente-media/file";
import { fileCreationPhotoSortTime } from "ente-media/file-metadata";

export const sortFiles = (files: EnteFile[], sortAsc = false) => {
    const factor = sortAsc ? -1 : 1;
    const sortTimeByFile = new Map<EnteFile, number>();
    const sortTimeForFile = (file: EnteFile) => {
        const cached = sortTimeByFile.get(file);
        if (cached != undefined) return cached;
        const t = fileCreationPhotoSortTime(file);
        sortTimeByFile.set(file, t);
        return t;
    };
    return files.sort((a, b) => {
        const at = sortTimeForFile(a);
        const bt = sortTimeForFile(b);
        return at == bt
            ? factor *
                  (b.metadata.modificationTime - a.metadata.modificationTime)
            : factor * (bt - at);
    });
};
