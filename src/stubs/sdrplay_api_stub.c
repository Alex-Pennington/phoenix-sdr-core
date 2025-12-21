/**
 * @file sdrplay_api_stub.c
 * @brief Stub implementations for SDRplay API
 * 
 * Used for CI builds where SDRplay SDK is not available.
 * All functions return error codes indicating hardware not found.
 * Real DLL is loaded at runtime if user has SDRplay installed.
 */

#include "sdrplay/sdrplay_api.h"

sdrplay_api_ErrT sdrplay_api_Open(void) {
    return sdrplay_api_NotInitialised;
}

sdrplay_api_ErrT sdrplay_api_Close(void) {
    return sdrplay_api_Success;
}

sdrplay_api_ErrT sdrplay_api_ApiVersion(float *apiVer) {
    if (apiVer) *apiVer = 0.0f;
    return sdrplay_api_NotInitialised;
}

sdrplay_api_ErrT sdrplay_api_LockDeviceApi(void) {
    return sdrplay_api_NotInitialised;
}

sdrplay_api_ErrT sdrplay_api_UnlockDeviceApi(void) {
    return sdrplay_api_Success;
}

sdrplay_api_ErrT sdrplay_api_GetDevices(sdrplay_api_DeviceT *devices, 
                                         unsigned int *numDevs, 
                                         unsigned int maxDevs) {
    (void)devices;
    (void)maxDevs;
    if (numDevs) *numDevs = 0;
    return sdrplay_api_NotInitialised;
}

sdrplay_api_ErrT sdrplay_api_SelectDevice(sdrplay_api_DeviceT *device) {
    (void)device;
    return sdrplay_api_NotInitialised;
}

sdrplay_api_ErrT sdrplay_api_ReleaseDevice(sdrplay_api_DeviceT *device) {
    (void)device;
    return sdrplay_api_Success;
}

const char* sdrplay_api_GetErrorString(sdrplay_api_ErrT err) {
    (void)err;
    return "SDRplay API not available (stub build)";
}

sdrplay_api_ErrT sdrplay_api_GetDeviceParams(HANDLE dev, 
                                              sdrplay_api_DeviceParamsT **deviceParams) {
    (void)dev;
    (void)deviceParams;
    return sdrplay_api_NotInitialised;
}

sdrplay_api_ErrT sdrplay_api_Init(HANDLE dev,
                                   sdrplay_api_CallbackFnsT *callbackFns,
                                   void *cbContext) {
    (void)dev;
    (void)callbackFns;
    (void)cbContext;
    return sdrplay_api_NotInitialised;
}

sdrplay_api_ErrT sdrplay_api_Uninit(HANDLE dev) {
    (void)dev;
    return sdrplay_api_Success;
}

sdrplay_api_ErrT sdrplay_api_Update(HANDLE dev,
                                     sdrplay_api_TunerSelectT tuner,
                                     sdrplay_api_ReasonForUpdateT reasonForUpdate,
                                     sdrplay_api_ReasonForUpdateExtension1T reasonForUpdateExt1) {
    (void)dev;
    (void)tuner;
    (void)reasonForUpdate;
    (void)reasonForUpdateExt1;
    return sdrplay_api_NotInitialised;
}
