.global _main
.align 2

; These registers are used when making system calls such as printing or exiting.
; When not being used for that, they can freely be used to hold temporary data.
sysarg_0   .req x0
sysarg_1   .req x1
sysarg_2   .req x2

tmp_0      .req x0
tmp_1      .req x1
tmp_2      .req x2

; These registers are used to store which permutations we've visited. For N=6
; there are 720 permutations so we'd need 12 registers (64-bits) for this. We
; arbitrarily assign a unique id for each permutation (based on lexical order).
visited_0  .req x3
visited_1  .req x4
visited_2  .req x5
visited_3  .req x6
visited_4  .req x7
visited_5  .req x8
visited_6  .req x9
visited_7  .req x10
visited_8  .req x11
visited_9  .req x12
visited_10 .req x13
visited_11 .req x14

; This register is used to store the number of 'wasted' characters remaining.
; It ticks down as the program recurses. See below for what 'wasted' means.
rem_waste  .req x15

; This register is used when making system calls and specifies the type of call.
; When not being used for that, it can freely be used to hold temporary data.
sys_call   .req x16
tmp_3      .req x16

; This register is used to store the maximum 'wasted' characters allowed for the
; current subproblem. It increments after each subproblem is solved.
max_waste  .req x17

; This register is used to store the best recursion depth we've seen across all
; subproblems. It is some multiple of 16 bytes below the current stack pointer.
best_depth .req x18

; This register is set to the base address of the max_perms_array. Normally this
; register is used to point to the stack frame but we don't need that.
max_perms .req x29

; This register is automatically set by the 'branch with link' instruction (bl)
; to the address just after the branch (i.e. where control should return to).
return_adr .req x30

; Registers x19 to x28 aren't used but they're 'callee saved' registers so we
; should choose others first if possible. That way, it would be easier to
; repurpose this code to make it interop with a calling process in the future.

_main:
  ; Set max_perms to the base address of 'max_perms_array' for convenience.
  adrp max_perms, max_perms_array@PAGE
  add max_perms, max_perms, max_perms_array@PAGEOFF

  ; Indent the start index of the array a bit so we can underflow it slightly.
  add max_perms, max_perms, 6 * 64

  ; Initially, we haven't visited any permutations so clear all the bitsets.
  mov visited_0, 0
  mov visited_1, 0
  mov visited_2, 0
  mov visited_3, 0
  mov visited_4, 0
  mov visited_5, 0
  mov visited_6, 0
  mov visited_7, 0
  mov visited_8, 0
  mov visited_9, 0
  mov visited_10, 0
  mov visited_11, 0

  mov tmp_0, 0
  mov max_waste, 0

  ; Initialize the max_perms array to the values we've already found for the
  ; number of permutations that fit into a string that wastes i characters.
  ;
  ; A wasted character is one that doesn't add a new permutation to the string.
  ; For example, '123456' + '2' == '1234562' and '234562' isn't a permutation.
  mov tmp_0, 6
  str tmp_0, [max_perms, max_waste, lsl 3]
  add max_waste, max_waste, 1

  mov tmp_0, 12
  str tmp_0, [max_perms, max_waste, lsl 3]
  add max_waste, max_waste, 1

  ; (The above lines can be omitted if running the search from scratch.)

  ; The best depth we've seen so far is the current stack pointer reduced by the
  ; maximum number of permutations we've seen, or 0 if running from scratch.
  ;
  ; We might actually want to set this 1..N - 1 higher if a previous run of the
  ; algorithm got further but didn't exhaust the search space for the subproblem.
  sub best_depth, sp, tmp_0, lsl 4

  ; Allow max_waste wasted characters when solving the first subproblem.
  mov rem_waste, max_waste

  next_subproblem:

  ; Arbitrarily start the depth-first search from permutation '123456' seeing as
  ; the problem is symmetrical. This call recursively visits other permutations.
  bl visit_123456

  ; Calculate the maximum number of permutations reached this run by comparing
  ; best_depth against the current stack pointer. We right shift by 4 because
  ; the result is a multiple of 16 bytes. This has the effect of dividing by 16.
  sub tmp_0, sp, best_depth
  lsr tmp_0, tmp_0, 4

  ; Store the maximum number of permutations in the array so we can use it to
  ; bound the search for future subproblems. This stores the value at a base
  ; address of 'max_perms' plus an index of 'max_waste' multiplied by 8 bytes.
  str tmp_0, [max_perms, max_waste, lsl 3]

  ; Allow one additional wasted character when solving the next subproblem.
  add max_waste, max_waste, 1
  mov rem_waste, max_waste

  ; If we didn't reach all N! permutations, start solving the next subproblem.
  cmp tmp_0, 720 ; or 360 if we're solving the palindromic version.
  b.ne next_subproblem

  ; Exit the program with status code 0.
  mov sys_call, 1
  mov sysarg_0, 0
  svc 0


