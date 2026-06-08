# Conduit Free

Conduit is an offline iOS app for freelancers, small agencies, and solo developers who need a clear map of client deployments without keeping everything in notes, spreadsheets, or memory.

The free version is focused on one job: keep local infrastructure details and sensitive credentials organized on device.

## What It Helps With

Conduit tracks the practical details developers reach for while maintaining small client systems:

- which clients or projects exist
- which apps are deployed for each client
- whether a system is marked online or offline
- admin URLs and local system ports
- Gunicorn and Nginx routing ports
- database names and ports
- server usernames
- Cloudflare tunnel names and ports
- custom text, URL, port, and password fields
- sensitive passwords stored separately in the iOS Keychain

It is not an SSH client, uptime monitor, Cloudflare dashboard, or CI/CD tracker. Conduit Free is the offline infrastructure map that sits between those tools.

## Free Version Scope

Conduit Free includes:

- local-only SwiftData storage
- manual client and deployment entry
- searchable client dashboard
- dark card-based operations UI
- inline editing for deployment metadata
- Cloudflare tunnel creation, editing, and deletion
- one-tap opening for saved admin URLs
- custom settings sections with text, URL, port, and password fields
- local delete flows that also clear saved credentials
- Face ID, Touch ID, or passcode-gated credential access

The free version does not include:

- iCloud sync
- active uptime monitoring
- Cloudflare API imports
- reusable custom field templates
- PDF or markdown handover exports
- subscription-only automation features

Those are future Pro features. The free branch should remain useful without depending on them.

## App Structure

Conduit organizes data into three levels:

- **Clients**: a top-level project, customer, server group, or environment.
- **Deployments**: an app or system running for a client.
- **Cloudflare Tunnels**: tunnel entries attached to a deployment.

Each deployment can store routing, database, system access, tunnel, and admin URL details. The deployment list intentionally stays compact: it shows the app name and online/offline status.

Custom settings are available for stack-specific details that do not fit the built-in sections. A custom field can be plain text, a clickable URL, a port, or a Keychain-backed password.

## Credential Safety

Passwords are not stored in SwiftData.

Conduit stores passwords in the iOS Keychain and saves them with device-only accessibility. Credential sections are locked by default and require Face ID, Touch ID, or device passcode authentication before editing.

Current credential types:

- database password
- system access password
- admin access password
- custom password fields

When a deployment or client is deleted, Conduit also deletes the related saved credentials from the Keychain.

## Interface Direction

Conduit uses a dark, card-based operations UI with bold headings, blue action accents, and green/red system status dots. The design direction is documented in [DESIGN.md](DESIGN.md) and should guide future free and Pro screens.

## Offline First

Conduit Free has no backend, no account system, and no remote sync. Server metadata stays in the local SwiftData store, and credentials stay in the local iOS Keychain.

This makes the free version useful for personal workflows, local-first client tracking, and quick reference while working on deployments.

## Development Notes

If the app fails to launch after a SwiftData schema change during development, delete the app from the simulator or device and run it again. This clears the old local store.

The app includes an `NSFaceIDUsageDescription` entry for biometric credential unlock prompts.
