--------------------------------------------------------------------------------
--Developed By : Jacob Seal
--sealenator@gmail.com
--07-28-2021
--filename: craps_game_TOP.vhd
--entity craps_game_TOP
--
--******************************************************************************
--general notes:
--This is a craps game simulation for the nandland GoBoard using a FSM to   	--	control the flow of the game.
--Pressing switch 4 triggers a new random value between 1 and 6 for each dice. 
--Both values are output to the 7 segment display
--The values of the dice are added together to determine the next move. 
--If the roll is 7 or 11 the player wins, indicated by lighting up LED 1. 
--If the roll is 2, 3, or 12 the player loses, indicated by lighting LED 4.
--If the roll is 4,5,6,8,9,10 these are "point numbers." The point numbers mode --	is indicated by the lighting up of LED 2 and LED 3.
--The player continues to roll until they hit their point number in which case --	they win, or until they hit 7 or 11, in which case they lose. It is just --	  like a real Craps table in a casino, but without the betting phase or the
-- 	 drunk douchebags who are stupid enough to bet their actual money on this. 
--
--the binary to 7segment converter was developed in a nandland tutorial 
--the switch debouncer was developed in a nandland tutorial 
--
--INPUTS
--i_Switch_4 - input from Switch 4 on the nandland GoBoard as defined in the 
--			file Go_Board_Constraints.pcf
--i_Clk - 25 MHz clock from the oscillator on the nandland GoBoard
--
--OUTPUTS
--o_LED_1 - these outputs are connected to 4 LED on the nandland
--o_LED_2 - GoBoard as defined in the file Go_Board_Constraints.pcf
--o_LED_3
--o_LED_4
--
--o_segment(x)_(y) - each 7 segment display has 7 outputs as defined in the file
--			Go_Board_Constraints.pcf
--			more information about 7 segment displays can be found on the wiki:
--			https://en.wikipedia.org/wiki/Seven-segment_display
--******************************************************************************
--------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity craps_game_TOP is
port (
		
		--inputs
		--push button to trigger r_random number
		i_Switch_4 		: 	in std_logic;									
		--25Mhz clock
		i_Clk			:	in std_logic;									 
		
		--outputs
		--LED outputs for binary 
		o_LED_1			:	out std_logic;
		o_LED_2			:	out std_logic;
		o_LED_3			:	out std_logic;
		o_LED_4			:	out std_logic;
		
		--output 7 seg display number 1(leftmost digit)
		o_Segment1_A	: 	out std_logic;	
		o_Segment1_B	: 	out std_logic;
		o_Segment1_C	: 	out std_logic;
		o_Segment1_D	: 	out std_logic;
		o_Segment1_E	: 	out std_logic;
		o_Segment1_F	: 	out std_logic;
		o_Segment1_G	: 	out std_logic;
		
		--output 7 seg display number 2(rightmost digit)
		o_Segment2_A	: 	out std_logic;	
		o_Segment2_B	: 	out std_logic;
		o_Segment2_C	: 	out std_logic;
		o_Segment2_D	: 	out std_logic;
		o_Segment2_E	: 	out std_logic;
		o_Segment2_F	: 	out std_logic;
		o_Segment2_G	: 	out std_logic
		);
end craps_game_TOP;

architecture Behavioral of craps_game_TOP is
	
	--flag to indicate the button has been pressed
	signal r_button_pressed : std_logic := '0';	

	--internal wires for connecting 7Seg1 outputs to bin converter outputs
	signal w_Segment1_A : std_logic:= '0';
	signal w_Segment1_B : std_logic:= '0';
	signal w_Segment1_C : std_logic:= '0';
	signal w_Segment1_D : std_logic:= '0';
	signal w_Segment1_E : std_logic:= '0';
	signal w_Segment1_F : std_logic:= '0';
	signal w_Segment1_G : std_logic:= '0';
	
	--internal wires for connecting 7Seg2 outputs to bin converter outputs
	signal w_Segment2_A : std_logic:= '0';
	signal w_Segment2_B : std_logic:= '0';
	signal w_Segment2_C : std_logic:= '0';
	signal w_Segment2_D : std_logic:= '0';
	signal w_Segment2_E : std_logic:= '0';
	signal w_Segment2_F : std_logic:= '0';
	signal w_Segment2_G : std_logic:= '0';

	--internal signals for LED
	signal r_LED_1 : std_logic := '0';
	signal r_LED_2 : std_logic := '0';
	signal r_LED_3 : std_logic := '0';
	signal r_LED_4 : std_logic := '0';

	--SWITCH SIGNALS
	signal r_Switch_4 	:std_logic := '0';
	signal w_Switch_4 	:std_logic;
	
	--holds the returned random numbers for each dice 
	signal w_rand_temp_1 : integer range 1 to 6; --dice 1
	signal w_rand_temp_2 : integer range 1 to 6; --dice 2
	
	--signal for assignment of random number to 7 seg display
	signal r_rand_1	:	std_logic_vector(2 downto 0) := (others => '0');
	signal r_rand_2	:	std_logic_vector(2 downto 0) := (others => '0');

	--clk divider factors for each dice
	--dice 2 runs 3 times slower than dice 1
	constant c_clk_divider_dice_1 : integer := 1;	--1 = no clock division
	constant c_clk_divider_dice_2 : integer := 3;

	--FSM states that control the game
	type t_FSM_Main is (s_Idle, s_Tally, s_Win, s_Lose,
                     s_Point_Numbers);
	signal r_FSM_Main : t_FSM_Main := s_Idle;
	
	
	
