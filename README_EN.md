# MIB2 Toolbox — MMI Mirror V2.4.1

**English** | [简体中文](README.md)

This project is designed for the Audi **MHI2Q** platform. It mirrors the MMI center display in real time to the map area of the **Virtual Cockpit**, with installation, start/stop control, updates, diagnostics, and uninstall/recovery integrated into the Green Engineering Menu / Toolbox.

> [!WARNING]
> **⚠️ A note before you start**
>
> During the earlier testing phase, some people repackaged and resold test builds of this project without permission. Seeing freely shared test work used for profit was one of the main reasons public development was stopped.
>
> The version published here is the most complete build retained from that testing period and has been validated in a real vehicle. This update is being released because the previously public build had become significantly outdated; it does **not** mean that long-term development has resumed.
>
> Our main development focus has now moved to **AltScreen**, whose core development is already largely complete. Unless a major bug affecting normal use is found, this project will no longer receive regular development or feature updates. CarLife support may be considered in the future, but there is no commitment.
>
> **This project is free and open source. Reselling it is prohibited.**
>
> You are welcome to learn from it, study it, and discuss it, but please do not repackage free work and sell it for profit.

> [!IMPORTANT]
> This project modifies system files on the head unit. Keep the SD card inserted and maintain stable power during installation, update, or uninstall operations.  
> **After installation or update, you must reboot the head unit / HMI before judging the result.**
>
> Do not perform installation, update, uninstall, or troubleshooting operations while driving.

---

<img width="1707" height="1280" alt="1fcb77abdb31026899b34a0c393d8056" src="https://github.com/user-attachments/assets/6098f5b9-f08b-40c0-a651-03676b7703d6" />

<img width="1707" height="1280" alt="131ec8d28840b205975e61d9b2784842" src="https://github.com/user-attachments/assets/033f645f-8a3b-4886-95b6-6a272c62e9ac" />

https://github.com/user-attachments/assets/54a7e453-c473-428b-8cbe-08c460c59622

Current features:

- Mirrors the MMI center display to the Virtual Cockpit map area in real time.
- Supports **Classic / Sport** cluster layouts.
- Supports **Full / Small** map-area changes.
- Dynamically adjusts the mirror display region according to the current cluster state.
- Supports source Crop, Scale, Offset, and natural edge clipping.
- When switching between Classic / Sport or Full / Small layouts, the watermark movement area is recalculated based on the new mirror position and visible cropped region.
- Supports manual start / stop.
- Supports AutoStart: when CarPlay starts and becomes available, MMI Mirror starts automatically.
- Supports direct in-place updates from older versions.
- Supports diagnostics and complete uninstall.

Current native binary:

~~~text
mmi-mirror-display
SHA256:
ee48454507b24ed1cb1f72c1f8ee5202e16e2b58dd045c64a594a3dec0c5d1d5
~~~

You can also verify the package using:

~~~text
Toolbox/apps/mmi-mirror/V2.4.1-SHA256SUMS
~~~

---

## Download and SD card preparation

Download the ZIP of the **main** branch and extract it.

Place the following items in the root directory of the SD card:

~~~text
metainfo2.txt
Toolbox/
~~~

Correct structure:

~~~text
SD CARD
├── metainfo2.txt
└── Toolbox
    ├── GEM
    ├── apps
    ├── final
    └── scripts
~~~

Do not keep the repository folder as an extra parent directory.

For example, this is incorrect:

~~~text
SD CARD
└── MHI2Q-CarPlay-MMI-Mirror-main
    ├── metainfo2.txt
    └── Toolbox
~~~

---

# Installation and usage

## 1. Update Toolbox

Copy:

~~~text
metainfo2.txt
Toolbox/
~~~

to the root of your Toolbox SD card.

Use the normal MIB2 High Toolbox update procedure so that the head unit loads the new GEM menus, scripts, and runtime files.

After the Toolbox update is complete, it is recommended to:

~~~text
Exit Green Engineering Menu
        ↓
Enter Green Engineering Menu again
~~~

This ensures that the new MMI Mirror menu is reloaded.

---

## 2. Install MMI Mirror

Go to:

~~~text
Main
  ↓
MQBCoding
  ↓
Customization
  ↓
MMI Mirror
~~~

Main menu entries:

