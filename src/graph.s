.global _main
.align 2

; This is a proof of concept for a program that traverses a directed graph. The
; basic idea is to do this as fast as possible by using registers on the CPU as
; a bitset of nodes we have visited.
;
; In this example, there are only two nodes so we have more than enough bits in
; one register (64) but the idea would be to extend this across multiple
; registers (there are 31 available).

; We need to be careful to use the correct immediate value for the 'eor' and
; 'tbnz' instructions when (un)setting a bit. The former expects a power of two.
; The latter expects the index value of a bit (in the range 0..63). To emphasise
; this difference, we use index 0 and 5 for A and B's position in the bitset,
; respectively (resulting in 2^0=1 and 2^5=32 powers of two).
;
; This example performs a depth-first traversal of the simple graph: a <--> b.
; We need to use the stack (stored in L1 cache) so that we can unwind and
; explore branches we haven't visited yet.

; When unwinding, we reset state back to how it was - in this case, that just
; means removing the current node from the visited bitset.

; We can make use of the 'tbnz' instruction to test if we've already visited a
; node and skip past it if we have. We could use the 'tbz' instruction instead
; of following it with 'bl' but 'tbz' does not set the hint that we're going to
; return here later, which could mess with CPU branch prediction.
;
; Note: If we want to recover the last path through graph, e.g. if writing a
; search algorithm (A*) that jumps when it finds a solution, we could change the
; 'str' and 'ldr' instructions to 'stp' and 'ldp' to store a pair of values on
; the stack, i.e. the stack pointer plus an id of the node we just visited. We
; can then read these interlaced values back from stack memory at the end.
;
; Alternatively, we could store the current bitset register (x0 in this example)
; as a means of recovering the path, but this becomes much more complicated
; because we somehow need to figure out which register it originated from. The
; advantage of this approach is it would save one instruction: the second 'eor'.

_main:
  mov x0, #0             ; we haven't visited any nodes yet
  bl visit_a;            ; visit node A

  mov x16, #1            ; system exit
  svc 0                  ; supervisor call


visit_a:
  str x30, [sp, -16]!    ; push the return address to the the stack
  eor x0, x0, #1         ; mark A as visited

  tbnz x0, #5, after_ab  ; if we've already visited B, branch to 'after_ab'
  bl visit_b             ; visit node B
  after_ab:

                         ; visit more nodes here for more complicated graphs
                         ; ...
                         ; ...

  eor x0, x0, #1         ; mark A as unvisited
  ldr x30, [sp], 16      ; pop the return address from the stack
  ret


visit_b:
  str x30, [sp, -16]!
  eor x0, x0, #32

  tbnz x0, #0, after_ba
  bl visit_a
  after_ba:

  eor x0, x0, #32
  ldr x30, [sp], 16
  ret
