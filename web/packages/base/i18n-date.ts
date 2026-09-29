import i18n, { t } from "i18next";

// These module-level formatters rely on locale changes doing a full reload.
const _dateFormat = new Intl.DateTimeFormat(i18n.language, {
    weekday: "short",
    day: "numeric",
    month: "short",
    year: "numeric",
});

const _dateWithoutWeekdayFormat = new Intl.DateTimeFormat(i18n.language, {
    day: "numeric",
    month: "short",
    year: "numeric",
});

const _dateWithoutYearFormat = new Intl.DateTimeFormat(i18n.language, {
    weekday: "short",
    day: "numeric",
    month: "short",
});

const _timeFormat = new Intl.DateTimeFormat(i18n.language, {
    timeStyle: "short",
});

interface FormattedDateOptions {
    omitWeekdayWhenYearIncluded?: boolean;
}

export const formattedDate = (date: Date, options?: FormattedDateOptions) =>
    (isSameYear(date)
        ? _dateWithoutYearFormat
        : options?.omitWeekdayWhenYearIncluded
          ? _dateWithoutWeekdayFormat
          : _dateFormat
    ).format(date);

const isSameYear = (date: Date) =>
    new Date().getFullYear() === date.getFullYear();

export const formattedTime = (date: Date) => _timeFormat.format(date);

export const formattedDateTime = (
    dateOrEpochMicroseconds: Date | number,
    options?: FormattedDateOptions,
) => _formattedDateTime(toDate(dateOrEpochMicroseconds), options);

const _formattedDateTime = (date: Date, options?: FormattedDateOptions) =>
    [formattedDate(date, options), t("at"), formattedTime(date)].join(" ");

const toDate = (dm: Date | number) =>
    typeof dm == "number" ? new Date(dm / 1000) : dm;

let _relativeTimeFormat: Intl.RelativeTimeFormat | undefined;

export const formattedDateRelative = (
    dateOrEpochMicroseconds: Date | number,
) => {
    const units: [Intl.RelativeTimeFormatUnit, number][] = [
        ["year", 24 * 60 * 60 * 1000 * 365],
        ["month", (24 * 60 * 60 * 1000 * 365) / 12],
        ["day", 24 * 60 * 60 * 1000],
        ["hour", 60 * 60 * 1000],
        ["minute", 60 * 1000],
        ["second", 1000],
    ];

    const date = toDate(dateOrEpochMicroseconds);

    const elapsed = date.getTime() - Date.now();
    const elapsedMagnitude = Math.abs(elapsed);

    const relativeTimeFormat = (_relativeTimeFormat ??=
        new Intl.RelativeTimeFormat(i18n.language, {
            localeMatcher: "best fit",
            numeric: "always",
            style: "short",
        }));

    for (const [u, d] of units) {
        if (elapsedMagnitude > d)
            return relativeTimeFormat.format(Math.round(elapsed / d), u);
    }

    return relativeTimeFormat.format(Math.round(elapsed / 1000), "second");
};
