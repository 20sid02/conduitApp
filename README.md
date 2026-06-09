<p align="center">
  <img src="assets/logo-new.png" width="128" alt="Conduit app icon">
</p>

<h1 align="center">Conduit</h1>

<p align="center">
  A private iOS workspace for keeping client deployments, ports, access details, and credentials organized on-device.
</p>

<p align="center">
  <img alt="iOS" src="https://img.shields.io/badge/iOS-26.5+-0A84FF?style=for-the-badge&logo=apple&logoColor=white">
  <img alt="Offline First" src="https://img.shields.io/badge/offline--first-local%20data-22C55E?style=for-the-badge">
  <img alt="Keychain Protected" src="https://img.shields.io/badge/credentials-Keychain%20protected-111827?style=for-the-badge">
  <img alt="Beta" src="https://img.shields.io/badge/status-closed%20beta-F59E0B?style=for-the-badge">
</p>

<p align="center">
  <a href="https://arksoft.xyz">
    <img alt="Powered by ArkSoft" src="https://img.shields.io/badge/Powered%20by-ArkSoft-0A84FF?style=flat-square">
  </a>
</p>

---

## What Conduit Is

Conduit is built for people who manage small client systems and need a clear, private place to remember what runs where.

Instead of spreading deployment details across notes, chats, spreadsheets, and memory, Conduit keeps the practical pieces together:

| Area | What it helps track |
| --- | --- |
| **Clients** | Projects, companies, or server groups |
| **Deployments** | Apps or systems attached to each client |
| **System Info** | Online/offline status, deployment URL, IP, location, and system port |
| **Database Config** | Database name, port, sensitive host/token value, and password |
| **Internal Routing** | Service names and ports used inside the deployment |
| **Admin Access** | Admin username and protected password |
| **Custom Options** | Extra text, URL, port, or password fields for stack-specific notes |

---

## Highlights

<table>
  <tr>
    <td width="50%">
      <h3>Private by Default</h3>
      <p>No account, backend, or sync requirement. Deployment records stay on the device.</p>
    </td>
    <td width="50%">
      <h3>Credential Aware</h3>
      <p>Sensitive values are stored separately in the iOS Keychain and unlocked with Face ID, Touch ID, or passcode.</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>Built for Real Deployments</h3>
      <p>Track URLs, ports, internal services, database details, and admin access without assuming one specific tech stack.</p>
    </td>
    <td width="50%">
      <h3>Flexible Custom Fields</h3>
      <p>Add custom categories with text, URL, port, or password fields when a deployment needs something unique.</p>
    </td>
  </tr>
</table>

---

## Preview

<p align="center">
  <img src="assets/appImages/Simulator%20Screenshot%20-%20Clone%202%20of%20iPhone%2017%20-%202026-06-09%20at%2023.54.30.png" width="220" alt="Conduit keyring dashboard">
  <img src="assets/appImages/Simulator%20Screenshot%20-%20Clone%202%20of%20iPhone%2017%20-%202026-06-09%20at%2023.54.50.png" width="220" alt="Conduit client deployment list">
  <img src="assets/appImages/Simulator%20Screenshot%20-%20Clone%202%20of%20iPhone%2017%20-%202026-06-09%20at%2023.54.54.png" width="220" alt="Conduit deployment detail screen">
</p>

<p align="center">
  <img src="assets/appImages/Simulator%20Screenshot%20-%20Clone%202%20of%20iPhone%2017%20-%202026-06-09%20at%2023.55.17.png" width="220" alt="Conduit custom option form">
</p>

---

## Conduit Free

Conduit Free is designed to be useful without a paid upgrade.

<details open>
<summary><strong>Included in the free beta</strong></summary>

| Feature | Included |
| --- | :---: |
| Local client and deployment tracking | Yes |
| Offline-first storage | Yes |
| Keychain-backed credentials | Yes |
| Biometric/passcode unlock | Yes |
| Internal routing and port tracking | Yes |
| Database and admin access sections | Yes |
| Custom text, URL, port, and password fields | Yes |
| In-app feedback email | Yes |
| Delete all local data option | Yes |

</details>

<details>
<summary><strong>Current free limits</strong></summary>

| Limit | Value |
| --- | --- |
| Clients | 4 |
| Deployments per client | 3 |
| Database config per deployment | 1 |
| Admin access section per deployment | 1 |
| Internal routing entries | Multiple |
| Custom options | Multiple |

</details>

<details>
<summary><strong>Not included in Conduit Free</strong></summary>

These are not part of the free beta:

- iCloud sync
- uptime monitoring
- Cloudflare or hosting-provider imports
- PDF or markdown infrastructure reports
- team sharing
- automated deployment checks

</details>

---

## Security Model

Conduit does not store passwords in the main app database.

General deployment records are stored locally with SwiftData. Passwords and sensitive token-like values are stored separately in the iOS Keychain using device-bound protection.

When a client or deployment is deleted, Conduit also removes its related saved credentials from the device.

---

## Beta Status

Conduit is currently prepared for closed beta testing.

The beta focus is simple:

- confirm the app is easy to understand on first launch
- test adding and editing real deployment information
- verify credential unlock and save flows
- check that deletion and local reset flows behave clearly
- collect feedback before adding larger paid features

---

## From ArkSoft

Conduit is made by ArkSoft as a focused utility for developers, freelancers, and small teams who want a calmer way to keep deployment details close at hand.

<p>
  <a href="https://arksoft.xyz">
    <img alt="Visit ArkSoft" src="https://img.shields.io/badge/Visit-ArkSoft-0A84FF?style=for-the-badge">
  </a>
</p>
