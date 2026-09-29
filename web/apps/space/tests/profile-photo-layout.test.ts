import { expect, test } from "vitest";
import {
    profilePhotoGap,
    profilePhotoRows,
} from "../src/utils/profile-photo-layout";

const photos = (ratios: number[]) =>
    ratios.map((aspectRatio, id) => ({ id, aspectRatio }));

test.each([
    { count: 2, rowSizes: [2] },
    { count: 3, rowSizes: [3] },
    { count: 4, rowSizes: [2, 2] },
])(
    "a profile with $count photos uses the adaptive grid",
    ({ count, rowSizes }) => {
        const tiles = photos(new Array<number>(count).fill(2 / 3));
        const rows = profilePhotoRows(tiles, 352);
        expect(rows.map(({ tiles }) => tiles.length)).toEqual(rowSizes);
        expect(rows.flatMap(({ tiles }) => tiles)).toEqual(tiles);
    },
);

test("a profile with exactly five photos uses the adaptive grid throughout", () => {
    const tiles = photos([3 / 2, 3 / 2, 3 / 2, 3 / 2, 3 / 2]);
    const rows = profilePhotoRows(tiles, 352);
    expect(rows.map(({ tiles }) => tiles.map(({ id }) => id))).toEqual([
        [0, 1],
        [2, 3],
        [4],
    ]);
});

test("three portraits share a compact row", () => {
    expect(
        profilePhotoRows(
            photos([2 / 3, 3 / 4, 2 / 3, 2 / 3, 3 / 4, 2 / 3]),
            328,
        ).map(({ tiles }) => tiles.length),
    ).toEqual([3, 3]);
});

test("a landscape can share a row with two portraits to avoid a lone portrait", () => {
    const tiles = photos([3 / 4, 3 / 4, 16 / 9, 3 / 4, 9 / 16]);
    expect(
        profilePhotoRows(tiles, 363).map(({ tiles }) =>
            tiles.map(({ id }) => id),
        ),
    ).toEqual([
        [0, 1],
        [2, 3, 4],
    ]);
});

test("a single-post section fills the width with the feed's portrait height cap", () => {
    const tiles = photos([9 / 16]);
    expect(profilePhotoRows(tiles, 324)).toEqual([
        { aspectRatio: 9 / 16, height: 432, width: 324, tiles },
    ]);
});

test("similar landscapes are not forced into full-width rows", () => {
    const tiles = photos(new Array<number>(10).fill(3 / 2));
    const rows = profilePhotoRows(tiles, 358);
    expect(rows.map(({ tiles }) => tiles.length)).toEqual([2, 2, 2, 2, 2]);
    expect(rows.flatMap(({ tiles }) => tiles)).toEqual(tiles);
});

test("wider photos stand alone when that fits better than a short paired row", () => {
    const tiles = photos([3 / 2, 3 / 2, 5 / 3, 5 / 3, 3 / 2, 3 / 2]);
    const rows = profilePhotoRows(tiles, 358);
    expect(rows.map(({ tiles }) => tiles.length)).toEqual([2, 1, 1, 2]);
    expect(rows.flatMap(({ tiles }) => tiles)).toEqual(tiles);
});

test("row grouping adapts to the available width and accounts for gaps", () => {
    const tiles = photos([1.5, 1.5, 1.5, 1.5, 1.5, 1.5]);
    expect(
        profilePhotoRows(tiles, 299 + profilePhotoGap).map(
            ({ tiles }) => tiles.length,
        ),
    ).toEqual([1, 1, 1, 1, 1, 1]);
    expect(
        profilePhotoRows(tiles, 300 + profilePhotoGap).map(
            ({ tiles }) => tiles.length,
        ),
    ).toEqual([2, 2, 2]);
    expect(
        profilePhotoRows(tiles, 456).map(({ tiles }) => tiles.length),
    ).toEqual([2, 2, 2]);
});

test("a panorama keeps its aspect ratio even when it cannot reach the minimum", () => {
    const tiles = photos([8, 1, 1, 1, 1]);
    const rows = profilePhotoRows(tiles, 328);
    expect(rows.map(({ tiles }) => tiles.length)).toEqual([1, 2, 2]);
    expect(rows[0]!.aspectRatio).toBe(8);
});

test.each([288, 328, 358, 568])(
    "rows preserve order, fit a %ipx grid, and meet the minimum when possible",
    (width) => {
        const tiles = photos([1.5, 1.2, 1.8, 0.75, 0.6, 8, 0.05, 1, 2, 1.5]);
        const rows = profilePhotoRows(tiles, width);
        expect(rows.flatMap(({ tiles }) => tiles)).toEqual(tiles);
        for (const row of rows) {
            expect(row.tiles.length).toBeLessThanOrEqual(3);
            const gaps = (row.tiles.length - 1) * profilePhotoGap;
            expect(
                row.tiles.reduce(
                    (sum, tile) => sum + tile.aspectRatio * row.height,
                    gaps,
                ),
            ).toBeCloseTo(row.width);
            expect(row.width).toBeLessThanOrEqual(width + 0.001);
            expect(row.height).toBeLessThanOrEqual(width * 0.75);
            expect(row.height).toBeGreaterThanOrEqual(
                Math.min(100, width / row.tiles[0]!.aspectRatio),
            );
        }
    },
);

test("an empty grid has no rows", () => {
    expect(profilePhotoRows([], 328)).toEqual([]);
});

test("the grid waits for its width to be measured", () => {
    expect(profilePhotoRows(photos([3 / 4, 3 / 2]), 0)).toEqual([]);
});
