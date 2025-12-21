# Phoenix SDR TCP Control Protocol

## Overview

Text-based TCP protocol for remote SDR control. Default port: 4535.

Commands are case-insensitive, one per line, terminated with `\n`.

---

## Response Format

```
OK [value]           # Success
ERR <code> [message] # Error
```

Error codes: `SYNTAX`, `UNKNOWN`, `PARAM`, `RANGE`, `STATE`, `BUSY`, `HARDWARE`, `TIMEOUT`

---

## Commands

### Frequency

| Command | Arguments | Description |
|---------|-----------|-------------|
| `SET_FREQ <hz>` | Frequency in Hz | Set center frequency |
| `GET_FREQ` | — | Query current frequency |

**Range:** 1 kHz – 2 GHz

### Gain

| Command | Arguments | Description |
|---------|-----------|-------------|
| `SET_GAIN <db>` | Gain reduction 20-59 | Set gain reduction |
| `GET_GAIN` | — | Query gain reduction |
| `SET_LNA <state>` | LNA state 0-8 | Set LNA attenuation |
| `GET_LNA` | — | Query LNA state |
| `SET_AGC <mode>` | OFF, 5HZ, 50HZ, 100HZ | Set AGC mode |
| `GET_AGC` | — | Query AGC mode |

**Note:** Hi-Z antenna only supports LNA states 0-4.

### Sample Rate / Bandwidth

| Command | Arguments | Description |
|---------|-----------|-------------|
| `SET_SRATE <hz>` | 2M – 10M | Set sample rate |
| `GET_SRATE` | — | Query sample rate |
| `SET_BW <khz>` | 200,300,600,1536,5000,6000,7000,8000 | Set bandwidth |
| `GET_BW` | — | Query bandwidth |

### Hardware

| Command | Arguments | Description |
|---------|-----------|-------------|
| `SET_ANTENNA <port>` | A, B, HIZ | Select antenna |
| `GET_ANTENNA` | — | Query antenna |
| `SET_BIAST <state> [CONFIRM]` | ON/OFF | Enable bias-T (requires CONFIRM for ON) |
| `SET_NOTCH <state>` | ON/OFF | Enable FM notch |
| `SET_DECIM <factor>` | 1,2,4,8,16,32 | Hardware decimation |
| `GET_DECIM` | — | Query decimation |
| `SET_IFMODE <mode>` | ZERO, LOW | IF mode |
| `GET_IFMODE` | — | Query IF mode |
| `SET_DCOFFSET <state>` | ON/OFF | DC offset correction |
| `GET_DCOFFSET` | — | Query DC offset |
| `SET_IQCORR <state>` | ON/OFF | IQ imbalance correction |
| `GET_IQCORR` | — | Query IQ correction |
| `SET_AGC_SETPOINT <dbfs>` | -72 to 0 | AGC setpoint |
| `GET_AGC_SETPOINT` | — | Query AGC setpoint |

### Streaming

| Command | Arguments | Description |
|---------|-----------|-------------|
| `START` | — | Begin I/Q streaming |
| `STOP` | — | Stop streaming |
| `STATUS` | — | Query full state |

### Utility

| Command | Arguments | Description |
|---------|-----------|-------------|
| `PING` | — | Returns `PONG` |
| `VER` | — | Version info |
| `CAPS` | — | Device capabilities |
| `HELP` | — | Command list |
| `QUIT` | — | Disconnect |

---

## Examples

```
> SET_FREQ 15000000
< OK

> GET_FREQ
< OK 15000000

> SET_ANTENNA HIZ
< OK

> SET_LNA 6
< ERR RANGE LNA must be 0-4 for HIZ antenna

> STATUS
< OK STREAMING=0 FREQ=15000000 GAIN=40 LNA=4 AGC=OFF SRATE=2000000 BW=200 HW=1

> START
< OK

> STATUS
< OK STREAMING=1 FREQ=15000000 GAIN=40 LNA=4 AGC=OFF SRATE=2000000 BW=200 HW=1 OVERLOAD=0
```

---

## Async Notifications

When streaming, the server may send unsolicited notifications:

```
!OVERLOAD 1          # ADC overload detected
!OVERLOAD 0          # Overload cleared
!GAIN 35.5 12        # Gain changed (total dB, LNA dB)
```

Notifications are prefixed with `!` to distinguish from command responses.

---

## Connection Example (Python)

```python
import socket

def send_cmd(sock, cmd):
    sock.send((cmd + '\n').encode())
    return sock.recv(1024).decode().strip()

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(('localhost', 4535))

print(send_cmd(sock, 'VER'))
print(send_cmd(sock, 'SET_FREQ 10000000'))
print(send_cmd(sock, 'SET_ANTENNA HIZ'))
print(send_cmd(sock, 'START'))

sock.close()
```

---

## Protocol Version

Current protocol version: **1.0**

Query with `VER` command returns: `OK PHOENIX_SDR=x.x.x PROTOCOL=1.0`
