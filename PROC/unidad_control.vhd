LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;

ENTITY unidad_control IS
    PORT (
				clk 			: IN STD_LOGIC;
				boot 			: IN STD_LOGIC;
				datard_m 	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				zero_flag  	: IN STD_LOGIC;
				alu_out		: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				intr			: IN STD_LOGIC;
				PSW 			: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				excep 		: IN STD_LOGIC;
				alu_u			: OUT STD_LOGIC_VECTOR(1 DOWNTO 0); 
				op				: OUT STD_LOGIC_VECTOR(2 downto 0);
				wrd 			: OUT STD_LOGIC;
				addr_a 		: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
				addr_b 		: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
				addr_d 		: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
				immed 		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
				pc 			: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
				ins_dad 		: OUT STD_LOGIC;
				save_pc 		: OUT STD_LOGIC;
				in_d 			: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
				immed_x2 	: OUT STD_LOGIC;
				wr_m 			: OUT STD_LOGIC;
				Rb_N	 		: OUT STD_LOGIC;
				word_byte 	: OUT STD_LOGIC;
				rd_in			: OUT STD_LOGIC;
				wr_out		: OUT STD_LOGIC;
				link_pc 		: OUT STD_LOGIC;
				mem_access	: OUT STD_LOGIC;
				is_fetch 	 : OUT STD_LOGIC;
				is_store		: OUT STD_LOGIC;
				-- Interrupcion regfile pins
				is_inter 	: OUT  STD_LOGIC; -- Is interrupcion
				sys_inst 	: OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- 00(NON), 01(EI), 10(DI), 11(RETI)
				d_sys  		: OUT  STD_LOGIC;
				a_sys  		: OUT  STD_LOGIC;
				inta			: OUT STD_LOGIC;
				-- Excepcion
				illegal_inst	: OUT STD_LOGIC;
				excep_ack		: OUT STD_LOGIC;
				protected_inst : OUT STD_LOGIC; --NNEW
				calls_inst		: OUT STD_LOGIC;  --NEW
				-- TLB
				tlb_flush   : OUT STD_LOGIC;
				tlb_conf_en : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
				);
END unidad_control;

ARCHITECTURE Structure OF unidad_control IS

    -- COMPONENT
	 COMPONENT control_l IS
		 PORT (
			ir 			: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			zero_flag	: IN STD_LOGIC; -- Alu zero Flag
			intr			: IN STD_LOGIC;
			excep 		: IN STD_LOGIC;
			alu_u			: OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- ALU UNIT 2 bits
			op				: OUT STD_LOGIC_VECTOR(2 downto 0); -- ALU Selected Unit Operation 3 bits
			ldpc 			: OUT STD_LOGIC;
			wrd			: OUT STD_LOGIC;
			addr_a		: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			addr_b 		: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			addr_d 		: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			immed 		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			wr_m 			: OUT STD_LOGIC;
			in_d 			: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			immed_x2 	: OUT STD_LOGIC;
			Rb_N	 		: OUT STD_LOGIC;
			word_byte 	: OUT STD_LOGIC;
			tknbr			: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			save_pc		: OUT STD_LOGIC;
			rd_in			: OUT STD_LOGIC;
			wr_out		: OUT STD_LOGIC;
			link_pc 		: OUT STD_LOGIC;
			mem_access	: OUT STD_LOGIC;
			is_store		: OUT STD_LOGIC;
			-- Interrupcion
			is_inter 	: OUT  STD_LOGIC; -- Is interrupcion
			sys_inst 	: OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- 00(NON), 01(EI), 10(DI), 11(RETI)
			d_sys  		: OUT  STD_LOGIC;
			a_sys  		: OUT  STD_LOGIC;
			inta			: OUT STD_LOGIC;
			-- Excepcion
			illegal_inst	: OUT STD_LOGIC;
			protected_inst : OUT STD_LOGIC;
			calls_inst : OUT STD_LOGIC;
			-- TLB
			tlb_flush   : OUT STD_LOGIC;
			tlb_conf_en : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
			);
	END COMPONENT;
	
	COMPONENT multi IS
		PORT(
				 boot      : IN  STD_LOGIC;
				 clk       : IN  STD_LOGIC;
				 ldpc_l    : IN  STD_LOGIC;
				 wrd_l     : IN  STD_LOGIC;
				 wr_m_l    : IN  STD_LOGIC;
				 w_b       : IN  STD_LOGIC;
				 Rb_N_l 	  : IN STD_LOGIC;
				 rd_in_l   : IN STD_LOGIC;
				 wr_out_l  	: IN STD_LOGIC;
				 calls_inst_l : IN STD_LOGIC;
				 protected_inst_l : IN STD_LOGIC;
				 mem_access_l : IN STD_LOGIC;
				 -- Interrupcion regfile pins
				 is_inter_l : IN  STD_LOGIC; -- Is interrupcion input
				 intr_enable : IN STD_LOGIC;
				 -- Excepcion
				 excep_l 			: IN STD_LOGIC;
				 illegal_inst_l	: IN STD_LOGIC;
				 ldpc      : OUT STD_LOGIC;
				 wrd       : OUT STD_LOGIC;
				 wr_m      : OUT STD_LOGIC;
				 ldir      : OUT STD_LOGIC;
				 ins_dad   : OUT STD_LOGIC;
				 word_byte : OUT STD_LOGIC;
				 Rb_N	 	  : OUT STD_LOGIC;
				 rd_in			: OUT STD_LOGIC;
				 wr_out		: OUT STD_LOGIC;
				 is_inter : OUT  STD_LOGIC; -- Is interrupcion
				 excep		: OUT STD_LOGIC;
				 illegal_inst	: OUT STD_LOGIC;
				 calls_inst : OUT STD_LOGIC;
				 protected_inst : OUT STD_LOGIC;
				 mem_access : OUT STD_LOGIC;
				 is_fetch 	: OUT STD_LOGIC
				 );
	END COMPONENT;
	
	-- SIGNALS
	
	
	signal ir_reg : std_logic_vector(15 downto 0) := x"C000"; -- ir reg
	
	signal tmp_ldpc, tmp_w_b, tmp_wr_m, tmp_wrd , tmp_ldir, tmp_Rb_N, tmp_rd_in, tmp_wr_out, tmp_is_inter : std_logic;
	
	signal o_ldpc : std_logic;
	
	-- PC signals
	signal new_pc : std_logic_vector(15 downto 0) := x"0000"; -- pc reg
	signal new_br_addr_pc : std_logic_vector(15 downto 0);
	signal tmp_tknbr	: std_logic_vector(1 downto 0) := "00"; -- pc multiplexor control signal
	-- Interrupcion signals
	signal o_sys_inst : std_logic_vector(1 downto 0) := "00";
	signal o_is_inter : std_logic;
	signal tmp_intr_enable : std_logic := '0';
	-- Excepcion signal
	signal o_excep, tmp_illegal_inst, tmp_call_inst, tmp_protected, tmp_mem_access : std_logic := '0';

