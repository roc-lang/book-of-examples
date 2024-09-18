app [main] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br",
    jd: "DataTypes/main.roc",
}
import "DataTypes/StudentData.json" as students : Str
import pf.Stdout
import pf.Task
import jd.DecodeStudent
import jd.DecodeStudentLong

main =
    Stdout.line! students

expect DecodeStudent.readStudents input == Ok expected
expect DecodeStudentLong.readJson input == Ok expected
# expected Student output
expected = [
    CurrentStudent {
        name: "Amy",
        modules: [{ name: "Maths 101", credits: 200, enrolled: Bool.true }, { name: "Physics 101", credits: 100, enrolled: Bool.false }],
        grade: 75,
    },
    GraduatedStudent {
        name: "John",
        modules: [{ name: "Maths 101", credits: 200, enrolled: Bool.true }],
        grade: 65,
    },
]

# JsonData representation for input
input = Object (Dict.single "students" (Array [amyObj, johnObj]))
amyObj =
    Dict.empty {}
    |> Dict.insert "name" (String "Amy")
    |> Dict.insert "modules" (amyMods)
    |> Dict.insert "grade" (Number 75)
    |> Dict.insert "#type" (String "currentStudent")
    |> Object
johnObj =
    Dict.empty {}
    |> Dict.insert "name" (String "John")
    |> Dict.insert "modules" (johnMod)
    |> Dict.insert "grade" (Number 65)
    |> Dict.insert "#type" (String "graduatedStudent")
    |> Object
amyMods = Array [mathsMod, physicsMod]
johnMod = Array [mathsMod]

mathsMod =
    Dict.empty {}
    |> Dict.insert "name" (String "Maths 101")
    |> Dict.insert "credits" (Number 200)
    |> Dict.insert "enrolled" (Boolean Bool.true)
    |> Object
physicsMod =
    Dict.empty {}
    |> Dict.insert "name" (String "Physics 101")
    |> Dict.insert "credits" (Number 100)
    |> Dict.insert "enrolled" (Boolean Bool.false)
    |> Object
