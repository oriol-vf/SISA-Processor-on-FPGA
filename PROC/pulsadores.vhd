LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
ENTITY pulsadores IS
    PORT (
			 boot  				: IN  STD_LOGIC;
			 clk  				: IN  STD_LOGIC;
			 inta  				: IN  STD_LOGIC;
			 i_keys  			: IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
			 intr  				: OUT  STD_LOGIC;
			 o_keys  			: OUT  STD_LOGIC_VECTOR(3 DOWNTO 0));
END pulsadores;

ARCHITECTURE Structure OF pulsadores IS
	signal reg : std_logic_vector(3 downto 0);
	signal tmp_intr : std_logic;
BEGIN
	process (clk, boot) begin
		if boot = '1' then
			tmp_intr <= '0';
		elsif rising_edge(clk) then
			if i_keys /= reg then
				tmp_intr <= '1';
				reg <= i_keys;
			elsif inta = '1' and tmp_intr = '1' then
				tmp_intr <= '0';
			end if;
		end if;
	end process;
	
	intr <= tmp_intr;
	o_keys <= reg;
END Structure;

