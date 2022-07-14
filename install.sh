#!/usr/bin/env bash
#
# NAME: Install script
# DESC: An installation and deployment script for Kazu's Qtile desktop.
# WARNING: Run this script at your own risk.
# DEPENDENCIES: 

if [ "$(id -u)" = 0 ]; then
    echo "##################################################################"
    echo "This script MUST NOT be run as root user since it makes changes"
    echo "to the \$HOME directory of the \$USER executing this script."
    echo "The \$HOME directory of the root user is, of course, '/root'."
    echo "We don't want to mess around in there. So run this script as a"
    echo "normal user. You will be asked for a sudo password when necessary."
    echo "##################################################################"
    exit 1
fi

echo "################################################################"
echo "## Syncing the repos and installing 'dialog' if not installed ##"
echo "################################################################"
sudo pacman --noconfirm --needed -Syu dialog || error "Error syncing the repos."

error() { \
    clear; printf "ERROR:\\n%s\\n" "$1" >&2; exit 1;
}

speedwarning() { \
    dialog --colors --title "\Z7\ZbInstalling!" --yes-label "Continue" --no-label "Exit" --yesno  "\Z4WARNING! The ParallelDownloads option is not enabled in /etc/pacman.conf. This may result in slower installation speeds. Are you sure you want to continue?" 16 60 || error "User choose to exit."
}

distrowarning() { \
    dialog --colors --title "\Z7\ZbInstalling!" --yes-label "Continue" --no-label "Exit" --yesno  "\Z4WARNING! While this script works on all Arch based distros, some distros choose to package certain things that we also package, please look at the package list and remove conflicts manually. Are you sure you want to continue?" 16 60 || error "User choose to exit."
}

grep -qs "#ParallelDownloads" /etc/pacman.conf && speedwarning
grep -qs "ID=arch" /etc/os-release || distrowarning

# --------------------------------------------------------------------------------------------------------

# Let's install each package listed in the pkglist.txt file.
sudo pacman --needed --ask 4 -Sy - < pkglist.txt || error "Failed to install required packages."

# Installing AUR helper yay
echo "######################################"
echo "## Installing yay as AUR helper.    ##"
echo "######################################"
cd /opt/
sudo git clone https://aur.archlinux.org/yay-git.git
sudo chown -R $USER:$USER yay-git/
cd yay-git
makepkg -si
cd ~/dotfiles-arch

echo "######################################"
echo "## Installing AUR packages.         ##"
echo "######################################"
yay --needed -Sy nerd-fonts-fira-code

# Changing the default shell to fish.
sudo chsh $USER -s "/bin/fish" &&
echo -e "fish has been set as your default USER shell. \nLogging out is required for this take effect."

# Copying config files
echo "################################################################"
echo "## Copying configuration files from /etc/dotfiles into \$HOME ##"
echo "################################################################"
[ ! -d /etc/dotfiles ] && sudo mkdir /etc/dotfiles
[ -d /etc/dotfiles ] && mkdir ~/dotfiles-backup-$(date +%Y.%m.%d-%H%M) && cp -Rf /etc/dotfiles ~/dotfiles-backup-$(date +%Y.%m.%d-%H%M)
[ ! -d ~/.config ] && mkdir ~/.config
[ -d ~/.config ] && mkdir ~/.config-backup-$(date +%Y.%m.%d-%H%M) && cp -Rf ~/.config ~/.config-backup-$(date +%Y.%m.%d-%H%M)
cp -Rf . /etc/dotfiles
cd /etc/dotfiles && cp -Rf . ~ && cd -

# Change all scripts in .local/bin to be executable.
find $HOME/.local/bin -type f -print0 | xargs -0 chmod 775

echo "######################################"
echo "## Enable lightdm as login manager. ##"
echo "######################################"
# Disable the current login manager
sudo systemctl disable $(grep '/usr/s\?bin' /etc/systemd/system/display-manager.service | awk -F / '{print $NF}') || echo "Cannot disable current display manager."
# Enable sddm as login manager
sudo systemctl enable lightdm

# Copying themes

# Kvantum to change the default theme of Qt application
echo "export QT_STYLE_OVERRIDE=kvantum" >> ~/.profile

while true; do
    read -p "Do you want to reboot? [Y/n] " yn
    case $yn in
        [Yy]* ) reboot;;
        [Nn]* ) break;;
        "" ) reboot;;
        * ) echo "Please answer yes or no.";;
    esac
done
