#include "include/smc_bridge.h"
#include <stdio.h>
#include <string.h>
#include <IOKit/IOKitLib.h>

typedef struct {
    uint8_t                  major;
    uint8_t                  minor;
    uint8_t                  build;
    uint8_t                  reserved;
    uint16_t                 release;
} SMCKeyData_vers_t;

typedef struct {
    uint16_t                 version;
    uint16_t                 length;
    uint32_t                 cpuPLimit;
    uint32_t                 gpuPLimit;
    uint32_t                 memPLimit;
} SMCKeyData_pLimitData_t;

typedef struct {
    uint32_t                 dataSize;
    uint32_t                 dataType;
    uint8_t                  dataAttributes;
} SMCKeyData_keyInfo_t;

typedef struct {
    uint32_t                  key;
    SMCKeyData_vers_t         vers;
    SMCKeyData_pLimitData_t   pLimitData;
    SMCKeyData_keyInfo_t      keyInfo;
    uint8_t                   result;
    uint8_t                   status;
    uint8_t                   data8;
    uint32_t                  data32;
    uint8_t                   bytes[32];
} SMCKeyData_t;

static io_connect_t g_conn = 0;

static uint32_t str_to_key(const char *str) {
    uint32_t val = 0;
    for (int i = 0; i < 4 && str[i] != '\0'; i++) {
        val = (val << 8) + (uint8_t)str[i];
    }
    return val;
}

bool smc_open(void) {
    if (g_conn != 0) return true;
    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
    if (!service) return false;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &g_conn);
    IOObjectRelease(service);
    return (kr == kIOReturnSuccess && g_conn != 0);
}

void smc_close(void) {
    if (g_conn != 0) {
        IOServiceClose(g_conn);
        g_conn = 0;
    }
}

bool smc_read_uint8(const char *key, uint8_t *val) {
    if (!smc_open()) return false;
    SMCKeyData_t input = {0};
    SMCKeyData_t output = {0};
    size_t inSize = sizeof(SMCKeyData_t);
    size_t outSize = sizeof(SMCKeyData_t);

    input.key = str_to_key(key);
    input.data8 = 9; // SMC_CMD_READ_KEYINFO
    kern_return_t kr = IOConnectCallStructMethod(g_conn, 2, &input, inSize, &output, &outSize);
    if (kr != kIOReturnSuccess) return false;

    memset(&input, 0, sizeof(input));
    input.key = str_to_key(key);
    input.keyInfo.dataSize = output.keyInfo.dataSize;
    input.data8 = 5; // SMC_CMD_READ_BYTES

    kr = IOConnectCallStructMethod(g_conn, 2, &input, inSize, &output, &outSize);
    if (kr != kIOReturnSuccess) return false;

    *val = output.bytes[0];
    return true;
}

bool smc_write_uint8(const char *key, uint8_t val) {
    if (!smc_open()) return false;
    SMCKeyData_t input = {0};
    SMCKeyData_t output = {0};
    size_t inSize = sizeof(SMCKeyData_t);
    size_t outSize = sizeof(SMCKeyData_t);

    input.key = str_to_key(key);
    input.data8 = 9; // SMC_CMD_READ_KEYINFO
    kern_return_t kr = IOConnectCallStructMethod(g_conn, 2, &input, inSize, &output, &outSize);
    if (kr != kIOReturnSuccess) return false;

    memset(&input, 0, sizeof(input));
    input.key = str_to_key(key);
    input.keyInfo.dataSize = 1;
    input.data8 = 6; // SMC_CMD_WRITE_BYTES
    input.bytes[0] = val;

    kr = IOConnectCallStructMethod(g_conn, 2, &input, inSize, &output, &outSize);
    return (kr == kIOReturnSuccess);
}
