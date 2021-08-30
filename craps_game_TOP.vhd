----------------------------------------------------------------------------------
--Developed By : Jacob Seal
--sealenator@gmail.com
--07-28-2021
--filename: craps_game_top.vhd
--entity Shitty_Craps
--
--********************************************************************************
--general notes:
--This is a craps game simulation for the  Digilent NEXYS 4 using a FSM to   	
--      control the flow of the game. The title is "Shitty Craps"
--VGA monitor is used as an output device. 
--Bets(integers 1 thru 9 are allowed) are entered VIA the PMOD keypad
--Pressing the middle button triggers a new random value between 1 and 6 for each dice. 
--Both values are output to VGA monitor with dice graphics.
--The values of the dice are added together to determine the next move. 
--If the roll is 7 or 11 the player wins. 
--If the roll is 2, 3, or 12 the player loses.
--If the roll is 4,5,6,8,9,10 these are "point numbers." The point numbers mode 
--	    is entered at this time. 
--The player continues to roll until they hit their point number in which case 
--	    they win, or until they hit 7, in which case they lose. It is just 
--	    like a real Craps table in a casino, but without the drunk douchebags 
--      who are stupid enough to bet their actual money on this. 
--
--INPUTS
--i_BTN - input from Switch 4 on the nandland GoBoard
--i_Clk - 25 MHz clock from the oscillator on the nandland GoBoard
--
--i_UART_RX - input from UART interface with the PC. accepts bet value input
--
-- o_VGA_HSync -- outputs for the VGA monitor connection
-- o_VGA_VSync 
-- o_VGA_Red_0 
-- o_VGA_Red_1 
-- o_VGA_Red_2 
-- o_VGA_Grn_0 
-- o_VGA_Grn_1 
-- o_VGA_Grn_2 
-- o_VGA_Blu_0 
-- o_VGA_Blu_1 
-- o_VGA_Blu_2 
--********************************************************************************
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.craps_types_pkg.all;
use work.my_useful_utils_pkg.all;


entity Shitty_Craps is
port (
		
		--push button to trigger dice roll
		i_BTN 		: 	in std_logic;									
		
        --100Mhz clock
		i_Clk			:	in std_logic;	
        
        --IO for the PMOD interface
        --1-4 for columns
        --7-10 for rows
        io_PMOD_1 : inout std_logic;
        io_PMOD_2 : inout std_logic;
        io_PMOD_3 : inout std_logic;
        io_PMOD_4 : inout std_logic;

        io_PMOD_7 : inout std_logic;
        io_PMOD_8 : inout std_logic;
        io_PMOD_9 : inout std_logic;
        io_PMOD_10 : inout std_logic;								 
		
		--VGA outputs
        o_VGA_HSync : out std_logic;
        o_VGA_VSync : out std_logic;
        o_VGA_Red_0 : out std_logic;
        o_VGA_Red_1 : out std_logic;
        o_VGA_Red_2 : out std_logic;
        o_VGA_Red_3 : out std_logic;
        o_VGA_Grn_0 : out std_logic;
        o_VGA_Grn_1 : out std_logic;
        o_VGA_Grn_2 : out std_logic;
        o_VGA_Grn_3 : out std_logic;
        o_VGA_Blu_0 : out std_logic;
        o_VGA_Blu_1 : out std_logic;
        o_VGA_Blu_2 : out std_logic;
        o_VGA_Blu_3 : out std_logic
        );
end Shitty_Craps;

