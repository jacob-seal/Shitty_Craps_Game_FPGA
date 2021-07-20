--Electronic dice with binary output and number showing random dice number on 7 seg display
--by Ninad Waingankar


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity edice is
generic ( width : integer := 3 );
port (
		--push : in std_logic;	--push button to draw random no on dice
		i_Switch_4 		: 	in std_logic;	--push button to draw random no on dice
		i_Clk			:	in std_logic;		--25Mhz clock 
		--random_num : out std_logic_vector (width-1 downto 0); 
		--LED outputs for binary 
		o_LED_1			:	out std_logic;
		o_LED_2			:	out std_logic;
		o_LED_3			:	out std_logic;
		o_LED_4			:	out std_logic;
		--display:out std_logic_vector(6 downto 0)--output random no on 7 seg display
		--output 7 seg display
		o_Segment2_A	: 	out std_logic;	
		o_Segment2_B	: 	out std_logic;
		o_Segment2_C	: 	out std_logic;
		o_Segment2_D	: 	out std_logic;
		o_Segment2_E	: 	out std_logic;
		o_Segment2_F	: 	out std_logic;
		o_Segment2_G	: 	out std_logic
		);
end edice;

architecture Behavioral of edice is
	signal button_pressed : std_logic := '0';	
	constant c_1sec : integer := 25000000; --1 second of clock cycles
	
	--signal divider:std_logic_vector(23 downto 0);	--clock divider signal
	signal divider : integer range 0 to c_1sec := 0; --range of 1 second
	signal rand	:	std_logic_vector(2 downto 0) := (others => '0');			--temporary signal for assignment
	signal r_1_sec_flag : std_logic := '0';
	
	signal r_LED_4 : std_logic := '0'; --testing signal to see if counter is reaching its mark 

	--internal wires for connecting 7Seg outputs to bin converter outputs
	signal w_Segment2_A : std_logic:= '0';
	signal w_Segment2_B : std_logic:= '0';
	signal w_Segment2_C : std_logic:= '0';
	signal w_Segment2_D : std_logic:= '0';
	signal w_Segment2_E : std_logic:= '0';
	signal w_Segment2_F : std_logic:= '0';
	signal w_Segment2_G : std_logic:= '0';


	--SWITCH SIGNALS
	signal r_Switch_4 	:std_logic := '0';
	signal w_Switch_4 	:std_logic;
	
	signal rand_temp : std_logic_vector(width-1 downto 0):=(width-1 => '1', others => '0');
	--signal rand_temp : std_logic_vector(width-1 downto 0):= "100";
begin
	--convert binary to output for 7Seg2   (right LCD)	
	bin_converter_seg2 : entity work.bin_to_7seg_3bit
		port map(
		i_Clk 	 => i_Clk,
		--i_Bin_Num => std_logic_vector(to_unsigned(r_int2, 4)),
		i_Bin_Num => rand,
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
	
	
	--process to set enable when pressing switch 4
	register_button : process(i_Clk) is
	begin
		if rising_edge(i_Clk) then
			r_Switch_4 <= w_Switch_4; --create a registered version of the input(previous value)
				if w_Switch_4 = '1'and r_Switch_4 = '0' then 		--rising edge(button PRESS) when not enabled
					button_pressed <= '1';		--button has been pressed
					
				else 
					button_pressed <= '0';
				end if;
		end if;		
	end process;
	
	
	
	clk_divider : process(i_Clk) 
	begin
		if(rising_edge(i_Clk)) then
				if divider = c_1sec - 1 then
					divider <= 0;
					r_1_sec_flag <= '1';
					
				else	
					divider<=divider + 1;
					r_1_sec_flag <= '0';
				end if;
			end if;	
			
	end process;

	create_rand : process(i_Clk)
		
		variable temp : std_logic := '0';
	begin
		if rising_edge(i_Clk) then
			if r_1_sec_flag = '1' then
				r_LED_4 <= not r_LED_4;
		--for random no generation
				temp := rand_temp(width-1) xor rand_temp(width-2);
				rand_temp(width-1 downto 1) <= rand_temp(width-2 downto 0);
				rand_temp(0) <= temp;
			end if;
		end if;
		rand <= rand_temp;
	
	end process;
	
	
	--LED outputs
	o_LED_1	<= std_logic(rand(2));
	o_LED_2	<= std_logic(rand(1));
	o_LED_3	<= std_logic(rand(0));
	
	o_LED_4 <= r_LED_4;
end Behavioral;


