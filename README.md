
Pascal Star Fighter
=========

A simple DOS Star Fighter game which I created as a final assignment in the introductory course of programming during the first semester at the uni. It was written in the prehistoric Borland Pascal IDE with blue background, white characters, great debugger and window of 80 characters!

## Code and compilation and running

See the [`ZAPOCTAK.PAS`](https://github.com/Tomiinek/PascalStarFighter/tree/master/ZAPOCTAK.PAS) file. Everything is written in this ultra-long file. Comments are in Czech :sob: which is something like Klingon language. 

Use DOSBox and Borland Pascal compiler v7.0 to compile and run the program. Two additional libraries for handling time and keyboard input are needed - `TIME.PAS` and `KEYBOARD.PAS` (original files available [here](https://github.com/Spekkio/Knight)). You can use precompiled libraries `TIME.TPU` and `KEYBOARD.TPU`.

## Gameplay

[![YOUTUBE_VIDEO](_img/video_thumbnail.png)](https://youtu.be/5rm_J-ofoT0)

## Troubleshooting

You may have a problem with the `Runtime error 200` (division by zero). It is a caused by a well-known bug of the CRT library and you should patch the errorneous executable file with PatchCRT or TPPatch.
