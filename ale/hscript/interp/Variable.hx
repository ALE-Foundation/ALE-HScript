package ale.hscript.interp;

import ale.hscript.parser.Property;

typedef Variable = {
    value:Dynamic,
    getter:Property,
    setter:Property
}