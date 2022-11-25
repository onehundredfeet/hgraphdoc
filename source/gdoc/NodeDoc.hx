package gdoc;

typedef DocNodeConnection = {
    name : String,
    target : String,
    id : Int,
    ?properties : haxe.DynamicAccess<String>
}
typedef DocNode = {
    name : String,
    id : Int,
    ?parent : String,
    ?parentID : Int,
    ?outgoing : Array<DocNodeConnection>,
    ?properties : haxe.DynamicAccess<String>
}

typedef NodeDocPage = {
    name : String,
    nodes : Array<DocNode>
}

typedef NodeDoc = Array<NodeDocPage>;

