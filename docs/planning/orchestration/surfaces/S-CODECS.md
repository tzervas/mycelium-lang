# Surface S-CODECS — JSON + TOML in std-io

**Status:** PRE-FREEZE (pure — can parallelize early)  
**Home:** `mycelium-std-io` (decision: extend std-io, no new repos)  
**Effects:** none

## API

```
json_to_value / value_to_json  // may partially exist
to_json / from_json for general user types (Encode/Decode)
parse_toml / toml_get
```

No wild: required. Ship pure.
