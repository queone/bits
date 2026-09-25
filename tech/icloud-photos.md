---
type: reference
---
## iCloud Photos Backup Guide
- Bits on how to safely back up your iCloud Photos library using `rsync` to an external drive.
- This type of backup only makes sense if you have "Download Original to this Mac" enabled. That setting can take a VERY LARGE CHUNK of your Mac's drive!
- Or you can export all your iCloud Photos locally using something like `icloudpd`, as described below.


### Export iCloud Photos Locally
The recommended way is to backup all your original iCloud media using the [iCloud Photo Downloader](https://github.com/icloud-photos-downloader/icloud_photos_downloader) Python utility `icloudpd`. It downloads all photos from your iCloud account via the CLI. This means *all* photos as well as *all* videos (so make sure you have enough hard disk space!): 

```bash
brew install icloudpd

mkdir icloud-photos
icloudpd -d icloud-photos -u YOUR-ICLOUD-EMAIL-ID@icloud.com
```

... then follow prompts.


### Default Photos Library Location
Alternatively, you can just reference **macOS**'s default Photos Library, which is located at `~/Pictures/Photos Library.photoslibrary/`

This single package contains:

- All original photos and videos (`Masters` or `Originals`)
- Albums, Smart Albums, keywords, and metadata
- All edits and Faces data

> **Important:** Do not copy individual subfolders inside the package. Always copy the full `.photoslibrary` package.


### Backup Strategy
Use `rsync` to copy your library to an External Drive.

Assuming your external backup drive is mounted at `/Volumes/bak` and contains a `Pictures/` subfolder, you can back up the library as follows:

```bash
# Close Photos app before running
rsync -avh --perms --delete ~/Pictures/Photos\ Library.photoslibrary/ /Volumes/bak/Pictures/
```

Explanation of options:

* `-a` : Archive mode (preserves permissions, symbolic links, timestamps)
* `-v` : Verbose output
* `-h` : Human-readable numbers
* `--perms` : Preserve file permissions
* `--delete` : Delete files on the destination that no longer exist on the source

> This creates an exact copy of your Photos Library in `/Volumes/bak/Pictures/`.


### Restore Strategy

To restore the library:

1. Copy the backed-up library back to `~/Pictures`:

```bash
rsync -avh --progress /Volumes/bak/Pictures/Photos\ Library.photoslibrary ~/Pictures/
```

2. Hold **Option** while opening Photos and select the restored library.
3. Photos will open exactly as it was, with all albums, edits, and metadata intact.
