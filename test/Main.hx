package test;

import seedyrng.Seedy;
import gdoc.SVGGenerate;
import gdoc.NodeGraph;
import gdoc.NodeGraphReader;
import gdoc.NodeDoc;

import gdoc.GraphRewriter;
import gdoc.NodeGraphPrinter;

using Lambda;

class Main {
	static function main() {
		var doc = gdoc.VisioImport.loadAsGraphDoc("data/tests.vdx");

		trace('Doc');
		for (p in doc) {
			trace('Page ${p.name}');
			for (n in p.nodes) {
				trace('\tNode ${n.name} [${n.id}] parent ${n.parent} [${n.parentID}]');
				if (n.properties != null) {
					trace('\t\tProperties');
					for (kv in n.properties.keyValueIterator()) {
						trace('\t\t\tproperty ${kv.key} -> ${kv.value}');
					}
				}
				if (n.outgoing != null && n.outgoing.length > 0) {
					trace('\t\tConnections');
					for (c in n.outgoing) {
						trace('\t\t\tconnection \'${c.name}\' -> ${c.target} [${c.id}]');
						if (c.properties != null) {
							trace('\t\t\t\tProperties');
							for (kv in c.properties.keyValueIterator()) {
								trace('\t\t\t\t\tproperty ${kv.key} -> ${kv.value}');
							}
						}
					}
				}
			}
		}

		trace('Graph');
		var test1Graph = NodeGraphReader.fromDoc(doc, "test1");

		trace('\tPage test1');
		for (n in test1Graph.nodes) {
			trace('\t\tNode ${n.name}');
			var n_parent = n.getParent();
			trace('\t\t\tParent ${n_parent != null ? n_parent.name : "None"}');
			if (n.properties != null) {
				trace('\t\t\tProperties');
				for (kv in n.properties.keyValueIterator()) {
					trace('\t\t\t\tproperty ${kv.key} -> ${kv.value}');
				}

				var n_outgoing = n.getOutgoingEdges().array();
				if (n_outgoing != null && n_outgoing.length > 0) {
					trace('\t\t\tOutgoing Connections');
					for (c in n_outgoing) {
						trace('\t\t\tconnection \'${c.name}\' -> ${c.target.name}');
						if (c.properties != null) {
							trace('\t\t\t\tProperties');
							for (kv in c.properties.keyValueIterator()) {
								trace('\t\t\t\t\tproperty ${kv.key} -> ${kv.value}');
							}
						}
					}
				}

				var n_incoming = n.getIncomingEdges().array();
				if (n_incoming != null && n_incoming.length > 0) {
					trace('\t\t\tIncoming Connections');
					for (c in n_incoming) {
						trace('\t\t\tconnection \'${c.name}\' -> ${c.target.name}');
						if (c.properties != null) {
							trace('\t\t\t\tProperties');
							for (kv in c.properties.keyValueIterator()) {
								trace('\t\t\t\t\tproperty ${kv.key} -> ${kv.value}');
							}
						}
					}
				}
			}
		}

		{
			trace('SVG');
			var testSVGGraph = new NodeGraph();
			var n1 = testSVGGraph.addNode();
			n1.name = "Node 1";
			var n2 = testSVGGraph.addNode();
			n2.name = "Node 2";
			n2.x = 100;
			n2.y = 100;

			testSVGGraph.connectNodes(n1, n2, "connection");

			SVGGenerate.writeNodeGraph("test.svg", testSVGGraph, (node, attr) -> {
				attr.fill = "lightgreen";
				attr.r = 10;
			});
		}

		/// rewrite test
		{
			var rewriteGraph = new NodeGraph();
			var startNode = rewriteGraph.addNode();
            startNode.name = "Start";
            var endNode = rewriteGraph.addNode();
            endNode.name = "End";
            rewriteGraph.connectNodes(startNode, endNode, "first");

            trace('Initial Graph');
            trace(NodeGraphPrinter.graphToString(rewriteGraph));

			var rules = [
				new Rule([new EdgePattern(DirAny, MatchAny)], new OpSplitEdge(new MetaEdge(MStrLiteral("incoming")), new MetaEdge(MStrLiteral("outgoing")), new MetaNode(MStrLiteral("split")))),
                new Rule([new NodePattern(MatchString("Start"))], new OpAddNode(new MetaEdge(MStrLiteral("NewStartExtension")),new MetaNode(MStrLiteral("NewExpansion")))),
                new Rule([new NodePattern(MatchString("End"))], new OpAddNode(new MetaEdge(MStrLiteral("NewEndExtension")),new MetaNode(MStrLiteral("NewEndExpansion")))),
			];
			var engine = new RewriteEngine(rules, [(_)-> return Seedy.random() * 10]);
            var out = engine.applyBest(rewriteGraph);

            if (out != null) {
                trace('Resulting Graph');

                trace(NodeGraphPrinter.graphToString(out));
            } else {
                trace("No rewrite found");
            }


		}
	}
}
