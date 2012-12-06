--
-- Copyright (C) 2012 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.hex_util.all;

entity sdram is
	port(
		-- SDRAM interface
		ramClk_in  : in    std_logic;
		ramCmd_in  : in    std_logic_vector(2 downto 0);
		ramBank_in : in    std_logic_vector(1 downto 0);
		ramAddr_in : in    std_logic_vector(11 downto 0);
		ramData_io : inout std_logic_vector(15 downto 0)
	);
end entity;

architecture behavioural of sdram is
	constant UPPER_BOUND : natural := 4*4096*512-1;
	type MemType is array (0 to UPPER_BOUND) of std_logic_vector(15 downto 0);
	constant RAM_ACT     : std_logic_vector(2 downto 0) := "011";
	constant RAM_READ    : std_logic_vector(2 downto 0) := "101";
	constant RAM_WRITE   : std_logic_vector(2 downto 0) := "100";
begin
	-- Read process
	process
		variable addr     : std_logic_vector(22 downto 0);
		variable logLine  : line;
		variable memBlock : MemType := (others => (others => 'X'));
		variable dataWord : std_logic_vector(15 downto 0);
	begin
		loop
			ramData_io <= (others => 'Z');
			wait until ramCmd_in = RAM_ACT;
			addr(21 downto 8) := ramAddr_in & ramBank_in;
			wait until ramCmd_in = RAM_READ or ramCmd_in = RAM_WRITE;
			addr(7 downto 0) := ramAddr_in(7 downto 0);
			addr(22) := ramAddr_in(8);
			if ( ramCmd_in = RAM_READ ) then
				write(logLine, string'("Read("));
				write(logLine, from_4("0" & addr(22 downto 20)) & from_4(addr(19 downto 16)) & from_4(addr(15 downto 12)) & from_4(addr(11 downto 8)) & from_4(addr(7 downto 4)) & from_4(addr(3 downto 0)));
				write(logLine, string'("): "));
				dataWord := memBlock(to_integer(unsigned(addr)));
				write(logLine, from_4(dataWord(15 downto 12)) & from_4(dataWord(11 downto 8)) & from_4(dataWord(7 downto 4)) & from_4(dataWord(3 downto 0)));
				writeline(output, logLine);
				wait until rising_edge(ramClk_in);
				wait until rising_edge(ramClk_in);
				ramData_io <= dataWord;
				wait until rising_edge(ramClk_in);
				ramData_io <= (others => 'Z');
			else
				dataWord := ramData_io;
				memBlock(to_integer(unsigned(addr))) := dataWord;
				write(logLine, string'("Write("));
				write(logLine, from_4("0" & addr(22 downto 20)) & from_4(addr(19 downto 16)) & from_4(addr(15 downto 12)) & from_4(addr(11 downto 8)) & from_4(addr(7 downto 4)) & from_4(addr(3 downto 0)));
				write(logLine, string'("): "));
				write(logLine, from_4(dataWord(15 downto 12)) & from_4(dataWord(11 downto 8)) & from_4(dataWord(7 downto 4)) & from_4(dataWord(3 downto 0)));
				writeline(output, logLine);
			end if;
		end loop;
	end process;
end architecture;
