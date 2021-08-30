----------------------------------------------------------------------------------
--Developed By : Jacob Seal
--sealenator@gmail.com
--07-28-2021
--filename: craps_types_pkg.vhd
--package craps_types_pkg
--
--********************************************************************************
--general notes:
--Custom types that can be used in the craps game. These are arrays for 
--    holding VGA graphics patterns or text messages for user feedback
--********************************************************************************
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.bitmaps_pkg.all;




package craps_types_pkg is

  -----------------------------------------------------------------------------
  -- Constants 
  -----------------------------------------------------------------------------   

    -- Array that holds all possible output messages to the VGA screen
    type t_gamestate_stringmap is array (0 to 11) of string(1 to 68);
        constant c_gamestate_stringmap : t_gamestate_stringmap :=
        (
            ("Awaiting Roll...                                                    "), --0
            ("You lose. Better luck next time. Place your bets and roll again.    "), --1
            ("You win!!! Place your bets and roll again.                          "), --2
            ("You must roll the same number again before rolling a 7 to win.      "), --3
            ("Press Button to roll the dice.                                      "), --4
            ("Awaiting bets...                                                    "), --5
            ("You bet:             $                                              "), --6
            ("You Rolled :                                                        "), --7
            ("Enter your bet on the Keyboard.                                     "), --8
            ("                                                                    "), --9 when nothing should be displayed. 
            ("You have rolled a point number. Please roll again to continue.      "),  --10
            ("Current bank:     $                                                 ") --11
        );

    -- type t_small_dicemap is array (1 to 6) of t_small_dice_bitmap;
    -- constant c_small_dicemap : t_small_dicemap :=
    --     (
    --         small_dice_bitmap_1,
    --         small_dice_bitmap_2,
    --         small_dice_bitmap_3,
    --         small_dice_bitmap_4,
    --         small_dice_bitmap_5,
    --         small_dice_bitmap_6
    --     );

        type t_medium_dicemap is array (0 to 6) of t_medium_dice_bitmap;
    constant c_medium_dicemap : t_medium_dicemap :=
        (
            medium_dice_bitmap_0,
            medium_dice_bitmap_1,
            medium_dice_bitmap_2,
            medium_dice_bitmap_3,
            medium_dice_bitmap_4,
            medium_dice_bitmap_5,
            medium_dice_bitmap_6
        );

  

  

  




  

  -----------------------------------------------------------------------------
  -- Numeric bit patterns for output to VGA for scorekeeping
  -----------------------------------------------------------------------------
  


  -----------------------------------------------------------------------------
  -- Component Declarations
  -----------------------------------------------------------------------------
  

  -----------------------------------------------------------------------------
  -- Function Declarations
  -----------------------------------------------------------------------------
      

    

  
end package craps_types_pkg;  

--package body craps_types_pkg is
    
--end package body craps_types_pkg;




