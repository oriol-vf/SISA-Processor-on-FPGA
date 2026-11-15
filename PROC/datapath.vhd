LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;

ENTITY datapath IS
	PORT (clk : IN STD_LOGIC;
			boot : IN STD_LOGIC;
			regfile_boot   : IN  STD_LOGIC; -- Regfile boot
			alu_u			: IN STD_LOGIC_VECTOR(1 DOWNTO 0); 
			op				: IN STD_LOGIC_VECTOR(2 downto 0);
			wrd : IN STD_LOGIC;
			addr_a : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
			addr_b : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
			addr_d : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
			Rb_N	 : IN STD_LOGIC;
			immed : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			immed_x2 : IN STD_LOGIC;
			datard_m : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			ins_dad : IN STD_LOGIC;
			save_pc : IN STD_LOGIC;
			pc : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			in_d 	: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			data_rd_io : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			link_pc 		: IN STD_LOGIC;
			-- Interrupcion regfile pins
		    is_inter : IN  STD_LOGIC; -- Is interrupcion
			sys_inst : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- 00(NON), 01(EI), 10(DI), 11(RETI)
			d_sys  : IN  STD_LOGIC;
			a_sys  : IN  STD_LOGIC;
			
			-- Puertos de memoria y ALU
			addr_m : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			data_wr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			alu_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			zero_flag : OUT STD_LOGIC;
			-- Excepcion 
			excep : IN STD_LOGIC;
			excepID : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			div_zero 		: OUT STD_LOGIC;
			PSW : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			
			tlb_flush   : IN STD_LOGIC;
			tlb_conf_en : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
			
			i_tlb_excep : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			i_tlb_v     : OUT STD_LOGIC;
			i_tlb_r     : OUT STD_LOGIC;
			
			d_tlb_excep : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			d_tlb_v     : OUT STD_LOGIC;
			d_tlb_r     : OUT STD_LOGIC
			);
END datapath;


