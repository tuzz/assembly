.global _main
.align 2

; Prints 'hello' 2^N times.
;   - repeatedly doubles x3 by adding it to itself x4 times
;   - repeatedly prints 'hello' by decrementing x3 until it reaches 0
;   - uses 'svc' to ask the supervising process to print and exit
;   - uses 'subs' instead of 'sub' to set process state so that we can compare
;     the previous value to 0 without an extra 'cmp' instruction
;   - the program's alignment is wrong if 'hello' comes before the instructions

_main:
  mov x3, #1        ; x3 = 1
  mov x4, #5        ; x4 = 5

loop1:
  add x3, x3, x3    ; double x3
  subs x4, x4, #1   ; decrement x4
  b.ne loop1        ; loop if x4 != 0

loop2:
  mov x0, #1        ; print to stdout
  adr x1, hello     ; string to print
  mov x2, #6        ; length to print
  mov x16, #4       ; system output
  svc 0             ; supervisor call
  subs x3, x3, #1   ; decrement x3
  b.ne loop2        ; loop if x3 != 0

  mov x0, #0        ; exit status
  mov x16, #1       ; system exit
  svc 0             ; supervisor call

hello: .ascii "hello\n"
