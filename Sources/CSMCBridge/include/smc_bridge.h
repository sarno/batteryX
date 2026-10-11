#ifndef SMC_BRIDGE_H
#define SMC_BRIDGE_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool smc_open(void);
void smc_close(void);
bool smc_read_uint8(const char *key, uint8_t *val);
bool smc_write_uint8(const char *key, uint8_t val);

#ifdef __cplusplus
}
#endif

#endif
