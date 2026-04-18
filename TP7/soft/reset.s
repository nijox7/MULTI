#################################################################################
#    File : reset.s
#    Author : Alain Greiner
#    Date : 25/12/2011
#################################################################################
#       This is a boot code for a mono-processor architecture.
#       - initializes the interrupt vector for DMA and TTY.
#       - initializes the ICU MASK register for DMA and TTY.
#       - initializes the Status Register.
#       - initializes the stack pointer.
#       - initializes the EPC register, and jumps to the user code.
#################################################################################
        
.section .reset,"ax",@progbits

.extern seg_stack_base
.extern seg_data_base
.extern seg_icu_base

.func   reset
.type   reset, %function

reset:
    .set noreorder

    # initialises interrupt vector
    la    $26,	  _interrupt_vector
    la    $27,    _isr_tty_get
    sw    $27,    12($26)           # _interrupt_vector[3] <= _isr_tty_get
    la    $27,    _isr_dma
    sw    $27,    0($26)            # _interrupt_vector[0] <= _isr_dma

    # get the processor id
    mfc0  $27,    $15,    1      # get the proc_id
    bne   $27,    $0,     proc1
    addi  $27,    $27,    -1
    bne   $27,    $0,     proc1
    addi  $27,    $27,    -1
    bne   $27,    $0,     proc2
    addi  $27,    $27,    -1
    bne   $27,    $0,     proc3

proc0:
    # initializes the ICU MASK[0] register
    la    $26,    seg_icu_base
    addiu $26,    $26,    0         # ICU[0]
    li    $27,    0b00001001        # IRQ_DMA[0] & IRQ_TTY[0]
    sw    $27,    8($26)

    # initializes stack pointer
    la    $29,    seg_stack_base
    li    $27,    0x40000           # stack size = 256K
    addu  $29,    $29,    $27       # $29 <= seg_stack_base + 64K

    # initializes SR register
    li    $26,    0x0000FF13
    mtc0  $26,    $12               # SR <= 0x0000FF13

    # jump to main in user mode
    la    $26,    seg_data_base
    lw    $26,    0($26)            # $26 <= main[0]
    mtc0  $26,    $14               # write it in EPC register
    eret

    .set reorder

proc1:
    # initializes the ICU[1] MASK register
    li      $26,    seg_icu_base
    addi    $26,    0x20          # ICU[1]
    li      $29,    0b00100001    # IRQ_DMA[0] & IRQ_TTY[1]
    sw      $27,    8($26)

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

proc2:
    # initializes the ICU[2] MASK register
    li      $26,    seg_icu_base
    addi    $26,    0x40          # ICU[2]
    li      $29,    0b10000001    # IRQ_DMA[0] & IRQ_TTY[2]
    sw      $27,    8($26)

    # initializes Status Register for PROC[2]
    li    $26,  0x0000FF13      # user mode, exception level = 1, irq mask = FF, irq enable
    mtc0  $26,  $12             # SR <= 0x0000FF13

    # jump to main in user mode: main[2]
    la    $26,    seg_data_base
    lw    $26,    8($26)         # $26 <= main[1], chaque adresse est sur 4 octet donc on fait 4($26)
    mtc0  $26,    $14            # write it in EPC register
    eret

proc3:
    # initializes the ICU[1] MASK register
    li      $26,    seg_icu_base
    addi    $26,    0x80          # ICU[1]
    li      $29,    0b1000000001  # IRQ_DMA[0] & IRQ_TTY[3]
    sw      $27,    8($26)

    # initializes Status Register for PROC[3]
    li    $26,  0x0000FF13      # user mode, exception level = 1, irq mask = FF, irq enable
    mtc0  $26,  $12             # SR <= 0x0000FF13

    # jump to main in user mode: main[3]
    la    $26,    seg_data_base
    lw    $26,    12($26)         # $26 <= main[1], chaque adresse est sur 4 octet donc on fait 4($26)
    mtc0  $26,    $14            # write it in EPC register
    eret

.endfunc
.size    reset, .-reset

