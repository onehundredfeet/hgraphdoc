package gdoc;

import gdoc.NodeGraph;

using Lambda;

typedef Graph = gdoc.NodeGraph;
typedef GraphElement = gdoc.Element;

enum EMatcher {
	MatchAny;
	MatchString(string:String);
	MatchInt(int:Int);
	MatchRegex(regex:EReg);
	MatchFn(fn:(Dynamic) -> Bool);
}

abstract Matcher(EMatcher) {
	public function match(value:Dynamic):Bool {
		if (value is String) {
			return matchString(value);
		}
		if (value is Int) {
			switch (this) {
				case MatchAny:
					return true;
				case MatchInt(i):
					return i == value;
				case MatchFn(f):
					return f(value);
				default:
					return false;
			}
		}
		switch (this) {
			case MatchAny:
				return true;
			case MatchFn(f):
				return f(value);
			default:
				return false;
		}
	}

	public function matchString(value:String):Bool {
		switch (this) {
			case MatchAny:
				return true;
			case MatchString(s):
				return s == value;
			case MatchInt(i):
				return value != null && Std.parseInt(value) == i;
			case MatchRegex(r):
				return value != null && r.match(value);
			case MatchFn(f):
				return f(value);
		}
		return false;
	}
}

typedef PathMatchFn = (path:MatchVector) -> Bool;
typedef NodeMatchFn = (pattern:NodePattern, path:MatchVector, source:Node) -> NodeMatch;
typedef EdgeMatchFn = (pattern:EdgePattern, path:MatchVector, source:Edge) -> EdgeMatch;

abstract class ElementMatch {
	public var element(get, never):GraphElement;

	abstract function get_element():GraphElement;
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

	public final node:Node;
	public var edges:Map<String, EdgeMatch>;
}

abstract class Pattern {
	public var user:Dynamic;
	public var name:Matcher;
	public var properties:Map<String, Matcher>;
	public var predicate:PathMatchFn;

	abstract function matchElement(previous:MatchVector, candidate:GraphElement):ElementMatch;

	public function noDuplicates():Pattern {
		_noDuplicates = true;
		return this;
	}

	var _noDuplicates:Bool = false;
}

class NodePattern extends Pattern {
	public function new(name:Matcher = null, properties:Map<String, Matcher> = null, fn:NodeMatchFn = null, user:Dynamic = null,
			edges:Map<String, EdgePattern> = null) {
		this.name = name;
		this.properties = properties;
		this.fn = fn;
		this.user = user;
		this.edges = edges;
	}

	public var fn:NodeMatchFn;
	public var edges:Map<String, EdgePattern>;

	public function noConnections():NodePattern {
		_onlyUnconnected = true;
		return this;
	}

	var _onlyUnconnected:Bool = false;

	public function matchElement(path:MatchVector, candidateElement:GraphElement):ElementMatch {
		if (candidateElement is Node) {
			return matchNode(path, cast candidateElement);
		}
		return null;
	}

