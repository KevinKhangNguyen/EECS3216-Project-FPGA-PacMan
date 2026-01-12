library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package mapping_pkg is
  subtype mapping_int is integer;
  type row_array is array (0 to 4) of mapping_int;
  type col_array is array (0 to 5) of mapping_int;
  
  constant row_mapping : row_array := (6, 18, 30, 42, 53);
  constant col_mapping : col_array := (12, 23, 34, 46, 57, 68);
end Mapping_Pkg;

package body mapping_pkg is
end mapping_pkg;
