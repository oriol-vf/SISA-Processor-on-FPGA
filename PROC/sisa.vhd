LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY sisa IS
    PORT (
			 HEX0 : OUT std_logic_vector(6 downto 0);
			 HEX1 : OUT std_logic_vector(6 downto 0);
			 HEX2 : OUT std_logic_vector(6 downto 0);
			 HEX3 : OUT std_logic_vector(6 downto 0);
			 CLOCK_50  : IN    STD_LOGIC;
          SRAM_ADDR : out   std_logic_vector(17 downto 0);
          SRAM_DQ   : inout std_logic_vector(15 downto 0);
          SRAM_UB_N : out   std_logic;
          SRAM_LB_N : out   std_logic;
          SRAM_CE_N : out   std_logic := '1';
          SRAM_OE_N : out   std_logic := '1';
          SRAM_WE_N : out   std_logic := '1';
			 LEDG  : out STD_LOGIC_VECTOR(7 DOWNTO 0);   
			 LEDR  : out STD_LOGIC_VECTOR(7 DOWNTO 0);
			 KEY	  : in std_logic_vector(3 downto 0);
          SW     : in std_logic_vector(9 downto 0);
			 PS2_CLK : INOUT STD_LOGIC;
			 PS2_DAT : INOUT STD_LOGIC;
			 VGA_R : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			 VGA_G : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			 VGA_B : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			 VGA_HS : OUT STD_LOGIC;
			 VGA_VS : OUT STD_LOGIC
			 );
END sisa;

ARCHITECTURE Structure OF sisa IS
	-- COMPONENTS
	
	COMPONENT proc IS
    PORT (
			clk : IN STD_LOGIC;
			boot : IN STD_LOGIC;
			datard_m : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			data_rd_io: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			intr		: IN STD_LOGIC;
			bad_alignment : IN STD_LOGIC;
			addr_m : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			data_wr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			wr_m : OUT STD_LOGIC;
			debug_pc : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			word_byte : OUT STD_LOGIC;
			addr_io : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			rd_in	 : OUT STD_LOGIC;
			wr_out : OUT STD_LOGIC;
			data_alu : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			inta 		: OUT STD_LOGIC);
	END COMPONENT;
	
	COMPONENT MemoryController is
	 PORT (CLOCK_50  : in  std_logic;
			addr      : in  std_logic_vector(15 downto 0);
			 wr_data   : in  std_logic_vector(15 downto 0);
			 rd_data   : out std_logic_vector(15 downto 0);
			 we        : in  std_logic;
			 byte_m    : in  std_logic;
			 -- señales para la placa de desarrollo
			 SRAM_ADDR : out   std_logic_vector(17 downto 0);
			 SRAM_DQ   : inout std_logic_vector(15 downto 0);
			 SRAM_UB_N : out   std_logic;
			 SRAM_LB_N : out   std_logic;
			 SRAM_CE_N : out   std_logic;
			 SRAM_OE_N : out   std_logic;
			 SRAM_WE_N : out   std_logic;
			 vga_addr : out std_logic_vector(12 downto 0);
			 vga_we : out std_logic;
			 vga_wr_data : out std_logic_vector(15 downto 0);
			 vga_rd_data : in std_logic_vector(15 downto 0);
			 vga_byte_m : out std_logic;
			 -- Excepciones
			 bad_alignment : out std_logic);
	end COMPONENT;
	
	COMPONENT controladores_IO IS
		PORT (boot : IN STD_LOGIC;
			CLOCK_50 : IN std_logic;
			addr_io : IN std_logic_vector(7 downto 0);
			wr_io : in std_logic_vector(15 downto 0);
			rd_io : out std_logic_vector(15 downto 0);
			wr_out : in std_logic;
			rd_in : in std_logic;
			led_verdes : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			led_rojos : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			seg_control  : OUT STD_LOGIC_VECTOR(19 downto 0);
			sw : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
			key : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			ps2_clk : INOUT STD_LOGIC;
			ps2_data : INOUT STD_LOGIC;
			vga_cursor : out std_logic_vector(15 downto 0);
			vga_cursor_enable : out std_logic;
			-- Interrupcions
			inta : IN STD_LOGIC;
			intr : OUT STD_LOGIC);
	END COMPONENT;
	
	COMPONENT hex_display_rep IS 
		PORT (
		NUMBER : IN std_logic_vector(15 downto 0);
		IS_ON : IN std_logic_vector(3 downto 0);
		HEX0 : OUT std_logic_vector(6 downto 0);
		HEX1 : OUT std_logic_vector(6 downto 0);
		HEX2 : OUT std_logic_vector(6 downto 0);
		HEX3 : OUT std_logic_vector(6 downto 0)
		);
	END COMPONENT;
	
	COMPONENT vga_controller is
    PORT(clk_50mhz      : in  std_logic;
         reset          : in  std_logic;
         blank_out      : out std_logic;
         csync_out      : out std_logic;
         red_out        : out std_logic_vector(7 downto 0);
         green_out      : out std_logic_vector(7 downto 0); 
         blue_out       : out std_logic_vector(7 downto 0); 
         horiz_sync_out : out std_logic; 
         vert_sync_out  : out std_logic; 
         --
         addr_vga          : in std_logic_vector(12 downto 0);
         we                : in std_logic;
         wr_data           : in std_logic_vector(15 downto 0);
         rd_data           : out std_logic_vector(15 downto 0);
         byte_m            : in std_logic;
         vga_cursor        : in std_logic_vector(15 downto 0);
         vga_cursor_enable : in std_logic
			);
	END COMPONENT;
		
	-- SIGNALS
	
	signal counter_clk : std_logic_vector(2 downto 0) := "000";
	signal clk_proc : std_logic := '0'; -- PROC CLK
	
	signal tmp_data_from_mem, tmp_addr_m, tmp_data_wr, tmp_debug_pc, tmp_data_alu, tmp_data_rd_io, tmp_vga_cursor, tmp_vga_wr_data, tmp_vga_rd_data : std_logic_vector(15 downto 0);
	signal tmp_addr_io, tmp_red_out, tmp_green_out, tmp_blue_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal tmp_wb, tmp_wr_m, tmp_wr_out, tmp_rd_in, tmp_vga_cursor_enable, tmp_vga_we, tmp_vga_byte_m, tmp_blank_out, tmp_csync_out, tmp_intr, tmp_inta, tmp_bad_alignment : std_logic;
	
	signal tmp_seg_control : std_logic_vector(19 downto 0);
	
	signal tmp_vga_addr : std_logic_vector(12 downto 0);

