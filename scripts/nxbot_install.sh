#!/usr/bin/env bash
# install_isaac_env.sh
# Installs Isaac ROS binaries and Python dependencies for perception / Nav2 work.
# Tested on Ubuntu 22.04 (ROS 2 Humble).  Run with:  sudo ./install_isaac_env.sh
set -euo pipefail

###############################################################################
# 0. Privilege check
###############################################################################
if [[ $EUID -ne 0 ]]; then
  echo "❌  Please run as root: sudo $0"
  exit 1
fi

###############################################################################
# 1. Apt sources & keys
###############################################################################
echo "🔑  Adding Nvidia Isaac ROS repository key and source…"
wget -qO - https://isaac.download.nvidia.com/isaac-ros/repos.key | apt-key add -

ISAAC_SOURCE="deb https://isaac.download.nvidia.com/isaac-ros/release-3 $(lsb_release -cs) legacy-release-3.1"
grep -qxF "$ISAAC_SOURCE" /etc/apt/sources.list || \
  echo "$ISAAC_SOURCE" | tee -a /etc/apt/sources.list

echo "🔑  Adding official ROS 2 key (ros.asc)…"
curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
  | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg

###############################################################################
# 2. Apt update & package install
###############################################################################
echo "🔄  Updating package index…"
apt-get update -y

echo "📦  Installing Isaac ROS binaries and Navigation2 stack (this can take a while)…"
apt-get install -y ros-humble-isaac-ros-perceptor-\* \
                      ros-humble-ros-testing \
                      ros-humble-navigation2 \
                      ros-humble-nav2-bringup

###############################################################################
# 3. Python environment
###############################################################################
echo "🐍  Installing Python packages (system-wide)…"
python3 -m pip install --upgrade pip

pip install nxva filterpy pyyaml tqdm seaborn
pip install ultralytics --no-deps
pip install ultralytics-thop py-cpuinfo

###############################################################################
# 4. Build torchvision v0.20.0 from source
###############################################################################
echo "🔧  Building torchvision v0.20.0 from source…"
WORKDIR=$(mktemp -d)
git clone https://github.com/pytorch/vision.git "$WORKDIR/vision"
pushd "$WORKDIR/vision" >/dev/null
git checkout tags/v0.20.0
FORCE_CUDA=1 python3 setup.py install
popd >/dev/null
rm -rf "$WORKDIR"

echo "✅  All done!  You can now source ROS 2 (e.g. 'source /opt/ros/humble/setup.bash') and start working."
