package gdoc;

import gdoc.NodeGraph;
import gdoc.NodeDoc;
import haxe.ds.IntMap;

class NodeGraphReader {
	public static function fromDoc(doc:NodeDoc, pageName:String):NodeGraph {
		for (page in doc) {
			if (page.name == pageName)
				return fromPage(page);
		}
		return null;
	}

	public static function fromPage(page:NodeDocPage):NodeGraph {
		var g = new NodeGraph();
		var nodeMap = new IntMap<Node>();

		for (doc_n in page.nodes) {
			var graph_n = g.addNode( doc_n.name);

			for (prop in doc_n.properties.keyValueIterator()) {
				graph_n.properties.set(prop.key, prop.value);
			}

			nodeMap.set(doc_n.id, graph_n);
		}
		for (doc_n in page.nodes) {
			var graph_n = nodeMap.get(doc_n.id);

			if (doc_n.parentID != null) {
				var parent_n = nodeMap.get(doc_n.parentID);

				parent_n.connectChild( graph_n );
			}

			if (doc_n.outgoing != null) {
				for (doc_c in doc_n.outgoing) {
					var c = graph_n.connectTo(nodeMap.get(doc_c.id), doc_c.name);

					for (prop in doc_c.properties.keyValueIterator()) {
						c.properties.set(prop.key, prop.value);
					}
				}
			}
		}

		return g;
	}
}
