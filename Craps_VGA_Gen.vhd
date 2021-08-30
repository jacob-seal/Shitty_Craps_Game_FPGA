----------------------------------------------------------------------------------
--Developed By : Jacob Seal
--sealenator@gmail.com
--07-28-2021
--filename: Craps_VGA_Gen.vhd
--entity Craps_VGA_Gen
--
--********************************************************************************
--general notes:
--This module generates all output which will display on the VGA output. 
--There are 4 instances of Pixel_On_Text.vhd to output 4 different sets of output
--      data to the screen as well as logic to draw the dice.
--
--Finally, there is a piece of combinational logic that ties these 5 outputs 
--      together. This is the main source of the required LUT of the game. I am 
--      currently not sure of another way to do this that would save resources.
--
--INPUTS
--i_dice1 - input value of the dice 1 roll
--i_dice2 - input value of the dice 1 roll
--i_state - current state of the game...comes from the FSM in the TOP module
--i_bet   - value of the current bet...not utilized at this time
--i_point - point numbers flag. '1' if in point numbers round '0' else
--i_HSync - Video synchronization signal
--i_VSync - Video synchronization signal
--
--OUTPUTS
--o_HSync - Video synchronization signal
--o_VSync - Video synchronization signal
--o_Red_Video - output signal for 3-bit VGA video - red
--o_Grn_Video - output signal for 3-bit VGA video - green
--o_Blu_Video - output signal for 3-bit VGA video - blue
--********************************************************************************
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.VGA_pkg.all;
use work.bitmaps_pkg.all;
use work.craps_types_pkg.all;

entity Craps_VGA_Gen is
    generic (
        g_VIDEO_WIDTH   : integer := 3;
        g_TOTAL_COLS    : integer := 800;
        g_TOTAL_ROWS    : integer := 525;
        g_ACTIVE_COLS   : integer := 640;
        g_ACTIVE_ROWS   : integer := 480
        );
    port (
        i_Clk           : in std_logic;
        
        i_dice1         : in integer;
        i_dice2         : in integer;

        i_state         : in integer;
        i_bet           : in integer;
        i_wallet        : in integer;
        i_point         : in std_logic;
        
        i_HSync         : in std_logic;
        i_VSync         : in std_logic;
        --
        o_HSync         : out std_logic := '0';
        o_VSync         : out std_logic := '0';
        o_Red_Video     : out std_logic_vector(g_VIDEO_WIDTH-1 downto 0);
        o_Grn_Video     : out std_logic_vector(g_VIDEO_WIDTH-1 downto 0);
        o_Blu_Video     : out std_logic_vector(g_VIDEO_WIDTH-1 downto 0)
        );
end entity Craps_VGA_Gen;

