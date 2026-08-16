# OCI FinOps Monitor — Linux Edition

A Streamlit dashboard for monitoring Oracle Cloud Infrastructure (OCI) spend
and surfacing rule-based cost-saving recommendations. Functionally identical
to the Windows VM build — same dashboard, same recommendation logic — packaged
for a Linux host instead.

## What it does

- Pulls daily cost/usage data from OCI's Usage API
- Shows total spend, daily average, month-over-month change, and a spend trend chart
- Breaks down spend by service and by compartment
- Scans for common cost-waste patterns and estimates potential monthly savings:
  - Unattached block volumes still billing
  - Long-stopped compute instances still billing attached storage
  - (Extendable — see `oci_finops.py` to add more rules)

## Requirements

- Linux VM (any distro with Python 3.9+; tested against Ubuntu/OEL conventions)
- Python 3.9+
- An OCI API signing key with **read access to the Usage/Cost API** for the
  tenancy you want to monitor (policy: `Allow group FinOpsViewers to read
  usage-report in tenancy`, plus read access to compute/block-storage
  resources for the recommendation engine)

## Quick install

```bash
git clone <your-repo-or-copy-this-folder> oci-finops-monitor
cd oci-finops-monitor
chmod +x install.sh
./install.sh
```

If you haven't set up OCI CLI credentials on this host yet:

```bash
pip install oci-cli --user
oci setup config
```

This creates `~/.oci/config` and a key pair — same file format the app reads
via the OCI Python SDK's default config loader, on any OS.

## Running it manually

```bash
venv/bin/streamlit run app.py --server.port 8501 --server.address 0.0.0.0
```

Then browse to `http://<vm-ip>:8501`.

## Running as a background service (recommended for a VM)

1. Copy the app to `/opt/oci-finops-monitor` (or update the paths in the
   service file to match wherever you placed it):

   ```bash
   sudo mkdir -p /opt/oci-finops-monitor
   sudo cp -r ./* /opt/oci-finops-monitor/
   sudo useradd -r -m -d /home/finops finops   # dedicated service account
   sudo chown -R finops:finops /opt/oci-finops-monitor
   ```

2. Set up the OCI config for that service user:

   ```bash
   sudo -u finops oci setup config   # or manually copy ~/.oci/config
   ```

3. Install the systemd unit:

   ```bash
   sudo cp finops-monitor.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now finops-monitor
   ```

4. Check status / logs:

   ```bash
   sudo systemctl status finops-monitor
   sudo journalctl -u finops-monitor -f
   ```

5. Open port 8501 on the VM's security list / NSG if accessing remotely, or
   put it behind a reverse proxy (nginx) with TLS for anything internet-facing.

## Project structure

```
oci-finops-monitor/
├── app.py                   # Streamlit dashboard (UI layer)
├── oci_finops.py             # OCI SDK calls + recommendation engine
├── requirements.txt
├── install.sh                 # venv setup script
├── finops-monitor.service     # systemd unit for always-on deployment
└── README.md
```

## Notes on parity with the Windows build

- Same dashboard layout, metrics, charts, and recommendation logic
- Same config file format (`~/.oci/config` on Linux vs.
  `%USERPROFILE%\.oci\config` on Windows) — the OCI SDK resolves this
  automatically, no code changes needed between platforms
- Only OS-specific pieces are packaging/deployment: this build uses a
  venv + systemd service instead of a Windows service/Task Scheduler entry
