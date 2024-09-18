module [readStudents]

import Student exposing [Student, Module]
import Decoding exposing [JsonDecoder, array, field, string, number, bool, map2, map3, or, oneOf, tag]

Students : List Student
Modules : List Module

readStudents : JsonDecoder Students
readStudents = \json ->
    studentsDecoder = array readStudent
    (field "students" studentsDecoder) json

readStudent : JsonDecoder Student
readStudent = \json ->
    nameField = field "name" string
    gradeField = field "grade" number
    currentStudent = map3 nameField readModules gradeField 
        \name, modules, grade -> CurrentStudent { name, modules, grade }
    graduatedStudent = map3 nameField readModules gradeField 
        \name, modules, grade -> GraduatedStudent { name, modules, grade }
    studentDecoders = 
        Dict.empty {}
        |> Dict.insert "currentStudent" currentStudent 
        |> Dict.insert "graduatedStudent" graduatedStudent 
    (tag studentDecoders) json

readModules : JsonDecoder Modules
readModules = \json -> 
    modulesDecoder = array readModule
    (field "modules" modulesDecoder) json

readModule : JsonDecoder Module
readModule = \json ->
    nameField = field "name" string
    creditsField = field "credits" number
    enrolledField = field "enrolled" bool
    f = \name, credits, enrolled -> { name, credits, enrolled }
    module = map3 nameField creditsField enrolledField f 
    module json