architecture RTL of Craps_VGA_Gen is

    component Sync_To_Count is
        generic (
        g_TOTAL_COLS    : integer;
        g_TOTAL_ROWS    : integer
        );
        port (
        i_Clk           : in std_logic;
        i_HSync         : in std_logic;
        i_VSync         : in std_logic;

        o_HSync         : out std_logic;
        o_VSync         : out std_logic;
        o_Col_Count     : out std_logic_vector(9 downto 0);
        o_Row_Count     : out std_logic_vector(9 downto 0)
        );
    end component Sync_To_Count;

    --video synch signals
    signal w_VSync : std_logic;
    signal w_HSync : std_logic;
    --signals to capture dice input value
    signal w_dice1 : integer range 1 to 6;
    signal w_dice2 : integer range 1 to 6;
    --signal to capture point value
    signal w_point : std_logic;
    --signal to capture the current bet
    signal w_bet : integer range 0 to 10 := 0;
    signal w_wallet : integer range 0 to 99;
    --signal to capture the current game state
    signal w_game_state : integer range 0 to 5 := 0;
    --outputs of all modules that draw to VGA
    signal w_draw_dice : std_logic;
    signal w_draw_text1 : std_logic;
    signal w_draw_text2 : std_logic;
    signal w_draw_score : std_logic;
    signal w_draw_text3 : std_logic;
    signal w_draw_text4 : std_logic;
    signal w_draw_wallet : std_logic;
    signal w_Draw_Splash : std_logic;                     --uncomment to use splash screen
    --connects output of all modules that draw to VGA
    signal w_Draw_Any       : std_logic;
    --unsigned counters (always positive) for row and column
    --Col_Count is x position
    --Row_Count is y position
    signal w_Col_Count : std_logic_vector(9 downto 0);
    signal w_Row_Count : std_logic_vector(9 downto 0);
    --signals for all string messages displayed on the VGA
    signal w_text1 : string (1 to c_gamestate_stringmap(0)'high);
    signal w_text2 : string (1 to c_gamestate_stringmap(0)'high);
    signal w_score : string(1 to 2); --score or bet(always 2 digit integer)
    signal w_text3 : string (1 to c_gamestate_stringmap(0)'high);
    signal w_text4 : string (1 to c_gamestate_stringmap(0)'high);
    signal w_wallet_str : string(1 to 2); --wallet...up to 99


begin
    --connections for input values
    w_dice1 <= i_dice1;
    w_dice2 <= i_dice2;
    w_game_state <= i_state;
    w_bet <= i_bet;
    w_point <= i_point;
    w_wallet <= i_wallet;

    
    --this process sets the output messages to the VGA screen based upon the current
    --game state input value from the TOP module. 
    string_output_parser : process(i_Clk) is 
    variable r_string_3 : string(1 to 2);
    begin
        if rising_edge(i_Clk) then 
            case w_game_state is
                when 0 => --splash screen --******uncomment to use splash screen
                    w_text1 <= c_gamestate_stringmap(9);
                    w_text2 <= c_gamestate_stringmap(9);
                    w_score <= "  ";
                    w_text3 <= c_gamestate_stringmap(9);
                    
                     if                     ((to_integer(unsigned(w_Col_Count)) - ((g_ACTIVE_COLS - dual_dice_bitmap(0)'high)/2) > -1 and
                                            to_integer(unsigned(w_Row_Count)) - ((g_ACTIVE_ROWS - dual_dice_bitmap'high)/2) > -1 and
                                            to_integer(unsigned(w_Col_Count)) - ((g_ACTIVE_COLS - dual_dice_bitmap(0)'high)/2) < dual_dice_bitmap(0)'high + 1 and
                                            to_integer(unsigned(w_Row_Count)) - ((g_ACTIVE_ROWS - dual_dice_bitmap'high)/2) < dual_dice_bitmap'high + 1) and
                                            (dual_dice_bitmap(to_integer(unsigned(w_Row_Count)) - ((g_ACTIVE_ROWS - dual_dice_bitmap'high)/2))(to_integer(unsigned(w_Col_Count)) - ((g_ACTIVE_COLS - dual_dice_bitmap(0)'high)/2)) = '1')) then
                                            w_Draw_Any <= '1';
                                            else 
                                            w_Draw_Any <= '0'; 

                     end if;                       
                when 1 => --idle
                    w_text1 <= c_gamestate_stringmap(8);
                    w_text2 <= c_gamestate_stringmap(5);
                    w_score <= "  ";
                    w_text3 <= c_gamestate_stringmap(9);
                    w_text4 <= c_gamestate_stringmap(11);
                    w_wallet_str <= int_to_str_width_2(w_wallet);
                    w_Draw_Any <= w_draw_text1 or w_draw_text2 or w_draw_wallet or w_draw_text4;                                                       --uncomment to use splash screen
                    
                when 2 => --bets
                    w_text1 <= c_gamestate_stringmap(8);
                    w_text2 <= c_gamestate_stringmap(6);
                    w_score <= int_to_str_width_2(w_bet);
                    w_text3 <= c_gamestate_stringmap(9);
                    w_text4 <= c_gamestate_stringmap(11);
                    w_wallet_str <= int_to_str_width_2(w_wallet);
                    w_Draw_Any <= w_draw_text1 or w_draw_text2 or w_draw_score or w_draw_wallet or w_draw_text4;                                       --uncomment to use splash screen
                    
                when 3 => --roll
                    w_text2 <= c_gamestate_stringmap(0);
                    if w_point = '0' then
                        w_text1 <= c_gamestate_stringmap(4);
                        w_score <= "  ";
                        w_text3 <= c_gamestate_stringmap(9);
                        r_string_3 := int_to_str_width_2(w_dice1 + w_dice2);
                        w_wallet_str <= int_to_str_width_2(w_wallet);
                        w_text4 <= c_gamestate_stringmap(11);
                        w_Draw_Any <= w_draw_text1 or w_draw_dice or w_draw_wallet or w_draw_text4 or w_draw_text2;
                    else
                        w_text1 <= c_gamestate_stringmap(10);
                        w_score <= r_string_3;
                        w_text3 <= c_gamestate_stringmap(3);
                        w_wallet_str <= int_to_str_width_2(w_wallet);
                        w_text4 <= c_gamestate_stringmap(11);
                        w_Draw_Any <= w_draw_dice or w_draw_text1 or w_draw_text2 or w_draw_score or w_draw_text3 or w_draw_wallet or w_draw_text4;    --uncomment to use splash screen
                    end if;
                            
                    
                when 4 => --tally
                        w_text1 <= c_gamestate_stringmap(9);
                        w_text2 <= c_gamestate_stringmap(7);
                        w_score <= int_to_str_width_2(w_dice1 + w_dice2);
                        w_text3 <= c_gamestate_stringmap(9);
                        w_wallet_str <= int_to_str_width_2(w_wallet);
                        w_text4 <= c_gamestate_stringmap(11);
                        w_Draw_Any <= w_draw_dice or w_draw_text2 or w_draw_score or w_draw_wallet or w_draw_text4;                                    --uncomment to use splash screen
                    
                when 5 => --win
                    w_text1 <= c_gamestate_stringmap(9);
                    w_text2 <= c_gamestate_stringmap(7);
                    w_score <= int_to_str_width_2(w_dice1 + w_dice2);
                    w_text3 <= c_gamestate_stringmap(2);
                    w_wallet_str <= int_to_str_width_2(w_wallet);
                    w_text4 <= c_gamestate_stringmap(11);
                    w_Draw_Any <= w_draw_dice or w_draw_text2 or w_draw_score or w_draw_text3 or w_draw_wallet or w_draw_text4;                        --uncomment to use splash screen
                    
                when 6 => --lose
                    w_text1 <= c_gamestate_stringmap(9);
                    w_text2 <= c_gamestate_stringmap(7);
                    w_score <= int_to_str_width_2(w_dice1 + w_dice2);
                    w_text3 <= c_gamestate_stringmap(1);
                    w_wallet_str <= int_to_str_width_2(w_wallet);
                    w_text4 <= c_gamestate_stringmap(11);
                    w_Draw_Any <= w_draw_dice or w_draw_text2 or w_draw_score or w_draw_text3 or w_draw_wallet or w_draw_text4;                        --uncomment to use splash screen

                when others =>
                    null;
            end case;
        end if;

    end process;
  
    --synchronizes the edges of video(like a carriage return on typewriter)
    Sync_To_Count_inst : Sync_To_Count
        generic map (
            g_TOTAL_COLS => g_TOTAL_COLS,
            g_TOTAL_ROWS => g_TOTAL_ROWS
        )
        port map (
            i_Clk       => i_Clk,
            i_HSync     => i_HSync,
            i_VSync     => i_VSync,
            o_HSync     => w_HSync,
            o_VSync     => w_VSync,
            o_Col_Count => w_Col_Count,
            o_Row_Count => w_Row_Count
        );

  
    --Register syncs to output data
    p_Reg_Syncs : process (i_Clk) is
    begin
        if rising_edge(i_Clk) then
        o_VSync <= w_VSync;
        o_HSync <= w_HSync;
        end if;
    end process p_Reg_Syncs; 

    --sets output pixel instruction message for the topmost text instruction
    textElement1: entity work.Pixel_On_Text
            generic map (
                textLength => c_gamestate_stringmap(0)'high
            )
            port map(
                clk => i_Clk,
                displayText => w_text1,
                x_pos => 50,
                y_pos => 50,
                horzCoord => to_integer(unsigned(w_Col_Count)),
                vertCoord => to_integer(unsigned(w_Row_Count)),
                pixel => w_draw_text1 -- result
            );

    --sets output pixel for you rolled/you bet message
    textElement2: entity work.Pixel_On_Text
            generic map (
                textLength => c_gamestate_stringmap(0)'high
            )
            port map(
                clk => i_Clk,
                displayText => w_text2,
                x_pos => 50,
                y_pos => 250,
                horzCoord => to_integer(unsigned(w_Col_Count)),
                vertCoord => to_integer(unsigned(w_Row_Count)),
                pixel => w_draw_text2 -- result
            );
    
    --sets output pixel for dice_score
    textElement3: entity work.Pixel_On_Text
            generic map (
                textLength => w_score'high
            )
            port map(
                clk => i_Clk,
                displayText => w_score,
                x_pos => 200,
                y_pos => 250,
                horzCoord => to_integer(unsigned(w_Col_Count)),
                vertCoord => to_integer(unsigned(w_Row_Count)),
                pixel => w_draw_score -- result
            );      
  
  --sets output pixel instruction message for the bottom text instruction
  textElement4: entity work.Pixel_On_Text
        generic map (
        	textLength => c_gamestate_stringmap(0)'high
        )
        port map(
        	clk => i_Clk,
        	displayText => w_text3,
        	--position => (50, 50), -- text position (top left)
            x_pos => 50,
            y_pos => 300,
        	horzCoord => to_integer(unsigned(w_Col_Count)),
        	vertCoord => to_integer(unsigned(w_Row_Count)),
        	pixel => w_draw_text3 -- result
        );      
      
  --sets output pixel for bank tally
    textElement5: entity work.Pixel_On_Text
            generic map (
                textLength => w_wallet_str'high
            )
            port map(
                clk => i_Clk,
                displayText => w_wallet_str,
                x_pos => 525,
                y_pos => 250,
                horzCoord => to_integer(unsigned(w_Col_Count)),
                vertCoord => to_integer(unsigned(w_Row_Count)),
                pixel => w_draw_wallet -- result
            );    

    --sets output pixel "current bank" message
  textElement6: entity work.Pixel_On_Text
        generic map (
        	textLength => c_gamestate_stringmap(0)'high
        )
        port map(
        	clk => i_Clk,
        	displayText => w_text4,
        	--position => (50, 50), -- text position (top left)
            x_pos => 400,
            y_pos => 250,
        	horzCoord => to_integer(unsigned(w_Col_Count)),
        	vertCoord => to_integer(unsigned(w_Row_Count)),
        	pixel => w_draw_text4 -- result
        );                    

  
  
  

  -----------------------------------------------------------------------------
  -- writes the dice_bitmap to the screen
  -- centered
  -----------------------------------------------------------------------------


w_draw_dice <= '1' when                 (--draw dice 1
                                            ((to_integer(unsigned(w_Col_Count)) - ((g_ACTIVE_COLS/2) - (2*c_medium_dicemap(w_dice1)(0)'high)) > -1 and
                                            to_integer(unsigned(w_Row_Count)) - 150 > -1 and
                                            to_integer(unsigned(w_Col_Count)) - ((g_ACTIVE_COLS/2) - (2*c_medium_dicemap(w_dice1)(0)'high)) < c_medium_dicemap(w_dice1)(0)'high + 1 and
                                            to_integer(unsigned(w_Row_Count)) - 150 < c_medium_dicemap(w_dice1)'high + 1) and
                                            (c_medium_dicemap(w_dice1)(to_integer(unsigned(w_Row_Count)) - 150)(to_integer(unsigned(w_Col_Count)) - ((g_ACTIVE_COLS/2) - (2*c_medium_dicemap(w_dice1)(0)'high))) = '1'))
                                             or --draw dice 2
                                             ((to_integer(unsigned(w_Col_Count)) - ((g_ACTIVE_COLS/2) + (c_medium_dicemap(w_dice1)(0)'high)) > -1 and
                                             to_integer(unsigned(w_Row_Count)) - 150 > -1 and
                                             to_integer(unsigned(w_Col_Count)) - ((g_ACTIVE_COLS/2) + (c_medium_dicemap(w_dice1)(0)'high)) < c_medium_dicemap(w_dice2)(0)'high + 1 and
                                             to_integer(unsigned(w_Row_Count)) - 150 < c_medium_dicemap(w_dice2)'high + 1) and
                                             (c_medium_dicemap(w_dice2)(to_integer(unsigned(w_Row_Count)) - 150)(to_integer(unsigned(w_Col_Count)) - ((g_ACTIVE_COLS/2) + (c_medium_dicemap(w_dice1)(0)'high))) = '1'))
                                        )
                                        else
                                           '0';
    --draws the splash screen. FPGA cant handle it. commented out so I can make a working game.
    --with new FSM this code is likely not needed
--  w_Draw_Splash <= '1' when                 (
--                                             ((to_integer(unsigned(w_Col_Count)) - 262 > -1 and
--                                             to_integer(unsigned(w_Row_Count)) - 200 > -1 and
--                                             to_integer(unsigned(w_Col_Count)) - 262 < dual_dice_bitmap(0)'high + 1 and
--                                             to_integer(unsigned(w_Row_Count)) - 200 < dual_dice_bitmap'high + 1) and
--                                             (dual_dice_bitmap(to_integer(unsigned(w_Row_Count)) - 200)(to_integer(unsigned(w_Col_Count)) - 262) = '1'))
                                             
--                                         )
--                                         else
--                                            '0';




    --output draw signal...prints the pixel if any of the modules are active high at this x,y position
    --comment out if using the splash screen
    --w_Draw_Any <= w_draw_dice or w_draw_text1 or w_draw_text2 or w_draw_score or w_draw_text3 or w_draw_wallet or w_draw_text4;      


  
  -- Assign Color outputs, only two colors, White or Black
  o_Red_Video <= (others => '1') when w_Draw_Any = '1' else (others => '0');
  o_Blu_Video <= (others => '1') when w_Draw_Any = '1' else (others => '0');
  o_Grn_Video <= (others => '1') when w_Draw_Any = '1' else (others => '0');
        

  
end architecture RTL;