begin
	
	--convert binary to output for 7Seg1   (left display)	
	bin_converter_seg1 : entity work.bin_to_7seg_3bit
		port map(
		i_Clk 	 => i_Clk,
		i_Bin_Num => r_rand_1,
		o_Seg_A => w_Segment1_A,
		o_Seg_B => w_Segment1_B,
		o_Seg_C => w_Segment1_C,
		o_Seg_D => w_Segment1_D,
		o_Seg_E => w_Segment1_E,
		o_Seg_F => w_Segment1_F,
		o_Seg_G => w_Segment1_G
		);
	
	--7Seg1 outputs
	o_Segment1_A <= not w_Segment1_A;
	o_Segment1_B <= not w_Segment1_B;
	o_Segment1_C <= not w_Segment1_C;
	o_Segment1_D <= not w_Segment1_D;
	o_Segment1_E <= not w_Segment1_E;
	o_Segment1_F <= not w_Segment1_F;
	o_Segment1_G <= not w_Segment1_G;
	
	
	--convert binary to output for 7Seg2   (right display)	
	bin_converter_seg2 : entity work.bin_to_7seg_3bit
		port map(
		i_Clk 	 => i_Clk,
		i_Bin_Num => r_rand_2,
		o_Seg_A => w_Segment2_A,
		o_Seg_B => w_Segment2_B,
		o_Seg_C => w_Segment2_C,
		o_Seg_D => w_Segment2_D,
		o_Seg_E => w_Segment2_E,
		o_Seg_F => w_Segment2_F,
		o_Seg_G => w_Segment2_G
		);
	
	--7Seg2 outputs
	o_Segment2_A <= not w_Segment2_A;
	o_Segment2_B <= not w_Segment2_B;
	o_Segment2_C <= not w_Segment2_C;
	o_Segment2_D <= not w_Segment2_D;
	o_Segment2_E <= not w_Segment2_E;
	o_Segment2_F <= not w_Segment2_F;
	o_Segment2_G <= not w_Segment2_G;
	
	--debounce switch 4	
	Debounce_Inst4 : entity work.Debounce_Switch
		port map(
		i_Clk 	 => i_Clk,
		i_switch => i_Switch_4,
		o_switch => w_Switch_4);

	
	
	--process to set button pressed flag on rising edge of switch 4
	register_button : process(i_Clk) is
	begin
		if rising_edge(i_Clk) then
			r_Switch_4 <= w_Switch_4; 											--create a registered version of the input(previous value)
				if w_Switch_4 = '1'and r_Switch_4 = '0' then 					--if rising edge(button PRESS)
					r_button_pressed <= '1';										--button has been pressed
				else 
					r_button_pressed <= '0';
				end if;
		end if;		
	end process;

	--instantiate Dice 1
	Dice_Inst_1 : entity work.dice
		generic map (
			clk_divider => c_clk_divider_dice_1
		)
		port map(
		i_Clk 	 => i_Clk,
		i_switch => r_button_pressed,
		o_rand => w_rand_temp_1);

		r_rand_1 <= std_logic_vector(to_unsigned(w_rand_temp_1,3));	

	--instantiate Dice 1
	Dice_Inst_2 : entity work.dice
		generic map (
			clk_divider => c_clk_divider_dice_2
		)
		port map(
		i_Clk 	 => i_Clk,
		i_switch => r_button_pressed,
		o_rand => w_rand_temp_2);

		r_rand_2 <= std_logic_vector(to_unsigned(w_rand_temp_2,3));	

		
	--FSM process runs the game
	FSM : process (i_Clk)
	--create variable to hold the addition of the 2 dice
	variable r_result	: integer range 0 to 12 := 0;
	--to register the current result and compare it against the next
	variable r_result_2 	: integer range 0 to 12 := 0; 
	--flag indicating we are in point numbers round
	variable point_flag : std_logic := '0';
	--counter to wait 2 seconds before changing states
	variable r_2second_counter : integer range 0 to 50000000 := 0;
	begin
	if rising_edge(i_Clk) then
        
      case r_FSM_Main is

        when s_Idle =>
          	--all LED are zero unless in point numbers round
			if point_flag = '0' then
				r_led_1 <= '0';
		  		r_led_2 <= '0';
		  		r_led_3 <= '0';
		  		r_led_4 <= '0';
			else
				r_led_1 <= '0';
		  		r_led_2 <= '1';
		  		r_led_3 <= '1';
		  		r_led_4 <= '0';
			end if;	  	  
		  	--dice rolls are reset to 0
		  	--r_rand_1 <= "000";
		  	--r_rand_2 <= "000";
          	--when button pressed go to next state
		  	if r_button_pressed = '1' then
            	r_FSM_Main <= s_Tally;
          	else
            	r_FSM_Main <= s_Idle;
          	end if;

        -- button has been pressed we must parse the result
        when s_Tally =>	
        	--add the 2 dice rolls
			r_result := w_rand_temp_1 + w_rand_temp_2;  

			if point_flag = '0' then
				case r_result is
					when 7 =>
						r_FSM_Main <= s_Win;
					when 11 =>
						r_FSM_Main <= s_Win;
					when 2 =>
						r_FSM_Main <= s_Lose;
					when 3 =>
						r_FSM_Main <= s_Lose;
					when 12 =>
						r_FSM_Main <= s_Lose;				
					when others =>
						r_FSM_Main <= s_Point_Numbers;
					end case;
			else
				r_FSM_Main <= s_Point_Numbers;
			end if;			
				
		-- you win baby!! Making that paper! Time to hit the buffet.       
        when s_Win =>
          	r_led_1 <= '1';
		  	r_led_2 <= '0';
		  	r_led_3 <= '0';
		  	r_led_4 <= '0';

        -- wait for the counter flag(2 seconds) then go back to idle to play --	-- again
		if r_2second_counter = 50000000 - 1 then
			r_2second_counter := 0;
			r_FSM_Main <= s_Idle;
		else
			r_2second_counter := r_2second_counter + 1;
			r_FSM_Main <= s_Win;
		end if;	


        -- you lose. Life is hard. Suck it up. 
        when s_Lose =>
          	r_led_1 <= '0';
		  	r_led_2 <= '0';
		  	r_led_3 <= '0';
		  	r_led_4 <= '1';

        -- wait for the counter flag(2 seconds) then go back to idle to play --	-- again
		if r_2second_counter = 50000000 - 1 then
			r_2second_counter := 0;
			r_FSM_Main <= s_Idle;
		else
			r_2second_counter := r_2second_counter + 1;
			r_FSM_Main <= s_Lose;
		end if;	

                  
        -- point numbers(4,5,6,8,9,10) have been rolled
        when s_Point_Numbers =>
          	r_led_1 <= '0';
		  	r_led_2 <= '1';
		  	r_led_3 <= '1';
		  	r_led_4 <= '0';

			if point_flag = '0' then
				r_result_2 := r_result;  
				point_flag := '1';
				r_FSM_Main <= s_Idle;
			else
				if r_result = r_result_2 then
					point_flag := '0';
					r_result_2 := 0;
					r_FSM_Main <= s_Win;
				elsif r_result = 7 then
					point_flag := '0';
					r_result_2 := 0;
					r_FSM_Main <= s_Lose;
				elsif r_result = 11 then	
					point_flag := '0';
					r_result_2 := 0;
					r_FSM_Main <= s_Lose;
				else
					r_FSM_Main <= s_Idle;
				end if;
			end if;		

        when others =>
          	r_FSM_Main <= s_Idle;

      end case;
    end if;
	
  end process FSM;
	
	
	--LED outputs are assigned to indicated that you won or that you lost
	o_LED_1	<= r_LED_1;
	o_LED_2	<= r_LED_2;
	o_LED_3	<= r_LED_3;
	o_LED_4	<= r_LED_4;

	
	
end Behavioral;

