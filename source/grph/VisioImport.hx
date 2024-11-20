package grph;

import sys.io.File;
import haxe.Json;
import grph.VisioXMLTools;
import grph.VisioXMLGraphModel;
import grph.NodeDoc;
//import grph.macro.MacroTools;
import haxe.ds.StringMap;

using StringTools;

class VisioImport {

    static function getPath( n : Xml) : String {
        if (isGroupProxy(n)) {
            n = getParentGroup(n);
        }

        var p = n.parent;
        var i = 0;
        var base = getParentGroup(n) != null ? getPath(getParentGroup(n)) : "";

        for (x in p.iterator()) {
            if (x == n) {
                return base + "|" + i;
            }
            i++;
        }

        throw "Node not found in parent";
    }
    static function asDynMap(properties : StringMap<String>)  {
        var dynmap  = new  haxe.DynamicAccess<String>();
        for (kv in properties.keyValueIterator()) {
            dynmap.set(kv.key, kv.value);
        }
        return dynmap;
    }

    static function parseMachine( page : Xml ) {
        var shapes = getAllShapes(page);

        for(s in shapes) {
            //trace ("s: " + s.nodeName);
        }
        var sm = new VisioXMLGraphModel(
            page.get("NameU"),
            shapes,
            shapes.filter(isStateShape),
            getAllConnections(page),
            shapes.filter(isTransitionShape)
        );



        /*
        _name = page.GetAttribute("NameU");
        var _settings = Import.GetSettings(page);
        _shapes = Import.GetAllShapes(page);
        _stateShapes = Import.SelectStateShapes(_shapes);
        _connections = Import.GetConnections(page);
        _transitions = Import.SelectTransitionShapes(_shapes);

        _graph = Import.BuildGraph(_shapes, _connections);

        _defaultState = _stateShapes.FirstOrDefault(x => x.HasProp("default")).GetStateShapeName();
        if (_defaultState == null) {
            _defaultState = "DEFAULT";
        }

        if (_settings != null) {
            Reactive = _settings.HasProp("reactive");
            ReEntrant = _settings.HasProp("reentrant");
        }

        _stateNames = _stateShapes.Select(Import.GetStateShapeName).Where(x => x != null).Select(ParseUtil.ScrubLabel).Distinct().ToArray();
        _transitionNames = _transitions.Select(Import.GetTransitionShapeName).Where(x => x != null).Select(ParseUtil.ScrubLabel).Distinct().ToArray();
    }
        */
        return sm;
    }

    static function getPages(root : Xml) : Array<Xml>{
        return getChildrenOf( root, "Pages");
    }
    static function read( path ) {
        var contents = sys.io.File.getContent(path);
        var root = Xml.parse(contents).firstElement();

        var machines = [];

        for( p in getPages( root )) {
            machines.push(parseMachine( p ));
        }

        return machines;
    }


	public static function loadAsGraphDoc( filepath : String ) : NodeDoc {
		var smArray = read(filepath);

		var pages = [];

		for (m in smArray) {
            var nodes = [];

			var page : NodeDocPage = {
                name : m.name,
                nodes : nodes
            };

            var stateIDs = new haxe.ds.StringMap<Int>();
            var stateIDCount = 0;
            for (s in m.stateShapes) {
                if (isGroupProxy(s)) {
					s = getParentGroup(s);
				}
                stateIDs.set(getPath(s),stateIDCount++);
            }

            
			for (s in m.stateShapes) {
                if (isGroupProxy(s)) {
					s = getParentGroup(s);
				}
                
				var node : DocNode = {
                    name : getStateShapeName(s),
                    id : stateIDs.get(getPath(s)),
                    properties: asDynMap(getPropertyMap(s))
                };
                

                var pg = getParentGroup(s);
				if (pg != null) {
                    var p = getRawStateShapeName(pg);                    
					node.parent = p;
                    node.parentID = stateIDs.get(getPath(pg));
                }
                /*
                if (isGroupNode(s)) {
                    var children = [];
                    var shapes = getShapes(s);
                    for (c in shapes) {
                        if (!isGroupProxy(c)) {
                            children.push( getRawStateShapeName(c));
                        }
                    }
                    node.children = children;
                }
                */

                var outgoing = [];
                m.walkOutgoingConnections(s, x -> {}, (trigger, triggerXML, targetState) -> {
                    var connection : DocNodeConnection = {
                        target : getStateShapeName(targetState ),
                        name : trigger,
                        id : stateIDs.get(getPath(targetState)),
                        properties: asDynMap(getPropertyMap(triggerXML))
                    };

                    outgoing.push(connection);
                }, false);
                if (outgoing.length > 0) {
                    node.outgoing = outgoing;
                }
                
               
				nodes.push(node);
			}
			
            
			pages.push(page);
		}

        return pages;
//		File.saveContent("out.json", Json.stringify(pages, null, "\t"));
	}
}
