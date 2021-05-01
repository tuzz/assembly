.global _main
.align 2

// This program exits with status 0 if a hamiltonian path exists for the graph I
// talked about in my presentation to the Boston Computation Club. It exits with
// status 1 if no path exists. It does not try to print the hamiltonian path.
//
// It is a depth-first search that starts from every possible node. It uses x0
// to remember which nodes it has visited in the path it is currently trying so
// that it doesn't visit the same node more than once.
//
// We use the indexes 0,1,2,3,4,5 in the bitset for A,B,C,D,E,F respectively.
//
// To test whether a path has been found, we check if the integer value of the
// x0 register is the binary number '111111' which is 63 in decimal.

_main:
  mov x0, #0

  bl visit_a
  bl visit_b
  bl visit_c
  bl visit_d
  bl visit_e
  bl visit_f

no_path_found:                // _main falls through to this subroutine.
  mov x16, #1
  mov x0, #1
  svc 0

found_a_path:
  mov x16, #1
  mov x0, #0
  svc 0

visit_a:
  str x30, [sp, -16]!
  eor x0, x0, #1              // This flips the bit corresponding to this node.

  tbnz x0, #1, after_ab
  bl visit_b
  after_ab:

  cmp x0, #63
  b.eq found_a_path

  eor x0, x0, #1              // Then flips it back again when unwinding.
  ldr x30, [sp], 16
  ret

visit_b:
  str x30, [sp, -16]!
  eor x0, x0, #2

  tbnz x0, #2, after_bc
  bl visit_c
  after_bc:

  tbnz x0, #3, after_bd
  bl visit_d
  after_bd:

  tbnz x0, #4, after_be
  bl visit_e
  after_be:

  tbnz x0, #5, after_bf
  bl visit_f
  after_bf:

  cmp x0, #63
  b.eq found_a_path

  eor x0, x0, #2
  ldr x30, [sp], 16
  ret

visit_c:
  str x30, [sp, -16]!
  eor x0, x0, #4

  tbnz x0, #5, after_cf
  bl visit_f
  after_cf:

  cmp x0, #63
  b.eq found_a_path

  eor x0, x0, #4
  ldr x30, [sp], 16
  ret

visit_d:
  str x30, [sp, -16]!
  eor x0, x0, #8

  tbnz x0, #0, after_da
  bl visit_a
  after_da:

  cmp x0, #63
  b.eq found_a_path

  eor x0, x0, #8
  ldr x30, [sp], 16
  ret

visit_e:
  str x30, [sp, -16]!
  eor x0, x0, #16

  cmp x0, #63
  b.eq found_a_path

  eor x0, x0, #16
  ldr x30, [sp], 16
  ret

visit_f:
  str x30, [sp, -16]!
  eor x0, x0, #32

  tbnz x0, #4, after_fe         // Comment these lines out to remove the edge
  bl visit_e                    // from F to E. The exit status of this program
  after_fe:                     // will change to 1 indicating no path exists.

  eor x0, x0, #32
  ldr x30, [sp], 16
  ret
