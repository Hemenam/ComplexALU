library verilog;
use verilog.vl_types.all;
entity mul is
    port(
        x               : in     vl_logic_vector(7 downto 0);
        y               : in     vl_logic_vector(7 downto 0);
        p               : out    vl_logic_vector(7 downto 0)
    );
end mul;
