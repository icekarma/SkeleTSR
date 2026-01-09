# SkeleTSR: A skeleton TSR for MS-DOS/PC DOS.

SkeleTSR is a minimalistic Terminate and Stay Resident (TSR) program designed
for the MS-DOS and PC DOS environment. It serves as a foundational template for
developers looking to create their own TSR applications.

## Features

- Minimalistic design for easy customization.
- Basic framework for TSR functionality.
- Written in assembly language for ease of access to low-level functionality.

## Requirements

- One of the following assemblers:
  - Borland Turbo Assembler 4.1
  - Microsoft Macro Assembler 6.11
  - JWasm 2.11
- One of the following Make utilities:
  - Borland Make
  - Microsoft NMake

Support for OpenWatcom WMake will probably be forthcoming. Support for
OpenWatcom WASM will probably not be forthcoming, as its syntax seems to be
quite different from MASM, and I am having trouble locating documentation for
it.

## Getting Started

To use SkeleTSR as a base for your own TSR, follow these steps.

1. Clone the repository:
   ```
   git clone https://github.com/icekarma/SkeleTSR.git
   ```

2. Edit the appropriate Makefile to set the user-configurable options:
   Makefile.b for TASM, and Makefile.m for MASM and JWasm.

   - BUILDTYPE: `debug` or `release`. In a debug build, _DEBUG is defined, and
     the assembler and linker are instructed to generate debug information. In
     a release build, NDEBUG is defined, and no debug information is
     generated.
   - BROWSEINFO: `yes` or `no`. If set to `yes`, MASM (only) is instructed to
     generate browse information, and `BSCMAKE` is invoked to generate a .BSC
     file. Only meaningful when BUILDTYPE is `debug` and ASSEMBLER is `masm`.
   - ASSEMBLER: `masm` or `jwasm`. Specifies the assembler to use.
   - LINKER: `link`. Specifies the linker to use. (Support for other linkers is
     forthcoming.)

3. Modify the source code to implement your desired functionality.

4. Build the TSR with Make. Two Makefiles have been provided: Makefile.b for
   Borland MAKE, and Makefile.m for Microsoft NMAKE.

   Borland:

     `make -f Makefile.b`

   Microsoft:

     `nmake -f Makefile.m`

5. Test your TSR.

## License

SkeleTSR is released under the 2-Clause "Simplified" BSD License. A copy of
this license can be found in the LICENSE.txt file in this repository.

Feel free to use and modify SkeleTSR for your own projects, and consider
contributing back interesting or novel changes!

## Contributing

Contributions are welcome! If you have suggestions or improvements, please open
an issue or submit a pull request.
