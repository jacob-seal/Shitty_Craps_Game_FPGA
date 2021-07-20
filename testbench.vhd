----------------------------------------------------------------------
-- testbench for the simulation of dice on the nandland GoBoard 
--this testbench really just sets a clock to run
--later expansion is for triggering with the button
--but for starters just working with the clock. 
----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity dice_TB is
end dice_TB;
 
architecture Behave of dice_TB is
   
  -- Test Bench uses a 100 MHz Clock --the goBoard uses 25MHz just FYI
  constant c_CLK_PERIOD : time := 10 ns;
   
  signal i_Switch_4_tb     : std_logic                    := '0';
  signal i_Clk_tb     : std_logic                    := '0';
  
   
begin
 
  -- Instantiate DICE
  DICE_INST : entity work.edice
    generic map (
      width => 3
      )
    port map (
      i_Switch_4     => i_Switch_4_tb,
      i_Clk       => i_Clk_tb
      );
 
 
 
 
  --set clock signal
  i_Clk_tb <= not i_Clk_tb after c_CLK_PERIOD/2;
   
   
end Behave;