| Menu item | Function |
| --- | --- |
| Install/Update MMI Mirror | First-time installation or in-place update |
| Start MMI Mirror | Manually start MMI Mirror |
| Stop MMI Mirror | Stop the current MMI Mirror session |
| AutoStart ON - start after MMI boot | Enable automatic start: MMI Mirror starts after CarPlay becomes active |
| AutoStart OFF - manual start only | Disable future automatic start |
| Copy MMI Mirror diagnostics to SD-card | Copy diagnostic logs to the SD card |
| Clear temporary MMI Mirror logs | Clear temporary runtime logs |
| Restore/Uninstall MMI Mirror | Uninstall MMI Mirror and restore the pre-install state |

Keep the SD card inserted and select:

~~~text
Install/Update MMI Mirror
~~~

The installer will:

~~~text
Check installation files on the SD card
        ↓
Stop any currently running older MMI Mirror session
        ↓
Create a new staged runtime
        ↓
Copy and verify the new binary / scripts / config
        ↓
Keep the old runtime temporarily as rollback
        ↓
Switch to the new runtime
        ↓
Run the binary loader self-test
        ↓
Run the launcher shell self-test
        ↓
Complete installation
~~~

If an error occurs during the update, the installer will try to restore the previous runtime instead of leaving a simple partial-overwrite state.

Installation log:

~~~text
Backup/<VERSION>/MMIMirror/install_mmi_mirror.log
~~~

where `<VERSION>` is the current firmware version of the head unit.

---

## 3. After installation

After a successful installation, **you must reboot the head unit / HMI**.

Recommended flow:

~~~text
Install/Update MMI Mirror
        ↓
Confirm installation succeeded
        ↓
Reboot head unit / HMI
        ↓
Wait for the system to fully boot
        ↓
Open the MMI Mirror menu again
        ↓
Start MMI Mirror
        ↓
Confirm the cluster mirror is working normally
~~~

Do not judge the result by starting MMI Mirror immediately after installation but before rebooting. The files on disk may already have been replaced while old processes or runtime state are still active in memory.

---

# Reinstallation / version upgrade

## Can an older MMI Mirror installation be upgraded directly?

**Yes.**

Under normal conditions, **you do not need to uninstall the previous version first**.

Simply use the new SD card package and run:

~~~text
Install/Update MMI Mirror
~~~

The installer detects an existing installation at:

~~~text
/mnt/app/root/mmi-mirror
~~~

If an existing installation or running MMI Mirror session is found, the installer first stops the old session and then switches to the new version using staged runtime + rollback handling instead of overwriting files one by one inside the live runtime directory.

### Recommended upgrade procedure

If AutoStart is currently enabled, first run:

~~~text
AutoStart OFF - manual start only
~~~

Then:

~~~text
Prepare the new SD card package
        ↓
Install/Update MMI Mirror
        ↓
Confirm the installation log reports success
        ↓
Reboot head unit / HMI
        ↓
Manually Start MMI Mirror
        ↓
Confirm mirror and layout behavior are normal
        ↓
Re-enable AutoStart if desired
~~~

### What is required for an upgrade?

You only need the new package:

~~~text
metainfo2.txt
Toolbox/
~~~

Make sure the following files and directories all come from the **same release package**:

~~~text
Toolbox/apps/mmi-mirror/mmi-mirror-display
Toolbox/apps/mmi-mirror/scripts/
Toolbox/apps/mmi-mirror/config.local
Toolbox/scripts/
Toolbox/GEM/
~~~

**Do not upgrade by copying only a new `mmi-mirror-display` binary into an old package.**

The V2.4.1 native binary, startup scripts, layout configuration, GEM menu, installer, and uninstaller are designed to work together and should be updated as one complete package.

### What happens to config.local?

The current package includes:

~~~text
Toolbox/apps/mmi-mirror/config.local
~~~

Therefore, Install/Update will prefer the configuration included on the SD card.

If you manually changed Crop / Scale / Offset values in an older version, back up the old `config.local` first and review those values again after upgrading.

---

# Manual start and stop

## Start

Go to:

~~~text
Main > MQBCoding > Customization > MMI Mirror
~~~

Select:

~~~text
Start MMI Mirror
~~~

MMI Mirror will begin capturing the center MMI display and output it to the Virtual Cockpit map area.

## Stop

Select:

~~~text
Stop MMI Mirror
~~~

This ends the current MMI Mirror session but does not uninstall the program.

You can start it again later with `Start MMI Mirror`.

---

# AutoStart

After confirming that manual start works correctly, select:

~~~text
AutoStart ON - start after MMI boot
~~~

This enables automatic start mode.

