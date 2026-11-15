LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;        --Esta libreria sera necesaria si usais conversiones TO_INTEGER
USE ieee.std_logic_unsigned.all; --Esta libreria sera necesaria si usais conversiones CONV_INTEGER
ENTITY interrupt_controller IS
	PORT (
		boot	:	IN	STD_LOGIC;
		clk	: 	IN STD_LOGIC;
		inta	:	IN STD_LOGIC;
		key_intr	: IN STD_LOGIC;
		ps2_intr	: IN STD_LOGIC;
		switch_intr : IN STD_LOGIC;
		timer_intr : IN STD_LOGIC;
		intr		: OUT STD_LOGIC;
		key_inta : OUT STD_LOGIC;
		ps2_inta	 : OUT STD_LOGIC;
		switch_inta	: OUT STD_LOGIC;
		timer_inta : OUT STD_LOGIC;
		iid	: OUT STD_LOGIC_VECTOR(7 downto 0)
	);
END interrupt_controller;

ARCHITECTURE Struc OF interrupt_controller IS
	signal tmp_timer_inta, tmp_key_inta, tmp_switch_inta, tmp_ps2_inta : std_logic;
	signal tmp_iid : std_logic_vector(7 downto 0);
BEGIN
	
	process (clk, boot) begin
		if boot = '1' then
			tmp_timer_inta <= '0';
			tmp_key_inta <= '0';
			tmp_switch_inta <= '0';
			tmp_ps2_inta <= '0';
			tmp_iid <= x"00";
		elsif rising_edge(clk) then
			-- Default values ------
			tmp_timer_inta <= '0';
			tmp_key_inta <= '0';
			tmp_switch_inta <= '0';
			tmp_ps2_inta <= '0';
			-- ---------------------
			if inta = '1' then
				if (timer_intr = '1') then
					tmp_iid <= x"00";
					tmp_timer_inta <= '1';
				elsif (key_intr = '1') then
					tmp_iid <= x"01";
					tmp_key_inta <= '1';
				elsif (switch_intr = '1') then
					tmp_iid <= x"02";
					tmp_switch_inta <= '1';
				elsif (ps2_intr = '1') then
					tmp_iid <= x"03";
					tmp_ps2_inta <= '1';
				end if;
			end if;
		end if;
	end process;
	
	-- OUTPUT SIGNALS
	intr <= '0' when boot = '1' else (key_intr or ps2_intr or switch_intr or timer_intr);
	
	timer_inta <= tmp_timer_inta;
	key_inta <= tmp_key_inta;
	switch_inta <= tmp_switch_inta;
	ps2_inta <= tmp_ps2_inta;
	
	iid <= tmp_iid;
END Struc;