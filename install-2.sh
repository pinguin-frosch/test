#!/bin/bash

# Recuperar datos install-1.sh
source envvars

# Software a instalar
pacman -S --noconfirm --needed - < pacman.txt
ln -s /usr/bin/ksshaskpass /usr/lib/ssh/ssh-askpass

# Nvidia
if [[ $nvidia == "s" ]]; then
    pacman -S --noconfirm --needed nvidia nvidia-utils nvidia-settings nvidia-prime
fi

# Contraseña root
echo -e "$root_password\n$root_password" | passwd

# Creación y configuración usuario
useradd -m $username
echo -e "$user_password\n$user_password" | passwd $username
usermod -aG wheel $username
usermod -s /usr/bin/zsh $username

# Configuración básica
echo "$hostname" >> /etc/hostname
ln -sf /usr/share/zoneinfo/America/Santiago /etc/localtime
hwclock --systohc
sed -i "s/^#es_CL.UTF-8 UTF-8/es_CL.UTF-8 UTF-8/" /etc/locale.gen
locale-gen
echo "LANG=es_CL.UTF-8" >> /etc/locale.conf
echo "KEYMAP=la-latin1" >> /etc/vconsole.conf

# Configuración sudo
sed -i "s/^# %wheel ALL=(ALL:ALL) ALL.*/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers

# Instalación y configuración systemd-boot
bootctl install
echo -e "default @saved\ntimeout 2\nconsole-mode max" > /boot/loader/loader.conf
echo -e "title Arch Linux\nlinux /vmlinuz-linux\ninitrd /initramfs-linux.img\noptions root=UUID=$root_uuid rw quiet loglevel=3 resume=UUID=$swap_uuid" > /boot/loader/entries/arch.conf

# Registrar hook para hibernación
sed -i "s|keyboard|resume keyboard|" /etc/mkinitcpio.conf

# Servicios
systemctl enable NetworkManager
systemctl enable sddm
systemctl enable bluetooth
systemctl enable cups

# Descargar y registrar pro
curl -LJO https://raw.githubusercontent.com/pinguin-frosch/arch-install-script/main/keymap/pro
mv pro /usr/share/X11/xkb/symbols/.

# Configurar teclado en sddm
echo "setxkbmap latam,pro" >> /usr/share/sddm/scripts/Xsetup

# Continuación
curl -LJO https://raw.githubusercontent.com/pinguin-frosch/arch-install-script/main/install-3.sh
curl -LJO https://raw.githubusercontent.com/pinguin-frosch/arch-install-script/main/programs/yay.txt
chown $username:$username install-3.sh
chown $username:$username yay.txt
chmod u+x install-3.sh
mv install-3.sh yay.txt /home/$username/.

# Eliminar envvars
rm envvars

# Salir
exit
