module sais;

import std.algorithm;
import std.array;
import std.conv : to;
import std.range;

enum SuffixType
{
    S,
    L,
    LMS,
}

SuffixType inheritSuffixType(SuffixType type)
{
    switch (type)
    {
    case SuffixType.LMS:
        return SuffixType.S;
    default:
        return type;
    }
    assert(false);
}

void suffixTypesFromText(uint[] input, SuffixType[] types)
{
    auto chars = input.enumerate.array.retro;
    auto lastCharWithIndex = chars.front;
    chars.popFront;

    auto lasti = lastCharWithIndex[0];
    auto lastc = lastCharWithIndex[1];

    types[lasti] = SuffixType.L;
    foreach (i, c; chars)
    {
        if (c < lastc)
            types[i] = SuffixType.S;
        else if (c > lastc)
            types[i] = SuffixType.L;
        else
            types[i] = inheritSuffixType(types[lasti]);
        if (types[i] == SuffixType.L && types[lasti] == SuffixType.S)
            types[lasti] = SuffixType.LMS;
        lastc = c;
        lasti = i;
    }
}

class Bins
{
    uint[] alphas;  // テキスト内に出現する文字の集合
    uint[] sizes;   // 各文字につき何度出現したか
    uint[] ptrs;    // バケットを管理するための配列

    this()
    {
        this.sizes = new uint[10_000]; // usize.maxは大きすぎるのでとりあえず
    }

    // alphasとsizesの更新, ptrsの初期化
    void findSizes(uint[] chars)
    {
        foreach (c; chars)
        {
            this.incSize(c);
            // first appeared.
            if (this.sizes[c] == 1)
            {
                this.alphas ~= c;
            }
        }
        this.alphas.sort();

        auto ptrsLen = this.alphas[this.alphas.length - 1] + 1;
        this.ptrs = new uint[ptrsLen];
    }

    void findHeadPointers()
    {
        uint sum = 0;
        foreach (c; this.alphas)
        {
            this.ptrs[c] = sum;
            sum += this.sizes[c];
        }
    }

    void findTailPointers()
    {
        uint sum = 0;
        foreach (c; this.alphas)
        {
            sum += this.sizes[c];
            this.ptrs[c] = sum - 1;
        }
    }

    // バケットの一番上の空きに格納
    void headInsert(uint[] sa, uint i, uint c)
    {
        auto ptr = &this.ptrs[c];
        sa[*ptr] = i;
        ++*ptr;
    }

    // バケットの一番下の空きに格納
    void tailInsert(uint[] sa, uint i, uint c)
    {
        auto ptr = &this.ptrs[c];
        sa[*ptr] = i;
        if (*ptr > 0)
            --*ptr;
    }

    // 文字の出現回数の更新
    void incSize(uint c)
    {
        if (c > this.sizes.length)
            this.sizes.length = 1 + c;
        this.sizes[c]++;
    }
}

uint[] sais(string text)
{
    uint[] input = text.map!(c => c.to!uint).array;
    auto sa = new uint[input.length];

    // L/S/LMS の配列を作る
    auto types = new SuffixType[input.length];
    suffixTypesFromText(input, types);

    auto bins = new Bins();
    bins.findSizes(input);  // 出現する文字とその回数を記憶
    bins.findTailPointers();

    // LMSをSuffix Arrayの表に入れる
    foreach (uint i, c; input)
    {
        if (types[i] == SuffixType.LMS)
            bins.tailInsert(sa, i, c);
    }

    bins.findHeadPointers();

    // L-type の位置を決定
    auto lasti = input.length.to!uint - 1;
    auto lastc = input[lasti];
    if (types[lasti] == SuffixType.L)
        bins.headInsert(sa, lasti, lastc);
    foreach (i; sa)
    {
        if (i == 0)
            continue;

        lasti = i - 1;
        lastc = input[lasti];
        if (types[lasti] == SuffixType.L)
            bins.headInsert(sa, lasti, lastc);
    }

    bins.findTailPointers();

    // S-typeの位置を決定
    foreach_reverse (i; sa)
    {
        if (i == 0)
            continue;

        lasti = i - 1;
        lastc = input[lasti];
        if (types[lasti] == SuffixType.S || types[lasti] == SuffixType.LMS)
            bins.tailInsert(sa, lasti, lastc);
    }
    return sa;
}