new_best_depth_found:
  ; Temporarily save tmp_0 in best_depth because we need that system argument.
  ; We know that best_depth equals the current stack pointer at present.
  mov best_depth, tmp_0

  ; TODO: Print string by storing it on the stack. The second register can be
  ; shared and contain two 32-bit integers for 'rem_waste' and 'permutation_id'
  ; or just simply the digit that was added to the end of the string.
  mov sys_call, 4
  mov sysarg_0, 1
  adr sysarg_1, todo
  mov sysarg_2, 23
  svc 0

  ; Restore tmp_0 to what it was previously.
  mov tmp_0, best_depth

  ; Set best_depth to the current stack pointer and return.
  mov best_depth, sp
  ret


visit_123456:
  ; Push the return address and the number of remaining wasted characters to
  ; the stack so we can restore them later. The return address is overridden
  ; by the next 'branch with link' instruction, i.e. when we recurse.
  stp return_adr, rem_waste, [sp, -16]!

  ; Mark the '123456' permutation as visited. The exclusive-or instruction flips
  ; the bit corresponding to this permutation. We only ever visit permutations
  ; that haven't been visited so this will always transition from '0' -> '1'.
  ; This instruction takes a bitmask so the immediate value needs to be 2^i.
  eor visited_0, visited_0, 1


  ; These are all the permutations we can reach without wasting any additional
  ; characters. There will always only be one permutation of this kind.
  ; ===========================================================================

  ; Test a bit of a register and check if it is non-zero. If so, branch to the
  ; label. This has the effect of skipping the subsequent line which visits that
  ; permutation. The permutation '234561' is 154th when written out lexically.
  ; Each register is 64-bits so its at position 26 in register 3 (0-indexed).
  tbnz visited_2, 25, after_134652_234561
  bl visit_234561
  after_134652_234561:

  ; Calculate how many bytes we are away from from the best recursion depth we've
  ; seen so far. This value is (usually) positive and a multiple of 16 bytes
  subs tmp_0, sp, best_depth

  ; If this number is negative it means we've reached a new best recursion
  ; depth. Call a subroutine that sets the new best_depth and prints the string.
  ;
  ; The branching here is negated because we want to provide a branch prediction
  ; hint using the 'bl' instruction that we will return here in a moment. This
  ; can help the CPU queue the correct instructions and minimise stalling.
  ;
  ; If we don't need to print the string we can avoid branching all-together and
  ; use a 'csel' instruction to update best_depth. That doesn't support 'sp' as
  ; an operand but we could then use a register as a replacement stack pointer.
  b.ge no_improvement_123456
  bl new_best_depth_found
  no_improvement_123456:


  ; These are all the permutations we can reach by wasting 1 character.
  ; ===========================================================================

  ; Decrement the remaining number of wasted characters by 1.
  sub rem_waste, rem_waste, 1

  ; Look up the maximum number of permutations we could hope to add to the
  ; string based on how many wasted characters we have remaining. The max_perms
  ; array stores elements at 8-byte intervals so left shift the index by 3 bits.
  ldr tmp_1, [max_perms, rem_waste, lsl 3]

  ; If it might be possible to recurse lower than best_depth then keep going,
  ; otherwise abandon this string and return back to the previous permutation.
  cmp tmp_0, tmp_1, lsl 4
  b.ge unwind_123456

  tbnz visited_4, 49, after_123456_345621
  bl visit_345621
  after_123456_345621:


  ; These are all the permutations we can reach by wasting 2 characters.
  ; ===========================================================================

  sub rem_waste, rem_waste, 1

  sub tmp_0, sp, best_depth
  ldr tmp_1, [max_perms, rem_waste, lsl 3]

  cmp tmp_0, tmp_1, lsl 4
  b.ge unwind_123456

  ; Omitted for brevity.
  ;
  ; The number of reachable permutations increases rapidly as the number of
  ; wasted characters increases. We could limit the search to only find strings
  ; that contain at most k consecutive wasted characters by simply omitting
  ; the lines of assembly from this region of the program.


  ; At the end, mark '123456' as unvisited and pop the return address from the
  ; stack so we can 'unwind' and continue the search from the level above. We
  ; also reset the remaining number of wasted characters to what it was before.
  unwind_123456:
  eor visited_0, visited_0, 1
  ldp return_adr, rem_waste, [sp], 16
  ret

; The program would then repeat the above ^ pattern for all N! permutations.
; This is only an example so we omit these for brevity. The two permutations
; visited above are stubbed out below so that this example can be compiled.

visit_234561:
  ret

visit_345621:
  ; Ignore this. This just ensures the example program terminates by making it
  ; appear as though we've visited all 720 permutations. Without this, we'd keep
  ; pushing '1' to max_perms_array until we overflow the array bounds.
  mov tmp_0, 719
  lsl tmp_0, tmp_0, 4
  sub best_depth, sp, tmp_0

  ret

todo:
  .ascii "todo: print the string\n"

; Store an array of 64-bit / 8-byte values to hold the maximum number of
; permutations that fit into a string that contains i wasted characters.
;
; The best known superpermutation for N=6 has 872 characters and it therefore
; wastes 872 - n! - (n - 1) = 147 characters so 200 elements should be enough.
.data
max_perms_array:
  .fill 200, 8, 0
