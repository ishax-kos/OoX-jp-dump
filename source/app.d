import std.stdio;
import std.algorithm;
import std.array;

/// Put game information in a folder called "raw"
// enum START = 0x07_3382;

void main() {
    ushort[] offsets = get_offsets_0x73382_isolated();
    char[] table_data = get_data_0x73382_isolated();

    File output_file = File("info.txt", "wb");


    foreach(ch, o; offsets) {
        char[] text = [];
        auto i = o;
        while (table_data[i] != '\0') {
            i += 1;
            text = table_data[o..i];
        }
        output_file.writefln("$%X:\n%s\n", i, text);
    }
}



/++ 
    Get the offsets that precedes the data at 0x73382
    which have been pulled out into a separate file.
+/
ushort[] get_offsets_0x73382_isolated() {
    File offsets_file = File("raw/table offsets 0x73382.dat", "rb");
    ushort[] offsets = new ushort[offsets_file.size/2];
    offsets = offsets_file.rawRead!ushort(offsets);
    offsets_file.close();
    return offsets.sort().array;
}


/++ 
    Get the string data at 0x73382
    which has been pulled out into a separate file.
+/
char[] get_data_0x73382_isolated() {
    File table_file = File("raw/table data 0x73382.dat", "rb");
    char[] table_data = new char[table_file.size];
    table_data = table_file.rawRead(table_data);
    table_file.close();
    return table_data;
}