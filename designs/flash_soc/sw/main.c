/* Self-checking test for flash_soc. Returns failure flags; 0 means every test passed. */
#include <stdint.h>

#define GPIO (*(volatile uint32_t *)0x00020000)

static const char check_str[] = "123456789";
static volatile uint32_t initialized = 0xA5A5F00Fu;   /* in .data: proves the IMEM-to-DMEM copy */
static volatile uint32_t scratch[256];        /* in .bss */

static uint32_t crc32(const char *s, int n) {
  uint32_t c = 0xFFFFFFFFu;
  for (int i = 0; i < n; i++) {
    c ^= (uint8_t)s[i];
    for (int k = 0; k < 8; k++) c = (c >> 1) ^ (0xEDB88320u & -(c & 1u));
  }
  return ~c;
}

int main(void) {
  uint32_t fail = 0;

  GPIO = 0x01;
#ifdef PLANT_FAIL
  if (crc32(check_str, 9) != 0xCBF43927u) fail |= 0x01;   /* control: wrong expected value */
#else
  if (crc32(check_str, 9) != 0xCBF43926u) fail |= 0x01;
#endif

  GPIO = 0x02;
  volatile uint32_t a = 12345, b = 6789;
  uint32_t p = a * b;
  if (p != 83810205u || p / b != a || (p + 7) % b != 7) fail |= 0x02;
  volatile int32_t n = -1000;
  if (n / 7 != -142 || n % 7 != -6) fail |= 0x02;

  GPIO = 0x03;
  volatile uint8_t *b8 = (volatile uint8_t *)scratch;
  volatile uint16_t *b16 = (volatile uint16_t *)scratch;
  scratch[0] = 0;
  b8[1] = 0x5A;
  b16[1] = 0xBEEF;
  if (scratch[0] != 0xBEEF5A00u || b8[1] != 0x5A) fail |= 0x04;

  GPIO = 0x04;
  for (int i = 0; i < 256; i++) scratch[i] = 1u << (i & 31);
  for (int i = 0; i < 256; i++) scratch[i] = ~scratch[i];
  for (int i = 0; i < 256; i++)
    if (scratch[i] != ~(1u << (i & 31))) { fail |= 0x08; break; }

  if (initialized != 0xA5A5F00Fu) fail |= 0x10;

  return (int)fail;
}
