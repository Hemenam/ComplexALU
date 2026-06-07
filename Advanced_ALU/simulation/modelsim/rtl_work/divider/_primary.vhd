library verilog;
use verilog.vl_types.all;
entity divider is
    port(
        n               : in     vl_logic_vector(7 downto 0);
        d               : in     vl_logic_vector(7 downto 0);
        q               : out    vl_logic_vector(7 downto 0)
    );
end divider;
