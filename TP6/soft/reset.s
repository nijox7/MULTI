#################################################################################
#    File : reset.s
#    Author : Alain Greiner
#################################################################################
#       This is an improved boot code for a bi-processor architecture.
#    Depending on the proc_id, each processor
#       - initializes the interrupt vector.
#       - initializes the ICU MASK registers.
#       - initializes the TIMER .
#       - initializes the Status Register.
#       - initializes the stack pointer.
#       - initializes the EPC register, and jumps to the user code.
#################################################################################
        
    .section .reset,"ax",@progbits

    .extern seg_stack_base
    .extern seg_data_base

    .func   reset
    .type   reset, %function

reset:
    .set noreorder

    # get the processor id
    mfc0  $27,    $15,    1      # get the proc_id
    andi  $27,    $27,    0x1    # no more than 2 processors
    bne   $27,    $0,     proc1

proc0:
    # initialises interrupt vector entries for PROC[0]
    la     $27,    _interrupt_vector
    la     $29,    _isr_timer
    sw     $29,    8($27)        # _vector_interrupt[2] = _isr_timer
    # initializes the ICU[0] MASK register
    li     $27,    0x9F000000    # $27 <= seg_icu_base
    li     $29,    0x8           # mask <= 00...100, met le mask de l'irq d'indice 2 à 1
    sw     $29,    8($27)        # icu_set <= mask, ICU0 a pour adresse seg_icu_base + 8
    # initializes TIMER[0] PERIOD and RUNNING registers
    li     $27,    0x91000000    # $27 <= seg_tim_base
    li     $29,    0xC350        # $29 <= 50000
    #li     $29,    0x16
    sw     $29,    8($27)        # period = 50000
    li     $29,    0x3           # 11, Timer ON et IRQ enabled
    sw     $29,    4($27)        # mode = 11
    # initializes stack pointer for PROC[0]
    la    $29,    seg_stack_base
    li    $27,    0x10000        # stack size = 64K
    addu  $29,    $29,    $27    # $29 <= seg_stack_base + 64K

    # initializes Status Register for PROC[0]
    li    $26,    0x0000FF13     # user mode, exception level = 1, irq mask = FF, irq enable
    mtc0  $26,    $12            # SR <= 0x0000FF13

    # jump to main in user mode: main[0]
    la    $26,    seg_data_base
    lw    $26,    0($26)         # $26 <= main[0]
    mtc0  $26,    $14            # write it in EPC register
    eret

proc1:
    # initialises interrupt vector entries for PROC[1]
    la      $27,    _interrupt_vector
    la      $29,    _isr_timer
    sw      $29,    16($27)        # _vector_interrupt[4] = _isr_timer
    # initializes the ICU[1] MASK register
    li      $27,    0x9F000000    # $27 <= seg_icu_base
    addi    $27,    0x20          # $27 <= $27 + 32 pour ICU 1
    li      $29,    0x8           # mask <= 00...100, met le mask de l'irq d'indice 2 à 1
    sw      $29,    8($27)        # icu_set <= mask, ICU0 a pour adresse seg_icu_base + 8
    # initializes TIMER[1] PERIOD and RUNNING registers
    li      $27,    0x91000000    # $27 <= seg_tim_base
    addi    $27,    0x10          # $27 <= $27 + 16 pour timer 1
    li      $29,    0x186A0       # $29 <= 10000
    sw      $29,    8($27)        # period = 10000
    li      $29,    0x3           # 11, Timer ON et IRQ enabled
    sw      $29,    4($27)        # mode = 11

    #sw     $29,    18($27)       # period = 100000, period du timer1 a pour adresse seg_tim_base + 18
    # initializes stack pointer for PROC[1]
    la  $29,    seg_stack_base
    li  $27,    0x20000         # offset -> stack_size proc0 + stack size proc1 = 128K
    addu $29, $29, $27          # $29 <= seg_stack_base + 2*64K

    # initializes Status Register for PROC[1]
    li    $26,  0x0000FF13      # user mode, exception level = 1, irq mask = FF, irq enable
    mtc0  $26,  $12             # SR <= 0x0000FF13

    # jump to main in user mode: main[1]
    la    $26,    seg_data_base
    lw    $26,    4($26)         # $26 <= main[1], chaque adresse est sur 4 octet donc on fait 4($26)
    mtc0  $26,    $14            # write it in EPC register
    eret

    .set reorder

    .set reorder

    .endfunc
    .size    reset, .-reset

