# Backups

### Smart Backups
This project handles backups automatically for installed services.
- **Auto-Discovery**: When you install a service via `install.sh`, a dedicated backup script is generated for it in its directory (e.g., `cloud-services/immich/backup.sh`).
- **Context-Aware**:
  - Services with Databases (Postgres) get a script that dumps the DB + syncs files.
  - Other services get a smart Rsync backup.
- **Master Schedule**: All active services are added to a master backup schedule (`backup/master-backup.sh`).

### Backup Storage Requirements (Crucial)

The backup system uses `rsync` with hard links (`--link-dest`) to create efficient, incremental daily backups. This ensures that unchanged files (like large Immich media or raw data) do not take up additional space.

To make this work, **your backup destination/external drive MUST be formatted with a Linux native file system**.

| File System | Supported | Notes |
| :--- | :--- | :--- |
| **ext4** | **Yes (Recommended)** | Standard Linux format. Rock-solid, preserves permissions, and supports hard links out of the box. |
| **btrfs** | **Yes** | Advanced format. Supports hard links and features built-in transparent compression (great for saving space on DB dumps). |
| **exFAT / FAT32** | NO | Windows/Universal formats. **Do not use.** They do not support Linux hard links or file permissions. Using these will cause backups to copy everything every time, quickly filling up your drive. |
| **NTFS** | NO | Windows format. Poor performance and permission mapping issues under Linux. |

#### Preparing an External USB Drive (Example for ext4)
If you are mounting an external drive for backups, format it to `ext4` using:
```bash
sudo mkfs.ext4 /dev/sdX1 # Replace sdX1 with your actual drive partition
```

### Manual On-Demand Backups
If you want to perform manual, on-demand backups for any installed service (even if it was not originally installed with auto-backup enabled), you can run:
```bash
./run_backups.sh
```
This interactive utility will:
1. Scan your configured Docker root for all installed services.
2. Present a menu to select which services to back up (supports selecting specific services or `all`).
3. Automatically generate the appropriate backup scripts (Rsync or Database Dump) on-demand if they don't already exist.
4. Execute the backups immediately to your target backup destination.
5. Ask whether you'd like to keep the newly generated `backup.sh` scripts in your service directories for future manual runs.
6. Automatically clean up the central schedule registry afterward to keep your daily automatic crontab schedule exactly as it was.
