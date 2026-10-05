/* RV32I instruction test: every base instruction type against a known answer. Returns failure flags. */
#include <stdint.h>

#define CHECK(bit, cond) do { if (!(cond)) fail |= (bit); } while (0)

static volatile int32_t vneg = -8, vpos = 5, vbig = 0x7FFFFFFF;
static volatile uint32_t vu = 0x80000001u;

int main(void) {
  uint32_t fail = 0;
  int32_t r;
  uint32_t u;

  /* Register-register and immediate arithmetic, logic and compare. */
  asm volatile("add %0, %1, %2" : "=r"(r) : "r"(vneg), "r"(vpos));        CHECK(0x01, r == -3);
  asm volatile("sub %0, %1, %2" : "=r"(r) : "r"(vneg), "r"(vpos));        CHECK(0x01, r == -13);
  asm volatile("addi %0, %1, -2047" : "=r"(r) : "r"(vpos));                CHECK(0x01, r == -2042);
  asm volatile("and %0, %1, %2" : "=r"(u) : "r"(0xF0F0F0F0u), "r"(0xFF00FF00u)); CHECK(0x01, u == 0xF000F000u);
  asm volatile("or  %0, %1, %2" : "=r"(u) : "r"(0xF0F0F0F0u), "r"(0x0F000F00u)); CHECK(0x01, u == 0xFFF0FFF0u);
  asm volatile("xor %0, %1, %2" : "=r"(u) : "r"(0xF0F0F0F0u), "r"(0xFFFF0000u)); CHECK(0x01, u == 0x0F0FF0F0u);
  asm volatile("andi %0, %1, 0x7F0" : "=r"(u) : "r"(0xFFFFFFFFu));          CHECK(0x01, u == 0x7F0u);
  asm volatile("ori %0, %1, -1" : "=r"(u) : "r"(0u));                       CHECK(0x01, u == 0xFFFFFFFFu);
  asm volatile("xori %0, %1, -1" : "=r"(u) : "r"(0x12345678u));             CHECK(0x01, u == 0xEDCBA987u);
  asm volatile("slt %0, %1, %2" : "=r"(r) : "r"(vneg), "r"(vpos));          CHECK(0x02, r == 1);
  asm volatile("sltu %0, %1, %2" : "=r"(r) : "r"(vneg), "r"(vpos));         CHECK(0x02, r == 0);
  asm volatile("slti %0, %1, -7" : "=r"(r) : "r"(vneg));                    CHECK(0x02, r == 1);
  asm volatile("sltiu %0, %1, 6" : "=r"(r) : "r"(vpos));                    CHECK(0x02, r == 1);

  /* Shifts, including arithmetic right shift of a negative number and shift amounts of 0 and 31. */
  asm volatile("sll %0, %1, %2" : "=r"(u) : "r"(1u), "r"(31));              CHECK(0x04, u == 0x80000000u);
  asm volatile("srl %0, %1, %2" : "=r"(u) : "r"(vu), "r"(31));              CHECK(0x04, u == 1u);
  asm volatile("sra %0, %1, %2" : "=r"(r) : "r"(0x80000000u), "r"(31));     CHECK(0x04, r == -1);
  asm volatile("slli %0, %1, 0" : "=r"(u) : "r"(vu));                       CHECK(0x04, u == 0x80000001u);
  asm volatile("srli %0, %1, 4" : "=r"(u) : "r"(0xF0000000u));              CHECK(0x04, u == 0x0F000000u);
  asm volatile("srai %0, %1, 4" : "=r"(r) : "r"(0xF0000000u));              CHECK(0x04, r == (int32_t)0xFF000000u);

  /* Upper immediates. */
  asm volatile("lui %0, 0xABCDE" : "=r"(u));                                CHECK(0x08, u == 0xABCDE000u);
  asm volatile("1: auipc %0, 0\n la %1, 1b\n sub %0, %0, %1" : "=r"(r), "=r"(u)); CHECK(0x08, r == 0);

  /* Every branch type, taken and not taken. */
  int t = 0;
  asm volatile("li %0, 0\n beq %1, %1, 1f\n addi %0, %0, 1\n 1:" : "=&r"(t) : "r"(vpos));        CHECK(0x10, t == 0);
  asm volatile("li %0, 0\n bne %1, %1, 1f\n addi %0, %0, 1\n 1:" : "=&r"(t) : "r"(vpos));        CHECK(0x10, t == 1);
  asm volatile("li %0, 0\n blt %1, %2, 1f\n addi %0, %0, 1\n 1:" : "=&r"(t) : "r"(vneg), "r"(vpos)); CHECK(0x10, t == 0);
  asm volatile("li %0, 0\n bge %1, %2, 1f\n addi %0, %0, 1\n 1:" : "=&r"(t) : "r"(vneg), "r"(vpos)); CHECK(0x10, t == 1);
  asm volatile("li %0, 0\n bltu %1, %2, 1f\n addi %0, %0, 1\n 1:" : "=&r"(t) : "r"(vneg), "r"(vpos)); CHECK(0x10, t == 1);
  asm volatile("li %0, 0\n bgeu %1, %2, 1f\n addi %0, %0, 1\n 1:" : "=&r"(t) : "r"(vneg), "r"(vpos)); CHECK(0x10, t == 0);

  /* Jumps: jal and jalr write the return address and land on the target. */
  asm volatile("li %0, 0\n jal %1, 1f\n addi %0, %0, 1\n 1: la %0, 1b\n sub %0, %0, %1"
               : "=&r"(r), "=&r"(u));                                        CHECK(0x20, r == 4);
  asm volatile("la %1, 2f\n jalr %0, 0(%1)\n nop\n 2: sub %0, %1, %0"
               : "=&r"(r), "=&r"(u));                                        CHECK(0x20, r == 4);

  /* Loads and stores of every width, signed and unsigned. */
  static volatile uint32_t mem[2];
  mem[0] = 0x8090A0B0u; mem[1] = 0;
  volatile int8_t *s8 = (volatile int8_t *)mem;
  volatile uint8_t *u8 = (volatile uint8_t *)mem;
  volatile int16_t *s16 = (volatile int16_t *)mem;
  volatile uint16_t *u16 = (volatile uint16_t *)mem;
  CHECK(0x40, s8[0] == (int8_t)0xB0 && u8[3] == 0x80 && s16[1] == (int16_t)0x8090 && u16[0] == 0xA0B0);
  u8[4] = 0x11; u16[3] = 0x2233;
  CHECK(0x40, mem[1] == 0x22330011u);

  (void)vbig;
  return (int)fail;
}
