# electronic_dice_game-Nandland-GoBoard
 implimentation of electronic dice on the nandland GoBoard
 includes a random number generator with 3 bits(integer values 1 to 6....like dice DUH!!!)
 display output on 7 segment LED
 
 
 original code repository for implimentation on Xilinx Spartan 6 found here:
 https://github.com/ninadwaingankar/Electronic-Dice-on-FPGA-

my aim is to use the constraints of the nandland GoBoard to impliment the same logic

07.20.2021 afternoon update_ what a PITA. this thing simulates in 2 different simulators and all outputs are giving proper results. 
But is does NOT run on the board. The 7 segment just says 0. I set the LED 4 to blink every time we reach the 1 second counter and that is working, so the problem must be in the 
syntax of the bits of code dealing with temp and rand_temp.

07.26.20201  abandoned the original attempt at using the XOR to generate a random number. It just doesnt work. I simulated the code from ninadwaingakar and it does not work so
so it was a lost cause. I assumed it was working since it was posted on an FPGA projects website. 
I made my own implimentation. I simply used a couple of counters to generate the random behavior. When the button is pressed, whichever value that counter_2 has counted to is the output dice integer. 
this is working fine. this e-dice module could be a part of the combinational logic of a larger program using the dice rolls in a game of some type
