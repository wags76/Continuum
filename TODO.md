# Continuum TODO

## Completed

- [x] Refresh the Dashboard, Calendar, Items, and Settings screens with a cohesive, modern visual system.
- [x] Add a dashboard for recurring costs, assets, warranties, renewals, and expirations.
- [x] Add searchable and filterable lists for subscriptions, recurring payments, assets, and warranties.
- [x] Add month and week calendar views for renewal and warranty dates.
- [x] Add JSON backup and restore for subscriptions, assets, warranties, and asset value history.
- [x] Verify the app builds, launches, and passes its current test targets on an iPhone simulator.

## Next

- [ ] Treat subscription due dates and warranty expiry dates as calendar days so items due today are not marked overdue or expired early.
- [ ] Advance a renewed subscription to its next future due date when it is multiple billing cycles overdue.
- [ ] Validate currency input using the user's locale and prevent invalid or negative amounts from silently becoming zero.
- [ ] Make backup restore safe with version validation, strict value validation, duplicate detection, a preview, and explicit merge or replace behavior.
- [ ] Surface persistence and save failures instead of discarding them silently.
- [ ] Add unit tests for billing-cycle calculations, date boundaries, localized currency parsing, and backup round trips and malformed imports.
- [ ] Add meaningful UI tests for creating, editing, renewing, filtering, importing, and deleting records.
- [ ] Confirm the intended minimum iOS version and lower the current iOS 26.2 deployment target if older supported devices should run Continuum.

## Later

- [x] Replace the empty dashboard's blank Overview card with onboarding copy and quick actions for adding each item type.
- [x] Make dashboard summary cards adaptive for narrow screens, iPad layouts, and larger Dynamic Type sizes.
- [x] Replace the calendar mode icon with a clearly labeled Month/Week control and keep the selected date synchronized while paging.
- [x] Localize calendar weekday headings and correct the month-grid range so it does not display an unnecessary extra week.
- [ ] Add deletion confirmation or undo support to item lists.
- [ ] Audit VoiceOver labels, Dynamic Type, dark mode, contrast, and portrait and landscape layouts.
- [ ] Extract shared currency formatting, date status logic, row components, and reusable calendar components.
- [ ] Remove unused duplicate list implementations after confirming the consolidated Items screen covers every flow.
- [x] Replace delayed dashboard tab switching with explicit navigation state.
