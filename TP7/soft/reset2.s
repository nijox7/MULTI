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

    mfc0  $26,	$15,    1	    # get processer id
    la 	  $27,  _interrupt_vector   # get interrupt_vector adress

    andi  $8,   $26,	1	    # keep LSB(0) of procid
    bne	  $8, 	$0,	    proc
    # initializes interrupt vector for dma
    nop
    la    $9, 	_isr_dma
    sw    $9,	0($27)        	# _interrupt_vector[0] <= _isr_dma

proc:
    # --- initializes interrupt vector for tty --- ;;;
    la    $8,	_isr_tty_get
    lw    $9, 	12($27)         # _interrupt_vector tty
    li    $10,  8
    mult  $10,  $26             # 8 * procid
    mflo  $10
    add   $27,  $27,    $10     # _interrupt_vector + 12 + 8*procid
    sw    $8,	0($27)            # _interrupt_vector[tty_id] <= _isr_tty_get


    # --- initializes the ICU MASK register--- ;;;
    la    $27,    seg_icu_base

    # calculating ICU[procid]
    li    $8,   0x20
    mult  $8,   $26
    mflo  $8
    add   $27,  $27,    $8  # $27 <= ICU[procid]

    # calculating MASK[tty] and MASK[dma]
    li    $8,   1
    li    $9,   2
    mult  $9,   $26
    mflo  $9                # procid * 2
    sll   $8,   3           # MASK[3]
    sllv  $8,   $8,     $9  # MASK[3 + 2*procid]
    addiu $8,   $8,     1   # MASK[0]
    sw    $8,    8($27)     # ICU[PROCID] <= MASK


    # --- initializes stack pointer --- ;;;
    la    $29,    seg_stack_base
    li    $27,    0x40000           # stack size = 256K
    add   $8,     $26,    1         # $8 <= procid + 1
    mult  $27,    $8                # 256K * (procid+1)
    mflo  $27
    addu  $29,    $29,    $27       # seg_stack_base + 256K*procid


    # --- initializes SR register --- ;;;
    li    $27,    0x0000FF13
    mtc0  $27,    $12               # SR <= 0x0000FF13


    # --- jump to main in user mode --- ;;;
    la    $27,    seg_data_base
    lw    $27,    0($27)            # $26 <= main
    mtc0  $27,    $14               # write it in EPC register
    eret

    .set reorder

.endfunc
.size    reset, .-reset
