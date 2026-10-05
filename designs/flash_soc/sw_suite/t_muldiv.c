/* RV32M test: every multiply and divide instruction, including the corner cases the ISA defines. */
#include <stdint.h>

#define CHECK(bit, cond) do { if (!(cond)) fail |= (bit); } while (0)

static volatile int32_t a = -7, b = 3, zero = 0, minint = (int32_t)0x80000000u, m1 = -1;
static volatile uint32_t big = 0xFFFFFFFFu, two = 2;

int main(void) {
  uint32_t fail = 0;
  int32_t r;
  uint32_t u;

  asm volatile("mul %0, %1, %2"    : "=r"(r) : "r"(a), "r"(b));        CHECK(0x01, r == -21);
  asm volatile("mulh %0, %1, %2"   : "=r"(r) : "r"(minint), "r"(minint)); CHECK(0x01, r == 0x40000000);
  asm volatile("mulhu %0, %1, %2"  : "=r"(u) : "r"(big), "r"(big));    CHECK(0x01, u == 0xFFFFFFFEu);
  asm volatile("mulhsu %0, %1, %2" : "=r"(r) : "r"(m1), "r"(big));     CHECK(0x01, r == -1);

  asm volatile("div %0, %1, %2"  : "=r"(r) : "r"(a), "r"(b));          CHECK(0x02, r == -2);
  asm volatile("rem %0, %1, %2"  : "=r"(r) : "r"(a), "r"(b));          CHECK(0x02, r == -1);
  asm volatile("divu %0, %1, %2" : "=r"(u) : "r"(big), "r"(two));      CHECK(0x02, u == 0x7FFFFFFFu);
  asm volatile("remu %0, %1, %2" : "=r"(u) : "r"(big), "r"(two));      CHECK(0x02, u == 1u);

  /* Division by zero: quotient all ones, remainder the dividend. */
  asm volatile("div %0, %1, %2"  : "=r"(r) : "r"(a), "r"(zero));       CHECK(0x04, r == -1);
  asm volatile("divu %0, %1, %2" : "=r"(u) : "r"(big), "r"(zero));     CHECK(0x04, u == 0xFFFFFFFFu);
  asm volatile("rem %0, %1, %2"  : "=r"(r) : "r"(a), "r"(zero));       CHECK(0x04, r == -7);
  asm volatile("remu %0, %1, %2" : "=r"(u) : "r"(big), "r"(zero));     CHECK(0x04, u == 0xFFFFFFFFu);

  /* Signed overflow: the most negative number divided by -1. */
  asm volatile("div %0, %1, %2" : "=r"(r) : "r"(minint), "r"(m1));     CHECK(0x08, r == (int32_t)0x80000000u);
  asm volatile("rem %0, %1, %2" : "=r"(r) : "r"(minint), "r"(m1));     CHECK(0x08, r == 0);

  /* A run of products and quotients checked against each other. */
  uint32_t acc = 1;
  for (uint32_t i = 1; i < 200; i++) {
    uint32_t p = (i * 2654435761u) ^ acc;
    uint32_t q = p / i, s = p % i;
    if (q * i + s != p || s >= i) { fail |= 0x10; break; }
    acc += q;
  }
#ifdef PLANT_FAIL
  if (acc != 0) fail |= 0x20;   /* control: acc is never 0 here */
#endif
  return (int)fail;
}
