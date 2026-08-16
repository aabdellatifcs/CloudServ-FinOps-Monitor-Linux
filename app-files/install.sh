#!/usr/bin/env bash
#
# install.sh - sets up OCI FinOps Monitor on a Linux host
#
# Usage:
#   chmod +x install.sh
#   ./install.sh
#
set -e

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$APP_DIR/venv"

echo "==> Installing OCI FinOps Monitor"
echo "    App directory: $APP_DIR"

sudo systemctl disable firewalld && sudo systemctl stop firewalld && sudo dnf install -y python3.9 python3-devel && sudo dnf install -y pip


# 2. Create virtual environment
echo "==> Creating virtual environment at $VENV_DIR"
python3 -m venv "$VENV_DIR"

# 3. Install dependencies
echo "==> Installing Python dependencies"
"$VENV_DIR/bin/pip3" install --upgrade pip
"$VENV_DIR/bin/pip3" install streamlit
"$VENV_DIR/bin/pip3" install -r "$APP_DIR/requirements.txt"

# 4. Check for OCI CLI config
if [ ! -f "$HOME/.oci/config" ]; then
    echo ""
    echo "NOTE: No OCI config found at ~/.oci/config"
    echo "Run the following to set up API credentials before starting the app:"
    echo "  pip3 install oci-cli --user   # if the CLI itself isn't installed"
    echo "  oci setup config"
    echo ""
fi

echo "==> Install complete."
echo ""
echo "To run the dashboard manually:"
echo "  $VENV_DIR/bin/streamlit run $APP_DIR/app.py --server.port 8501 --server.address 0.0.0.0"
echo ""
echo "To install as a systemd service instead, see README.md."