BEGIN
	
	-- Control_l moduel
	c0 : control_l port map(ir => ir_reg, zero_flag => zero_flag, intr => o_is_inter, excep => o_excep, alu_u => alu_u, op => op, ldpc => tmp_ldpc, wrd => tmp_wrd, 
									addr_a => addr_a, addr_b => addr_b, addr_d => addr_d, immed => immed, 
									wr_m => tmp_wr_m, in_d => in_d, immed_x2 => immed_x2, word_byte => tmp_w_b,
									Rb_N => tmp_Rb_N, tknbr => tmp_tknbr, save_pc => save_pc, rd_in => tmp_rd_in, wr_out => tmp_wr_out,
									link_pc => link_pc, is_inter => tmp_is_inter, sys_inst => o_sys_inst, d_sys => d_sys, a_sys => a_sys, inta => inta, is_store => is_store,
									illegal_inst => tmp_illegal_inst, mem_access => tmp_mem_access, protected_inst => tmp_protected, calls_inst => tmp_call_inst, tlb_flush => tlb_flush, tlb_conf_en => tlb_conf_en);
	sys_inst <= o_sys_inst; -- System interrupcion instruccion
	-- Multi module
	tmp_intr_enable <= PSW(1);
	
	m0 : multi port map(boot => boot, clk => clk, ldpc_l => tmp_ldpc, w_b => tmp_w_b, intr_enable => tmp_intr_enable, illegal_inst_l => tmp_illegal_inst, calls_inst_l => tmp_call_inst, protected_inst_l => tmp_protected, mem_access_l => tmp_mem_access,
							  wr_m_l => tmp_wr_m, wrd_l => tmp_wrd, Rb_N_l => tmp_Rb_N, rd_in_l => tmp_rd_in, wr_out_l => tmp_wr_out, 
							  is_inter_l => intr, excep_l => excep, ins_dad => ins_dad, ldir => tmp_ldir, ldpc => o_ldpc, word_byte => word_byte, 
							  wr_m => wr_m, wrd => wrd, Rb_N => Rb_N, rd_in => rd_in, wr_out => wr_out, is_inter => o_is_inter, excep => o_excep, illegal_inst => illegal_inst, calls_inst => calls_inst, protected_inst => protected_inst, mem_access => mem_access,
							  is_fetch => is_fetch); 
	
	is_inter <= tmp_is_inter; -- Interrupcion
	excep_ack <= '1' when o_excep = '1' else '0';
	new_br_addr_pc <= (14 downto 8 => ir_reg(7)) & ir_reg(7 downto 0) & '0';
	
	-- PC process
	process (clk, boot) begin
		if boot = '1' then
			new_pc <= x"C000"; -- boot reset
		elsif rising_edge(clk) then
		
			if (o_ldpc = '1') then
				if (tmp_is_inter = '1' or o_excep = '1') then -- Interrupcion
					new_pc <= alu_out; -- PC <- S5
				elsif (o_sys_inst = "11") then
					new_pc <= alu_out; -- PC <- S1
				else
					case tmp_tknbr is
						when "00"=>
							new_pc <= new_pc + 2;
						when "01" =>
							new_pc <= (new_pc + 2) + new_br_addr_pc;
						when "10" =>
							new_pc <= alu_out;
						when others =>
					end case;
				end if;
			end if;
		end if;
	end process;
	
	
	-- IR process
	process (clk, boot) begin
		if boot = '1' then
			ir_reg <= x"FFFF"; -- boot reset-> HALT
		elsif rising_edge(clk) then
			if (tmp_ldir = '1') then
				ir_reg <= datard_m;
			end if;
		end if;
	end process;
	
	pc <= new_pc;
END Structure;