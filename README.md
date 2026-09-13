## Installing Packages

### Pacman

```sh
sudo pacman -Syu android-tools archlinux-xdg-menu ark awww bluez bluez-utils brightnessctl btop celluloid cliphist evince fastfetch feh git github-cli gnome-keyring grim gvfs-mtp gvfs-gphoto2 hypridle hyprlock hyprpicker hyprpolkitagent hyprsunset imagemagick libmtp matugen nautilus nautilus-python nwg-look pavucontrol pipewire-alsa pipewire-pulse playerctl qt5ct qt6ct quickshell reflector satty slurp starship sushi udiskie ufw unzip vim wl-clip-persist xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xorg-xhost
```

### Yay

```sh
git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si && yay -Syu auto-cpufreq downgrade google-chrome grub-customizer localsend-bin spicetify-cli spotify visual-studio-code-bin
```

# Arch Linux Installation

```sh
------------------Live USB-----------------------------

1. Connecting to internet & time sync:

• iwctl station wlan0 scan
• iwctl station wlan0 connect SSID
• timedatectl set-ntp true


2. Disk operations:

(i) Wiping the disk
• gdisk /dev/sda
• press x for expert mode
• press z for wiping


(ii) Partitioning
• cgdisk /dev/sda
• boot:    1024MiB  (EF00 - EFI System Partition)
• swap:    8GiB     (8200 - Linux swap)
• root:    60GiB    (8300 - Linux filesystem)
• home:    60GiB    (8300 - Linux filesystem)
• storage: (rest)   (8300 - Linux filesystem)


(iii) Formatting
• mkfs.fat -F 32 /dev/sda1
• mkswap /dev/sda2
• swapon /dev/sda2
• mkfs.ext4 /dev/sda3
• mkfs.ext4 /dev/sda4
• mkfs.ext4 /dev/sda5


(iv) Mounting
• mount /dev/sda3 /mnt
• mkdir -p /mnt/boot /mnt/home /mnt/storage
• mount /dev/sda1 /mnt/boot
• mount /dev/sda4 /mnt/home
• mount /dev/sda5 /mnt/storage


3. Sorting mirror list:

• cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
• reflector --latest 20 --protocol https --sort rate --download-timeout 60 --save /etc/pacman.d/mirrorlist


4. Installing Linux base system:

• pacstrap -K /mnt base linux linux-headers linux-firmware base-devel intel-ucode
• genfstab -U /mnt >> /mnt/etc/fstab


5. Chrooting and System Configuration:

(i) Installing essential packages & services
• arch-chroot -S /mnt
• pacman -Syu hyprland kitty uwsm greetd greetd-tuigreet git nano networkmanager grub efibootmgr os-prober ufw zsh
• systemctl enable fstrim.timer
• systemctl enable NetworkManager.service
• systemctl enable greetd.service
• systemctl enable ufw.service
• nano /etc/pacman.conf (uncomment [multilib] section)
• touch /var/tmp/tty-colors.sh
• curl -o /etc/greetd/config.toml https://raw.githubusercontent.com/whoisabdi/dotfiles/master/.config/greetd/config.toml
• curl -o /etc/tuigreet/config.toml https://raw.githubusercontent.com/whoisabdi/dotfiles/master/.config/tuigreet/config.toml

(ii) Localization
• ln -sf /usr/share/zoneinfo/Asia/Karachi /etc/localtime
• hwclock --systohc
• nano /etc/locale.gen (uncomment en_US.UTF-8 UTF-8)
• locale-gen
• echo "LANG=en_US.UTF-8" > /etc/locale.conf

(iii) Security, System administration & User creation
• echo empire > /etc/hostname
• passwd (set strong root password)
• useradd -m -G wheel,storage,power -s /bin/zsh nightwing
• passwd nightwing (set user password)
• EDITOR=nano visudo
• uncomment %wheel ALL=(ALL:ALL) ALL
• ufw default deny incoming
• ufw default allow outgoing


6. Installing bootloader

(i) GRUB (dual boot with Windows)
• mkdir -p /windows
• mount /dev/wbp /windows
• nano /etc/default/grub
• change timeout duration and OS Prober (uncomment GRUB_DISABLE_OS_PROBER=false)
• grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
• grub-mkconfig -o /boot/grub/grub.cfg

OR

(ii) Systemd-boot (Arch only)
• mount -t efivarfs none /sys/firmware/efi/efivars/
• bootctl install
• nano /boot/loader/entries/arch.conf

--  title   Arch Linux                       --
--  linux   /vmlinuz-linux                   --
--  initrd  /intel-ucode.img                 --
--  initrd  /initramfs-linux.img             --
--  options root=PARTUUID=xxxx-xxxx rw       --

(Tip: Run `blkid -s PARTUUID -o value /dev/sda3` to get your root PARTUUID)


7. Finishing it up
• exit
• umount -R /mnt
• reboot and you're done!!

--------------------Arch--------------------------------
```
