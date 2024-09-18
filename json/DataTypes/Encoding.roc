module []
import JsonData exposing [Json]

JsonEncoder t : t -> Json

string : JsonEncoder Str
string = \str ->
    String str

number : JsonEncoder U64
number = \num ->
    Number num

bool : JsonEncoder Bool
bool = \b ->
    Boolean b

list : JsonEncoder a -> JsonEncoder (List a)
list = \encoderA ->
    \data ->
        json = List.map data encoderA
        Array json

# field : Str, JsonEncoder a -> JsonEncoder (Str, Json)
field = \fieldName, encoderA ->
    \data ->
        j = encoderA data
        (fieldName, j)
# TESTS
# primitives
expect string "hello" == (String "hello")
expect number 50 == (Number 50)
expect bool Bool.true == (Boolean Bool.true)
# there is no null type in Roc

# list tests
strs = ["hello", "hello again"]
expect (list string) strs == Array [String "hello", String "hello again"]

# field encoder
expect (field "fieldName" string) "fieldValue" == ("fieldName", String "fieldValue")
