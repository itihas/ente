import { minimumPostPhotoFrameAspectRatio } from "../styles/tiles";

export const profilePhotoGap = 6;
const profilePhotoMinRowHeight = 100;

export const profilePhotoRows = <Tile extends { aspectRatio: number }>(
    tiles: Tile[],
    width: number,
) => {
    const rows: {
        aspectRatio: number;
        height: number;
        width: number;
        tiles: Tile[];
    }[] = [];
    if (width <= 0) return rows;

    const targetRowHeight = width / 2;
    const costs = new Array<number>(tiles.length + 1).fill(Infinity);
    const rowSizes = new Array<number>(tiles.length);
    costs[tiles.length] = 0;

    for (let index = tiles.length - 1; index >= 0; index--) {
        let aspectRatio = 0;
        for (
            let rowSize = 1;
            rowSize <= 3 && index + rowSize <= tiles.length;
            rowSize++
        ) {
            aspectRatio += tiles[index + rowSize - 1]!.aspectRatio;
            const height =
                (width - (rowSize - 1) * profilePhotoGap) / aspectRatio;
            if (rowSize > 1 && height < profilePhotoMinRowHeight) continue;

            const cost =
                (height / targetRowHeight - 1) ** 2 + costs[index + rowSize]!;
            if (cost <= costs[index]!) {
                costs[index] = cost;
                rowSizes[index] = rowSize;
            }
        }
    }

    for (let index = 0; index < tiles.length; ) {
        const rowSize = rowSizes[index]!;
        const rowTiles = tiles.slice(index, index + rowSize);
        const aspectRatio = rowTiles.reduce(
            (sum, tile) => sum + tile.aspectRatio,
            0,
        );
        const gaps = (rowSize - 1) * profilePhotoGap;
        const height = Math.min(
            (width - gaps) / aspectRatio,
            tiles.length == 1
                ? width / minimumPostPhotoFrameAspectRatio
                : width * 0.75,
        );
        rows.push({
            aspectRatio,
            height,
            width: tiles.length == 1 ? width : height * aspectRatio + gaps,
            tiles: rowTiles,
        });
        index += rowSize;
    }

    return rows;
};
