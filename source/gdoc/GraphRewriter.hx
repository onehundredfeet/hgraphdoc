package gdoc;

import gdoc.NodeGraph;

using Lambda;

typedef Graph = gdoc.NodeGraph;
typedef GraphElement = gdoc.Element;

class MatcherContext {
	public function new( graph: Graph, pattern: Pattern, path: MatchVector) {
        this.graph = graph;
        this.pattern = pattern;
        this.path = path;
    }

	public var graph:Graph;
	public var pattern:Pattern;
	public var subject:Element;
	public var path:MatchVector;
}

typedef ValueMatchFn = (value:Dynamic, context:MatcherContext) -> Bool;
typedef ElementMatchFn = (element:Element, context:MatcherContext) -> Bool;
typedef NodeMatchFn = (node:Node, context:MatcherContext) -> Bool;
typedef EdgeMatchFn = (edge:Edge, context:MatcherContext) -> Bool;

enum EMatcher {
	MNull;
	MAny;
	MNode;
	MEdge;
	MName(expr:Matcher);
	MProperty(name:String, expr:Matcher);
	MString(string:String);
	MInt(int:Int);
	MRegex(regex:EReg);
	MValueFn(fn:ValueMatchFn);
	MElementFn(fn:ElementMatchFn);
	MNodeFn(fn:NodeMatchFn);
	MEdgeFn(fn:EdgeMatchFn);
	MNot(expr:Matcher);
	MAnd(expr1:Matcher, expr2:Matcher);
	MOr(expr1:Matcher, expr2:Matcher);
	MNoDuplicates;
    MNoConnected;
}

abstract Matcher(EMatcher) from EMatcher {
	public function match(value:Dynamic, context:MatcherContext):Bool {
		trace('match?');
		switch (this) {
			case MNull:
				return value == null;
			case MAny:
				return true;
			case MEdge:
				return value is Edge;
			case MNode:
				return value is Node;
			case MNoDuplicates:
				if (value is Element) {
					var element = cast(value, Element);
					for (elementMatch in context.path) {
						if (elementMatch.element == element) {
							return false;
						}
					}
				}
				return true;
			case MName(expr):
				if (expr is Element) {
					var element = cast(expr, Element);
					return expr.match(element.name, context);
				}
				return false;
			case MProperty(name, expr):
				if (expr is Element) {
					var element = cast(expr, Element);
					return element.properties.exists(name) && expr.match(element.properties.get(name), context);
				}
				return false;
			case MValueFn(f):
				return f(value, context);
			case MElementFn(fn):
				if (value is Element) {
					return fn(cast(value, Element), context);
				}
				return false;
			case MNodeFn(fn):
				if (value is Node) {
					return fn(cast(value, Node), context);
				}
				return false;
			case MEdgeFn(fn):
				if (value is Edge) {
					return fn(cast(value, Edge), context);
				}
				return false;
			case MNot(expr):
				// trace('not: ${!expr.match(value)}');
				return !expr.match(value, context);
			case MAnd(expr1, expr2):
				return expr1.match(value, context) && expr2.match(value, context);
			case MOr(expr1, expr2):
				return expr1.match(value, context) || expr2.match(value, context);
			case MString(s):
				return s == value;
			case MInt(i):
				if (value is Int) {
					return value == i;
				}
				if (value is String) {
					return Std.parseInt(value) == i;
				}
				return false;
			case MRegex(r):
				if (value is String)
					return value != null && r.match(value);
				return false;
            case MNoConnected:
                if (value is Node) {
                    var node = cast(value, Node);
                    for (elementMatch in context.path) {
                        if (elementMatch is NodeMatch) {
                            var nodeMatch = cast(elementMatch, NodeMatch);
                            if (node.isConnected(nodeMatch.node)) {
                                return false;
                            }
                        }
                    }
                }
                return true;
		}

		return false;
	}
}

typedef PathMatchFn = (path:MatchVector) -> Bool;

abstract class ElementMatch {
	public var element(get, never):GraphElement;

	abstract function get_element():GraphElement;

	public abstract function remap(g:Graph):ElementMatch;
}

typedef MatchVector = Array<ElementMatch>;

