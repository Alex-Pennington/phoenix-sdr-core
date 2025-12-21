# phoenix-sdr-core

**Version:** v0.1.0  
**Part of:** Phoenix Nest MARS Communications Suite  
**Developer:** Alex Pennington (KY4OLB)

---

## Overview

Core SDR hardware interface library for the Phoenix Nest MARS Suite. Provides low-level access to SDRplay RSP2 Pro hardware with I/Q streaming, multi-stage decimation, and TCP command interface.

This is the **foundation layer** that other Phoenix SDR tools build upon.

---

## Features

- **SDRplay RSP2 Pro Integration** — Full hardware control via SDRplay API v3
- **Multi-stage Decimation** — 2 MSPS → 48 kHz with polyphase resampling
- **TCP Command Interface** — Remote control protocol for SDR parameters
- **Low-latency Streaming** — Direct I/Q callbacks for real-time processing
- **GPS Timing Support** — Integration with GPS PPS for precision timing

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    phoenix-sdr-core                       │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │ sdr_device  │    │ sdr_stream  │    │  decimator  │  │
│  │  RSP2 API   │───►│  Callbacks  │───►│  2M → 48k   │  │
│  └─────────────┘    └─────────────┘    └─────────────┘  │
│         │                                      │         │
│         │          ┌─────────────┐             │         │
│         └─────────►│tcp_commands │◄────────────┘         │
│                    │   Control   │                       │
│                    └─────────────┘                       │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Dependencies

### Required

- **SDRplay API v3.x** — Download from [sdrplay.com](https://www.sdrplay.com/api/)
- **kiss_fft** — FFT library (git submodule)

### Build Tools

- Windows: MinGW-w64 or MSVC
- PowerShell 5.1+ for build script

---

## Building

### Quick Build

```powershell
.\build.ps1
```

### Build Options

```powershell
.\build.ps1 -Release          # Release build with optimizations
.\build.ps1 -Clean            # Clean before build
.\build.ps1 -Target server    # Build only the SDR server
```

### First-time Setup

```powershell
# Clone with submodules
git clone --recurse-submodules https://github.com/Alex-Pennington/phoenix-sdr-core.git

# Or if already cloned:
git submodule update --init --recursive
```

---

## Components

### sdr_device.c/.h

Device enumeration, configuration, and hardware control:

```c
psdr_error_t psdr_enumerate(psdr_device_info_t *devices, size_t max, size_t *count);
psdr_error_t psdr_open(psdr_context_t **ctx, unsigned int device_idx);
psdr_error_t psdr_configure(psdr_context_t *ctx, const psdr_config_t *config);
void psdr_close(psdr_context_t *ctx);
```

### sdr_stream.c

Streaming control with callbacks:

```c
psdr_error_t psdr_start(psdr_context_t *ctx, const psdr_callbacks_t *callbacks);
psdr_error_t psdr_stop(psdr_context_t *ctx);
psdr_error_t psdr_update(psdr_context_t *ctx, const psdr_config_t *config);
```

### decimator.c/.h

Multi-stage decimation (2 MSPS → 48 kHz):

```c
decim_error_t decim_create(decim_state_t **state, double in_rate, double out_rate);
decim_error_t decim_process_int16(decim_state_t *s, const int16_t *xi, 
                                   const int16_t *xq, size_t count,
                                   decim_complex_t *out, size_t max, size_t *out_count);
void decim_destroy(decim_state_t *state);
```

### tcp_commands.c

TCP control protocol parser and executor:

```c
tcp_error_t tcp_parse_command(const char *line, tcp_command_t *cmd);
tcp_error_t tcp_execute_command(const tcp_command_t *cmd, 
                                 tcp_sdr_state_t *state,
                                 tcp_response_t *response);
```

---

## TCP Command Protocol

Commands are text-based, one per line. Examples:

```
SET_FREQ 15000000      → Set frequency to 15 MHz
GET_FREQ               → Returns: OK 15000000
SET_GAIN 40            → Set gain reduction to 40 dB
SET_ANTENNA HIZ        → Select Hi-Z antenna port
START                  → Begin streaming
STOP                   → Stop streaming
STATUS                 → Query current state
```

See [docs/TCP_PROTOCOL.md](docs/TCP_PROTOCOL.md) for full specification.

---

## Usage Example

```c
#include "phoenix_sdr.h"
#include "decimator.h"

// Callback for I/Q samples
void on_samples(const int16_t *xi, const int16_t *xq, 
                uint32_t count, bool reset, void *ctx) {
    decim_state_t *dec = (decim_state_t *)ctx;
    decim_complex_t out[4096];
    size_t out_count;
    
    decim_process_int16(dec, xi, xq, count, out, 4096, &out_count);
    // Process decimated samples...
}

int main() {
    psdr_context_t *sdr;
    decim_state_t *dec;
    
    // Create decimator
    decim_create(&dec, 2000000.0, 48000.0);
    
    // Open SDR
    psdr_open(&sdr, 0);
    
    // Configure
    psdr_config_t config;
    psdr_config_defaults(&config);
    config.freq_hz = 10000000.0;  // 10 MHz
    config.antenna = PSDR_ANT_HIZ;
    psdr_configure(sdr, &config);
    
    // Start streaming
    psdr_callbacks_t cb = {
        .on_samples = on_samples,
        .user_ctx = dec
    };
    psdr_start(sdr, &cb);
    
    // ... run ...
    
    psdr_stop(sdr);
    psdr_close(sdr);
    decim_destroy(dec);
    return 0;
}
```

---

## Related Repositories

| Repository | Description |
|------------|-------------|
| [mars-suite](https://github.com/Alex-Pennington/mars-suite) | Phoenix Nest MARS Suite index |
| [phoenix-kiss-fft](https://github.com/Alex-Pennington/phoenix-kiss-fft) | FFT library (submodule) |
| [phoenix-reference-library](https://github.com/Alex-Pennington/phoenix-reference-library) | Technical documentation |
| [phoenix-wwv](https://github.com/Alex-Pennington/phoenix-wwv) | WWV time signal detection |
| [phoenix-waterfall](https://github.com/Alex-Pennington/phoenix-waterfall) | SDR waterfall display |

---

## License

AGPL-3.0 — See [LICENSE](LICENSE)

---

*Phoenix Nest MARS Communications Suite*  
*KY4OLB*
