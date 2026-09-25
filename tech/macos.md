---
type: reference
---
## macOS
macOS bits.

- [iCloud Photos Backup Guide](icloud-photos.md)

### Mac Migration
- Update hostname: 

```bash
sudo scutil --set HostName <new_name>
sudo scutil --set LocalHostName <new_name>
sudo scutil --set ComputerName <new_name>
dscacheutil -flushcache
```

- Install Homebrew as per <https://brew.sh/>

- Install the usual suspects using `brew`
    - `brew install iterm2 coreutils fd jq git vscodium duckduckgo imagemagick appcleaner ffmpeg pwgen nmap iperf3 gnutls python go`

- Install every [gkit](https://github.com/queone/gkit) utility, once Go is in from the brew list above or from the [Go](go.md) page
    - `go install github.com/queone/gkit/cmd/...@latest`
    - Binaries land in `$GOPATH/bin`, which the `.bashrc` below puts on `PATH`

- iTerm2
    - Use the saved preferences from your private settings folder

- VSCodium
    - On SRC: `cd && tar czf codium.tar.gz --exclude='*.sock' Library/Application\ Support/VSCodium`, then keep the archive in your private settings folder
    - On DST: `cd && tar xzf codium.tar.gz`

- Switch to BASH: `chsh -s /bin/bash`

- Update screen capture behaviour with [mac_screencap.sh](https://github.com/queone/gkit/blob/main/scripts/mac_screencap.sh) from the gkit scripts folder


### BASHRC
Both files live in the gkit scripts folder: [bashrc_user.sh](https://github.com/queone/gkit/blob/main/scripts/bashrc_user.sh) for a user account and [bashrc_root.sh](https://github.com/queone/gkit/blob/main/scripts/bashrc_root.sh) for root.

```bash
curl -Lo ~/.bashrc https://github.com/queone/gkit/raw/main/scripts/bashrc_user.sh
sudo curl -Lo /var/root/.bashrc https://github.com/queone/gkit/raw/main/scripts/bashrc_root.sh
```

The user file shows the current git branch in the prompt when `~/.gitbranch.sh` is installed, as described under [Show Branch in Shell Prompt](git/index.md#show-branch-in-shell-prompt). It ends by sourcing `~/.bashrc.local` when that file exists. Private settings such as tokens, tenant IDs, and account aliases go through that file and never enter a repo. Once both files are in place, macfit in the next section keeps them the same on every Mac.

### Keep Config Files In Sync
[macfit](https://github.com/queone/gkit/tree/main/cmd/macfit), another gkit utility, keeps the same config files on every Mac. It holds them in one encrypted store file. Put that file in a folder that iCloud Drive or another sync client carries to each Mac. Every Mac that sees the folder opens it with one passphrase. The store is the remote, as in git: `push` sends live files up, `pull` brings them down.

```bash
macfit init -N -s <synced-folder>/macfit.store   # first Mac: create the store and set a passphrase
macfit add -g ~/.bashrc                          # register a file for every Mac and capture it
macfit add ~/.bashrc.local                       # register a file for this Mac only
macfit push                                      # send changed live files into the store
macfit init -s <synced-folder>/macfit.store      # another Mac: unlock with the passphrase, once
macfit pull                                      # plan the restore, nothing written
macfit pull -f                                   # write it
macfit                                           # status and drift
```

### Network Quality
Check network quality => `networkQuality -v`

### Useful CLI Site
Awesome macOS Command-Line = <https://github.com/herrbischoff/awesome-macos-command-line>

### What TCP Ports Are Listening

```bash
sudo lsof -iTCP -sTCP:LISTEN -n -P    # List what TCP ports apps are listening on
```


### Turn Off IPV6

```bash
sudo networksetup -setv6off "Wi-Fi"
sudo networksetup -setv6off "Thunderbolt Ethernet"
sudo networksetup -setv6off "Ethernet"
```

To re- enable

```bash
sudo networksetup -setv6automatic "Wi-Fi"
sudo networksetup -setv6automatic "Thunderbolt Ethernet"
sudo networksetup -setv6automatic "Ethernet"
```


### DNS

```bash
FLUSH
sudo killall -HUP mDNSResponder;sudo killall mDNSResponderHelper;sudo dscacheutil -flushcache

SHOW  
sudo networksetup -getdnsservers    "Wi-Fi"
sudo networksetup -getsearchdomains "Wi-Fi"
sudo networksetup -getdnsservers    "Thunderbolt Ethernet"
sudo networksetup -getsearchdomains "Thunderbolt Ethernet"

SET
sudo networksetup -getsearchdomains "Wi-Fi"
sudo networksetup -getsearchdomains "Thunderbolt Ethernet"
sudo networksetup -setsearchdomains "Wi-Fi" "mydomain.com aws.mydomain.com"
sudo networksetup -setsearchdomains "Thunderbolt Ethernet" "mydomain.com aws.mydomain.com"
sudo killall -HUP mDNSResponder
sudo networksetup -getsearchdomains "Wi-Fi"
sudo networksetup -getsearchdomains "Thunderbolt Ethernet"

networksetup -listallnetworkservices

sudo networksetup -setdnsservers Wi-Fi empty
sudo networksetup -setdnsservers Wi-Fi 8.8.8.8 8.8.4.4
sudo killall -HUP mDNSResponder

scutil --dns | grep 'nameserver\[[0-9]*\]'
```


### Image Conversion
- JPEG 

```bash
# Resize all files to 1024 pixels at their largest side (the other side proportionately)
for N in *.jpg ; do sips -Z 1024 $N ; done

# Lower resolution of all JPEG files by %20
for N in *.jpg ; do sips -s format jpeg -s formatOptions 20 $N -o ${N}.jpg ; done

# Convert all JPEG files in current directory to PDF, and vice-versa
for N in *.jpg ; do sips -s format pdf $N -o ${N}.pdf ; done
for N in *.pdf ; do sips -s format jpeg $N -o ${N}.jpg ; done
```

- PGN

```bash
# Resize file in place by 60%, replaces original
magick mogrify -resize 60% yul.png 
```

### View Hardware Information

```bash
# NUMBER OF CPUs, etc. Equivalent commands to Linux's nproc and free, etc
sysctl -n hw.ncpu
python -c 'import multiprocessing as mp; print(mp.cpu_count())'
system_profiler SPHardwareDataType  # To see actual number of cores

sysctl hw.memsize
hw.memsize: 68719476736

sysctl hw.ncpu
hw.ncpu: 12

system_profiler SPHardwareDataType
Hardware:

    Hardware Overview:

      Model Name: Mac mini
      Model Identifier: Macmini8,1
      Processor Name: 6-Core Intel Core i7
      Processor Speed: 3.2 GHz
      Number of Processors: 1
      Total Number of Cores: 6
      L2 Cache (per Core): 256 KB
      L3 Cache: 12 MB
      Hyper-Threading Technology: Enabled
      Memory: 64 GB
      Boot ROM Version: 1037.40.124.0.0 (iBridge: 17.16.11081.0.0,0)
      Serial Number (system): <SERIAL>
      Hardware UUID: <UUID>
      Activation Lock Status: Disabled
```


### Disk Trix

```bash
FORMAT
sudo newfs_msdos -F 16 /dev/disk2

BURN RAW IMAGE TO DISK
sudo dd -f image.raw /dev/disk2
brew install ddrescue
sudo ddrescue -f image.raw /dev/disk2

CREATE IMAGE FROM DISK
diskutil unmountDisk /dev/disk2
sudo ddrescue -vS /dev/disk2 image.raw ddrescue.log

LIST ALL DISKS
diskutil list

LIST SUPPORTED FILESYSTEMS
diskutil listFilesystems

UNMOUNT DISK
diskutil unmountDisk /dev/disk2

MOUNT/UNMOUNT NON-HYBRID ISO FILES : PUT IT ON /Volume/nonhybrid
hdiutil mount -quiet "nonhybrid.iso"
hdiutil unmount -quiet nonhybrid

MOUNTING HYBRID ISO FILES (usually Linux CDs)
hdiutil attach -quiet -noverify -nomount "centos.iso"
diskutil list   # To capture the /dev/diskX identifier above was mapped to
sudo mkdir /Volumes/centos
sudo mount_cd9660 /dev/diskX /Volumes/centos
...
sudo umount /Volumes/centos && diskutil eject /dev/diskX
sudo rmdir /Volumes/centos
```


### Convert ISO to IMG

```bash
hdiutil convert ubuntu-20.04-desktop-amd64.iso -format UDRW -o ubuntu-20.04-desktop-amd64
# Will automatically add the .dmg extension = ubuntu-20.04-desktop-amd64.dmg
```

### Create macOS USB Installer
- Download latest macOS installer via the App Store
  - Quit without continuing installation!
  - May take a while

- Format a +16GB size USB
  - Name   = Untitled
  - Format = Mac OS Extended (Journaled)
  - Scheme = GUID Partition Map
  - Security Options = Fastest

- `sudo "/System/Volumes/Data/Applications/Install macOS Catalina.app/Contents/Resources/createinstallmedia" --volume /Volumes/Untitled`
  Path will differ based on macOS version name

- Right click and EJECT

### Startup Keys
- For newer Apple Silicon CPU machines:
  Switch on your Mac with the power button. Keep pressing it until you see a window that lists the drives connected to your Mac.

- For older Apple Intel CPU machines:

```bash
Options-Command-R    Boot into Recovery Mode with latest OS for this hardware
Command-R            Boot into Recovery Mode with original OS
Options              Access Mac Startup Manager
C                    Boot from USB/CD
N                    NetBoot
Shift                Safe Boot
Command-V            Verbose Mode
Command-S            Single User Mode
Command-Option-P-R   Reset PRAM
T                    Enable Target Disk Mode
```
