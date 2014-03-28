--
-- Copyright (C) 2012 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of mem_ctrl is
	type StateType is (
		-- Initialisation states
		S_INIT_WAIT,
		S_INIT_PRE,
		S_INIT_REF1,
		S_INIT_REF1_WAIT,
		S_INIT_REF2,
		S_INIT_REF2_WAIT,
		S_INIT_LMR,
		S_INIT_LMR_WAIT,

		-- Execute a write
		S_WRITE1,
		S_WRITE2,
		S_WRITE3,
		
		-- Execute a read
		S_READ1,
		S_READ2,
		S_READ3,

		-- Do a refresh operation
		S_REFRESH,
		
		-- Execute an interruptable refresh
		S_IDLE
	);
	constant RAM_NOP      : std_logic_vector(2 downto 0) := "111";
	constant RAM_ACT      : std_logic_vector(2 downto 0) := "011";
	constant RAM_READ     : std_logic_vector(2 downto 0) := "101";
	constant RAM_WRITE    : std_logic_vector(2 downto 0) := "100";
	constant RAM_PRE      : std_logic_vector(2 downto 0) := "010";
	constant RAM_REF      : std_logic_vector(2 downto 0) := "001";
	constant RAM_LMR      : std_logic_vector(2 downto 0) := "000";

	--                                                               Reserved
	--                                                              /      Write Burst Mode (0=Burst, 1=Single)
	--                                                             /      /     Reserved
	--                                                            /      /     /      Latency Mode (CL=2)
	--                                                           /      /     /      /       Burst Type (0=Sequential, 1=Interleaved)
	--                                                          /      /     /      /       /     Burst Length (1,2,4,8,X,X,X,Full)
	--                                                         /      /     /      /       /     /
	--                                                        /      /     /      /       /     /
	constant LMR_VALUE    : std_logic_vector(11 downto 0) := "00" & "1" & "00" & "010" & "0" & "000";
	signal state          : StateType := S_INIT_WAIT;
	signal state_next     : StateType;
	signal count          : unsigned(12 downto 0) := INIT_COUNT;
	signal count_next     : unsigned(12 downto 0);
	signal rowAddr        : std_logic_vector(8 downto 0) := (others => '0');
	signal rowAddr_next   : std_logic_vector(8 downto 0);
	signal bankAddr       : std_logic_vector(1 downto 0) := (others => '0');
	signal bankAddr_next  : std_logic_vector(1 downto 0);
	signal wrData         : std_logic_vector(15 downto 0) := (others => '0');
	signal wrData_next    : std_logic_vector(15 downto 0);
