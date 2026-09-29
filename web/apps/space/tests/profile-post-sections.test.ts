import { expect, test } from "vitest";
import { profilePostSections } from "../src/utils/profile-post-sections";

const post = (id: string, timestamp: Date) => ({
    id,
    timestampMs: timestamp.getTime(),
});

test("each post appears once in the first matching calendar section", () => {
    const now = new Date(2026, 8, 24, 12);
    const posts = [
        post("today", new Date(2026, 8, 24)),
        post("yesterday", new Date(2026, 8, 23)),
        post("this-week", new Date(2026, 8, 21)),
        post("last-week-end", new Date(2026, 8, 20, 23, 59, 59, 999)),
        post("last-week-start", new Date(2026, 8, 14)),
        post("this-month", new Date(2026, 8, 13, 23, 59, 59, 999)),
        post("august-1", new Date(2026, 7, 31)),
        post("august-2", new Date(2026, 7, 1)),
        post("july", new Date(2026, 6, 1)),
        post("last-year", new Date(2025, 7, 1)),
    ];
    const sections = profilePostSections(posts, now);

    expect(
        sections.map(({ title, items }) => [title, items.map((p) => p.id)]),
    ).toEqual([
        ["Today", ["today"]],
        ["Yesterday", ["yesterday"]],
        ["This week", ["this-week"]],
        ["Last week", ["last-week-end", "last-week-start"]],
        ["This month", ["this-month"]],
        ["Aug 2026", ["august-1", "august-2"]],
        ["Jul 2026", ["july"]],
        ["Aug 2025", ["last-year"]],
    ]);
    expect(sections.flatMap(({ items }) => items)).toEqual(posts);
    expect(new Set(sections.map(({ id }) => id)).size).toBe(sections.length);
});

test("a new month still gives yesterday and weekly sections priority", () => {
    const posts = [
        post("today", new Date(2026, 9, 1)),
        post("yesterday", new Date(2026, 8, 30)),
        post("monday", new Date(2026, 8, 28)),
        post("sunday", new Date(2026, 8, 27)),
        post("last-monday", new Date(2026, 8, 21)),
        post("older", new Date(2026, 8, 20)),
    ];
    expect(
        profilePostSections(posts, new Date(2026, 9, 1, 12)).map(
            ({ title, items }) => [title, items.map((p) => p.id)],
        ),
    ).toEqual([
        ["Today", ["today"]],
        ["Yesterday", ["yesterday"]],
        ["This week", ["monday"]],
        ["Last week", ["sunday", "last-monday"]],
        ["Sep 2026", ["older"]],
    ]);
});

test("Monday starts a new week while Sunday remains yesterday", () => {
    const posts = [
        post("monday", new Date(2026, 8, 28)),
        post("sunday", new Date(2026, 8, 27)),
        post("saturday", new Date(2026, 8, 26)),
    ];
    expect(
        profilePostSections(posts, new Date(2026, 8, 28, 12)).map(
            ({ title }) => title,
        ),
    ).toEqual(["Today", "Yesterday", "Last week"]);
});

test("Sunday is the last day of this week", () => {
    const posts = [
        post("friday", new Date(2026, 8, 25)),
        post("monday", new Date(2026, 8, 21)),
        post("last-sunday", new Date(2026, 8, 20)),
    ];
    expect(
        profilePostSections(posts, new Date(2026, 8, 27, 12)).map(
            ({ title, items }) => [title, items.map((p) => p.id)],
        ),
    ).toEqual([
        ["This week", ["friday", "monday"]],
        ["Last week", ["last-sunday"]],
    ]);
});

test("last week spans the year boundary", () => {
    const posts = [
        post("yesterday", new Date(2026, 0, 4)),
        post("saturday", new Date(2026, 0, 3)),
        post("last-monday", new Date(2025, 11, 29)),
        post("older", new Date(2025, 11, 28)),
    ];
    expect(
        profilePostSections(posts, new Date(2026, 0, 5, 12)).map(
            ({ title, items }) => [title, items.map((p) => p.id)],
        ),
    ).toEqual([
        ["Yesterday", ["yesterday"]],
        ["Last week", ["saturday", "last-monday"]],
        ["Dec 2025", ["older"]],
    ]);
});

test("month headings include the year and skip empty periods", () => {
    const posts = [
        post("december", new Date(2025, 11, 21)),
        post("october", new Date(2025, 9, 15)),
        post("older-december", new Date(2024, 11, 31)),
    ];
    expect(
        profilePostSections(posts, new Date(2026, 0, 1, 12)).map(
            ({ title }) => title,
        ),
    ).toEqual(["Dec 2025", "Oct 2025", "Dec 2024"]);
    expect(profilePostSections([], new Date(2026, 0, 1))).toEqual([]);
});

test.each([
    { now: new Date(2026, 2, 9, 12), olderTitle: "This month" },
    { now: new Date(2026, 10, 2, 12), olderTitle: "Oct 2026" },
])(
    "uses local midnights across daylight saving changes: $now",
    ({ now, olderTitle }) => {
        const year = now.getFullYear();
        const month = now.getMonth();
        const day = now.getDate();
        const posts = [
            post("today", new Date(year, month, day)),
            post("late-yesterday", new Date(year, month, day - 1, 23, 59)),
            post("early-yesterday", new Date(year, month, day - 1)),
            post("before-yesterday", new Date(year, month, day - 2, 23, 59)),
            post("last-week-start", new Date(year, month, day - 7)),
            post("before-last-week", new Date(year, month, day - 8, 23, 59)),
        ];
        expect(
            profilePostSections(posts, now).map(({ title, items }) => [
                title,
                items.map((p) => p.id),
            ]),
        ).toEqual([
            ["Today", ["today"]],
            ["Yesterday", ["late-yesterday", "early-yesterday"]],
            ["Last week", ["before-yesterday", "last-week-start"]],
            [olderTitle, ["before-last-week"]],
        ]);
    },
);
