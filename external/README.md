# External Dependencies

This directory contains git submodules.

## kiss_fft

FFT library for signal processing.

**Setup:**
```bash
git submodule update --init --recursive
```

Or when cloning:
```bash
git clone --recurse-submodules https://github.com/Alex-Pennington/phoenix-sdr-core.git
```

## Manual Setup

If submodules fail, clone manually:
```bash
cd external
git clone https://github.com/Alex-Pennington/phoenix-kiss-fft.git kiss_fft
```
