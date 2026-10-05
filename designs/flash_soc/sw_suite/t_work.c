/* A longer workload with a known answer: a prime sieve, a bubble sort and a Fibonacci table, folded into
   one checksum. Keeps the pipeline, branches and memory busy for many thousands of cycles. */
#include <stdint.h>

#define N 1000

static uint8_t composite[N];
static int32_t data[64];

int main(void) {
  uint32_t fail = 0;

  /* Primes below 1000: there are 168, and their sum is 76127. */
  for (int i = 2; i * i < N; i++)
    if (!composite[i])
      for (int j = i * i; j < N; j += i) composite[j] = 1;
  uint32_t count = 0, sum = 0;
  for (int i = 2; i < N; i++)
    if (!composite[i]) { count++; sum += (uint32_t)i; }
  if (count != 168 || sum != 76127) fail |= 0x01;

  /* Sort 64 pseudo-random signed numbers and check the order and the total. */
  uint32_t s = 12345;
  int32_t total = 0;
  for (int i = 0; i < 64; i++) {
    s = s * 1103515245u + 12345u;
    data[i] = (int32_t)(s >> 8) - (1 << 22);
    total += data[i];
  }
  for (int i = 0; i < 63; i++)
    for (int j = 0; j < 63 - i; j++)
      if (data[j] > data[j + 1]) { int32_t t = data[j]; data[j] = data[j + 1]; data[j + 1] = t; }
  int32_t after = 0;
  for (int i = 0; i < 64; i++) {
    after += data[i];
    if (i && data[i - 1] > data[i]) fail |= 0x02;
  }
  if (after != total) fail |= 0x02;

  /* Fibonacci: F(47) is the largest that fits in 32 bits, 2971215073. */
  uint32_t f0 = 0, f1 = 1;
  for (int i = 2; i <= 47; i++) { uint32_t f2 = f0 + f1; f0 = f1; f1 = f2; }
  if (f1 != 2971215073u) fail |= 0x04;

  return (int)fail;
}
