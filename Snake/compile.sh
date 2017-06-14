#!/bin/sh

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p compiled

rm "compiled/$1.bin"
rm "compiled/$1.flp"
rm "$1.iso"

nasm -f bin -o "compiled/$1.bin" "$1.asm" -w+all
cp "base.flp" "compiled/$1.flp"
dd status=noxfer conv=notrunc if="compiled/$1.bin" of="compiled/$1.flp"
mkisofs -o "$1.iso" -b "$1.flp" "$dir/compiled"