AutoStart does **not** immediately start the mirror just because the head unit has booted. After the required MMI runtime environment is ready, it waits for **CarPlay to start and become available**. MMI Mirror is started automatically only after CarPlay is detected as active.

Once AutoStart is enabled, the SD card does not need to remain inserted during normal daily use.

To disable it:

~~~text
AutoStart OFF - manual start only
~~~

AutoStart OFF disables future CarPlay-triggered automatic starts.

If MMI Mirror is already running, it will not stop the current session automatically. To stop the current session, also run:

~~~text
Stop MMI Mirror
~~~

### Before updating or uninstalling

If AutoStart is enabled, it is recommended to disable AutoStart before performing an update or uninstall.

After the operation and reboot, test the system manually first, then re-enable AutoStart if needed.

---

# Logs and troubleshooting

If you encounter:

- MMI Mirror fails to start
- MMI Mirror exits after starting
- Black screen in the cluster
- Incorrect mirror position
- Sport / Classic layout switching issues
- Full / Small display-region issues
- Update or uninstall failure

Go to:

~~~text
Main > MQBCoding > Customization > MMI Mirror
~~~

Select:

~~~text
Copy MMI Mirror diagnostics to SD-card
~~~

Diagnostic data will be stored at:

~~~text
Backup/<VERSION>/MMIMirror/RuntimeLogs/<TIMESTAMP>/
~~~

Installation log:

~~~text
Backup/<VERSION>/MMIMirror/install_mmi_mirror.log
~~~

If you want to reproduce an issue with a cleaner temporary log state, use:

~~~text
Clear temporary MMI Mirror logs
~~~

This clears disposable temporary logs only. It does not stop or uninstall MMI Mirror.

---

# Uninstall / recovery

If AutoStart has been enabled, it is recommended to disable it first:

~~~text
AutoStart OFF - manual start only
~~~

If MMI Mirror is currently running, you may stop it first:

~~~text
Stop MMI Mirror
~~~

Then select:

~~~text
Restore/Uninstall MMI Mirror
~~~

The uninstall script removes the current MMI Mirror runtime and restores relevant files according to the state recorded during installation.

During uninstall:

- Do not remove the SD card.
- Do not interrupt power to the head unit.
- Do not force reboot midway through the process.

After uninstall completes, **you must reboot the head unit / HMI**.

Recommended flow:

~~~text
AutoStart OFF
        ↓
Stop MMI Mirror
        ↓
Restore/Uninstall MMI Mirror
        ↓
Confirm uninstall succeeded
        ↓
Reboot head unit / HMI
        ↓
Confirm the stock display works normally
~~~

If uninstall reports an error, first preserve:

~~~text
Backup/<VERSION>/MMIMirror/
~~~

including its logs and backup files. Do not repeatedly run cleanup operations or manually delete files on the head unit.

---

# SD card backups

Installation, update, and uninstall scripts create:

~~~text
Backup/<VERSION>/MMIMirror/
~~~

This directory may contain:

- Installation logs
- State information required for uninstall / recovery
- Diagnostic logs
- Runtime state snapshots
- Required recovery files

**Do not casually delete the Backup directory.**

Keep it at least until installation, update, or uninstall has completed successfully and the head unit has been rebooted and verified to be working normally.

---

# Branches

Current recommended version:

~~~text
main
└── V2.4.1
    └── Vehicle validated
~~~

Older backup:

~~~text
V2.2
└── Complete historical backup of the previous main branch
~~~

---

# Open-source notice

This is a free and open-source project.

> **Free and open source. Reselling is prohibited.**

---

# Acknowledgements

Thanks to the following projects and authors for their foundational work and references:

- [yuedizhibo / mib2q-MMI-Cockpit-Mirror](https://github.com/yuedizhibo/mib2q-MMI-Cockpit-Mirror) — Important foundation for mirroring the MMI center display to the Virtual Cockpit.
- [OneB1t / VcMOSTRenderMqb](https://github.com/OneB1t/VcMOSTRenderMqb) — Important research foundation for MQB Virtual Cockpit / MOST custom rendering.
- [fifthBro / mh2p-cluster](https://github.com/fifthBro/mh2p-cluster) — Useful reference for QNX HMI capture and GPU crop / zoom / pan approaches.
- [jilleb / mib2-toolbox](https://github.com/jilleb/mib2-toolbox) — MIB2 High Toolbox, Green Engineering Menu, and deployment framework.

Upstream files and components remain subject to their original licenses and copyright notices.
