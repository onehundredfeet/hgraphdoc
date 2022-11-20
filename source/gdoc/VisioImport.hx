package gdoc;

import sys.io.File;
import haxe.Json;
import tink.core.Pair;
import gdoc.Visio;
import gdoc.VisioXMLTools;
import gdoc.VisioXMLGraphModel;
import gdoc.NodeDoc;
//import gdoc.macro.MacroTools;
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
	public static function loadAsGraphDoc( filepath : String ) : NodeDoc {
		var smArray = Visio.read(filepath);

		var pages = [];

		for (m in smArray) {
            var nodes = [];

			var page : NodeDocPage = {
                name : m.name,
                nodes : nodes
            };
			trace('Found model ${m.name}');

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
                    name : getRawStateShapeName(s),
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
