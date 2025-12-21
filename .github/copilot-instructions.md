# Phoenix SDR Core - Copilot Instructions

## P0 - CRITICAL RULES

1. **NO unauthorized additions.** Do not add features, flags, modes, or files without explicit instruction. ASK FIRST.
2. **Minimal scope.** Fix only what's requested. One change at a time.
3. **Suggest before acting.** Explain your plan, wait for confirmation.
4. **Verify before modifying.** Run `git status`, read files before editing.

---

## Architecture Overview

**Phoenix SDR Core** provides the hardware interface for SDRplay RSP2 Pro, including decimation and TCP control.

### Signal Flow
```
SDRplay RSP2 Pro (USB)
        │
        ▼
   sdr_device.c ──── Device enumeration, open/close
        │
        ▼
   sdr_stream.c ──── Streaming control, callbacks
        │
        ▼
   decimator.c ───── 2 MHz → 48 kHz multi-stage
        │
        ▼
   tcp_commands.c ── Remote control protocol
        │
        ▼
   TCP Clients (waterfall, analyzers, etc.)
```

### Key Directories
| Path | Purpose |
|------|---------|
| `src/` | Core SDR interface modules |
| `include/` | Public headers, `phoenix_sdr.h` is main API |
| `docs/` | Protocol documentation |

---

## Build

```powershell
.\build.ps1                    # Debug build
.\build.ps1 -Release           # Optimized build
.\build.ps1 -Clean             # Clean artifacts
```

**Dependencies:** SDRplay API v3.x, Winsock2

---

## SDRplay API Pattern

### Device Lifecycle
```c
// 1. Open API
sdrplay_api_Open();

// 2. Lock device selection
sdrplay_api_LockDeviceApi();

// 3. Select device
sdrplay_api_GetDevices(devices, &numDevs, maxDevs);
sdrplay_api_SelectDevice(&devices[0]);

// 4. Unlock
sdrplay_api_UnlockDeviceApi();

// 5. Get device params
sdrplay_api_GetDeviceParams(device.dev, &deviceParams);

// 6. Configure and init
sdrplay_api_Init(device.dev, &callbacks, NULL);

// 7. Stream...

// 8. Cleanup
sdrplay_api_Uninit(device.dev);
sdrplay_api_ReleaseDevice(&device);
sdrplay_api_Close();
```

### Callback Pattern
```c
void stream_callback(short *xi, short *xq, 
                     sdrplay_api_StreamCbParamsT *params,
                     unsigned int numSamples, 
                     unsigned int reset, 
                     void *cbContext) {
    // Process I/Q samples
    for (unsigned int i = 0; i < numSamples; i++) {
        int16_t I = xi[i];
        int16_t Q = xq[i];
        // ...
    }
}
```

---

## Decimation Chain

2 MHz → 48 kHz in multiple stages:

```
2 MHz ──┬── Stage 1: 8:1 ──→ 250 kHz
        │   (FIR lowpass)
        │
        └── Stage 2: 5:1 ──→ 50 kHz
            (FIR lowpass)
            │
            └── Stage 3: 50/48 ──→ 48 kHz
                (Polyphase resampler)
```

Each stage uses appropriate filter order to prevent aliasing.

---

## TCP Control Protocol

Text-based, one command per line. Port 4535 (default).

### Command Format
```
COMMAND [ARG1] [ARG2]\n
```

### Response Format
```
OK [value]           # Success
ERR <code> [message] # Error
```

### Key Commands
| Command | Description |
|---------|-------------|
| `SET_FREQ <hz>` | Set center frequency |
| `GET_FREQ` | Query frequency |
| `SET_GAIN <db>` | Set IF gain reduction |
| `SET_LNA <state>` | Set LNA attenuation (0-8) |
| `SET_ANTENNA <port>` | A, B, or HIZ |
| `START` | Begin streaming |
| `STOP` | Stop streaming |
| `STATUS` | Query full state |

### Error Codes
`SYNTAX`, `UNKNOWN`, `PARAM`, `RANGE`, `STATE`, `BUSY`, `HARDWARE`, `TIMEOUT`

---

## I/Q Streaming Protocol

Binary protocol on port 4536 (default).

### Stream Header (PHXI)
```c
struct {
    uint32_t magic;           // 0x50485849
    uint32_t version;         // Protocol version
    uint32_t sample_rate;     // Hz
    uint32_t sample_format;   // 1=S16, 2=F32
    uint32_t center_freq_lo;
    uint32_t center_freq_hi;
    uint32_t gain_reduction;
    uint32_t lna_state;
};
```

### Data Frame (IQDQ)
```c
struct {
    uint32_t magic;           // 0x49514451
    uint32_t sequence;
    uint32_t num_samples;
    uint32_t flags;           // Bit 0: overload
    // Followed by I/Q data
};
```

---

## RSP2 Pro Specifics

### Antenna Ports
| Port | Use Case |
|------|----------|
| A | General HF/VHF (50Ω) |
| B | General HF/VHF (50Ω) |
| HIZ | HF only, high impedance, LNA limited to 0-4 |

### LNA States
- Port A/B: 0-8 (higher = more attenuation)
- Port HIZ: 0-4 only

### Bias-T
Available on Port A. Requires explicit CONFIRM to enable (safety).

---

## Dependencies

| Library | Location | Purpose |
|---------|----------|---------|
| SDRplay API 3.x | `C:\Program Files\SDRplay\API\` | Hardware access |
| kiss_fft | submodule | Decimation filters |
| Winsock2 | Windows SDK | TCP networking |