class EdgeMatch extends ElementMatch {
	public function new(edge:Edge, source:NodeMatch, target:NodeMatch) {
		this.edge = edge;
		this.source = source;
		this.target = target;
	}

	function get_element():GraphElement {
		return edge;
	}

	function remap(g:Graph):ElementMatch {
		var newEdge = g.getEdgeFromID(edge.id);
		// trace('Remapped edge ${edge.id} -> ${newEdge}');
		var newSource:NodeMatch = source != null ? cast(source.remap(g), NodeMatch) : null;
		var newTarget:NodeMatch = target != null ? cast(target.remap(g), NodeMatch) : null;

		return new EdgeMatch(newEdge, newSource, newTarget);
	}

	public final edge:Edge;
	public final source:NodeMatch;
	public final target:NodeMatch;
}

class NodeMatch extends ElementMatch {
	public function new(node:Node, edges:Map<String, EdgeMatch> = null) {
		this.node = node;
		this.edges = edges;
	}

	function get_element():GraphElement {
		return node;
	}

	function remap(g:Graph):ElementMatch {
		var newNode = g.getNodeFromID(node.id);

		if (edges == null) {
			return new NodeMatch(newNode);
		}

		var newEdges = new Map<String, EdgeMatch>();

		for (e in edges.keyValueIterator()) {
			var newEdge = cast(e.value.remap(g), EdgeMatch);
			newEdges.set(e.key, newEdge);
		}

		return new NodeMatch(newNode, newEdges);
	}

	public final node:Node;
	public var edges:Map<String, EdgeMatch>;
}

abstract class Pattern {
	public var predicates:Array<Matcher>;

	abstract function matchElement(candidate:GraphElement, context: MatcherContext):ElementMatch;

	public function noDuplicates():Pattern {
		_noDuplicates = true;
		return this;
	}

	public function addPredicate(predicate:Matcher) {
		predicates.push(predicate);
        return this;
	}
    

	var _noDuplicates:Bool = false;
}

class NodePattern extends Pattern {
	public function new(predicates: Array<Matcher>, edges:Map<String, EdgePattern> = null) {
		this.edges = edges;
        this.predicates = predicates;
	}

	public var edges:Map<String, EdgePattern>;

	public function noConnections():NodePattern {
		addPredicate(MNoConnected);
		return this;
	}

	public function matchElement(candidateElement:GraphElement, context: MatcherContext):ElementMatch {
		if (candidateElement is Node) {
			return matchNode(cast candidateElement, context);
		}
		return null;
	}

    
	public function matchNode( candidateNode:Node, context: MatcherContext):NodeMatch {
		for (predicate in predicates) {
            if (!predicate.match(candidateNode,context)) {
                return null;
            }
        }
        
		if (edges != null) {
			var edgeMatches = new Map<String, EdgeMatch>();
			for (edgePattern in edges.keyValueIterator()) {
				var edgeMatch:EdgeMatch = null;

				for (candidate in candidateNode.connections) {
					switch (edgePattern.value.direction) {
						case EDirection.DirOutgoing:
							if (candidate.source != candidateNode) {
								continue;
							}
						case EDirection.DirIncoming:
							if (candidate.target != candidateNode) {
								continue;
							}
						case EDirection.DirAny:
							break;
					}

					var edgeMatch = edgePattern.value.matchEdge(candidate, context);
					if (edgeMatch != null) {
						break;
					}
				}

				if (edgeMatch == null) {
					return null;
				}
				edgeMatches.set(edgePattern.key, edgeMatch);
			}
			return new NodeMatch(candidateNode, edgeMatches);
		}
        
		return new NodeMatch(candidateNode);
	}
}

enum EDirection {
	DirOutgoing;
	DirIncoming;
	DirAny;
}

class EdgePattern extends Pattern {
	public function new(predicates: Array<Matcher>, direction = EDirection.DirAny, source:NodePattern = null, target:NodePattern = null) {
		this.source = source;
		this.target = target;
		this.direction = direction;
        this.predicates = predicates;
	}

	public var fn:EdgeMatchFn;
	public var source:NodePattern;
	public var target:NodePattern;
	public var direction:EDirection;

