# Conduit UI Direction

Conduit uses a dark, operations-focused interface for personal server and deployment management. The app should feel like a compact network control surface: calm, high-contrast, secure, and quick to scan.

## Visual Style

- Use a near-black navy gradient as the main screen background.
- Use dark glass cards for clients, deployments, settings groups, tunnels, and vault content.
- Keep card corners moderately rounded, with subtle white strokes and low-opacity fills.
- Use bold white headings and app/client names as the strongest visual signal.
- Use muted gray secondary text for metadata, labels, empty values, and helper states.
- Use blue as the action accent, especially for add buttons and unlock/save actions.
- Use status dots instead of verbose status badges where possible.
- Use green for online systems and red for offline systems in deployment contexts.

## Screen Patterns

- The first visible field in a deployment list should be the deployed app name.
- Client and deployment rows should be compact cards, not default table rows.
- Detail screens should group editable fields into titled cards.
- The deployment detail header should show the app name and online/offline state immediately.
- Secure credentials belong in a dedicated `Secure Vault` section.
- Passwords should appear locked by default and only become editable after biometric or passcode authentication.

## Interaction Feel

- Prefer direct inline editing for non-sensitive deployment metadata.
- Keep credential fields separate from SwiftData-backed fields.
- Keep add flows as sheets, but tint and background them to match the dark app shell.
- Avoid decorative imagery, heavy gradients, and marketing-style layouts inside the app.

This design direction is the baseline for future Conduit UI work.
