package grph;

import grph.VisioXMLTools;
using Lambda;
import grph.VisioXMLTools;



class VisioXMLGraphModel {
	
	
		public function new( n : String, shapes : Array<Xml>, states : Array<Xml>, connections : Array<Xml>, transitions : Array<Xml>) {
			_name = n;
			_allShapes = shapes;
			_stateShapes = states;
			_connections = connections;
			_transitions = transitions;
	
			_defaultStates = states.filter( function (x) return (hasProp(x, "default") || hasProp(x, "root")) ).map(x -> getStateShapeName(x));
	
	
			if (_defaultStates == null || _defaultStates.length == 0) {
				_defaultStates.push("DEFAULT");
			}
	
			var filteredShapes = _stateShapes.filter( (x) -> getStateShapeName(x) != null);
			for (fs in filteredShapes) {
				_stateMap[scrubLabel(getStateShapeName(fs))] = fs;
			}
			_stateNames = [for (k in _stateMap.keys()) k];
			_transitionNames = unique(_transitions.map(getTransitionShapeName).filter(notNull).map(scrubLabel).array());
	
			buildGraph();
		}
	
		public var stateShapes(get, never):Array<Xml>;
		function get_stateShapes() :Array<Xml> return _stateShapes;
	
		public var name(get, never):String;
		function get_name() :String return _name;
	
		public var stateNames(get, never):Array<String>;
		function get_stateNames() :Array<String> return _stateNames;
	
		public var transitionNames(get, never):Array<String>;
		function get_transitionNames() :Array<String> return _transitionNames;
	
		public var transitions(get, never):Array<Xml>;
		function get_transitions() :Array<Xml> return _transitions;
	
		
		public var defaultStates(get, never):Array<String>;
		function get_defaultStates() :Array<String> return _defaultStates;
	
		public function defaultState(subgraph : Int):String {
			return _defaultStates[subgraph];
		}
	
		public function getStateNode( name : String ) {
			return _stateMap.get(name);
		}
		var _allShapes : Array<Xml>;
		var  _stateShapes : Array<Xml>;
		var _connections : Array<Xml>;
		var _transitions : Array<Xml>;
		
		var  _stateNames : Array<String>;
		var  _defaultStates : Array<String>;
		var _transitionNames : Array<String>;
		var  _name : String;
	
		var _stateMap = new Map<String, Xml>();
	
	
		function buildGraph() {
	   
			for ( shape in _allShapes) {
				var id = getShapeID(shape);
				if (isNotEmpty(id)) {
					IDToShape[id] = shape;
					ShapeToID[shape] = id;
				} else {
					trace('No id for ${shape}');
				}
			}
	
	  
			for ( con in _connections) {
				var from = con.get("FromSheet");
				var source = con.get("FromPart") == "9";
				var to = con.get("ToSheet");
				if (isNotEmpty(from) && isNotEmpty(to)) {
					RawConnections[connectionId(from,source)] = to;
					if (source) {
						var list = OutgoingConnections.get(to);
						if (list == null) {
							(OutgoingConnections[to] = new Array<String>()).push(from);
						} else {
							list.push(from);
						}
					}
				} else {
					trace('Broken Connection ${from} ${to} ${source}');
				}
			}      
			
			for(i in OutgoingConnections.keyValueIterator()) {
				//trace('Connection: ${i.key} -> ${i.value}');
			}
		}
	
	
		public var IDToShape = new Map<String, Xml>();
		public var ShapeToID = new Map<Xml, String>();
		public var RawConnections = new Map<String, String>();
		public var OutgoingConnections = new Map<String, Array<String>>();
	
		public static function connectionId(targetID : String,source:Bool) : String {
			return targetID + "_" + source;
		}
	
		public function walkOutgoingConnections(current:Xml, missingName:String->Void, validConnection:(String, Xml, Xml) -> Void, requireTransitionContent = true) {
			var stateShape = getConcreteShape(current);
			
			var id = scrubLabel(getShapeID(stateShape));
	
			
			if (isEmpty(id))
				return;
			//trace('Walking ${id} [${OutgoingConnections[id]}]w/${OutgoingConnections}' );
	
			var targetIDs = OutgoingConnections[id];
			if (targetIDs != null) {
			  //  trace("Connections " + targetIDs);
	
				for (targetID in targetIDs) {
					var targetNode = IDToShape[targetID];
					//trace('walking ${id} to ${targetID} : ${targetNode} on ${[for (k in IDToShape.keys()) k]}');
	
					if (targetNode != null) {
						if (isStateShape(targetNode)) {
							if (missingName != null)
								missingName(targetID);
						} else if (isTransitionShape(targetNode)) {
							var targetTransition = targetNode;
							var transitionContent = scrubLabel(getTransitionShapeName(targetTransition));
							if (requireTransitionContent && isEmpty(transitionContent)) {
								if (missingName != null)
									missingName(transitionContent);
							} else {
								var finalNodeID = RawConnections[connectionId(targetID,false)];
								if (finalNodeID != null) {
									if (validConnection != null) {
										validConnection(transitionContent, targetTransition, IDToShape[finalNodeID]);
									}    
								} else {
									trace('No connection ${targetID} in ${[for (k in RawConnections.keys()) k]}');
								}
							}
						}
					}
				}
			}
		}
		/*
			public IEnumerable<(Xml, Xml)> WalkOutgoingConnections(Xml current, Action<String> missingName) {
				
				var stateShape = current.GetConcreteShape();
				var id = stateShape.GetShapeID();
				if (String.IsNullOrWhiteSpace(id)) yield break;
	
				if (OutgoingConnections.TryGetValue(id, out var targetIDs)) {
					foreach (var targetID in targetIDs) {
						if (IDToShape.TryGetValue(targetID, out var targetNode)) {
							if (targetNode.IsStateShape()) {
								missingName?.Invoke(targetID);
							}
							else if (targetNode.IsTransitionShape()) {
								var targetTransition = targetNode;
								var transitionContent = targetTransition.GetTransitionShapeName();
								if (String.IsNullOrWhiteSpace(transitionContent)) {
									missingName?.Invoke(transitionContent);
								}
								else {
									var finalNodeID = RawConnections[(targetID, false)];
	
									var finalShape = IDToShape[finalNodeID];
	
									yield return (targetNode, finalShape);
									//.Permit( ETrigger.<#=transitionContent #>, EState.<#= finalNode #> )
								}
							}
						}
					}
	
				}
			}
		 */
	}