	public function edgeMatchFn(fn:EdgeMatchFn):EdgePattern {
		this.fn = fn;
		return this;
	}

	public function matchElement( candidateElement:GraphElement, context:MatcherContext):ElementMatch {
		if (candidateElement is Edge) {
			return matchEdge( cast candidateElement, context);
		}
		return null;
	}

	public function matchEdge(candidateEdge:Edge, context:MatcherContext):EdgeMatch {
		for (predicate in predicates) {
            if (!predicate.match(candidateEdge, context)) {
                return null;
            }
        }
		var sourceMatch:NodeMatch = null;
		if (source != null) {
			sourceMatch = source.matchNode(candidateEdge.source, context);
			if (sourceMatch == null) {
				return null;
			}
		} else {
			sourceMatch = new NodeMatch(candidateEdge.source);
		}

		var targetMatch:NodeMatch = null;
		if (target != null) {
			targetMatch = target.matchNode(candidateEdge.target, context);
			if (targetMatch == null) {
				return null;
			}
		} else {
			targetMatch = new NodeMatch(candidateEdge.target);
		}

		return new EdgeMatch(candidateEdge, sourceMatch, targetMatch);
	}
}

class MetaContext {
	public function new(graph:Graph, user:Dynamic = null, propertyPolicy:EMetaValue = EMetaValue.ECopy) {
		this.graph = graph;
		this.user = user;
		this.propertyPolicy = propertyPolicy;
	}

	public var matched:ElementMatch;
	public var graph:Graph;
	public var user:Dynamic;
	public var propertyPolicy:EMetaValue;
}

enum EMetaString {
	MStrNull;
	MStrEmpty;
	MStrCopy;
	MStrLiteral(string:String);
	MStrRewrite(regex:EReg, sub:String);
	MStrFn(fn:(MetaElement, String, Dynamic) -> String);
}

function generateString(element:MetaElement, generator:EMetaString, value:String, context:MetaContext):String {
	return switch (generator) {
		case MStrNull: null;
		case MStrEmpty: "";
		case MStrCopy: value;
		case MStrLiteral(s): s;
		case MStrRewrite(r, sub): r.replace(value, sub);
		case MStrFn(f): f(element, value, context.user);
	}
}

enum EMetaValue {
	EClear;
	EDefault;
	ENull;
	EStrEmpty;
	ECopy;
	EString(string:String);
	EInt(int:Int);
	EFloat(float:Float);
	EBool(bool:Bool);
	MStrRewrite(regex:EReg, sub:String);
	EFn(fn:(MetaElement, MatchVector, Dynamic) -> Dynamic);
}

function generateValue(element:MetaElement, matched:MatchVector, generator:EMetaValue, value:Dynamic, context:MetaContext):Dynamic {
	return switch (generator) {
		case EDefault: context.propertyPolicy != EDefault ? generateValue(element, matched, context.propertyPolicy, value, context) : null;
		case EClear, ENull: null;
		case EString(s): s;
		case EInt(i): i;
		case EFloat(f): f;
		case EBool(b): b;
		case EFn(f): f(element, matched, context.user);
		case ECopy: value;
		case EStrEmpty: "";
		case MStrRewrite(r, sub): value is String ? r.replace(cast(value, String), sub) : null;
	}
}

class MetaElement {
	public var name:EMetaString;
	public var properties:Map<String, EMetaValue>;
	public var user:Dynamic;
	public var propertyPolicy:EMetaValue;

	static final DEFAULT_STRING = "";

	public function mutate(match:MatchVector, element:Element, context:MetaContext) {
		if (name != null) {
			element.name = generateString(this, name, element.name, context);
		}

		if (properties != null) {
			for (prop in properties.keyValueIterator()) {
				var generator = prop.value;
				var existingValue = element.properties.get(prop.key);
				switch (generator) {
					case null:
					case EMetaValue.EClear:
						element.properties.remove(prop.key);
						break;
					default:
						element.properties.set(prop.key, generateValue(this, match, generator, existingValue, context));
				}
			}

			var leftovers = [];
			for (k in element.properties.keys()) {
				if (!properties.exists(k)) {
					leftovers.push(k);
				}
			}

			if (context.propertyPolicy == EMetaValue.EClear) {
				for (lo in leftovers) {
					element.properties.remove(lo);
				}
			} else {
				for (lo in leftovers) {
					element.properties.set(lo, generateValue(this, match, context.propertyPolicy, element.properties.get(lo), context));
				}
			}
		} else {
			if (context.propertyPolicy != EMetaValue.EClear) {
				for (prop in element.properties.keyValueIterator()) {
					element.properties.set(prop.key, generateValue(this, match, context.propertyPolicy, element.properties.get(prop.key), context));
				}
			} else {
				element.properties.clear();
			}
		}
	}

