# electronic_dice_on_FPGA-Nandland-GoBoard
 implimentation of electronic dice on the nandland GoBoard
 includes a random number generator with 3 bits(integer values 1 to 6....like dice DUH!!!)
 display output on 7 segment LED
 
 
 original code repository for implimentation on Xilinx Spartan 6 found here:
 https://github.com/ninadwaingankar/Electronic-Dice-on-FPGA-

my aim is to use the constraints of the nandland GoBoard to impliment the same logic

07.20.2021 afternoon update_ what a PITA. this thing simulates in 2 different simulators and all outputs are giving proper results. 
But is does NOT run on the board. The 7 segment just says 0. I set the LED 4 to blink every time we reach the 1 second counter and that is working, so the problem must be in the 
syntax of the bits of code dealing with temp and rand_temp.