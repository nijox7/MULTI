#################################################################################
# File : reset.s
# Author : Alain Greiner
#################################################################################
# - It initializes the Status Register (SR) 
# - It defines the stack size  and initializes the stack pointer ($29) 
# - It initializes the EPC register, and jumps to user code.
#################################################################################
        
.section .reset,"ax",@progbits

.extern seg_stack_base
.extern seg_data_base

.func reset
.type reset, %function

reset:
    .set noreorder

    # initializes stack pointer
    mfc0 $27, $15, 1        # récupère le numéro du processeur
    la $29, seg_stack_base  # récupère l'adresse de la base de la pile

    li $26, 0x10000         # r26 <= 64 000
    addiu $27, $27, 1       # procid <= procid + 1, on fait ça pour que le processeur 0 ait une adresse à +64kBytes et aps à 0
    mult $27, $26           # res <= r27 * r26 = procid * 64 000
    mflo $27                # r27 <= res, move from low (LSB de la multiplication)
    
    addu $29, $29, $27      # stack_base <= stack_base + (procid+1) * 64000

    # initializes SR register
    li    $26, 0x0000FF13    
    mtc0  $26, $12            # SR <= 0x0000FF13

    # jump to main in user mode
    la    $26, seg_data_base
    lw    $26, 0($26)         # get the user code entry point 
    mtc0  $26, $14            # write it in EPC register
    eret

    .set reorder

    .endfunc
    .size    reset, .-reset

