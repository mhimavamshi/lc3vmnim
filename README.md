# LC3 VM

I read the reference, [Write your Own Virtual Machine, By: Justin Meiners and Ryan Pendleton](https://www.jmeiners.com/lc3-vm/) to implement a LC3 VM in [nim](https://nim-lang.org/) programming language.

## Requirements
Install both `nim` compiler and `nimble` package manager.

## Usage
1. Build the binary
```bash
nimble build # to build the lc3vmnim binary
```
2. Use it
```bash
./lc3vmnim [image-file1.obj] [image-file2.obj] ... # all will be loaded into memory and written, as per origin
```
Use `Ctrl+C` to interrupt to exit.

## Demonstration
You can download this "image file" or .obj file: [2048.obj](https://www.jmeiners.com/lc3-vm/supplies/2048.obj) and run it, to get started quickly.

```bash
$ ./lc3vmnim 2048.obj 
```