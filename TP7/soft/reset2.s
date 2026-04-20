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

    la 	  $26,  _interrupt_vector

    mfc0  $27,	$15,	1	# get processer id
    andi  $27,  $27,	0	# keep LSB(0)
    bne	  $27, 	$0,	proc

    # initialises interrupt vector for dma
    la    $27, 	_isr_dma
    sw    $27,	0($26)        	# _interrupt_vector[0] <= _isr_dma

proc:
    # initialises interrupt vector for tty
    nop
    la    $27,	_isr_tty_get
    lw    $26, 	0($26)

    li	  $26,  8

    mul   $8,  

    sw    $27,	12($26)           # _interrupt_vector[3] <= _isr_tty_get

    # initializes the ICU MASK[0] register
    la    $26,    seg_icu_base
    addiu $26,    $26,    0         # ICU[0]
    li    $27,    0b00001001        # IRQ_DMA[0] & IRQ_TTY[0]
    sw    $27,    8($26)

    # initializes stack pointer
    la    $29,    seg_stack_base
    li    $26,    0x40000           # stack size = 256K
    addu  $29,    $29,    $26       # seg_stack_base + 256K

    # initializes SR register
    li    $26,    0x0000FF13
    mtc0  $26,    $12               # SR <= 0x0000FF13

    # jump to main in user mode
    la    $26,    seg_data_base
    lw    $26,    0($26)            # $26 <= main
    mtc0  $26,    $14               # write it in EPC register
    eret

    .set reorder

proc1:
    # initialises interrupt vector for tty
    la    $26,	  _interrupt_vector
    la    $27,    _isr_tty_get
    sw    $27,    20($26)           # _interrupt_vector[5] <= _isr_tty_get

    # initializes the ICU[1] MASK register
    la      $26,    seg_icu_base
    addi    $26,    $26,    0x20  # ICU[1]
    li      $27,    0b00100001    # IRQ_DMA[0] & IRQ_TTY[1]
    sw      $27,    8($26)

    # initializes stack pointer for PROC[1]
    la      $29,    seg_stack_base
    li      $26,    0x80000
    add     $29,    $29,   $26  # $29 <= seg_stack_base + 2*256K

    # initializes Status Register for PROC[1]
    li    $26,  0x0000FF13      # user mode, exception level = 1, irq mask = FF, irq enable
    mtc0  $26,  $12             # SR <= 0x0000FF13

    # jump to main in user mode: main
    la    $26,    seg_data_base
    lw    $26,    0($26)         # $26 <= main
    mtc0  $26,    $14            # write it in EPC register
    eret

proc2:
    # initializes interrupt vector for tty
    la    $26,	  _interrupt_vector
    la    $27,    _isr_tty_get
    sw    $27,    28($26)          # _interrupt_vector[7] <= _isr_tty_get

    # initializes the ICU[2] MASK register
    la      $26,    seg_icu_base
    addi    $26,    $26,    0x40  # ICU[2]
    li      $27,    0b10000001    # IRQ_DMA[0] & IRQ_TTY[2]
    sw      $27,    8($26)

    # initializes stack pointer for PROC[2]
    la      $29,    seg_stack_base
    li      $26,    0xC0000
    add     $29,    $29,  $26	# seg_stack_base + 3*256K

    # initializes Status Register for PROC[2]
    li    $26,  0x0000FF13      # user mode, exception level = 1, irq mask = FF, irq enable
    mtc0  $26,  $12             # SR <= 0x0000FF13

    # jump to main in user mode: main
    la    $26,    seg_data_base
    lw    $26,    0($26)         # $26 <= main
    mtc0  $26,    $14            # write it in EPC register
    eret

proc3:
    # initializes interrupt vector for tty
    la    $26,	  _interrupt_vector
    la    $27,    _isr_tty_get
    sw    $27,    36($26)           # _interrupt_vector[9] <= _isr_tty_get

    # initializes the ICU[1] MASK register
    la      $26,    seg_icu_base
    addi    $26,    $26,    0x60  # ICU[3]
    li      $27,    0b1000000001  # IRQ_DMA[0] & IRQ_TTY[3]
    sw      $27,    8($26)

    # intitializes stack pointer for PROC[3]
    la    $29,	seg_stack_base
    li    $26,  0x100000
    add   $29,  $29,  $26 	# seg_stack_base + 4*256k

    # initializes Status Register for PROC[3]
    li    $26,  0xFF13      	# user mode, exception level = 1, irq mask = FF, irq enable
    mtc0  $26,  $12             # SR <= 0xFF13

    # jump to main in user mode: main
    la    $26,    seg_data_base
    lw    $26,    0($26)       # $26 <= main
    mtc0  $26,    $14           # write it in EPC register
    eret


    .set reorder

rien:

.endfunc
.size    reset, .-reset


