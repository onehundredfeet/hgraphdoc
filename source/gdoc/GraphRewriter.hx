package gdoc;
import gdoc.NodeGraph;

using Lambda;


typedef Graph = NodeGraph;


enum EMatcher {
    EAny;
    EString(string:String);
    EInt(int:Int);
    ERegex(regex:EReg);
    EFn( fn : (Dynamic) -> Bool);
}

abstract Matcher(EMatcher) {
    public function match(value:Dynamic):Bool {
        if (value is String) {
            return matchString(value);
        }
        if (value is Int) {
            switch (this) {
                case EAny: return true;
                case EInt(i): return i == value;
                case EFn(f): return f(value);
                default:return false;
            }
        }
        switch (this) {
            case EAny: return true;
            case EFn(f): return f(value);
            default:return false;
        }
    }
    public function matchString(value:String):Bool {
        switch (this) {
            case EAny: return true;
            case EString(s): return s == value;
            case EInt(i): return value != null && Std.parseInt(value) == i;
            case ERegex(r): return value != null && r.match(value);
            case EFn(f): return f(value);
        }
        return false;
    }
}


typedef NodeMatchFn = (pattern: NodePattern, source:Node) -> NodeMatch;
typedef EdgeMatchFn = (pattern:EdgePattern, source:Edge) -> EdgeMatch;

class EdgeMatch {
    public function new(edge:Edge, source:NodeMatch, target:NodeMatch) {
        this.edge = edge;
        this.source = source;
        this.target = target;
    }
    public final edge:Edge;
    public final source:NodeMatch;
    public final target:NodeMatch;
}

class NodeMatch {
    public function new(node:Node, edges:Map<String, EdgeMatch> = null) {
        this.node = node;
        this.edges = edges;
    }
    public final node:Node;
    public var edges: Map<String, EdgeMatch>;
}

class NodePattern {
    public function new(name:Matcher = null, properties:Map<String, Matcher> = null, fn:NodeMatchFn = null, user:Dynamic = null, edges:Map<String, EdgePattern> = null) {
        this.nameMatch = name;
        this.properties = properties;
        this.fn = fn;
        this.user = user;
        this.edges = edges;
    }
    public var nameMatch: Matcher;
    public var properties:Map<String, Matcher>;
    public var fn: NodeMatchFn;
    public var user:Dynamic;
    public var edges:Map<String, EdgePattern>;

    public function match(source:Node) : NodeMatch {
        if (fn != null) {
            return fn(this, source);
        }
        if (nameMatch != null && !nameMatch.matchString(source.name)) {
            return null;
        }
        if (properties != null) {
            for (prop in properties.keyValueIterator()) {
                if (!source.properties.exists(prop.key) || !prop.value.match(source.properties.get(prop.key))) {
                    return null;
                }
            }
        }
        if (edges != null) {
            var edgeMatches = new Map<String, EdgeMatch>();
            for (edgePattern in edges.keyValueIterator()) {
                var edgeMatch : EdgeMatch = null;

                for (candidate in source.connections) {
                    switch(edgePattern.value.direction) {
                        case EDirection.EOutgoing:
                            if (candidate.source != source) {
                                continue;
                            }
                        case EDirection.EIncoming:
                            if (candidate.target != source) {
                                continue;
                            }
                        case EDirection.EAny:
                            break;
                    }

                    var edgeMatch = edgePattern.value.match(candidate);
                    if (edgeMatch != null) {
                        break;
                    }
                }

                if (edgeMatch == null) {
                    return null;
                }
                edgeMatches.set(edgePattern.key, edgeMatch);
            }
            return new NodeMatch(source, edgeMatches);
        }
        return new NodeMatch(source);
    }

    public function matchAll( graph : Graph) : Array<NodeMatch> {
        var matches = new Array<NodeMatch>();
        for (node in graph.nodes) {
            var match = this.match(node);
            if (match != null) {
                matches.push(match);
            }
        }
        return matches;
    }

    public function matchFirst( graph : Graph) : NodeMatch {
        for (node in graph.nodes) {
            var match = this.match(node);
            if (match != null) {
                return match;
            }
        }
        return null;
    }
}

enum EDirection {
    EOutgoing;
    EIncoming;
    EAny;
}

class EdgePattern {
    public function new(direction : EDirection = EAny, name:Matcher = null, properties:Map<String, Matcher> = null, fn:EdgeMatchFn = null, user:Dynamic = null, source: NodePattern = null, target: NodePattern = null) {
        this.name = name;
        this.properties = properties;
        this.fn = fn;
        this.user = user;
        this.source = source;
        this.target = target;
        this.direction = direction;
    }
    public var name: Matcher;
    public var properties:Map<String, Matcher>;
    public var fn: EdgeMatchFn;
    public var user:Dynamic;
    public var source: NodePattern;
    public var target: NodePattern;
    public var direction : EDirection;

    public function match(candidate:Edge):EdgeMatch {
        if (fn != null) {
            return fn(this, candidate);
        }
        if (name != null && !name.matchString(candidate.name)) {
            return null;
        }
        if (properties != null) {
            for (prop in properties.keyValueIterator()) {
                if (!candidate.properties.exists(prop.key) || !prop.value.match(candidate.properties.get(prop.key))) {
                    return null;
                }
            }
        }
        var sourceMatch : NodeMatch = null;
        if (source != null) {
            sourceMatch = source.match(candidate.source);
            if (sourceMatch == null) {
                return null;
            }
        } else {
            sourceMatch = new NodeMatch(candidate.source);
        }

        var targetMatch : NodeMatch = null;
        if (target != null) {
            targetMatch = target.match(candidate.target);
            if (targetMatch == null) {
                return null;
            }
        } else {
            targetMatch = new NodeMatch(candidate.target);
        }
        

        return new EdgeMatch(candidate, sourceMatch, targetMatch);
    }

    public function matchAll( graph : Graph) : Array<EdgeMatch> {
        var matches = new Array<EdgeMatch>();
        for (edge in graph.edges) {
            var match = this.match(edge);
            if (match != null) {
                matches.push(match);
            }
        }
        return matches;
    }

    public function matchFirst( graph : Graph) : EdgeMatch {
        for (edge in graph.edges) {
            var match = this.match(edge);
            if (match != null) {
                return match;
            }
        }
        return null;
    }
}


// operations patterns

// Mutate an edge (e.g., change its name, properties, etc.)
// Mutate a node (e.g., change its name, properties, etc.)
// Replace Edge with subgraph that has designated nodes to connect the edge source and targets
// Replace a node with a subgraph (with the edges mapped to the new nodes)
// Collapse edge and neighbor nodes into a single node
// Collapse a node and its neighbors into a single edge

