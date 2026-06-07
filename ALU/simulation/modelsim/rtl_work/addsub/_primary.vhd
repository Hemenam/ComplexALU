library verilog;
use verilog.vl_types.all;
entity addsub is
    port(
        x               : in     vl_logic_vector(7 downto 0);
        y               : in     vl_logic_vector(7 downto 0);
        op              : in     vl_logic;
        s               : out    vl_logic_vector(7 downto 0)
    );
end addsub;
