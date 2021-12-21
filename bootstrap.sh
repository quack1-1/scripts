#!/usr/bin/env sh

#vmc start termina
lxc stop penguin --force &&
lxc rename penguin debian &&
lxc launch ubuntu:18.04 penguin &&
lxc exec penguin -- bash
#as root user
apt update && apt upgrade &&
echo "deb https://storage.googleapis.com/cros-packages bullseye main" > /etc/apt/sources.list.d/cros.list &&
if [ -f /dev/.cros_milestone ]; then sudo sed -i "s?packages?packages/$(cat /dev/.cros_milestone)?" /etc/apt/sources.list.d/cros.list; fi &&
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1397BC53640DB551 &&
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7638D0442B90D010 &&
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC &&
apt update && 
apt install binutils && 
apt download cros-ui-config &&
ar x cros-ui-config_0.12_all.deb data.tar.gz &&
gunzip data.tar.gz &&
tar f data.tar --delete ./etc/gtk-3.0/settings.ini &&
gzip data.tar &&
ar r cros-ui_config_0.12_all.deb data.tar.gz &&
apt install cros-guest-tools ./cros-ui-config_0.12_all.deb && 
rm cros-ui-config_0.12_all.deb &&
rm -rf data.tar.gz &&
apt install adwaita-icon-theme-full &&
sudo apt-get install gnome-tweaks && 
sudo apt-get install nautilus && 
sudo apt-get install gnome-terminal && 
sudo apt-get install zsh && 
sudo apt-get install neofetch &&
sudo apt-get install libreoffice && 
sudo apt-get install gedit && 
sudo apt-get install eog && 
sudo apt-get install celluloid &&
shutdown -h now
#in terminal app
sudo do-release-upgrade &&
sudo nano /etc/update-manager/release-upgrades &&
sudo do-release-upgrade &&
sudo do-release-upgrade
echo "Script finished. Running neofetch to check"
neofetch