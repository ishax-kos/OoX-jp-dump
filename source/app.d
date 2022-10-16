import std.stdio;
import std.algorithm;
import std.array;
import std.mmfile;

enum offsets_start  = 0x71CC8;
enum data_start     = 0x73382;
enum data_end       = 0x7C7BC;


void main() {
    ushort[] offsets;
    char[] table_data;
    {
        File f = File("raw/en_oos.gbc", "rb");
        offsets    = f.array_from_file!(ushort, offsets_start, data_start);//.sort().array;
        table_data = f.array_from_file!(char,   data_start,    data_end  );
        f.close();
    }

    File output_file = File("info.txt", "wb");

    foreach(index, o; offsets[1..$]) {
        char[] text = [];
        auto j = o;
        while (table_data[j] != '\0') {
            j += 1;
            text = table_data[o..j];
        }
        output_file.writefln("$%X:\n%s\n", index, text);
    }
    writefln("File has been dumped to \"%s\".", output_file.name);
}


auto array_from_file(E, size_t start, size_t stop)(ref File file) {
    static assert(stop > start);
    enum section_size = stop-start;
    static assert(section_size%E.sizeof == 0);

    E[] output_array = new E[section_size/E.sizeof];
    file.seek(start);
    output_array = file.rawRead!E(output_array);
    return output_array;
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
