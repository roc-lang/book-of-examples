# Goals of chapter
I want to show a scale model of how you could JSON decoding (and encoding) in Roc. Doing so will demonstrate using tag unions for modelling your data, pattern matching, function reuse and how to build a small Codec libary.

[This article](https://dev.to/matthewsj/you-could-have-designed-the-jsondecode-library-2d8) was a great help in thinking about how to teach people these concepts. 

# Code Structure
`Student.roc` this is my domain data type of what I want to decode into.

`JsonData.roc` this is my ADT for JSON. I have purposefully not made it an accurate representation of the JSON data type as it adds a lot of noise for not much gain. 

`DecodeStudentLong.roc` is the verbose version of a JSON decoder where the error handling code and other boilerplate-y code is all tangled up in the business logic. The purpose of it is to highlight lots of the repeated code, so then we can refactor out patterns that we spot. 

`Decoding.roc` this is the meat of what I want to show. I have deocders for my `Json` to `a`, along with some helper functions. Still to do would be a decoder for Sum types and Product types (see below for more). 

`DecodeStudent.roc` is the final, much simpler Student decoder, which utilises the `Decoding.roc` code. 

`Encoding.roc` this is still a work in progress, and isn't going to be included in my talk, but hopefully the chapter (possibly starting with it as it is a simpler thing to get your head around).

`json/main.roc` here I test both my verbose and simple decoders for `Student`

### TODOs
`sumDecoder` - I am thinking passing in a list of `JsonDecoder a`, where `a` is the super type, and trying each of them till one is successful

`productDecoder` - I think for this a `List (Str JsonDecoder a)` would make sense as an input, where each item in the list is the field name and the Json Decoder respectively. But not sure how I can build a record from that and/or how to handle an error if one of the decoders fails.

