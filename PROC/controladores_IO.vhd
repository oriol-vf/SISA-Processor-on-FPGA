LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;        --Esta libreria sera necesaria si usais conversiones TO_INTEGER
USE ieee.std_logic_unsigned.all; --Esta libreria sera necesaria si usais conversiones CONV_INTEGER

ENTITY controladores_IO IS
	GENERIC (
		N_PORTS : integer := 32
	);
	PORT (
		boot       : IN STD_LOGIC;
		CLOCK_50   : IN std_logic;
		addr_io    : IN std_logic_vector(7 downto 0);
		wr_io      : in std_logic_vector(15 downto 0);
		rd_io      : out std_logic_vector(15 downto 0);
		wr_out     : in std_logic;
		rd_in      : in std_logic;
		led_verdes : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		led_rojos  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		seg_control  : OUT STD_LOGIC_VECTOR(19 downto 0);
		sw         : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
		key        : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		ps2_clk    : INOUT STD_LOGIC;
		ps2_data   : INOUT STD_LOGIC;
		-- VGA
		vga_cursor : out std_logic_vector(15 downto 0);
		vga_cursor_enable : out std_logic;
		-- Interrupcions
		inta : IN STD_LOGIC;
		intr : OUT STD_LOGIC
	);
END controladores_IO;

