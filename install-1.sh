#!/bin/bash

# Inicio
loadkeys la-latin1
timedatectl set-ntp true > /dev/null

# Describir particiones
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS,PATH,PARTLABEL
sleep 3

# Crear particiones
echo -n "¿Crear particiones? [s/n]: "
read response
if [[ $response == "s" ]]; then
    echo -n "Disco: "
    read disk
    cfdisk $disk

    # Mostrar las particiones nuevamente
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS,PATH,PARTLABEL
    sleep 3
fi

# Registrar las particiones
echo -n "Partición efi:  "
read efi_partition

echo -n "Partición root: "
read root_partition

echo -n "Partición home: "
read home_partition

echo -n "Partición swap: "
read swap_partition

# Formatear las particiones condicionalmente
echo -n "¿Formatear efi? [s/n]:  "
read efi
if [[ $efi == "s" ]]; then
    mkfs.fat -F 32 $efi_partition
fi

echo -n "¿Formatear root? [s/n]: "
read root
if [[ $root == "s" ]]; then
    mkfs.ext4 $root_partition
fi

echo -n "¿Formatear home? [s/n]: "
read home
if [[ $home == "s" ]]; then
    mkfs.ext4 $home_partition
fi

echo -n "¿Formatear swap? [s/n]: "
read swap
if [[ $swap == "s" ]]; then
    mkswap $swap_partition
fi

# Inputs
echo -n "Contraseña root: "
read root_password

echo -n "Nombre de usuario: "
read username

echo -n "Contraseña de usuario: "
read user_password

echo -n "Hostname: "
read hostname

echo -n "Directorio de trabajo: "
read workdir

echo -n "Shell: "
read shell

echo -n "¿Instalar drivers nvidia? [s/n]: "
read nvidia

echo -n "¿Instalar dotfiles? [s/n]: "
read dotfiles

# Montar las particiones
mount $root_partition /mnt
mount --mkdir $efi_partition /mnt/boot
mount --mkdir $home_partition /mnt/home
swapon $swap_partition

# Obtener uuid de root y swap
root_uuid=$(lsblk -dno UUID $root_partition)
swap_uuid=$(lsblk -dno UUID $swap_partition)

# Asegurar que las firmas no estén vencidas
pacman -Sy --noconfirm archlinux-keyring

# Instalación básica
pacstrap /mnt base linux linux-firmware

# Obtener parte 2
curl -LJO https://raw.githubusercontent.com/pinguin-frosch/arch-install-script/$rama/install-2.sh
curl -LJO https://raw.githubusercontent.com/pinguin-frosch/arch-install-script/$rama/programs/pacman.txt
chmod +x install-2.sh
mv install-2.sh pacman.txt /mnt

# Pasar datos a install-2.sh
echo "root_password=$root_password" >> envvars
echo "username=$username" >> envvars
echo "user_password=$user_password" >> envvars
echo "hostname=$hostname" >> envvars
echo "nvidia=$nvidia" >> envvars
echo "root_uuid=$root_uuid" >> envvars
echo "swap_uuid=$swap_uuid" >> envvars
echo "rama=$rama" >> envvars
echo "dotfiles=$dotfiles" >> envvars
echo "workdir=$workdir" >> envvars
echo "shell=$shell" >> envvars
mv envvars /mnt

# Fstab y chroot
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt ./install-2.sh

# Reiniciar
rm /mnt/install-2.sh /mnt/pacman.txt
reboot
