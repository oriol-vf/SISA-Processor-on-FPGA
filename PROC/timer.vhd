LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
ENTITY timer IS
	PORT(
		CLOCK_50 : IN STD_LOGIC;
		boot 		: IN STD_LOGIC;
		inta		: IN STD_LOGIC;
		intr		: OUT STD_LOGIC
	);
END timer;

ARCHITECTURE Struc OF timer IS
	signal tmp_intr : std_logic;
	signal tick_counter : std_logic_vector(15 downto 0) := x"0000"; -- Max num: 65535
	signal ms_counter	: std_logic_vector(5 downto 0) := (others => '0'); -- Number of iteracions
BEGIN
	-- tiempo de ciclo=20ns(50Mhz) (1ms=50000ciclos)
	process (CLOCK_50, boot) begin
		if boot = '1' then
			tmp_intr <= '0';
		elsif rising_edge(CLOCK_50) then 
			-- Timer
			if tick_counter > 0 then
				tick_counter <= tick_counter - 1; -- Ha pasat 1 tick
			else -- tick_counter = 0
				tick_counter <= x"C350"; -- (1ms=50000ciclos)
				if ms_counter > 0 then
					ms_counter <= ms_counter - 1; -- Ha pasat 1ms
				else -- ms_counter = 0
					ms_counter <= "110010"; -- 50 ms
					tmp_intr <= '1'; -- Han pasat 50ms => interrupcio
				end if;
			end if;
			
			-- Interrupcio Ack Func
			if inta = '1' then
				tmp_intr <= '0';
			end if;
			
		end if;
	end process;
	
	-- Output signals
	intr <= tmp_intr;
END Struc;