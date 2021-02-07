.global _main
.align 2

; This improves on src/graph by reducing the number of instructions per edge
; from 2 to 1 which should scale better for large graphs. It achieves this by
; moving the check of whether we've visited a node into the 'visit_' subroutine.
;
; Rather than branch back to the 'caller' directly, we first jump to the bottom
; of the subroutine so that we can use the the 'ret' instruction. This provides
; a hint that this is a subroutine return that we wouldn't get otherwise.
; TODO: test this vs. returning directly to x30

_main:
  mov x0, #0             ; we haven't visited any nodes yet
  bl visit_a             ; visit node A

  mov x0, #0             ; exit status
  mov x16, #1            ; system exit
  svc 0                  ; supervisor call

visit_a:
  tbnz x0, #0, x30       ; if we've already visited A, branch to the return

  str x30, [sp, -16]!    ; push the return address to the the stack
  eor x0, x0, #1         ; mark A as visited

  bl visit_b             ; visit node B
                         ; visit more nodes here for more complicated graphs

  eor x0, x0, #1         ; mark A as visited
  ldr x30, [sp], 16      ; pop the return address from the stack

  ret


visit_b:
  tbnz x0, #5, x30

  str x30, [sp, -16]!
  eor x0, x0, #32

  bl visit_a

  eor x0, x0, #32
  ldr x30, [sp], 16

  ret