begin
	-- Infer registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				state <= S_INIT_WAIT;
				count <= INIT_COUNT;
				rowAddr <= (others => '0');
				bankAddr <= (others => '0');
				wrData <= (others => '0');
			else
				state <= state_next;
				count <= count_next;
				rowAddr <= rowAddr_next;
				bankAddr <= bankAddr_next;
				wrData <= wrData_next;
			end if;
		end if;
	end process;

	-- Next state logic
	process(
		state, count, mcAutoMode_in, mcCmd_in, mcAddr_in, mcData_in, rowAddr, bankAddr, wrData,
		ramData_io)
	begin
		-- Internal signal defaults
		state_next <= state;
		rowAddr_next <= rowAddr;
		bankAddr_next <= bankAddr;
		wrData_next <= wrData;
		if ( count = 0 ) then
			count_next <= count;
		else
			count_next <= count - 1;
		end if;

		-- Client interface defaults
		mcReady_out <= '0';
		mcRDV_out <= '0';
		mcData_out <= (others => 'X');

		-- SDRAM interface defaults
		ramCmd_out <= RAM_NOP;
		ramBank_out <= (others => 'X');
		ramAddr_out <= (others => 'X');
		ramData_io  <= (others => 'Z');
		
		case state is
			----------------------------------------------------------------------------------------
			-- The init sequence: 4800 NOPs, PRE all, 2xREF, & LMR
			----------------------------------------------------------------------------------------

			-- Issue NOPs until the count hits the threshold
			when S_INIT_WAIT =>
				if ( count = 0 ) then
					state_next <= S_INIT_PRE;
				end if;

			-- Issue a PRECHARGE command to all banks
			when S_INIT_PRE =>
				state_next <= S_INIT_REF1;
				ramCmd_out <= RAM_PRE;
				ramAddr_out(10) <= '1';  -- A10=1: Precharge all banks

			-- Issue a refresh command. Must wait 63ns (four clocks, conservatively)
			when S_INIT_REF1 =>
				state_next <= S_INIT_REF1_WAIT;
				ramCmd_out <= RAM_REF;
				count_next <= REFRESH_LENGTH;
			when S_INIT_REF1_WAIT =>  -- Three NOPs
				if ( count = 0 ) then
					state_next <= S_INIT_REF2;
				end if;

			-- Issue a refresh command. Must wait 63ns (four clocks, conservatively)
			when S_INIT_REF2 =>
				state_next <= S_INIT_REF2_WAIT;
				ramCmd_out <= RAM_REF;
				count_next <= REFRESH_LENGTH;
			when S_INIT_REF2_WAIT =>  -- Three NOPs
				if ( count = 0 ) then
					state_next <= S_INIT_LMR;
				end if;

			-- Issue a Load Mode Register command. Must wait tMRD (two clocks).
			when S_INIT_LMR =>
				state_next <= S_INIT_LMR_WAIT;
				ramCmd_out <= RAM_LMR;
				ramAddr_out <= LMR_VALUE;
			when S_INIT_LMR_WAIT =>
				count_next <= REFRESH_DELAY;
				state_next <= S_IDLE;

			-------------------------------------------------------------------------------------------
			-- Do a write
			-------------------------------------------------------------------------------------------

			when S_WRITE1 =>
				state_next <= S_WRITE2;
				ramCmd_out <= RAM_WRITE;
				ramData_io <= wrData;
				ramBank_out <= bankAddr;
				ramAddr_out <= "000" & rowAddr;

			when S_WRITE2 =>
				state_next <= S_WRITE3;

			when S_WRITE3 =>
				ramCmd_out <= RAM_PRE;
				ramAddr_out(10) <= '1';  -- A10=1: Precharge all banks
				state_next <= S_IDLE;
				
			-------------------------------------------------------------------------------------------
			-- Do a read
			-------------------------------------------------------------------------------------------

			when S_READ1 =>
				state_next <= S_READ2;
				ramCmd_out <= RAM_READ;
				ramBank_out <= bankAddr;
				ramAddr_out <= "000" & rowAddr;  -- no auto precharge

			when S_READ2 =>
				state_next <= S_READ3;

			when S_READ3 =>
				ramCmd_out <= RAM_PRE;
				ramAddr_out(10) <= '1';  -- A10=1: Precharge all banks
				mcData_out <= ramData_io;
				mcRDV_out <= '1';
				state_next <= S_IDLE;

			-------------------------------------------------------------------------------------------
			-- Refresh
			-------------------------------------------------------------------------------------------

			when S_REFRESH =>
				if ( count = 0 ) then
					state_next <= S_IDLE;
					count_next <= REFRESH_DELAY;
				end if;
				
			-------------------------------------------------------------------------------------------
			-- S_IDLE, etc
			-------------------------------------------------------------------------------------------
			when others =>
				if ( count = 0 and mcAutoMode_in = '1' ) then
					state_next <= S_REFRESH;
					ramCmd_out <= RAM_REF;
					count_next <= REFRESH_LENGTH;
				else
					mcReady_out <= '1';
					case mcCmd_in is
						when MC_REF =>
							state_next <= S_REFRESH;
							ramCmd_out <= RAM_REF;
							count_next <= REFRESH_LENGTH;

						when MC_RD =>
							state_next <= S_READ1;
							ramCmd_out <= RAM_ACT;
							ramAddr_out <= mcAddr_in(21 downto 10);
							ramBank_out <= mcAddr_in(9 downto 8);
							rowAddr_next <= mcAddr_in(22) & mcAddr_in(7 downto 0);
							bankAddr_next <= mcAddr_in(9 downto 8);
							
						when MC_WR =>
							state_next <= S_WRITE1;
							ramCmd_out <= RAM_ACT;
							ramAddr_out <= mcAddr_in(21 downto 10);
							ramBank_out <= mcAddr_in(9 downto 8);
							rowAddr_next <= mcAddr_in(22) & mcAddr_in(7 downto 0);
							bankAddr_next <= mcAddr_in(9 downto 8);
							wrData_next <= mcData_in;
							
						when others =>
							null;
					end case;
				end if;
		end case;
	end process;

	-- Don't mask anything
	ramLDQM_out <= '0';
	ramUDQM_out <= '0';
	
end architecture;
