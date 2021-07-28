--------------------------------------------------------------------------------
--Developed By : Jacob Seal
--sealenator@gmail.com
--07-27-2021
--filename: dice.vhd
--entity dice
--******************************************************************************
--general notes:                                                               
--dice simulation for an FPGA written in VHDL								   
--button press of switch triggers a new random value between 1 and 6		   
--the button is assumed to be already debounced								   
--the random number is only psuedo random									   
--the human is pressing the button at a random time interval....so it seems    --random to the user
--

--Generics:
--clk_divider - determines the clock speed so different instantiated dice will
--		have a different value. The counter runs at speed 1/clk_divider
--		ex:
--		1: no clock division - counter runs at the clock speed of the FPGA
--		2: counter runs at half speed
--      3: counter runs at 1/3rd speed
--
--Inputs:
--i_Clk - input clock from the FPGA clock input
--i_Switch - debounced signal from a switch on the FPGA
--

--Outputs
--o_rand - psuedo-random integer value returned to the instantiating module
--******************************************************************************
--------------------------------------------------------------------------------




library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity dice is
generic(
		--clock divider factor
		clk_divider		:	integer
);
port (
		--inputs
  		--push button to trigger random number
		i_Switch 		: 	in std_logic;									
		--25Mhz clock
		i_Clk			:	in std_logic;									 
		
		--outputs
		--output integer value between 1 and 6 
		o_rand 			: 	out integer
		);
end dice;


architecture Behavioral of dice is
	
	--counter for psuedo_random logic
	signal r_counter : integer range 1 to 6 := 1;

	--counter for clock divider
	signal r_clk_counter : integer range 0 to clk_divider := 0;

	--signal used to register the random number for the output o_rand
	signal w_rand_temp : integer range 1 to 6;	
	
	
	
begin
	
	--counts from 1 to 6 incrementing on every clock cycle when the 
	--clock divider reaches its factor
	counter_proc : process(i_Clk)
    begin
    	if rising_edge(i_Clk) then
			if r_clk_counter = clk_divider - 1 then
				r_clk_counter <= 0;
        		if r_counter = 6 then
            		r_counter <= 1;
            	else
            		r_counter <= r_counter + 1;
            	end if;
			else
				r_clk_counter <= r_clk_counter + 1;
			end if;	
        end if;
    end process;   
       


	--captures the value of the counter when the button is pressed
  create_rand : process(i_Clk)
	begin
		if rising_edge(i_Clk) then
      --check for button press
			if i_Switch = '1' then			
				--capture the value of counter as the random number
				w_rand_temp <= r_counter;
			end if;
		end if;
		
		--assign random number to output "o_rand"
		o_rand <= w_rand_temp;

end process;
	
end Behavioral;