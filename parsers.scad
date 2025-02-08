include <BOSL2/std.scad>


// Parse a string containing 2-vectors into a list of 2-vectors
function parse_vector_list(str) = (
    let(cleaned = str_replace_char(str, " ", ""))
    let(vector_strings = str_split(cleaned, "[", keep_nulls=false))
    [for (vec_str = vector_strings) each [parse_vector(vec_str)]]
);

// Parse a single vector string (e.g., "[1,2]") into a 2-vector
function parse_vector(vec_str) = (
    let(cleaned = str_replace_char(vec_str, "]", ""))
    let(coords = str_split(cleaned, ",", keep_nulls=false))
    len(coords) == 2 ? [parse_int(coords[0]), parse_int(coords[1])] : undef
);
