library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Debounce_Switch is
	port(
	i_Clk : in std_logic;
	i_switch : in std_logic;
	o_switch : out std_logic);
end entity Debounce_Switch;	

architecture rtl of Debounce_Switch is
	--10 ms at 25 MHz
	constant c_Debounce_Limit : integer := 250000;
	
	signal r_State : std_logic := '0'; --filters state of i Switch
	signal r_count : integer range 0 to c_Debounce_Limit := 0;
	
begin
	proc_Debounce : process(i_Clk) is
	begin
		if rising_edge(i_Clk) then
			if (i_Switch /= r_State and r_Count < c_Debounce_Limit) then
				r_Count <= r_Count + 1;
			elsif r_Count = c_Debounce_Limit then
				r_State <= i_switch;
				r_Count <= 0;
			else
				r_Count <= 0;
			end if;
        end if;
	end process;	
	o_switch <= r_State;
end architecture rtl;