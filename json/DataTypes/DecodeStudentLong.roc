module [readJson]

import JsonData exposing [Json]
import Student exposing [Student, Module]
import Decoding exposing [typeToStr, DecodingErrors]

Students : List Student

readJson : Json -> Result Students DecodingErrors
readJson = \json ->
    when json is
        Object obj ->
            when Dict.get obj "students" is
                Ok students -> readStudents students
                Err KeyNotFound -> Err (FieldNotFound "students")

        _ -> Err (WrongJsonType "$(typeToStr json)")

readStudents : Json -> Result Students DecodingErrors
readStudents = \json ->
    when json is
        Array students ->
            List.mapTry students readStudent

        _ -> Err (WrongJsonType "$(typeToStr json)")

readStudent : Json -> Result Student DecodingErrors
readStudent = \json ->
    when json is
        Object obj ->
            when Dict.get obj "name" is
                Ok (String name) ->
                    when Dict.get obj "modules" is
                        Ok moduleArr ->
                            when readModules moduleArr is
                                Ok modules ->
                                    when Dict.get obj "grade" is
                                        Ok (Number grade) ->
                                            when Dict.get obj "#type" is
                                                Ok (String "currentStudent") -> Ok (CurrentStudent { name, modules, grade })
                                                Ok (String "graduatedStudent") -> Ok (GraduatedStudent { name, modules, grade })
                                                _ -> Err (FieldNotFound "#type")

                                        _ -> Err (FieldNotFound "grade")

                                Err e -> Err e

                        _ -> Err (FieldNotFound "modules")

                _ -> Err (FieldNotFound "name")

        _ -> Err (WrongJsonType "$(typeToStr json)")

readModules : Json -> Result (List Module) DecodingErrors
readModules = \json ->
    when json is
        Array modules ->
            List.mapTry modules readModule

        _ -> Err (WrongJsonType "$(typeToStr json)")

readModule : Json -> Result Module DecodingErrors
readModule = \json ->
    when json is
        Object fields ->
            when Dict.get fields "name" is
                Ok (String name) ->
                    when Dict.get fields "credits" is
                        Ok (Number credits) ->
                            when Dict.get fields "enrolled" is
                                Ok (Boolean enrolled) ->
                                    Ok ({ name, credits, enrolled })

                                _ -> Err (FieldNotFound "enrolled")

                        _ -> Err (FieldNotFound "credits")

                _ -> Err (FieldNotFound "name")

        _ -> Err (WrongJsonType "$(typeToStr json)")
