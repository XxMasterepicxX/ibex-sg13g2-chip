/* Memory test: a march test over every DMEM word below the stack, reads of constants from IMEM,
   and a GPIO readback walk. Returns failure flags. */
#include <stdint.h>

#define GPIO (*(volatile uint32_t *)0x00020000)
#define DMEM ((volatile uint32_t *)0x00010000)
/* The stack grows down from the top of DMEM; leave its last 256 bytes alone. */
#define WORDS ((4096 - 256) / 4)

static const uint32_t table[8] = {0x01234567u, 0x89ABCDEFu, 0xFEDCBA98u, 0x76543210u,
                                  0xA5A5A5A5u, 0x5A5A5A5Au, 0x00000000u, 0xFFFFFFFFu};

int main(void) {
  uint32_t fail = 0;

  /* March C-: up w0; up r0 w1; up r1 w0; down r0 w1; down r1 w0; down r0. */
  for (int i = 0; i < WORDS; i++) DMEM[i] = 0;
  for (int i = 0; i < WORDS; i++) { if (DMEM[i] != 0) fail |= 0x01; DMEM[i] = 0xFFFFFFFFu; }
  for (int i = 0; i < WORDS; i++) { if (DMEM[i] != 0xFFFFFFFFu) fail |= 0x01; DMEM[i] = 0; }
  for (int i = WORDS - 1; i >= 0; i--) { if (DMEM[i] != 0) fail |= 0x01; DMEM[i] = 0xFFFFFFFFu; }
  for (int i = WORDS - 1; i >= 0; i--) { if (DMEM[i] != 0xFFFFFFFFu) fail |= 0x01; DMEM[i] = 0; }
  for (int i = WORDS - 1; i >= 0; i--) if (DMEM[i] != 0) fail |= 0x01;

  /* Address in address: catches address lines stuck or shorted together. */
  for (int i = 0; i < WORDS; i++) DMEM[i] = (uint32_t)i * 0x00010001u ^ 0xC3C30000u;
  for (int i = 0; i < WORDS; i++) if (DMEM[i] != ((uint32_t)i * 0x00010001u ^ 0xC3C30000u)) fail |= 0x02;

  /* Checkerboard on every data bit. */
  for (int i = 0; i < WORDS; i++) DMEM[i] = (i & 1) ? 0x55555555u : 0xAAAAAAAAu;
  for (int i = 0; i < WORDS; i++) if (DMEM[i] != ((i & 1) ? 0x55555555u : 0xAAAAAAAAu)) fail |= 0x04;

  /* Constants live in IMEM; the core reads them over the data port. */
  volatile const uint32_t *t = table;
  uint32_t x = 0;
  for (int i = 0; i < 8; i++) x ^= t[i] + (uint32_t)i;
  if (x != (0x01234567u ^ (0x89ABCDEFu + 1) ^ (0xFEDCBA98u + 2) ^ (0x76543210u + 3) ^
            (0xA5A5A5A5u + 4) ^ (0x5A5A5A5Au + 5) ^ 6u ^ (0xFFFFFFFFu + 7)))
    fail |= 0x08;

  /* GPIO is readable: walk a one through the low 7 bits; bit 7 is kept 0 until the end. */
  for (int i = 0; i < 7; i++) {
    GPIO = 1u << i;
    if ((GPIO & 0xFFu) != (1u << i)) fail |= 0x10;
  }
  GPIO = 0;
  return (int)fail;
}
