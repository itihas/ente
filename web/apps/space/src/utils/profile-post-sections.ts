export const profilePostSections = <Item extends { timestampMs: number }>(
    items: Item[],
    now = new Date(),
) => {
    const year = now.getFullYear();
    const month = now.getMonth();
    const day = now.getDate();
    // Weeks start on Monday. Construct local dates rather than subtracting
    // 24-hour periods so yesterday stays correct across daylight saving changes.
    const daysSinceMonday = (now.getDay() + 6) % 7;
    const recentSections = [
        { id: "today", title: "Today", since: new Date(year, month, day) },
        {
            id: "yesterday",
            title: "Yesterday",
            since: new Date(year, month, day - 1),
        },
        {
            id: "week",
            title: "This week",
            since: new Date(year, month, day - daysSinceMonday),
        },
        {
            id: "last-week",
            title: "Last week",
            since: new Date(year, month, day - daysSinceMonday - 7),
        },
        { id: "month", title: "This month", since: new Date(year, month, 1) },
    ].map((section) => ({ ...section, items: new Array<Item>() }));
    const months = new Map<
        number,
        { id: string; title: string; items: Item[] }
    >();

    for (const item of items) {
        const recentSection = recentSections.find(
            ({ since }) => item.timestampMs >= since.getTime(),
        );
        if (recentSection) {
            recentSection.items.push(item);
            continue;
        }

        const date = new Date(item.timestampMs);
        const monthStart = new Date(date.getFullYear(), date.getMonth(), 1);
        const key = monthStart.getTime();
        let section = months.get(key);
        if (!section) {
            section = {
                id: `${date.getFullYear()}-${date.getMonth() + 1}`,
                title: monthStart.toLocaleDateString("en-US", {
                    month: "short",
                    year: "numeric",
                }),
                items: [],
            };
            months.set(key, section);
        }
        section.items.push(item);
    }

    return [
        ...recentSections.filter(({ items }) => items.length > 0),
        ...[...months.entries()]
            .sort(([a], [b]) => b - a)
            .map(([, section]) => section),
    ];
};