	public function generateProperties(element:Element, match:MatchVector, context:MetaContext) {
		if (properties != null) {
			for (prop in properties.keyValueIterator()) {
				if (prop.value != null && prop.value != EMetaValue.EClear) {
					element.properties.set(prop.key, generateValue(this, match, prop.value, null, context));
				}
			}
		}
	}
}

class MetaNode extends MetaElement {
	public function new(name:EMetaString, properties:Map<String, EMetaValue> = null, post:(meta:MetaNode, node:Node, context:MetaContext) -> Void = null) {
		this.name = name;
		this.properties = properties;
		this.post = post;
	}

	public var post:(meta:MetaNode, node:Node, context:MetaContext) -> Void;
	public var parent:MetaEdge;

	public function addChild(key:String = null):MetaEdge {
		var edge = new MetaEdge(key == null ? EMetaString.MStrEmpty : EMetaString.MStrCopy);
		edge.parent = this;
		return edge;
	}

	public override function mutate(match:MatchVector, element:Element, context:MetaContext) {
		var node = cast(element, Node);
		super.mutate(match, node, context);
		if (post != null) {
			post(this, node, context);
		}
	}

	public function generateNode(match:MatchVector, context:MetaContext):Node {
		var name = generateString(this, name, MetaElement.DEFAULT_STRING, context);
		var node = context.graph.addNode(name);

		generateProperties(node, match, context);

		if (post != null) {
			post(this, node, context);
		}
		return node;
	}
}

class MetaEdge extends MetaElement {
	public function new(name:EMetaString, properties:Map<String, EMetaValue> = null, post:(meta:MetaEdge, edge:Edge) -> Void = null) {
		this.name = name;
		this.properties = properties;
		this.post = post;
	}

	public function addChild(key:String = null):MetaNode {
		var node = new MetaNode(key == null ? EMetaString.MStrEmpty : EMetaString.MStrCopy);
		node.parent = this;
		return node;
	}

	public override function mutate(match:MatchVector, element:Element, context:MetaContext) {
		super.mutate(match, element, context);
		var edge = cast(element, Edge);

		if (post != null) {
			post(this, edge);
		}
	}

	public function generateEdge(match:MatchVector, source:Node, target:Node, context:MetaContext):Edge {
		var name = generateString(this, name, MetaElement.DEFAULT_STRING, context);
		var edge = context.graph.connectNodes(source, target, name);

		generateProperties(edge, match, context);

		if (post != null) {
			post(this, edge);
		}
		return edge;
	}

	public var post:(meta:MetaEdge, edge:Edge) -> Void;
	public var parent:MetaNode;
}

class Action {}

abstract class Operation {
	public abstract function apply(matches:MatchVector, context:MetaContext):Bool;

	public function andThen(next:Operation):Operation {
		return _next = next;
	}

	var _next:Operation;
}

class OpMutateEdge extends Operation {
	public function new(edge:MetaEdge) {
		this.edge = edge;
	}

	public function apply(matches:MatchVector, context:MetaContext) {
		if (matches.length == 0) {
			return false;
		}

		var m = matches[0];
		if (m is NodeMatch) {
			return false;
		}

		var edgeMatch = cast(m, EdgeMatch);

		edge.mutate(matches, edgeMatch.edge, context);
		return true;
	}

	public var edge:MetaEdge;
}

class OpMutateNode extends Operation {
	public function new(node:MetaNode) {
		this.node = node;
	}

