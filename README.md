# Shitty-Craps_game_FPGA
 The best Shitty Craps game currently available for the Nexys4. Feel that Vegas excitement!
 
 
 Developed by Jacob Seal, for funsies. 
 Anyone can use this code for any reason. I don't care, really. 
 
 The game accepts a bet from the 16 key PMOD keypad from Digilent(if you dont have it the switch to UART is pretty easy), then you press the middle button on the Nexys4  to roll. There are 2 instantiations of psuedo-random electronic dice. From here it plays like casino rules Craps. All bets are paid out or lost at 2x, which is not really accurate but it works for this simple game.  
 
 On the VGA part there is now a splash screen and a gaming table and it makes for a much more playable game.   
 
 To find all the required modules to build the project, look in my other repositories:
 
 https://github.com/jacob-seal/electronic_dice_FPGA
 
 https://github.com/jacob-seal/FPGA_toolbox
 
 Everything is found there
 
 No further developement is planned on this game. It was my goal as a learning project and there isn't much more that I can do with it. 
