include <BOSL2/std.scad>
include <BOSL2/strings.scad>


// Parse a string containing vectors of any length into a list of vectors
function parse_vector_list(str) = (
    let(cleaned = str_replace_char(str, " ", ""))
    let(vector_strings = str_split(cleaned, "[", keep_nulls=false))
    [for (vec_str = vector_strings) each [parse_vector(vec_str)]]
);

// Parse a single vector string (e.g., "[1,2]") into a vector
function parse_vector(vec_str) = (
    let(cleaned = str_replace_char(vec_str, "]", ""))
    let(coords = str_split(cleaned, ",", keep_nulls=false))
    [for (coord = coords) parse_num(coord)]
);