BEGIN
	
	-- PROC CLK PROCESS
	process (CLOCK_50) begin
		if rising_edge(CLOCK_50) then
			if (counter_clk = "011") then
				clk_proc <= not clk_proc;
				counter_clk <= "000";
			else 
				counter_clk <= counter_clk + 1; -- Increment clk proc counter
			end if;
		end if;
	end process;
	
	-- MODULES
	pro0 : proc port map(boot => SW(9), clk => clk_proc, datard_m => tmp_data_from_mem, intr => tmp_intr,
								word_byte => tmp_wb, wr_m => tmp_wr_m, addr_m => tmp_addr_m, data_rd_io => tmp_data_rd_io,
								data_wr => tmp_data_wr, debug_pc => tmp_debug_pc, addr_io => tmp_addr_io, rd_in => tmp_rd_in, wr_out => tmp_wr_out, 
								data_alu => tmp_data_alu, inta => tmp_inta, bad_alignment => tmp_bad_alignment);
	
	mem0 : MemoryController port map(CLOCK_50 => CLOCK_50, byte_m => tmp_wb, we => tmp_wr_m,
												addr => tmp_addr_m, wr_data => tmp_data_wr, SRAM_CE_N => SRAM_CE_N,
												SRAM_LB_N => SRAM_LB_N, SRAM_OE_N => SRAM_OE_N, 
												SRAM_UB_N => SRAM_UB_N, SRAM_WE_N => SRAM_WE_N,
												SRAM_ADDR => SRAM_ADDR, rd_data => tmp_data_from_mem,
												SRAM_DQ => SRAM_DQ, vga_addr => tmp_vga_addr, vga_we => tmp_vga_we, 
												vga_wr_data => tmp_vga_wr_data, vga_rd_data => tmp_vga_rd_data,
												vga_byte_m => tmp_vga_byte_m, bad_alignment => tmp_bad_alignment
												);
												
	io0 : controladores_IO port map(boot => SW(9), CLOCK_50 => CLOCK_50, addr_io => tmp_addr_io, wr_io => tmp_data_alu, inta => tmp_inta, 
											  rd_io => tmp_data_rd_io, wr_out => tmp_wr_out, rd_in => tmp_rd_in, led_verdes => LEDG, 
											  led_rojos => LEDR, sw => SW(8 downto 0), key => KEY, seg_control => tmp_seg_control,
											  ps2_clk => PS2_CLK, ps2_data => PS2_DAT, vga_cursor => tmp_vga_cursor, vga_cursor_enable => tmp_vga_cursor_enable,
											  intr => tmp_intr);
	
	vga0 : vga_controller port map (clk_50mhz => CLOCK_50, reset => SW(9), blank_out => tmp_blank_out, csync_out => tmp_csync_out,
											  red_out => tmp_red_out, green_out => tmp_green_out, blue_out => tmp_blue_out, horiz_sync_out => VGA_HS,
											  vert_sync_out => VGA_VS, addr_vga => tmp_vga_addr, we => tmp_vga_we, wr_data => tmp_vga_wr_data, rd_data => tmp_vga_rd_data,
											  byte_m => tmp_vga_byte_m, vga_cursor => tmp_vga_cursor, vga_cursor_enable => tmp_vga_cursor_enable);
	VGA_R <= tmp_red_out(3 downto 0);
	VGA_G <= tmp_green_out(3 downto 0);
	VGA_B <= tmp_blue_out(3 downto 0);
	
	seg0 : hex_display_rep port map(NUMBER => tmp_seg_control(19 downto 4), IS_ON => tmp_seg_control(3 downto 0), HEX0 => HEX0, HEX1 => HEX1, HEX2 => HEX2, HEX3 => HEX3);
END Structure;