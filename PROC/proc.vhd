LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY proc IS
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
END proc;

ARCHITECTURE Structure OF proc IS

    -- COMPONENTS
	 COMPONENT unidad_control IS
		 PORT (
				clk 		    : IN STD_LOGIC;
				boot 			 : IN STD_LOGIC;
				datard_m 	 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				zero_flag  	 : IN STD_LOGIC;
				alu_out		 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				intr			 : IN STD_LOGIC;
				PSW 			 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				excep 		: IN STD_LOGIC;
				alu_u			 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); 
				op				 : OUT STD_LOGIC_VECTOR(2 downto 0);
				wrd 			 : OUT STD_LOGIC;
				addr_a 		 : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
				addr_b 		 : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
				addr_d 		 : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
				immed 		 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
				pc 			 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
				ins_dad 		 : OUT STD_LOGIC;
				save_pc 		 : OUT STD_LOGIC;
				in_d 			 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
				immed_x2 	 : OUT STD_LOGIC;
				wr_m 			 : OUT STD_LOGIC;
				Rb_N	 		 : OUT STD_LOGIC;
				word_byte 	 : OUT STD_LOGIC;
				rd_in			 : OUT STD_LOGIC;
				wr_out		 : OUT STD_LOGIC;
				link_pc 		 : OUT STD_LOGIC;
				mem_access	 : OUT STD_LOGIC;
				is_fetch 	 : OUT STD_LOGIC;
				is_store 	 : OUT STD_LOGIC;
				-- Interrupcion regfile pins
				is_inter 	 : OUT  STD_LOGIC; -- Is interrupcion
				sys_inst 	 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- 00(NON), 01(EI), 10(DI), 11(RETI)
				d_sys  		 : OUT  STD_LOGIC;
				a_sys  		 : OUT  STD_LOGIC;
				inta			 : OUT STD_LOGIC;
				-- Excepcion
				illegal_inst : OUT STD_LOGIC;
				excep_ack	: OUT STD_LOGIC;
				protected_inst : OUT STD_LOGIC; --NNEW
				calls_inst		: OUT STD_LOGIC;
				-- TLB
				tlb_flush   : OUT STD_LOGIC;
				tlb_conf_en : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
				);
	END COMPONENT;
	
	COMPONENT datapath IS
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
	END COMPONENT;
		
	COMPONENT exception_controller IS
		PORT (
			boot	:	IN	STD_LOGIC;
			clk	: 	IN STD_LOGIC;
			div_zero : IN STD_LOGIC;
			mem_access	 : IN STD_LOGIC;
			bad_alignment : IN STD_LOGIC;
			illegal_inst : IN STD_LOGIC;
			excep_ack	: IN STD_LOGIC;
			is_fetch : IN STD_LOGIC;
			is_store : IN STD_LOGIC;
			sys_mode : IN STD_LOGIC;
			protected_inst : IN STD_LOGIC;
			calls_inst : IN STD_LOGIC;
			addr_m : IN STD_LOGIC_VECTOR(15 downto 0);
			-- TLB Excepcions
			i_tlb_excep : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			i_tlb_v     : IN STD_LOGIC;
			i_tlb_r     : IN STD_LOGIC;
			
			d_tlb_excep : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			d_tlb_v     : IN STD_LOGIC;
			d_tlb_r     : IN STD_LOGIC;
			excep	:	OUT STD_LOGIC;
			excepId : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
		);
	END COMPONENT;
	
	-- SIGNALS
	signal tmp_wrd, tmp_immed_x2, tmp_ins_data, tmp_rb_n, tmp_zero_flag, tmp_save_pc, tmp_is_inter, tmp_d_sys, tmp_a_sys, tmp_link_pc, tmp_div_zero, tmp_illegal_inst, tmp_excep, tmp_excep_ack : STD_LOGIC;
	signal tmp_mem_access, tmp_protected_inst, tmp_calls_inst, tmp_tlb_flush : std_logic;
	signal tmp_i_tlb_v, tmp_i_tlb_r, tmp_d_tlb_v, tmp_d_tlb_r, tmp_is_fetch, tmp_is_store : STD_LOGIC;
	signal tmp_op : STD_LOGIC_VECTOR(2 DOWNTO 0);
	signal tmp_excepID : STD_LOGIC_VECTOR(3 DOWNTO 0);
	signal tmp_alu_u, tmp_in_d, tmp_sys_inst, tmp_i_tlb_excep, tmp_d_tlb_excep : STD_LOGIC_VECTOR(1 DOWNTO 0);
	signal tmp_addr_a, tmp_addr_b, tmp_addr_d, tmp_tlb_conf_en : STD_LOGIC_VECTOR(2 DOWNTO 0);
	signal tmp_immed, tmp_pc, tmp_alu_out, tmp_PSW, tmp_addr_m  : STD_LOGIC_VECTOR(15 DOWNTO 0);
	
