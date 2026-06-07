# Conduit

Conduit is an offline iOS app for keeping track of personal server deployments, local ports, tunnels, and sensitive credentials in one place.

It is built for a simple personal workflow: open a client, see the apps deployed on that server, check the important ports and routing details, and unlock passwords only when needed.

## What Conduit Tracks

Conduit organizes infrastructure into three levels:

- **Clients**: the top-level grouping for a person, project, server, or environment.
- **Deployments**: apps or systems running under a client.
- **Cloudflare Tunnels**: tunnel names and ports attached to a deployment.

Each deployment can store:

- app name
- online/offline status
- admin URL override
- local system port
- Gunicorn port
- Nginx port
- database name
- database port
- system username
- Cloudflare tunnel entries

## Credentials

Passwords are not stored in SwiftData.

Conduit stores passwords in the iOS Keychain and protects access with Face ID, Touch ID, or device passcode fallback. Credential items are saved with device-only accessibility, so they stay tied to the current device.

Current credential types:

- database password
- system access password
- Django admin superuser password

From a deployment screen, unlock the relevant credential section, edit or enter the password, then save. The view locks again after saving.

## Current App Flow

1. Open Conduit.
2. Add a client.
3. Open the client.
4. Add a deployment for an app running on that client/server.
5. Fill in routing, database, system access, and tunnel details.
6. Unlock credential fields only when you need to view or update passwords.

The deployment list intentionally stays compact: it shows the app name and an online/offline indicator.

## Offline First

Conduit is designed for local, offline personal use. Server metadata is stored on device with SwiftData, and credentials are stored separately in the iOS Keychain.

There is no remote sync, account system, or backend dependency in the current version.

## Current Status

Conduit is usable as a personal deployment tracker.

Implemented so far:

- client list and client detail screens
- deployment creation and editing
- inline editing for deployment settings
- Cloudflare tunnel creation, editing, and deletion
- add-option sheet for deployment details
- Keychain-backed credential storage
- biometric/passcode-gated credential unlock

## Notes

If the app fails to launch after a schema change during development, delete the app from the simulator/device and run it again. This clears the old local SwiftData store.

For Face ID testing, the app should include an `NSFaceIDUsageDescription` entry in its app settings.
