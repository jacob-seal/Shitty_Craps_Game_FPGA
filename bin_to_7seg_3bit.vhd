----------------------------------------------------------------------
-- converts an incoming binary number to a hex value  
--which corresponds to the proper configuration for a 7 segment
--display output
--only 3 bit since we just need to count to 6. 
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--input 3 bit binary number, drives signal bit outputs to 7 seg display
entity bin_to_7seg_3bit is
	port(
		i_Clk : in std_logic;
		i_Bin_Num : in std_logic_vector(2 downto 0);
		o_Seg_A : out std_logic;
		o_Seg_B : out std_logic;
		o_Seg_C : out std_logic;
		o_Seg_D : out std_logic;
		o_Seg_E : out std_logic;
		o_Seg_F : out std_logic;
		o_Seg_G : out std_logic
		);
		

end entity bin_to_7seg_3bit;

architecture rtl of bin_to_7seg_3bit is

	signal r_Hex_Encoding : std_logic_vector(7 downto 0) := (others => '0');
	
	begin
	
		process(i_Clk) is 
		begin
			if rising_edge(i_Clk) then
				case i_Bin_Num is
					
					when "001" =>
						r_Hex_Encoding <= X"30";
					when "010" =>
						r_Hex_Encoding <= X"6D";
					when  "011"=>
						r_Hex_Encoding <= X"79";
					when  "100"=>
						r_Hex_Encoding <= X"33";	
					when  "101"=>
						r_Hex_Encoding <= X"5B";
					when  "110"=>
						r_Hex_Encoding <= X"5F";
					when others =>
						r_Hex_Encoding <= X"7E"; --Hex value	
						
				end case;
			end if;
		end process;
		
		o_Seg_A <= r_Hex_Encoding(6);
		o_Seg_B <= r_Hex_Encoding(5);
		o_Seg_C <= r_Hex_Encoding(4);
		o_Seg_D <= r_Hex_Encoding(3);
		o_Seg_E <= r_Hex_Encoding(2);
		o_Seg_F <= r_Hex_Encoding(1);
		o_Seg_G <= r_Hex_Encoding(0);
end architecture rtl;		