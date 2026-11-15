library ieee;
use ieee.std_logic_1164.all;
entity hex_display_rep is 
	port (
	NUMBER : IN std_logic_vector(15 downto 0);
	IS_ON : IN std_logic_vector(3 downto 0);
	HEX0 : OUT std_logic_vector(6 downto 0);
	HEX1 : OUT std_logic_vector(6 downto 0);
	HEX2 : OUT std_logic_vector(6 downto 0);
	HEX3 : OUT std_logic_vector(6 downto 0)
	);
end hex_display_rep;

architecture Struc_hex_display_rep of hex_display_rep is
	component single_hex_rep is
		port (
			NUMBER : IN std_logic_vector(3 downto 0);
			IS_ON : IN std_logic;
			HEX : OUT std_logic_vector(6 downto 0)
		);
	end component;
begin

	rep0 : single_hex_rep port map(NUMBER(3 downto 0),IS_ON(0),HEX0);
	rep1 : single_hex_rep port map(NUMBER(7 downto 4),IS_ON(1),HEX1);
	rep2 : single_hex_rep port map(NUMBER(11 downto 8),IS_ON(2),HEX2);
	rep3 : single_hex_rep port map(NUMBER(15 downto 12),IS_ON(3),HEX3);
	
end Struc_hex_display_rep;


-- Representacio Hexadecimal en un 7 seg display
library ieee;
use ieee.std_logic_1164.all;
entity single_hex_rep is
	port (
		NUMBER : IN std_logic_vector(3 downto 0);
		IS_ON : IN std_logic;
		HEX : OUT std_logic_vector(6 downto 0)
	);
end single_hex_rep;

architecture Struc_single_hex_rep of single_hex_rep is

begin
	
	with IS_ON & NUMBER select
	HEX <= "1000000" when "10000",
			 "1111001" when "10001",
			 "0100100" when "10010",
			 "0110000" when "10011",
			 "0011001" when "10100",
			 "0010010" when "10101",
			 "0000011" when "10110",
			 "1111000" when "10111",
			 "0000000" when "11000",
			 "0011000" when "11001",
			 "0001000" when "11010", -- A
			 "0000011" when "11011", -- b
			 "1000110" when "11100" , -- C
			 "0100001" when "11101" , -- d
			 "0000110" when "11110" , -- E
			 "0001110" when "11111" , -- F
			 "1111111" when others;

end Struc_single_hex_rep;