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
use ieee.std_logic_textio.all;
use std.textio.all;
use work.hex_util.all;
use work.mem_ctrl_pkg.all;

entity mem_ctrl_tb is
end entity;

architecture behavioural of mem_ctrl_tb is
	-- Clocks
	signal intClk     : std_logic;  -- main system clock
	signal extClk     : std_logic;  -- display version of intClk, which transitions 4ns before it
	signal reset      : std_logic;

	-- Client interface
	signal mcAutoMode : std_logic;
	signal mcCmd      : MCCmdType;
	signal mcAddr     : std_logic_vector(22 downto 0);
	signal mcDataRd   : std_logic_vector(15 downto 0);
	signal mcDataWr   : std_logic_vector(15 downto 0);
	signal mcRDV      : std_logic;
	signal mcReady    : std_logic;

	-- SDRAM signals
	signal ramCmd     : std_logic_vector(2 downto 0);
	signal ramBank    : std_logic_vector(1 downto 0);
	signal ramAddr    : std_logic_vector(11 downto 0);
	signal ramDataIO  : std_logic_vector(15 downto 0);
	signal ramLDQM    : std_logic;
	signal ramUDQM    : std_logic;
begin
	-- Instantiate the memory controller for testing
	uut: entity work.mem_ctrl
		generic map(
			INIT_COUNT     => "0" & x"004",  --\
			REFRESH_DELAY  => "0" & x"010",  -- Much longer in real hardware!
			REFRESH_LENGTH => "0" & x"005"   --/
		)
		port map(
			clk_in        => intClk,
			reset_in      => reset,

			-- Client interface
			mcAutoMode_in => mcAutoMode,
			mcCmd_in      => mcCmd,
			mcAddr_in     => mcAddr,
			mcData_out    => mcDataRd,
			mcData_in     => mcDataWr,
			mcRDV_out     => mcRDV,
			mcReady_out   => mcReady,

			-- SDRAM interface
			ramCmd_out    => ramCmd,
			ramBank_out   => ramBank,
			ramAddr_out   => ramAddr,
			ramData_io    => ramDataIO,
			ramLDQM_out   => ramLDQM,
			ramUDQM_out   => ramUDQM
		);

	-- Instantiate the SDRAM model for testing
	sdram_model: entity work.sdram_model
		port map(
			ramClk_in  => extClk,
			ramCmd_in  => ramCmd,
			ramBank_in => ramBank,
			ramAddr_in => ramAddr,
			ramData_io => ramDataIO
		);

	-- Drive the internal clock.
	process
	begin
		intClk <= '0';
		loop
			wait for 6.944 ns;
			intClk <= not(intClk);
		end loop;
	end process;
	
	-- Drive the external clock.
	process
	begin
		extClk <= '0';
		wait for 10.416 ns; -- 3/4
		wait for 1.771 ns;
		loop
			wait for 6.944 ns;
			extClk <= not(extClk);
		end loop;
	end process;
	

	-- Deassert the synchronous reset a couple of cycles after startup.
	--
	process
	begin
		reset <= '1';
		wait until rising_edge(intClk);
		wait until rising_edge(intClk);
		reset <= '0';
		wait;
	end process;

	-- Drive the unit under test. Read stimulus from stimulus.sim and write results to results.sim
	process
		variable inLine  : line;
		variable outLine : line;
		file inFile      : text open read_mode is "stimulus.sim";
		file outFile     : text open write_mode is "results.sim";
		function to_mcCmd(c : character) return MCCmdType is begin
			case c is
				when 'R' =>
					return MC_RD;
				when 'W' =>
					return MC_WR;
				when '*' =>
					return MC_REF;
				when others =>
					return MC_NOP;
			end case;
		end function;
		function from_mcCmd(cmd : MCCmdType) return string is begin
			case cmd is
				when MC_RD =>
					return "RD ";
				when MC_WR =>
					return "WR ";
				when MC_REF =>
					return "REF";
				when MC_NOP =>
					return "NOP";
				when others =>
					return "ILL";
			end case;
		end function;
		function from_ramCmd(cmd : std_logic_vector(2 downto 0)) return string is begin
			case cmd is
				when "000" =>
					return "LMR";
				when "001" =>
					return "REF";
				when "010" =>
					return "PRE";
				when "011" =>
					return "ACT";
				when "100" =>
					return "WR ";
				when "101" =>
					return "RD ";
				when "111" =>
					return "NOP";
				when others =>
					return "ILL";
			end case;
		end function;
	begin
		mcAutoMode <= '1';
		mcCmd <= MC_NOP;
		mcAddr <= (others => 'X');
		mcDataWr <= (others => 'X');
		wait until falling_edge(reset);
		wait until rising_edge(intClk);
		while ( not endfile(inFile) ) loop
			readline(inFile, inLine);
			while ( inLine.all'length = 0 or inLine.all(1) = '#' or inLine.all(1) = ht or inLine.all(1) = ' ' ) loop
				readline(inFile, inLine);
			end loop;
			mcAutoMode <= to_1(inLine.all(1));
			mcCmd <= to_mcCmd(inLine.all(3));
			mcAddr <= to_3(inLine.all(5)) & to_4(inLine.all(6)) & to_4(inLine.all(7)) & to_4(inLine.all(8)) & to_4(inLine.all(9)) & to_4(inLine.all(10));
			mcDataWr <= to_4(inLine.all(12)) & to_4(inLine.all(13)) & to_4(inLine.all(14)) & to_4(inLine.all(15));
			wait until falling_edge(intClk);
			write(outLine, mcAutoMode);
			write(outLine, ' ');
			write(outLine, mcReady);
			write(outLine, ' ');
			write(outLine, from_mcCmd(mcCmd));
			write(outLine, ' ');
			write(outLine, mcAddr(22 downto 20));
			write(outLine, ':');
			write(outLine, from_4(mcAddr(19 downto 16)) & from_4(mcAddr(15 downto 12)) & from_4(mcAddr(11 downto 8)) & from_4(mcAddr(7 downto 4)) & from_4(mcAddr(3 downto 0)));
			write(outLine, ' ');
			write(outLine, from_4(mcDataWr(15 downto 12)) & from_4(mcDataWr(11 downto 8)) & from_4(mcDataWr(7 downto 4)) & from_4(mcDataWr(3 downto 0)));
			write(outLine, ' ');
			write(outLine, from_4(mcDataRd(15 downto 12)) & from_4(mcDataRd(11 downto 8)) & from_4(mcDataRd(7 downto 4)) & from_4(mcDataRd(3 downto 0)));
			write(outLine, ' ');
			write(outLine, mcRDV);
			write(outLine, ' ');
			write(outLine, '|');
			write(outLine, ' ');
			write(outLine, from_ramCmd(ramCmd));
			write(outLine, ' ');
			write(outLine, ramBank);
			write(outLine, ' ');
			write(outLine, ramAddr(11 downto 8));
			write(outLine, ':');
			write(outLine, from_4(ramAddr(7 downto 4)) & from_4(ramAddr(3 downto 0)));
			write(outLine, ' ');
			write(outLine, from_4(ramDataIO(15 downto 12)) & from_4(ramDataIO(11 downto 8)) & from_4(ramDataIO(7 downto 4)) & from_4(ramDataIO(3 downto 0)));
			writeline(outFile, outLine);
			wait until rising_edge(intClk);
		end loop;
		mcAutoMode <= '1';
		mcCmd <= MC_NOP;
		mcAddr <= (others => 'X');
		mcDataWr <= (others => 'X');
		wait;
	end process;
end architecture;
