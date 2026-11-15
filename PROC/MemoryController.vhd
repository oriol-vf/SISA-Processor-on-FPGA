library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity MemoryController is
    port (CLOCK_50  : in  std_logic;
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
          SRAM_CE_N : out   std_logic := '1';
          SRAM_OE_N : out   std_logic := '1';
          SRAM_WE_N : out   std_logic := '1';
			 -- Señales para el VGA
			 vga_addr : out std_logic_vector(12 downto 0);
			 vga_we : out std_logic;
			 vga_wr_data : out std_logic_vector(15 downto 0);
			 vga_rd_data : in std_logic_vector(15 downto 0);
			 vga_byte_m : out std_logic;
			 -- Excepciones
			 bad_alignment : out std_logic
			 );
end MemoryController;

architecture comportament of MemoryController is
	-- COMPONENT
	COMPONENT SRAMController is
		 port (clk         : in    std_logic;
				 -- señales para la placa de desarrollo
				 SRAM_ADDR   : out   std_logic_vector(17 downto 0);
				 SRAM_DQ     : inout std_logic_vector(15 downto 0);
				 SRAM_UB_N   : out   std_logic;
				 SRAM_LB_N   : out   std_logic;
				 SRAM_CE_N   : out   std_logic;
				 SRAM_OE_N   : out   std_logic;
				 SRAM_WE_N   : out   std_logic;
				 -- señales internas del procesador
				 address     : in    std_logic_vector(15 downto 0);
				 dataReaded  : out   std_logic_vector(15 downto 0);
				 dataToWrite : in    std_logic_vector(15 downto 0);
				 WR          : in    std_logic;
				 byte_m      : in    std_logic);
	END COMPONENT;
	
	-- SIGNALS
	
	signal tmp_WR, tmp_vga_we : std_logic := '0';
	signal memory_rd_data : std_logic_vector(15 downto 0);
	signal tmp_vga_addr : std_logic_vector(15 downto 0);
begin
	-- word access to odd @
	bad_alignment <= '1' when (byte_m = '0' and addr(0) = '1') else '0';
	
	-- Less Than 
	tmp_WR <= we when (addr < x"C000") else '0'; 
	
	-- SRAM CONTROLLER INST
	sram0 : SRAMController port map (WR => tmp_WR, byte_m => byte_m, clk => CLOCK_50, 
												address => addr, dataToWrite => wr_data, SRAM_CE_N => SRAM_CE_N,
												SRAM_LB_N => SRAM_LB_N, SRAM_OE_N => SRAM_OE_N, 
												SRAM_UB_N => SRAM_UB_N, SRAM_WE_N => SRAM_WE_N,
												SRAM_ADDR => SRAM_ADDR, dataReaded => memory_rd_data,
												SRAM_DQ => SRAM_DQ);
	-- VGA
	tmp_vga_addr <= (addr - x"A000");
	vga_addr <= tmp_vga_addr(12 downto 0); -- Comprovar
	tmp_vga_we <= '1' when ((addr >= x"A000") and (addr < x"C000")) else '0'; -- VGA write enable
	vga_we <= tmp_vga_we;
	vga_byte_m <= byte_m;
	vga_wr_data <= wr_data;
	 
	-- Read Data (MEM or VGA)
	rd_data <= memory_rd_data when (tmp_vga_we = '0') else vga_rd_data;
end comportament;