ARCHITECTURE Structure OF datapath IS

    -- Componentes
	 COMPONENT alu IS
    PORT (x  				: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          y  				: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          alu_u			: IN STD_LOGIC_VECTOR(1 DOWNTO 0); 
			 op				: IN STD_LOGIC_VECTOR(2 downto 0);
			 z					: OUT STD_LOGIC;
			 div_zero 		: OUT STD_LOGIC;
          w  				: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT regfile IS
    PORT (
			 -- INPUTS
			 clk    : IN  STD_LOGIC;
			 boot   : IN  STD_LOGIC; -- Boot
          wrd    : IN  STD_LOGIC;
          d      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          addr_a : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
			 addr_b : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
          addr_d : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
			 -- Interrupcion regfile pins
			 is_inter : IN  STD_LOGIC; -- Is interrupcion
			 sys_inst : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- 00(NON), 01(EI), 10(DI), 11(RETI)
			 d_sys  : IN  STD_LOGIC;
			 a_sys  : IN  STD_LOGIC;
			 -- Exceptions
			 excep : IN STD_LOGIC;
			 excepID : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			 excepMemAddr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			 -- OUTPUTS
          a      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			 b      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			 PSW : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT tlb IS
		 PORT(
			  I_or_D          : IN  std_logic;
			  clk             : IN  std_logic;
			  boot				: IN 	std_logic;
			  flush           : IN  std_logic;
			  vtag            : IN  std_logic_vector(3 downto 0);
			  -- Config TLB
			  conf_en         : IN  std_logic_vector(2 downto 0);
			  addr_line_conf  : IN  std_logic_vector(2 downto 0);
			  new_line_conf   : IN  std_logic_vector(5 downto 0); -- v(1bit) - r(1bit) - tag(4bits)
			  -- Outputs
			  tlb_excep       : OUT std_logic_vector(1 downto 0);
			  ptag            : OUT std_logic_vector(3 downto 0);
			  v               : OUT std_logic;
			  r               : OUT std_logic
		 );
	END COMPONENT;

	-- ALU wires
	signal o_alu0, y_alu0 : std_logic_vector(15 downto 0) := (others => '0');
	-- REGFILE wires
	signal i_reg0 : std_logic_vector(15 downto 0) := (others => '0');
	signal o_a_reg0, o_b_reg0 : std_logic_vector(15 downto 0) := (others => '0');
	-- Others
	signal i_immed, tmp_addr_m : std_logic_vector(15 downto 0) := (others => '0');
	signal tmp_pc_value : std_logic_vector(15 downto 0);
	
	-- TLB wires
	signal i_ptag, d_ptag : std_logic_vector(3 downto 0);
	
BEGIN
	-- Instanciacion modulos ALU y REGFILE
	reg0 : regfile port map(clk => clk, boot => regfile_boot, wrd => wrd, d => i_reg0, addr_a => addr_a, 
									addr_b => addr_b, addr_d => addr_d, a => o_a_reg0, b => o_b_reg0,
									is_inter => is_inter, sys_inst => sys_inst, d_sys => d_sys, a_sys => a_sys, PSW => PSW,
									excep => excep, excepID => excepID, excepMemAddr => tmp_addr_m);
									
	alu0 : alu port map(x => o_a_reg0, y => y_alu0, alu_u => alu_u, op => op, z => zero_flag, div_zero => div_zero, w => o_alu0);
	
	-- TLB de Instrucciones (I_or_D = '0')
	inst_tlb : tlb port map(
		I_or_D         => '0',
		clk            => clk,
		boot				=> boot,
		flush          => tlb_flush,
		vtag           => pc(15 downto 12),           -- Los 4 bits superiores del PC
		conf_en        => tlb_conf_en,
		addr_line_conf => o_a_reg0(2 downto 0),       -- Los bits de menor peso del registro Ra indexan la tabla
		new_line_conf  => o_b_reg0(5 downto 0),       -- Los bits de menor peso de Rb tienen el tag fisico, v y r
		tlb_excep      => i_tlb_excep,
		ptag           => i_ptag,                     -- Salida: tag fisico traducido
		v              => i_tlb_v,
		r              => i_tlb_r
	);
	
	-- TLB de Datos (I_or_D = '1')
	data_tlb : tlb port map(
		I_or_D         => '1',
		clk            => clk,
		boot				=> boot,
		flush          => tlb_flush,
		vtag           => o_alu0(15 downto 12),       -- Los 4 bits superiores de la salida de la ALU
		conf_en        => tlb_conf_en,
		addr_line_conf => o_a_reg0(2 downto 0),       -- Los bits de menor peso del registro Ra indexan la tabla
		new_line_conf  => o_b_reg0(5 downto 0),       -- Los bits de menor peso de Rb tienen el tag fisico, v y r
		tlb_excep      => d_tlb_excep,
		ptag           => d_ptag,                     -- Salida: tag fisico traducido
		v              => d_tlb_v,
		r              => d_tlb_r
	);
	
	-- Otros Modulos / conexiones (MUX, REG, ...)
	
	-- Multiplexor entrada REGFILE, alu_dato(0) o mem_dato(1)
	tmp_pc_value <= o_alu0 when save_pc = '0' else pc when link_pc = '0' else pc+2;
	
	i_reg0 <= tmp_pc_value when in_d = "00" else datard_m when in_d = "01" else data_rd_io when in_d = "10" else x"DEAD";
	
	-- Multiplexor de immediato, immed(0) o immed * 2 (1)
	i_immed <= immed when immed_x2 = '0' else (immed(14 downto 0) & '0');
	
	-- Los 12 bits de menor peso son el offset directo desde PC o ALU
	tmp_addr_m(11 downto 0) <= pc(11 downto 0) when ins_dad = '0' else o_alu0(11 downto 0);
	
	-- Los 4 bits de mayor peso vienen del tag fisico traducido por el TLB correspondiente
	tmp_addr_m(15 downto 12) <= i_ptag when ins_dad = '0' else d_ptag;
	
	addr_m <= tmp_addr_m;
	
	-- Puerto Lectura B del REG0 a data wr de la memoria
	data_wr <= o_b_reg0;
	
	-- Multiplexor de Y ALU, o_b_reg0(0) o i_immed(1)
	y_alu0 <= o_b_reg0 when Rb_N = '0' else i_immed;
	
	-- ALU return value to control unite
	alu_out <= o_alu0; 
	
END Structure;