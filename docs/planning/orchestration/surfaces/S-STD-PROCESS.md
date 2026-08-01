# Surface S-STD-PROCESS — subprocess (v0)

**Status:** PRE-FREEZE shape  
**Home decision:** start in `mycelium-std-sys` (sys-now-split-later)  
**I/O:** blocking-hypha

## API

```
spawn(cmd, args, opts) -> Result<Child, ProcessError>
wait(child) -> Result<ExitStatus, ProcessError>
kill(child, sig) -> Result<(), ProcessError>
capture(cmd, args, opts) -> Result<Output, ProcessError>
mkfifo(path) -> Result<(), ProcessError>   // relay
```

## wild names (catalog)

| name | notes |
|------|-------|
| `process_spawn` | returns handle id in Value |
| `process_wait` | |
| `process_kill` | |
| `fifo_mk` | optional v0.1 |

## Non-goals

- Full shell expansion
- Windows job objects (later matrix)