ARCHITECTURE Structure OF controladores_IO IS
	-- COMPONENTS
	COMPONENT keyboard_controller IS
    PORT (clk        : in    STD_LOGIC;
          reset      : in    STD_LOGIC;
          ps2_clk    : inout STD_LOGIC;
          ps2_data   : inout STD_LOGIC;
          read_char  : out   STD_LOGIC_VECTOR (7 downto 0);
          clear_char : in    STD_LOGIC;
          data_ready : out   STD_LOGIC;
			 inta			: in 	  STD_LOGIC; -- Interrupt ACK (Mod)
			 intr			: OUT   STD_LOGIC -- Interrupt Flag (Mod)
			 );
	END COMPONENT;
	
	COMPONENT pulsadores IS
		 PORT (
				 boot  				: IN  STD_LOGIC;
				 clk  				: IN  STD_LOGIC;
				 inta  				: IN  STD_LOGIC;
				 i_keys  			: IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
				 intr  				: OUT  STD_LOGIC;
				 o_keys  			: OUT  STD_LOGIC_VECTOR(3 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT interuptores IS
		 PORT (
				 boot  				: IN  STD_LOGIC;
				 clk  				: IN  STD_LOGIC;
				 inta  				: IN  STD_LOGIC;
				 i_switch 			: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
				 intr  				: OUT  STD_LOGIC;
				 o_switch  			: OUT  STD_LOGIC_VECTOR(7 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT timer IS
		PORT(
			CLOCK_50 : IN STD_LOGIC;
			boot 		: IN STD_LOGIC;
			inta		: IN STD_LOGIC;
			intr		: OUT STD_LOGIC
		);
	END COMPONENT;
	
	COMPONENT interrupt_controller IS
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
	END COMPONENT;
	
	-- TYPES
	type BLOQUE_REG is array ((N_PORTS-1) downto 0) of std_logic_vector(15 downto 0); -- de 0 a (N_PORTS-1)
	
	-- SIGNALS
	signal IO_regs : BLOQUE_REG;
	signal tmp_read_char : std_logic_vector(7 downto 0);
	signal tmp_data_ready, tmp_clear_char : std_logic;

	signal contador_ciclos : STD_LOGIC_VECTOR(15 downto 0):=x"0000";
	signal contador_milisegundos : STD_LOGIC_VECTOR(15 downto 0):=x"0000"; 
	
	signal tmp_timer_inta, tmp_key_inta, tmp_switch_inta, tmp_ps2_inta : std_logic;
	signal tmp_timer_intr, tmp_key_intr, tmp_switch_intr, tmp_ps2_intr : std_logic;
	signal tmp_read_key : std_logic_vector(3 downto 0);
	signal tmp_rd_switch, tmp_iid : std_logic_vector(7 downto 0);
	
BEGIN

	PS2_KeyBCont0 : keyboard_controller port map(clk => CLOCK_50, reset => boot, ps2_clk => ps2_clk, ps2_data => ps2_data, 
												  read_char => tmp_read_char, clear_char => tmp_clear_char, 
												  data_ready => tmp_data_ready, inta => tmp_ps2_inta, intr => tmp_ps2_intr);
	
	keyCont0 : pulsadores port map(boot => boot, clk => CLOCK_50, inta => tmp_key_inta ,
											i_keys => key, intr => tmp_key_intr, o_keys => tmp_read_key);
	
	SwitchCont0 : interuptores port map(boot => boot, clk => CLOCK_50, inta => tmp_switch_inta,
											i_switch => sw(7 downto 0), intr => tmp_switch_intr, o_switch => tmp_rd_switch);
	
	TimerCont0 : timer port map(boot => boot, CLOCK_50 => CLOCK_50, inta => tmp_timer_inta, intr => tmp_timer_intr);
	
	inteCont : interrupt_controller port map (boot => boot, clk => CLOCK_50, inta => inta, key_intr => tmp_key_intr,
															ps2_intr => tmp_ps2_intr, switch_intr => tmp_switch_intr, timer_intr => tmp_timer_intr,
															intr => intr, key_inta => tmp_key_inta, ps2_inta => tmp_ps2_inta, switch_inta => tmp_switch_inta,
															timer_inta => tmp_timer_inta, iid => tmp_iid);
	
	-- Write Process
	process (CLOCK_50, boot) begin
		 if boot = '1' then
				IO_regs <= (others => (others => '0'));
				tmp_clear_char <= '0';
		 elsif rising_edge(CLOCK_50) then 
			  -- Dafault Values
			  tmp_clear_char <= '0';
			  
			  -- Timer
			  if contador_ciclos=0 then
				 contador_ciclos<=x"C350"; -- tiempo de ciclo=20ns(50Mhz) 1ms=50000ciclos
				 if contador_milisegundos>0 then
					contador_milisegundos <= contador_milisegundos-1;
				 end if;
			 else
				 contador_ciclos <= contador_ciclos-1;
			 end if;
			  
			  -- Write Port logic
			  if wr_out = '1' then
					if conv_integer(addr_io) < N_PORTS then
						 case conv_integer(addr_io) is
							  when 7 | 8 | 15 | 20 => 
									null; -- Read only ports
							  when 16 =>
									if tmp_clear_char = '0' then
										 tmp_clear_char <= '1';  -- Send clean signal to keyboard controller
									end if;
							  when 21 =>
									contador_milisegundos <= wr_io;
							  when others =>
									IO_regs(conv_integer(addr_io)) <= wr_io;
						 end case;
					end if;
			  end if;
		 end if;
	end process;
	
	-- Mapeo de SALIDAS
	led_verdes <= IO_regs(5)(7 downto 0);
	led_rojos  <= IO_regs(6)(7 downto 0);
	seg_control  <= IO_regs(10) & IO_regs(9)(3 downto 0); -- 19:4: seg value and 3:0 on_off
	vga_cursor <= IO_regs(11); -- Write cursor pos
	vga_cursor_enable <= IO_regs(12)(0); -- Enable Cursor
	
	-- Read Process
	process(rd_in, inta)
	begin
		-- Default return value
		rd_io <= (others => '0'); 
		
		if rd_in = '1' then
			if inta = '1' then
				rd_io <= x"00" & tmp_iid;
			else
				case conv_integer(addr_io) is
					when 7 => 
						rd_io <= (15 downto 4 => '0') & tmp_read_key(3 downto 0); -- Read Key
					when 8 => 
						rd_io <= (15 downto 8 => '0') & tmp_rd_switch(7 downto 0); -- Read Sw
					when 15 =>
						rd_io <= x"00" & tmp_read_char; -- Read Keyboard key
					when 16 =>
						rd_io <= (15 downto 1 => '0') & tmp_data_ready;
					when 20 =>
						rd_io <= contador_ciclos;
					when 21 =>
						rd_io <= contador_milisegundos;
					when others => 
						if conv_integer(addr_io) < N_PORTS then 
							rd_io <= IO_regs(conv_integer(addr_io));
						else
							rd_io <= x"DEAD"; -- Return value for out of range acces
						end if;
				end case;
			end if;
		end if;
	end process;
	
END Structure;
