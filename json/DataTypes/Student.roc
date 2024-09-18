module [Student, Module]
 
Student : [
    CurrentStudent {
        name : Str,
        modules : List (Module),
        grade : U64
    }, 
    GraduatedStudent {
        name : Str,
        modules : List (Module),
        grade : U64
    }
]

Module : {
    name : Str,
    credits : U64,
    enrolled : Bool
}