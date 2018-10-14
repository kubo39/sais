import std.stdio;
import sais;

void main()
{
    auto input = "abracadabra";
    auto sa = sais.sais(input);
    writeln(sa);
    foreach (i; sa)
    {
        writeln(input[i .. $]);
    }
}
