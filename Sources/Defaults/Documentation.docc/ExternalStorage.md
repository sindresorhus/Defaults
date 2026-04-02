# External Storage

Store large values on disk instead of in UserDefaults.

## Overview

For large values like images or documents, you can use external storage to store the data on disk instead of in UserDefaults. This prevents UserDefaults from becoming bloated and keeps memory usage low.

When external storage is enabled, only a UUID reference is stored in UserDefaults, while the actual data is written to disk in the Application Support directory.

## Usage

Enable external storage by setting the `externalStorage` parameter to `true` when creating a key:

```swift
import Defaults

extension Defaults.Keys {
	static let largeData = Key<Data>("largeData", default: Data(), externalStorage: true)
}

// Store large data
let data = Data(repeating: 0, count: 1_000_000) // 1MB
Defaults[.largeData] = data

// Retrieve it
let retrieved = Defaults[.largeData]
```

## How It Works

When `externalStorage: true` is enabled:

- Only a UUID reference is stored in UserDefaults
- The actual data is written to disk in the Application Support directory under `.Defaults_EXTERNAL_STORAGE/<key-name>/<uuid>`
- Data is automatically cleaned up when the key is reset or overwritten
- Files are excluded from iCloud and Time Machine backups
- Per-key locks ensure thread-safe concurrent access

## Limitations

- Only works with `UserDefaults.standard` suite
- Cannot be used with ``Defaults/iCloud`` synchronization (UUID references would sync, but not the actual files)
- Files are stored locally and not automatically synchronized across devices

## Performance Considerations

External storage is designed for large binary data. For small values (< 100 KB), storing directly in UserDefaults is usually faster due to:

- No disk I/O overhead
- No file system fragmentation
- No additional UUID lookup

Use external storage when:

- Values are larger than 100 KB
- You need to reduce UserDefaults memory footprint
- You're storing binary data like images, documents, or media files

## Topics

### Enabling External Storage

- ``Defaults/Key/init(_:default:suite:iCloud:externalStorage:)``