architecture Behavioral of Shitty_Craps is
	
	-- VGA Constants to set Frame Size
    constant c_VIDEO_WIDTH : integer := 4;
    constant c_TOTAL_COLS  : integer := 800;
    constant c_TOTAL_ROWS  : integer := 525;
    constant c_ACTIVE_COLS : integer := 640;
    constant c_ACTIVE_ROWS : integer := 480;
    
    -- Common VGA Signals
    signal w_HSync_VGA       : std_logic;
    signal w_VSync_VGA       : std_logic;
    signal w_HSync_Porch     : std_logic;
    signal w_VSync_Porch     : std_logic;
    signal w_Red_Video_Porch : std_logic_vector(c_VIDEO_WIDTH-1 downto 0);
    signal w_Grn_Video_Porch : std_logic_vector(c_VIDEO_WIDTH-1 downto 0);
    signal w_Blu_Video_Porch : std_logic_vector(c_VIDEO_WIDTH-1 downto 0);
 
  -- VGA Test Pattern Signals
    signal w_HSync_TP     : std_logic;
    signal w_VSync_TP     : std_logic;
    signal w_Red_Video_TP : std_logic_vector(c_VIDEO_WIDTH-1 downto 0);
    signal w_Grn_Video_TP : std_logic_vector(c_VIDEO_WIDTH-1 downto 0);
    signal w_Blu_Video_TP : std_logic_vector(c_VIDEO_WIDTH-1 downto 0);

    --data valid flag from keypad
    signal w_RX_DV : std_logic;
	

    --Stores the integer value of the current bet to send to the VGA_gen module
    signal w_bet : integer range 0 to 9;
    signal r_bet : integer range 0 to 9;
    
    --rolling total cash
    signal w_wallet : integer range 0 to 99 := 25;

	--SWITCH 4 SIGNALS
	signal r_BTN 	:std_logic := '0';
	signal w_BTN 	:std_logic;

    --flag to indicate middle button has been pressed
	signal r_button_pressed : std_logic := '0';	
	
	--holds the returned random numbers for each dice 
	signal w_int_dice_1 : integer range 0 to 6 := 0; --dice 1
	signal w_int_dice_2 : integer range 0 to 6 := 0; --dice 2

	--clk divider factors for each dice
	--dice 2 runs 3 times slower than dice 1
	constant c_clk_divider_dice_1 : integer := 1;	--1 = no clock division
	constant c_clk_divider_dice_2 : integer := 3;

    
    --FSM states that control the game
	type t_FSM_Main is (s_Splash, s_Idle, s_Bets, s_Roll, s_Tally, s_Win, s_Lose,
                     s_Point_Numbers);
	signal r_FSM_Main : t_FSM_Main := s_Splash;

    --Signals used in the FSM
    --stores the value of the point_flag to send to the VGA_gen module
    signal w_point_flag : std_logic := '0';
    --sends the FSM state to the VGA_Gen module
    signal r_gamestate : integer range 0 to 6 := 0;
    
    
    --divided clock for external modules and VGA sync
    signal r_Clk_25MHz : std_logic := '0';

    --output from keypad decoder
    signal w_decoded : std_logic_vector(3 downto 0);
	
	
	
