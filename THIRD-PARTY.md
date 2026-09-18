# Third-party notices

PDF Order redistributes the following component. Its licence text is reproduced
in full below and must travel with any copy of this software, including the
compiled `.exe`, which carries the library embedded inside it.

---

## PDFsharp 1.50.5147

- Author: empira Software GmbH, Cologne Area (Germany)
- Copyright: Copyright (c) 2005-2019 empira Software GmbH
- Project: http://www.pdfsharp.net/
- Package: https://www.nuget.org/packages/PDFsharp/1.50.5147
- Licence: MIT

PDFsharp does all of the actual PDF reading and writing in this app. PowerShell
has no PDF engine of its own.

The library is **not** committed to this repository. `build\build.ps1` downloads
the official NuGet package at build time, caches the assembly in `build\lib\`,
and inlines it as base64 into a temporary copy of the script so that the shipped
`.exe` remains a single self-contained file.

### MIT License

```
Copyright (c) 2005-2019 empira Software GmbH, Cologne Area (Germany)

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

---

## PS2EXE

The `.exe` is produced with [PS2EXE](https://github.com/MScholtes/PS2EXE) by
Markus Scholtes (originally by Ingo Karstein), MIT licensed. It is a build-time
tool only — no PS2EXE code is redistributed here beyond the standard launcher
stub it generates.