BEGIN
	-- Control Unit
	c0: unidad_control port map(boot => boot, clk => clk, datard_m => datard_m, alu_out => tmp_alu_out, intr => intr, PSW => tmp_PSW, zero_flag => tmp_zero_flag, immed_x2 => tmp_immed_x2, 
										in_d => tmp_in_d, excep => tmp_excep, ins_dad => tmp_ins_data, word_byte => word_byte, wr_m => wr_m,
										wrd => tmp_wrd, alu_u => tmp_alu_u, op => tmp_op, addr_a => tmp_addr_a, addr_b => tmp_addr_b, is_fetch => tmp_is_fetch, is_store => tmp_is_store,
										addr_d => tmp_addr_d, immed => tmp_immed, pc => tmp_pc, Rb_N => tmp_rb_n, save_pc => tmp_save_pc, rd_in => rd_in, wr_out => wr_out,
										is_inter => tmp_is_inter, sys_inst => tmp_sys_inst, d_sys => tmp_d_sys, a_sys => tmp_a_sys, inta => inta, link_pc => tmp_link_pc, illegal_inst => tmp_illegal_inst,
										excep_ack => tmp_excep_ack, mem_access => tmp_mem_access, protected_inst => tmp_protected_inst, calls_inst => tmp_calls_inst, tlb_flush => tmp_tlb_flush, tlb_conf_en => tmp_tlb_conf_en);
	-- Datapath
	e0: datapath port map(clk => clk, boot => boot, regfile_boot => boot, tlb_flush => tmp_tlb_flush, tlb_conf_en => tmp_tlb_conf_en, immed_x2 => tmp_immed_x2, in_d => tmp_in_d, ins_dad => tmp_ins_data, wrd => tmp_wrd,
								alu_u => tmp_alu_u, op => tmp_op, addr_a => tmp_addr_a, addr_b => tmp_addr_b, addr_d => tmp_addr_d, 
								immed => tmp_immed, datard_m => datard_m, pc => tmp_pc, addr_m => tmp_addr_m, data_wr => data_wr, Rb_N => tmp_rb_n,
								alu_out => tmp_alu_out, zero_flag => tmp_zero_flag, save_pc => tmp_save_pc, data_rd_io => data_rd_io,
								is_inter => tmp_is_inter, sys_inst => tmp_sys_inst, d_sys => tmp_d_sys, a_sys => tmp_a_sys, link_pc => tmp_link_pc, PSW => tmp_PSW, 
								div_zero => tmp_div_zero, excep => tmp_excep_ack, excepID => tmp_excepID,
								i_tlb_excep => tmp_i_tlb_excep, i_tlb_v => tmp_i_tlb_v, i_tlb_r => tmp_i_tlb_r,
								d_tlb_excep => tmp_d_tlb_excep, d_tlb_v => tmp_d_tlb_v, d_tlb_r => tmp_d_tlb_r);
	
	-- Excepcion Controller
	excep0 : exception_controller port map(clk => clk, boot => boot, div_zero => tmp_div_zero, mem_access => tmp_mem_access, bad_alignment => bad_alignment, illegal_inst => tmp_illegal_inst, 
														excep_ack => tmp_excep_ack, excep => tmp_excep, excepID => tmp_excepID, sys_mode => tmp_PSW(0), protected_inst => tmp_protected_inst, calls_inst => tmp_calls_inst,
														addr_m => tmp_addr_m, i_tlb_excep => tmp_i_tlb_excep, i_tlb_v => tmp_i_tlb_v, i_tlb_r => tmp_i_tlb_r, is_fetch => tmp_is_fetch, is_store => tmp_is_store,
														d_tlb_excep => tmp_d_tlb_excep, d_tlb_v => tmp_d_tlb_v, d_tlb_r => tmp_d_tlb_r);
	
	debug_pc <= tmp_pc;
	data_alu <= tmp_alu_out; -- Data from alu
	addr_io <= tmp_immed(7 downto 0);
	addr_m <= tmp_addr_m;
END Structure;