begin
	

    --accept input from the PMOD 16 key pad
    keypad_wrapper_inst : entity work.Keypad_Wrapper
        port map(
                    --clock input 100 MHz
                    i_Clk   => i_Clk,
                    
                    --IO for the rows and columns(PMOD at top level)
                    i_ROW_4 => io_PMOD_7,
                    i_ROW_3 => io_PMOD_8,
                    i_ROW_2 => io_PMOD_9,
                    i_ROW_1 => io_PMOD_10,
                    
                    o_COL_4 => io_PMOD_1,
                    o_COL_3 => io_PMOD_2,
                    o_COL_2 => io_PMOD_3,
                    o_COL_1 => io_PMOD_4,
                    --decoded output
                    o_Decoded => w_decoded	
                );   
	
    --convert keypad output to Integer
    w_bet <= to_integer(unsigned(w_decoded));

    --set the DV flag to 1 when new info entered on the keypad
    data_flag_set : process(r_Clk_25MHz) is
    begin
        if rising_edge(r_Clk_25MHz) then
            r_bet <= w_bet;
                if w_bet /= r_bet then
                    w_RX_DV <= '1';
                else 
                    w_RX_DV <= '0';    
                end if;
        end if;
    --r_bet <= 0;
    end process;

    --------------------------------------------------------------------------------------
    --End UART
    --------------------------------------------------------------------------------------

    --clock divider for VGA
    --clock divider
    clock_divider_25MHz: entity work.clock_div_pow2
        port map   (
                    i_clk  => i_Clk,
                    i_rst  => '1',
                    o_clk_div2 => open,
                    o_clk_div4  => r_Clk_25MHz,
                    o_clk_div8  => open,
                    o_clk_div16 => open
                    );
	
    --************************************************************************************
    --Switches
    --************************************************************************************

    --debounce switch 4	
	Debounce_Inst4 : entity work.Debounce_Switch
	generic map (
            DEBOUNCE_LIMIT => 250000                            --10ms at 25MHz
    )
    port map(
		i_Clk 	 => r_Clk_25MHz,
		i_switch => i_BTN,
		o_switch => w_BTN);

	--set button pressed flag on rising edge of switch 4
	register_button : process(r_Clk_25MHz) is
	begin
		if rising_edge(r_Clk_25MHz) then
			r_BTN <= w_BTN; 				            --create a registered version of the input(previous value)
				if w_BTN = '1'and r_BTN = '0' then 	--if rising edge(button PRESS)
					r_button_pressed <= '1';					--button has been pressed
				else 
					r_button_pressed <= '0';
				end if;
		end if;		
	end process;

    --------------------------------------------------------------------------------------
    --End Switches
    --------------------------------------------------------------------------------------

    --************************************************************************************
    --Dice
    --************************************************************************************

    --instantiate Dice 1
	Dice_Inst_1 : entity work.dice
	generic map (
		clk_divider => c_clk_divider_dice_1
		)
	port map(
		i_Clk 	 => r_Clk_25MHz,
		i_switch => r_button_pressed,
		o_rand => w_int_dice_1);

			

	--instantiate Dice 2
	Dice_Inst_2 : entity work.dice
	generic map (
		clk_divider => c_clk_divider_dice_2
		)
	port map(
		i_Clk 	 => r_Clk_25MHz,
		i_switch => r_button_pressed,
		o_rand => w_int_dice_2);

	--------------------------------------------------------------------------------------
    --End Dice
    --------------------------------------------------------------------------------------		

    
    --************************************************************************************
    --VGA PARTS 
    --************************************************************************************
    
    --Generates signals at Horizontal and Vertical Boundaries used to synchronize VGA
    VGA_Sync_Pulses_inst : entity work.VGA_Sync_Pulses
    generic map (
        g_TOTAL_COLS  => c_TOTAL_COLS,
        g_TOTAL_ROWS  => c_TOTAL_ROWS,
        g_ACTIVE_COLS => c_ACTIVE_COLS,
        g_ACTIVE_ROWS => c_ACTIVE_ROWS
        )
    port map (
        i_Clk       => r_Clk_25MHz,
        o_HSync     => w_HSync_VGA,
        o_VSync     => w_VSync_VGA,
        o_Col_Count => open,
        o_Row_Count => open
        );
    
  --handles all VGA output. Depending on game state
  Craps_VGA_Gen_inst : entity work.Craps_VGA_Gen
    generic map (
        g_Video_Width => c_VIDEO_WIDTH,
        g_TOTAL_COLS  => c_TOTAL_COLS,
        g_TOTAL_ROWS  => c_TOTAL_ROWS,
        g_ACTIVE_COLS => c_ACTIVE_COLS,
        g_ACTIVE_ROWS => c_ACTIVE_ROWS
      )
    port map (
        --inputs
        i_Clk       => r_Clk_25MHz,
        i_dice1     => w_int_dice_1,
        i_dice2     => w_int_dice_2,
        i_state => r_gamestate,
        i_bet => w_bet,
        i_wallet => w_wallet,
        i_point => w_point_flag,
        i_HSync     => w_HSync_VGA,
        i_VSync     => w_VSync_VGA,
        --outputs
        o_HSync     => w_HSync_TP,
        o_VSync     => w_VSync_TP,
        o_Red_Video => w_Red_Video_TP,
        o_Blu_Video => w_Blu_Video_TP,
        o_Grn_Video => w_Grn_Video_TP
      );
   
  --modify video signal to include Front and Back porch of VGA space
  VGA_Sync_Porch_Inst : entity work.VGA_Sync_Porch
    generic map (
        g_Video_Width => c_VIDEO_WIDTH,
        g_TOTAL_COLS  => c_TOTAL_COLS,
        g_TOTAL_ROWS  => c_TOTAL_ROWS,
        g_ACTIVE_COLS => c_ACTIVE_COLS,
        g_ACTIVE_ROWS => c_ACTIVE_ROWS 
      )
    port map (
        --inputs
        i_Clk       => r_Clk_25MHz,
        i_HSync     => w_HSync_VGA,
        i_VSync     => w_VSync_VGA,
        i_Red_Video => w_Red_Video_TP,
        i_Grn_Video => w_Blu_Video_TP,
        i_Blu_Video => w_Grn_Video_TP,
        --outputs
        o_HSync     => w_HSync_Porch,
        o_VSync     => w_VSync_Porch,
        o_Red_Video => w_Red_Video_Porch,
        o_Grn_Video => w_Blu_Video_Porch,
        o_Blu_Video => w_Grn_Video_Porch
      );

    --assign all VGA output signals       
    o_VGA_HSync <= w_HSync_Porch;
    o_VGA_VSync <= w_VSync_Porch;
       
    o_VGA_Red_0 <= w_Red_Video_Porch(0);
    o_VGA_Red_1 <= w_Red_Video_Porch(1);
    o_VGA_Red_2 <= w_Red_Video_Porch(2);
    o_VGA_Red_3 <= w_Red_Video_Porch(3);
   
    o_VGA_Grn_0 <= w_Grn_Video_Porch(0);
    o_VGA_Grn_1 <= w_Grn_Video_Porch(1);
    o_VGA_Grn_2 <= w_Grn_Video_Porch(2);
    o_VGA_Grn_3 <= w_Grn_Video_Porch(3);
 
    o_VGA_Blu_0 <= w_Blu_Video_Porch(0);
    o_VGA_Blu_1 <= w_Blu_Video_Porch(1);
    o_VGA_Blu_2 <= w_Blu_Video_Porch(2);
    o_VGA_Blu_3 <= w_Blu_Video_Porch(3);

    --------------------------------------------------------------------------------------
    --End VGA PARTS 
    --------------------------------------------------------------------------------------


    --************************************************************************************
    --Start FSM. FSM process runs the entire game
    --************************************************************************************	
	
	FSM : process (r_Clk_25MHz)
	--create variable to hold the addition of the 2 dice
	variable r_result	: integer range 0 to 12 := 0;
	--to register the current result and compare it against the next
	variable r_result_2 	: integer range 0 to 12 := 0; 
	--flag indicating we are in point numbers round
	variable point_flag : std_logic := '0';
	--counter to wait 2 seconds before changing states
	variable r_2second_counter : integer range 0 to 50000000 := 0;
    variable r_splash_counter : integer range 0 to 150000000 := 0; --6 seconds max
    variable r_wallet : integer range 0 to 99;
	begin
        if rising_edge(r_Clk_25MHz) then
            
            case r_FSM_Main is

                when s_Splash =>  --uncomment this state to use the splash screen
                r_gamestate <= 0;

                -- wait for the counter flag(6 seconds) then go to idle state
                    if r_splash_counter = 150000000 - 1 then
                        r_splash_counter := 0;
                        r_FSM_Main <= s_Idle;
                    else
                        r_splash_counter := r_splash_counter + 1;
                        r_FSM_Main <= s_Splash;
                    end if;	

                --When idle the System is waiting for a bet to be entered by UART
                when s_Idle =>
                    
                    if point_flag = '0' then        --normal round. Accept bet and move to S_Bets
                        r_gamestate <= 1;  
                            --when bet placed go to next state
                        if w_RX_DV = '1' then
                            r_FSM_Main <= s_Bets;
                        else
                            r_FSM_Main <= s_Idle;
                        end if;
                    else                            --point round go directly to roll again
                        
                        r_FSM_Main <= s_Roll;
                    end if;	  	 

                --Bet has been entered on the UART. Wait 2 seconds then go to S_Roll
                when s_Bets =>
                    r_gamestate <= 2;
                    

                    -- wait for the counter flag(2 seconds) then go to roll state
                    if r_2second_counter = 50000000 - 1 then
                        r_2second_counter := 0;
                        r_FSM_Main <= s_Roll;
                        r_wallet := r_wallet - w_bet;
                    else
                        r_2second_counter := r_2second_counter + 1;
                        r_FSM_Main <= s_Bets;
                    end if;	    
                
                --Time to roll the dice by pressing Switch 4
                when s_Roll =>
                    r_gamestate <= 3;    

                    if r_button_pressed = '1' then  --when button pressed go to next state
                        r_FSM_Main <= s_Tally;
                    else
                        r_FSM_Main <= s_Roll;
                    end if;
                
                -- button has been pressed we must calculate the result
                when s_Tally =>	
                    --add the 2 dice rolls
                    r_result := w_int_dice_1 + w_int_dice_2;  
                    r_gamestate <= 4;

                    -- wait for the counter(2 seconds) then determine next state
                    -- next state is always S_Win, S_Lose, or S_Point_Numbers
                    if r_2second_counter = 50000000 - 1 then
                        r_2second_counter := 0;
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
                    else
                        r_2second_counter := r_2second_counter + 1;
                        r_FSM_Main <= s_Tally;
                    end if;    
                        
                -- you win baby!! Making that paper! Time to hit the buffet.       
                when s_Win =>
                    r_gamestate <= 5;
                    
                    
                    -- wait for the counter(2 seconds) then go back to idle to play again
                    if r_2second_counter = 50000000 - 1 then
                        r_2second_counter := 0;
                        r_wallet := r_wallet + 2*w_bet;
                        r_FSM_Main <= s_Idle;
                    else
                        r_2second_counter := r_2second_counter + 1;
                        r_FSM_Main <= s_Win;
                    end if;	


                -- you lose. Life is hard. Suck it up and seek some counseling. 
                when s_Lose =>
                    r_gamestate <= 6;  

                    -- wait for the counter (2 seconds) then go back to idle to play again
                    if r_2second_counter = 50000000 - 1 then
                        r_2second_counter := 0;
                        r_wallet := r_wallet - w_bet;
                        r_FSM_Main <= s_Idle;
                        
                    else
                        r_2second_counter := r_2second_counter + 1;
                        r_FSM_Main <= s_Lose;
                    end if;	

                -- point numbers(4,5,6,8,9,10) have been rolled
                when s_Point_Numbers =>
                    
                    if point_flag = '0' then        --first time in Point Numbers round
                        r_result_2 := r_result;     --register the current result for testing against the next result 
                        point_flag := '1';          --poing mode active!
                        r_FSM_Main <= s_Idle;       --go back to idle and start the round in point mode
                    else                            --re-entering point numbers round to determine if I rolled the same number
                        if r_result = r_result_2 then
                            point_flag := '0';
                            r_result_2 := 0;
                            r_FSM_Main <= s_Win;
                        elsif r_result = 7 then
                            point_flag := '0';
                            r_result_2 := 0;
                            r_FSM_Main <= s_Lose;
                        else
                            r_FSM_Main <= s_Idle;
                        end if;
                    end if;		
                    w_point_flag <= point_flag;
                when others =>
                    r_FSM_Main <= s_Idle;

            end case;
        end if;
    w_wallet <= r_wallet;    
	
    end process FSM;
    --------------------------------------------------------------------------------------
    --End FSM
    --------------------------------------------------------------------------------------

end Behavioral;