	public function matchNode(path:MatchVector, candidateNode:Node):NodeMatch {
		if (predicate != null) {
			if (!predicate(path)) {
				return null;
			}
		}

		if (_onlyUnconnected || _noDuplicates) {
			for (p in path) {
				if (p is NodeMatch) {
					var nodeMatch = cast p, NodeMatch;
					if (_noDuplicates && nodeMatch.node == candidateNode) {
						return null;
					}
					if (_onlyUnconnected && nodeMatch.node.isConnected(candidateNode)) {
						return null;
					}
				}
			}
		}

		if (fn != null) {
			return fn(this, path, candidateNode);
		}
		if (name != null && !name.matchString(candidateNode.name)) {
			return null;
		}
		if (properties != null) {
			for (prop in properties.keyValueIterator()) {
				if (!candidateNode.properties.exists(prop.key) || !prop.value.match(candidateNode.properties.get(prop.key))) {
					return null;
				}
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

					var edgeMatch = edgePattern.value.matchEdge(path, candidate);
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
	public function new(direction:EDirection = DirAny, name:Matcher = null, properties:Map<String, Matcher> = null, fn:EdgeMatchFn = null,
			user:Dynamic = null, source:NodePattern = null, target:NodePattern = null) {
		this.name = name;
		this.properties = properties;
		this.fn = fn;
		this.user = user;
		this.source = source;
		this.target = target;
		this.direction = direction;
	}

	public var fn:EdgeMatchFn;
	public var source:NodePattern;
	public var target:NodePattern;
	public var direction:EDirection;

	public function matchElement(path:Array<ElementMatch>, candidateElement:GraphElement):ElementMatch {
		if (candidateElement is Edge) {
			return matchEdge(path, cast candidateElement);
		}
		return null;
	}

	public function matchEdge(path:Array<ElementMatch>, candidateEdge:Edge):EdgeMatch {
		if (predicate != null) {
			if (!predicate(path)) {
				return null;
			}
		}

		if (fn != null) {
			return fn(this, path, candidateEdge);
		}
		if (name != null && !name.matchString(candidateEdge.name)) {
			return null;
		}
		if (properties != null) {
			for (prop in properties.keyValueIterator()) {
				if (!candidateEdge.properties.exists(prop.key) || !prop.value.match(candidateEdge.properties.get(prop.key))) {
					return null;
				}
			}
		}
		var sourceMatch:NodeMatch = null;
		if (source != null) {
			sourceMatch = source.matchNode(path, candidateEdge.source);
			if (sourceMatch == null) {
				return null;
			}
		} else {
			sourceMatch = new NodeMatch(candidateEdge.source);
		}

		var targetMatch:NodeMatch = null;
		if (target != null) {
			targetMatch = target.matchNode(path, candidateEdge.target);
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
		trace('Generating edge ${name} from ${source.name} to ${target.name}');
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
		trace('Splitting edge ${matches}');
		var match = matches[0];

		if (match is NodeMatch) {
			return false;
		}
		var edgeMatch = cast(match, EdgeMatch);
		var edge = edgeMatch.edge;

		trace('subdividing edge ${edge} on graph ${context.graph}');

		var source = edge.source;
		var target = edge.target;

		var newNode = node.generateNode(matches, context);

		var newIncoming = incoming.generateEdge(matches, source, newNode, context);
		var newOutgoing = outgoing.generateEdge(matches, newNode, target, context);

		context.graph.removeEdge(edge);

		return true;
	}
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

		return true;
	}
}

class OpAddEdge extends Operation {
	public function new(edge:MetaEdge) {
		this.edge = edge;
	}

	public var edge:MetaEdge;

	public function apply(matches:Array<ElementMatch>, context:MetaContext) {
		if (matches == null || matches.length != 0) {
			return false;
		}
		if (matches[0] is EdgeMatch || matches[1] is EdgeMatch) {
			return false;
		}

		var sourceNode = cast(matches[0], NodeMatch);
		var targetNode = cast(matches[1], NodeMatch);

		if (sourceNode == targetNode) {
			return false;
		}

		if (sourceNode.node.isConnected(targetNode.node)) {
			return false;
		}

		edge.generateEdge(matches, sourceNode.node, targetNode.node, context);

		return true;
	}
}

class Rule {
	public function new(patterns:Array<Pattern>, operation:Operation) {
		this.patterns = patterns;
		this.operation = operation;
	}

	public var patterns:Array<Pattern>;
	public var operation:Operation;

	function getElementsMatchingPath(path:MatchVector, pattern:Pattern, graph:Graph):Array<ElementMatch> {
		var matches:Array<ElementMatch> = [];

		if (pattern is NodePattern) {
			var nodePattern = cast(pattern, NodePattern);
			for (n in graph.nodes) {
				var match = nodePattern.matchNode(path, n);
				if (match != null) {
					matches.push(match);
				}
			}
			return matches;
		} else {
			var edgePattern = cast(pattern, EdgePattern);
			trace('Looking for edge pattern ${edgePattern} in ${graph.edges}');
			for (e in graph.edges) {
				var match = edgePattern.matchEdge(path, e);
				trace('Match ${match}');
				if (match != null) {
					matches.push(match);
				}
			}
			return matches;
		}
	}

	function getAllVariations(graph:Graph, variations:Array<MatchVector>, patterns:Array<Pattern>) {
		trace('variations ${variations} - patterns ${patterns}');
		if (patterns.length == 0) {
			return variations;
		}

		var newVariations = [];
		var pattern = patterns[0];
		var rest = patterns.slice(1);

		for (v in variations) {
			var elements = getElementsMatchingPath(v, pattern, graph);
			if (elements != null && elements.length > 0) {
				for (e in elements) {
					var newVariation = v.slice(0);
					newVariation.push(e);
					newVariations.push(newVariation);
				}
			}
		}

		if (rest.length == 0) {
			return newVariations;
		}
		return getAllVariations(graph, newVariations, rest);
	}

	function getFirstVariations(graph:Graph, variations:Array<MatchVector>, patterns:Array<Pattern>):MatchVector {
		var newVariations = [];
		var pattern:NodePattern = cast patterns[0];
		var rest = patterns.slice(1);

		for (v in variations) {
			var elements = getElementsMatchingPath(v, pattern, graph);
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

typedef FitnessFn = (Graph) -> Float;

class RewriteEngine {
	public function new(rules:Array<Rule>, baselineFitness:Array<FitnessFn> = null) {
		this.rules = rules;
		this.baselineFitness = baselineFitness == null ? [] : baselineFitness;
	}

	public var rules:Array<Rule>;
	public var propertyPolicy:EMetaValue = EMetaValue.ECopy;
	public var baselineFitness:Array<FitnessFn>;

	public function applyFirst(graph:Graph, user:Dynamic) {
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

	public function applyBest(graph:Graph, fitness:Array<FitnessFn> = null, user:Dynamic = null) {
		var context = new MetaContext(graph, user);
		context.graph = graph;
		var finalFitness = fitness != null ? baselineFitness.concat(fitness) : baselineFitness;
		var topScore = Math.NEGATIVE_INFINITY;
		var topGraph:Graph = null;
		for (r in rules) {
			trace('Applying rule ${r}');
			var ruleVariations = r.findAllVariations(graph);
			trace('Result: ${ruleVariations.length} variations');
			if (ruleVariations != null) {
				for (v in ruleVariations) {
					var newGraph = graph.clone();
					context.graph = newGraph;
					r.apply(v, context);
					var score = finalFitness.fold((v,total) -> v(newGraph) + total, 0.0);
					if (score > topScore) {
						topScore = score;
						topGraph = newGraph;
					}
				}
			}
		}
		return topGraph;
	}
}
