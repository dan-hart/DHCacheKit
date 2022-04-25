# DHCacheKit

### Insert Values
```Swift
let cache = Cache<String, [String]>(useLocalDisk: true)
cache.insert(["1", "2", "3"], forKey: "Numbers")
```

### Read Values
```Swift
let entry = cache.entry(forKey: "Numbers")
print(entry.value) // ["1", "2", "3"]
```

### Other features
- Persist to disk
- Friendly cache size "8 MB"
- Clear all