	public function apply(matches:MatchVector, context:MetaContext) {
		if (matches.length == 0) {
			return false;
		}
		var m = matches[0];
		if (m is EdgeMatch) {
			return false;
		}

		var nodeMatch = cast(m, NodeMatch);
		node.mutate(matches, nodeMatch.node, context);
		return true;
	}

	public var node:MetaNode;
}

class OpSplitEdge extends Operation {
	public function new(incoming:MetaEdge, outgoing:MetaEdge, node:MetaNode) {
		this.incoming = incoming;
		this.outgoing = outgoing;
		this.node = node;
	}

	public var incoming:MetaEdge;
	public var outgoing:MetaEdge;
	public var node:MetaNode;

	public function apply(matches:MatchVector, context:MetaContext) {
		var match = matches[0];

		if (match is NodeMatch) {
			return false;
		}
		var edgeMatch = cast(match, EdgeMatch);
		var edge = edgeMatch.edge;

		var source = edge.source;
		var target = edge.target;

		var newNode = node.generateNode(matches, context);

		newNode.x = (source.x + target.x) / 2;
		newNode.y = (source.y + target.y) / 2;

		var newIncoming = incoming.generateEdge(matches, source, newNode, context);
		var newOutgoing = outgoing.generateEdge(matches, newNode, target, context);

		context.graph.removeEdge(edge);
		//        trace('-------after edge removal');
		//      trace(NodeGraphPrinter.graphToString(context.graph));

		if (_post != null) {
			_post(matches, newNode, context);
		}
		return true;
	}

	public function post(fn:(MatchVector, Node, MetaContext) -> Void):OpSplitEdge {
		_post = fn;
		return this;
	}

	var _post:(MatchVector, Node, MetaContext) -> Void;
}

class OpAddNode extends Operation {
	public function new(edge:MetaEdge, node:MetaNode) {
		this.edge = edge;
		this.node = node;
	}

	public var edge:MetaEdge;
	public var node:MetaNode;

	public function apply(matches:MatchVector, context:MetaContext) {
		if (matches.length == 0) {
			return false;
		}
		var match = matches[0];

		if (match is EdgeMatch) {
			return false;
		}

		var nodeMatch = cast(match, NodeMatch);
		var newNode = node.generateNode(matches, context);
		edge.generateEdge(matches, nodeMatch.node, newNode, context);

		if (_post != null) {
			_post(matches, newNode, context);
		}

		return true;
	}

	public function post(fn:(MatchVector, Node, MetaContext) -> Void):OpAddNode {
		_post = fn;
		return this;
	}

	var _post:(MatchVector, Node, MetaContext) -> Void;
}

class OpNop extends Operation {
	public function new() {}

	public function apply(matches:MatchVector, context:MetaContext) {
		return true;
	}
}

class OpAddEdge extends Operation {
	public function new(edge:MetaEdge) {
		this.edge = edge;
	}

	public var edge:MetaEdge;

	public function apply(matches:Array<ElementMatch>, context:MetaContext) {
		if (matches == null || matches.length == 0) {
			trace('OpAddEdge - No matches');
			return false;
		}
		if (matches[0] is EdgeMatch || matches[1] is EdgeMatch) {
			trace('OpAddEdge - matches are edges');

			return false;
		}

		var sourceNode = cast(matches[0], NodeMatch);
		var targetNode = cast(matches[1], NodeMatch);

		if (sourceNode == targetNode) {
			trace('OpAddEdge - targets are the same');
			return false;
		}

		if (sourceNode.node.isConnected(targetNode.node)) {
			return false;
		}

		var newEdge = edge.generateEdge(matches, sourceNode.node, targetNode.node, context);

		if (_post != null) {
			_post(matches, newEdge, context);
		}

		return true;
	}

	public function post(fn:(MatchVector, Edge, MetaContext) -> Void):OpAddEdge {
		_post = fn;
		return this;
	}

	var _post:(MatchVector, Edge, MetaContext) -> Void;
}

class Rule {
	public function new(patterns:Array<Pattern>, operation:Operation) {
		this.patterns = patterns;
		this.operation = operation;
	}

	public var patterns:Array<Pattern>;
	public var operation:Operation;

