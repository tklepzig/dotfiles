# minidlna

Lightweight DLNA/UPnP-AV media server. Runs on the **White Queen** Pi 5,
presenting media to clients like VLC on the LAN. (Gerbera was tried first but
its libupnp never emitted SSDP on that box — minidlna just works.)

- Config: `/etc/minidlna.conf` (a synced copy lives in the white-queen repo at
  `pi-stuff/minidlna.conf`).
- Service: `minidlna.service`; HTTP/SOAP on port `8200`.
- Media root: `/srv/media` (the external USB drive), split by content type:
  `A,/srv/media/music`, `V,/srv/media/video`, `P,/srv/media/pictures`.
- The server name clients see comes from `friendly_name=White Queen`.

## Service control

```sh
sudo systemctl restart minidlna     # picks up config changes
systemctl status minidlna
sudo systemctl stop minidlna
```

## Forcing a rescan

minidlna has `inotify=yes`, so **new media files** dropped into a `media_dir`
are picked up automatically. But database/metadata changes (and playlist drops)
are safest with an explicit rescan. `-R` sets a rebuild flag that takes effect
on the **next start** — it does not rescan a running daemon:

```sh
sudo systemctl stop minidlna
sudo minidlnad -R                   # flag a full rebuild on next start
sudo systemctl start minidlna
```

If `-R` misbehaves, the heavier hammer is to delete the cache DB and let it
rebuild from scratch:

```sh
sudo systemctl stop minidlna
sudo rm /var/cache/minidlna/files.db
sudo systemctl start minidlna
```

A full rebuild re-indexes the **entire** library, not just the change — give it
a minute before browsing on a large collection.

## Playlists

The **Playlists** container always shows in the browse tree (next to Albums,
Artists, etc.) even when empty — that's why it's visible before you've added
anything. minidlna populates it purely from playlist **files** it finds while
scanning; there's no config switch to enable.

Drop an `.m3u` (or `.m3u8` / `.pls`) into the **audio** dir and rescan. It then
appears under **Music → Playlists**:

```sh
# /srv/media/music/Morning Mix.m3u
#EXTM3U
#EXTINF:-1,Morning mix - Track 1
artist-a/song1.mp3
#EXTINF:-1,Morning mix - Track 2
artist-b/song2.flac
```

- Entry paths may be **absolute** (`/srv/media/music/...`) or **relative to the
  playlist file's own location** (as above).
- `#EXTINF` lines are optional but give each entry a readable title in the
  client instead of the raw filename.
- Point entries only at files minidlna has already indexed (inside a
  `media_dir`, of a type it serves). A path to an unindexed/unsupported file
  just silently won't appear — no error.
- Keep playlists within the music tree. Mixing audio + video in one playlist is
  murky under DLNA; `.m3u` of audio under `/srv/media/music` is the clean path.

## Gotchas

- After editing `/etc/minidlna.conf`, `restart` the service — it does not reload
  config live.
- An entry that won't appear is almost always a **path problem** (typo, or the
  target isn't under a `media_dir`), not a minidlna bug.
- `network_interface=eth0` binds it to the wired NIC — WiFi is off on the Pi 5
  by design, so don't expect it on `wlan0`.
