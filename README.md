# Conduit Free

Conduit is an offline iOS app I am building for freelancers, small agencies, and solo developers who need a clear map of client deployments without keeping everything scattered across notes, spreadsheets, chats, and memory.

For the free version, I am keeping the focus simple: local infrastructure details and sensitive credentials should be organized on the device, easy to reach, and not mixed into a general notes app.

## What I Want It To Help With

I am using Conduit to track the practical details I usually need when maintaining small client systems:

- which clients or projects exist
- which apps are deployed for each client
- whether a system is marked online or offline
- deployment URLs and local system ports
- internal service names and ports
- database names, ports, and sensitive host/token values
- server and admin usernames
- custom text, URL, port, and password fields
- sensitive passwords stored separately in the iOS Keychain

I am not trying to make Conduit an SSH client, uptime monitor, provider dashboard, or CI/CD tracker in the free version. I want it to sit between those tools as a personal offline infrastructure map.

## Free Version Scope

For Conduit Free, I am including:

- local-only SwiftData storage
- manual client and deployment entry
- searchable client dashboard
- dark card-based operations UI
- inline editing for deployment metadata
- flexible internal routing with service-name and port rows
- one-tap opening for saved deployment URLs
- custom settings sections with text, URL, port, and password fields
- local delete flows that also clear saved credentials
- Face ID, Touch ID, or passcode-gated credential access

The free version currently has these limits:

- up to 4 clients
- up to 3 deployments per client
- one database config per deployment
- one system access config per deployment

I am intentionally leaving these out of the free version for now:

- iCloud sync
- active uptime monitoring
- provider/API imports
- provider-specific infrastructure management
- reusable custom field templates
- PDF or markdown handover exports
- subscription-only automation features

Those are future Pro ideas. My goal is for the free branch to stay useful on its own without depending on any paid feature.

## App Structure

I am organizing Conduit around three levels:

- **Clients**: a top-level project, customer, server group, or environment.
- **Deployments**: an app or system running for a client.
- **Internal Routes**: service names and ports for local routing.

Each deployment can store routing, database, system access, admin access, custom settings, and deployment URL details. I am keeping the deployment list compact on purpose: it shows the app name and online/offline status first, then the deeper details live inside the deployment screen.

Custom settings are there for stack-specific details that do not fit the built-in sections. A custom field can be plain text, a clickable URL, a port, or a Keychain-backed password.

## Credential Safety

I am not storing passwords in SwiftData.

Conduit stores passwords and sensitive host/token values in the iOS Keychain with device-only accessibility. Credential rows stay beside their related settings, and they require Face ID, Touch ID, or device passcode authentication before editing.

Current credential types:

- database host/token
- database password
- system access password
- admin access password
- custom password fields

When a deployment or client is deleted, Conduit also deletes the related saved credentials from the Keychain.

## Interface Direction

I am aiming for a dark, card-based operations UI with bold headings, blue action accents, green/red system status dots, and lightweight ArkSoft attribution. The app icon uses the branded background logo, while app screens keep branding minimal with a bottom "Powered by ArkSoft" link.

The design direction is documented in [DESIGN.md](DESIGN.md), and I want future free and Pro screens to stay consistent with it.

## Offline First

Conduit Free has no backend, no account system, and no remote sync. Server metadata stays in the local SwiftData store, and credentials stay in the local iOS Keychain.

That is intentional. I want the free version to be useful for personal workflows, local-first client tracking, and quick reference while working on deployments.

## Development Notes

On a fresh empty install, Conduit seeds sample local data once so I can test the free workflow immediately.

If the app fails to launch after a SwiftData schema change during development, I delete the app from the simulator or device and run it again. That clears the old local store.

The app includes an `NSFaceIDUsageDescription` entry for biometric credential unlock prompts.
