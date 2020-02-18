# See LICENSE for license details.

#
# Test tagger
#

#include "riscv_test.h"
#include "test_macros.h"
#define TAG_LOAD_FAULT 16
#define TAG_STORE_FAULT 17
#define NEXT_PC_FAULT 18

RVTEST_RV64M
RVTEST_CODE_BEGIN

#ifdef __MACHINE_MODE
  #define sscratch mscratch
  #define sstatus mstatus
  #define scause mcause
  #define sepc mepc
  #define sret mret
  #define stvec_handler mtvec_handler
  #undef SSTATUS_SPP
  #define SSTATUS_SPP MSTATUS_MPP
#endif

  # For RV64, make sure UXL encodes RV64.  (UXL does not exist for RV32.)
#if __riscv_xlen == 64
  # If running in M mode, use mstatus.MPP to check existence of U mode.
  # Otherwise, if in S mode, then U mode must exist and we don't need to check.
#ifdef __MACHINE_MODE
  li t0, MSTATUS_MPP
  csrc mstatus, t0
  csrr t1, mstatus
  and t0, t0, t1
  bnez t0, 1f
#endif
  # If U mode is present, UXL should be 2 (XLEN = 64-bit)
  TEST_CASE(13, a0, SSTATUS_UXL & (SSTATUS_UXL << 1), csrr a0, sstatus; li a1, SSTATUS_UXL; and a0, a0, a1)
#ifdef __MACHINE_MODE
  j 2f
1:
  # If U mode is not present, UXL should be 0
  TEST_CASE(14, a0, 0, csrr a0, sstatus; li a1, SSTATUS_UXL; and a0, a0, a1)
2:
#endif
#endif

  csrwi sscratch, 3
  TEST_CASE( 2, a0,         3, csrr a0, sscratch);
  TEST_CASE( 3, a1,         3, csrrci a1, sscratch, 1);
  TEST_CASE( 4, a2,         2, csrrsi a2, sscratch, 4);
  TEST_CASE( 5, a3,         6, csrrwi a3, sscratch, 2);
  TEST_CASE( 6, a1,         2, li a0, 0xbad1dea; csrrw a1, sscratch, a0);
  TEST_CASE( 7, a0, 0xbad1dea, li a0, 0x0001dea; csrrc a0, sscratch, a0);
  TEST_CASE( 8, a0, 0xbad0000, li a0, 0x000beef; csrrs a0, sscratch, a0);
  TEST_CASE( 9, a0, 0xbadbeef, csrr a0, sscratch);

	la a0, fsw_data
	li a1, 22
  	sw a1, 0(a0)

	la a1, sized_pointer_tag
	lw a2, 0(a1)
	sw a2, 0(a0)

	la sp, sized_pointer_tag
  	lw a1, 0(sp)
        la t1, sized_pointer_data
     .word (0x00007003 | (( 2) << 15) | (( 1) << 7))
     .word (0x00007003 | (( 2) << 15) | (( 2) << 7))
	## avoid bad bypass value
	sw sp, 0(t1)
	sw sp, 0(t1)
     .word (0x00007003 | (( 2) << 15) | (( 3) << 7))
     .word (0x00007003 | (( 2) << 15) | (( 4) << 7))
     .word (0x00007003 | (( 2) << 15) | (( 5) << 7))
     .word (0x00007003 | (( 2) << 15) | (( 6) << 7))
     .word (0x00007003 | (( 2) << 15) | (( 7) << 7))
     .word (0x00007003 | (( 2) << 15) | (( 8) << 7))
     .word (0x00007003 | (( 2) << 15) | (( 9) << 7))
     .word (0x00007003 | (( 2) << 15) | ((10) << 7))
     .word (0x00007003 | (( 2) << 15) | ((11) << 7))
     .word (0x00007003 | (( 2) << 15) | ((12) << 7))
     .word (0x00007003 | (( 2) << 15) | ((13) << 7))
     .word (0x00007003 | (( 2) << 15) | ((14) << 7))
     .word (0x00007003 | (( 2) << 15) | ((15) << 7))

     li    x1, 1
     csrw 0x802, x1
     TEST_CASE(15, a0, 1, csrr a0, 0x802) ;

     la x3, sized_pointer_tag
     lw x4, 0(x3)
     la x1, sized_pointer_data
     sw x4, 0(x1)
     la x2, sized_pointer_data2
     # assign x1's tag from 0(x3)
     .word (0x00007003 | (( 3) << 15) | (( 1) << 7))
     ## avoid bad bypass value
     or x0, x0, x0
     or x0, x0, x0
     lw x2, 0(x1)
     lw x2, 8(x1)
     .word (0x00007023 | (( 3) << 15) | (( 1) << 20))
     .word (0x00007003 | (( 3) << 15) | (( 1) << 7))
     or x0, x0, x0
     or x0, x0, x0

     ## this load should trap
     #lw x2, 32(x1)
     ## verify pointer add is tracked
     addi x1, x1, 16
     lw x2, 16(x1)

     j fail

  TEST_PASSFAIL

finish:
  RVTEST_PASS

  .align 2
  .global stvec_handler
stvec_handler:
  csrr t0, scause
  csrr t0, scause
  li t1, TAG_LOAD_FAULT
  beq t0, t1, finish
  li t1, CAUSE_USER_ECALL
  bne t0, t1, fail
  RVTEST_PASS

privileged:
  # Make sure scause indicates a lack of privilege.
  csrr t0, scause
  li t1, 16
  bne t0, t1, fail
  # Return to user mode, but skip the trapping instruction.
  csrr t0, sepc
  addi t0, t0, 4
  csrw sepc, t0
  sret

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

padding: .word 1
fsw_data: .word 17
sized_pointer_scratch:	 .word 0
sized_pointer_tagbefore: .word 0xbef00000
sized_pointer_tag:	.word (0xc0000000 | (16 << 15))
sized_pointer_tagafter:	.word 0xaf700000
sized_pointer_data:	.word 0x17172242
sized_pointer_data2:	.word 0xbad0beef

RVTEST_DATA_END
