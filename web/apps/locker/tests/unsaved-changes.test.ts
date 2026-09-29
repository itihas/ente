import { expect, test } from "vitest";
import { hasUnsavedItemChanges } from "../src/components/create-item/item-form-fields-utils";

test("detects input changes while ignoring empty and unchanged fields", () => {
    const initial = { title: "Saved" };
    expect(hasUnsavedItemChanges({ title: "" }, {}, [], [], "")).toBe(false);
    expect(hasUnsavedItemChanges({ title: "Draft" }, {}, [], [], "")).toBe(
        true,
    );
    expect(
        hasUnsavedItemChanges({ ...initial, notes: "" }, initial, [], [], ""),
    ).toBe(false);
    expect(
        hasUnsavedItemChanges({ title: "Edited" }, initial, [], [], ""),
    ).toBe(true);
    expect(hasUnsavedItemChanges({ title: "" }, initial, [], [], "")).toBe(
        true,
    );
});

test("detects collection changes and drafts but ignores collection order", () => {
    expect(hasUnsavedItemChanges({}, {}, [2, 1], [1, 2], "")).toBe(false);
    expect(hasUnsavedItemChanges({}, {}, [2], [1], "")).toBe(true);
    expect(hasUnsavedItemChanges({}, {}, [], [1], "")).toBe(true);
    expect(hasUnsavedItemChanges({}, {}, [], [], "New collection")).toBe(true);
});
