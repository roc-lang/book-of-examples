---
---

[Example code](https://github.com/lukewilliamboswell/roc-ansi/blob/main/examples/text-editor.roc)

## working with the terminal
- introduce [basic-cli](https://github.com/roc-lang/basic-cli) dependency
- background on the terminal
  - ANSI escape codes control the cursor and colors etc
  - Raw mode to read keypresses
- handle any errors using a tag union, and print to STDERR 
- using ANSI escape codes manually
  - clear the window
  - write out a colored "Hello World" message

## a simple TUI window
- introduce [roc-ansi](https://github.com/lukewilliamboswell/roc-ansi) dependency
- minimum code needed to create a "window" with a cursor
- handle `ESC` keypress to close and exit
- introduce `Model` and how state is passed between draws
- introduce a cursor, move it around

## read a file
- parse file path from command line arguments
- check file exists, and read contents
- parse file into `Grapheme`s (unicode text segmentation)

## display file contents
- introduce a [Piece Table](https://en.wikipedia.org/wiki/Piece_table)
- split file into lines `splitIntoLines : List Grapheme, List Grapheme, List (List Grapheme) -> List (List Grapheme)`
- draw lines of file into a viewport on the screen
- only use a single piece table in state i.e. 

```roc
fileContents: { original : List Grapheme, added : List Grapheme, table : List Entry,}
```

## text editor
- handle vertical scrolling of text in the viewport using a `lineOffset`
- map cursor position on screen to a position in the file `calculateCursorIndex : List (List Grapheme), U32, {row : I32, col : I32 }, U64 -> U64`
- keep changes between user input in state, use a `history` and `future` list to keep track of multipl piece tables
- implement CTRL-S to save file contents to disk
- implement typing to insert text
- implement CTRL-Z to undo, and CRTl-Y to redo