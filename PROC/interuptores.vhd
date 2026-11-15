LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
ENTITY interuptores IS
    PORT (
			 boot  				: IN  STD_LOGIC;
			 clk  				: IN  STD_LOGIC;
			 inta  				: IN  STD_LOGIC;
			 i_switch 			: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			 intr  				: OUT  STD_LOGIC;
			 o_switch  			: OUT  STD_LOGIC_VECTOR(7 DOWNTO 0));
END interuptores;

ARCHITECTURE Structure OF interuptores IS
	signal reg : std_logic_vector(7 downto 0) := (others => '0');
	signal tmp_intr : std_logic;
BEGIN
	process (clk, boot) begin
		if boot = '1' then
			tmp_intr <= '0';
		elsif rising_edge(clk) then
			if i_switch /= reg then
				tmp_intr <= '1';
				reg <= i_switch;
			elsif inta = '1' and tmp_intr = '1' then
				tmp_intr <= '0';
			end if;
		end if;
	end process;
	
	intr <= tmp_intr;
	o_switch <= reg;
END Structure;