	function getMatchingElements(path:MatchVector, pattern:Pattern, graph:Graph):Array<ElementMatch> {
		var matches:Array<ElementMatch> = [];
        var context = new MatcherContext(graph, pattern, path);
		if (pattern is NodePattern) {
			var nodePattern = cast(pattern, NodePattern);
			for (n in graph.nodes) {
                context.subject = n;
				var match = nodePattern.matchNode(n, context);
				if (match != null) {
					matches.push(match);
				}
			}
			return matches;
		} else {
			var edgePattern = cast(pattern, EdgePattern);
			for (e in graph.edges) {
                context.subject = e;
				var match = edgePattern.matchEdge( e, context);
				if (match != null) {
					matches.push(match);
				}
			}
			return matches;
		}
	}

	function getAllVariations(graph:Graph, variations:Array<MatchVector>, patterns:Array<Pattern>) {
		if (patterns.length == 0) {
			return [];
		}

		var newVariations = [];
		var pattern = patterns[0];
		var rest = patterns.slice(1);

		// trace('Looking for pattern ${pattern}');
		for (v in variations) {
			var elements = getMatchingElements(v, pattern, graph);
			if (elements != null && elements.length > 0) {
				// trace('Found with v ${v} : ${elements.length} elements ${elements}');
				for (e in elements) {
					var newVariation = v.slice(0);
					newVariation.push(e);
					newVariations.push(newVariation);
				}
			}
		}

		if (rest.length == 0 || newVariations.length == 0) {
			return newVariations;
		}
		return getAllVariations(graph, newVariations, rest);
	}

	function getFirstVariations(graph:Graph, variations:Array<MatchVector>, patterns:Array<Pattern>):MatchVector {
		var newVariations = [];
		var pattern:NodePattern = cast patterns[0];
		var rest = patterns.slice(1);

		for (v in variations) {
			var elements = getMatchingElements(v, pattern, graph);
			if (elements != null && elements.length > 0) {
				for (e in elements) {
					var newVariation = v.slice(0);
					newVariation.push(e);

					if (rest.length == 0) {
						return newVariation;
					}
				}
			}
		}

		if (rest.length == 0) {
			return null;
		}

		return getFirstVariations(graph, newVariations, rest);
	}

	public function findFirstVariation(graph:Graph) {
		return getFirstVariations(graph, [[]], patterns);
	}

	public function findAllVariations(graph) {
		return getAllVariations(graph, [[]], patterns);
	}

	public function apply(matches:Array<ElementMatch>, context:MetaContext) {
		return operation.apply(matches, context);
	}
}

typedef FitnessFn = (Graph) -> Null<Float>;

class GraphRewriter {
	public static function applyFirst(graph:Graph, rules:Array<Rule>, user:Dynamic) {
		var context = new MetaContext(graph, user);
		context.graph = graph;

		for (r in rules) {
			var match = r.findFirstVariation(graph);
			if (match != null) {
				for (m in match) {
					r.apply(match, context);
				}
				break;
			}
		}
	}

	public static function applyBest(graph:Graph, rules:Array<Rule>, fitness:Array<FitnessFn> = null, user:Dynamic = null) {
		var context = new MetaContext(graph, user);
		context.graph = graph;
		var topScore = Math.NEGATIVE_INFINITY;
		var topGraph:Graph = null;
		var topOperation:Operation = null;

		for (r in rules) {
			var ruleVariations = r.findAllVariations(graph);
			if (ruleVariations != null) {
				// trace('ruleVariations: $ruleVariations');
				for (v in ruleVariations) {
					var newGraph = graph.clone();
					context.graph = newGraph;

					var v1 = v.map((e) -> return e.remap(newGraph));
					if (r.apply(v1, context)) {
						var accum = 0.0;
						var valid = true;
						for (f in fitness) {
							var x = f(newGraph);
							if (x == null) {
								valid = false;
								break;
							}
							accum += x;
						}
						// trace('Score is ${score} vs ${topScore}');
						if (valid && accum > topScore) {
							topScore = accum;
							topGraph = newGraph;
							topOperation = r.operation;
						}
					}
				}
			}
		}

		if (topOperation != null) {
			trace('TOP OPERATION ${topOperation}');
		}
		return topGraph;
	}
}
