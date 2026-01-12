library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package start_screen_pkg is

    constant START_TEXT_COLOR : std_logic_vector(11 downto 0) := X"FFF"; -- White
    constant START_PACMAN_COLOR : std_logic_vector(11 downto 0) := X"FF0"; -- Yellow
    constant START_BORDER_COLOR : std_logic_vector(11 downto 0) := X"00F"; -- Blue
    constant START_BACKGROUND_COLOR : std_logic_vector(11 downto 0) := X"000"; -- Black

    constant START_TEXT_WIDTH : integer := 320;
    constant START_TEXT_HEIGHT : integer := 80;
    constant START_CHAR_WIDTH : integer := 20;
    constant START_CHAR_HEIGHT : integer := 20;

    constant ANIMATION_SPEED : integer := 5000000;
    constant ANIMATION_FRAMES : integer := 8;

    constant PACMAN_TEXT_ROW : integer := 120;
    constant PACMAN_TEXT_COL : integer := 160;
    constant INSTRUCTION_TEXT_ROW : integer := 300;
    constant INSTRUCTION_TEXT_COL : integer := 200;
end package start_screen_pkg;

package body start_screen_pkg is
end package body start_screen_pkg;