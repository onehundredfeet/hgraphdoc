package test;

import gdoc.Quad2D;
import gdoc.PrimConnectivity2D;
import gdoc.Rect2D;
import gdoc.Poisson2D;
import gdoc.PointField2D;
import gdoc.Polygon2D;
import haxe.Int64;
import gdoc.FaceMesh3D.FaceMesh3DFace;
import seedyrng.Seedy;
import gdoc.Random;
import gdoc.SVGGenerate;
import gdoc.NodeGraph;
import gdoc.NodeGraphReader;
import gdoc.NodeDoc;
import gdoc.GraphRewriter;
import gdoc.NodeGraphPrinter;
import gdoc.HalfEdgeMesh2D;
import gdoc.QuickHull3D;
import gdoc.Point3D;
import gdoc.Point2D;
import gdoc.PowerDiagram;
import gdoc.WeightedPoint2D;
import gdoc.EarClipping;
import gdoc.Triangle2D;
import gdoc.DelaunayTriangulator;
import gdoc.TriangleFilter;
import gdoc.Relax;
import gdoc.SVGWriter;
import gdoc.Prim2D;
import gdoc.PrimConnectivity2D;
import gdoc.Triangle2D;

using Lambda;

class GraphMain {
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
				new Rule([new EdgePattern([], DirAny)],
					new OpSplitEdge(new MetaEdge(MStrLiteral("incoming")), new MetaEdge(MStrLiteral("outgoing")), new MetaNode(MStrLiteral("split")))),
				new Rule([new NodePattern([MString("Start")])],
					new OpAddNode(new MetaEdge(MStrLiteral("NewStartExtension")), new MetaNode(MStrLiteral("NewExpansion")))),
				new Rule([new NodePattern([MString("End")])],
					new OpAddNode(new MetaEdge(MStrLiteral("NewEndExtension")), new MetaNode(MStrLiteral("NewEndExpansion")))),
			];

			var out = GraphRewriter.applyBest(rewriteGraph, rules, [(_) -> return Seedy.random() * 10]);

			if (out != false) {
				trace('Resulting Graph');

				trace(NodeGraphPrinter.graphToString(rewriteGraph));
			} else {
				trace("No rewrite found");
			}
		}

		testTetrahedron();
		testCube();
		testOctahedron();
		testCoplanarPoints();
		testColinearPoints();
		testDuplicatePoints();
		testRandomPointCloud();
		testLargeDataset();
		powerTestEquilateralTriangle();

		testSquareEqualWeights();
		testSquareRandomWeights();
		testFiveEqualWeights();
		randomEqualWeights();

		testConvexTriangle();
		testConvexSquare();
		testConvexPentagon();
		testConcaveArrow();
		testConcaveStar();
		testPolygonWithColinearPoints();
		testPolygonWithDuplicatePoints();
		testDegeneratePolygons();

		dttestPointInCircumcircle();
		dttestTriangleEquality();
		dttestSimpleTriangle();
		dttestConvexSquare();
		dttestConvexPentagon();
		dttestConcavePolygon();
		dttestRandomPointCloud();
		dttestColinearPoints();
		dttestDuplicatePoints();
		dttestDegenerateCases();

		tftestTrianglesCompletelyInsidePolygon();
		tftestTrianglesPartiallyOverlappingPolygon();
		tftestTrianglesCompletelyOutsidePolygon();
		tftestTrianglesSharingEdgesWithPolygon();
		tftestTrianglesWithMultiplePolygons();
		tftestDegenerateTriangles();

		pftestGenerateEdgePoints();
		pftestGenerateInteriorPoints();
		pftestGeneratePointField();
		pftestMerge();

		relaxTriFunadmental();

		heBasic();

		primDisolve();
		primDisolveVert();
		primCollapseEdge();
		primRemove();
		primSubdivide();
		primAngles();
		primRelax();
	}

	static var passedTests = 0;
	static var failedTests = 0;

	private static function logResult(testName:String, passed:Bool, message:String = ""):Void {
		if (passed) {
			trace("PASS: " + testName);
			passedTests++;
		} else {
			trace("FAIL: " + testName + (message != "" ? " - " + message : ""));
			failedTests++;
		}
	}

	static var random = new Random(Int64.make(123456789, 987654321));

	public static function powerTestEquilateralTriangle():Void {
		var testName = "Equilateral Triangle with Equal Weights";

		try {
			var points2D = [
				WeightedPoint2D.fromPoint2D(new Point2D(0, 0), 1),
				WeightedPoint2D.fromPoint2D(new Point2D(1, 0), 1),
				WeightedPoint2D.fromPoint2D(new Point2D(0.5, Math.sqrt(3) / 2), 1)
			];
			var cells = PowerDiagram.computeCells(points2D, new Point2D(-0.5, -0.5), new Point2D(1.5, 1.5), random);
			// Expected: Each cell should correspond to one point
			var expectedCells = 3;
			var keys = [for (k in cells.keys()) k];
			var actualCells = keys.length;
			var pass1 = Assert.assertEquals(expectedCells, actualCells, "Number of cells should be " + expectedCells);

			// Additional check: Each cell should have at least one dual vertex
			var pass2 = true;
			for (cell in cells) {
				if (cell.length < 1) {
					pass2 = false;
					break;
				}
			}
			var pass = pass1 && pass2;
			logResult(testName, pass, pass ? "" : "One or more cells have no dual vertices.");
		} catch (e:String) {
			logResult(testName, false, "Exception occurred: " + e);
		}
	}

	public static function testSquareEqualWeights():Void {
		var testName = "Square with Equal Weights";
		try {
			var points2D = [
				WeightedPoint2D.fromPoint2D(new Point2D(-1, -1), 1),
				WeightedPoint2D.fromPoint2D(new Point2D(1, -1), 1),
				WeightedPoint2D.fromPoint2D(new Point2D(1, 1), 1),
				WeightedPoint2D.fromPoint2D(new Point2D(-1, 1), 1)
			];
			var cells = PowerDiagram.computeCells(points2D, new Point2D(-2.0, -2.0), new Point2D(2.0, 2.0), random);
			var expectedCells = 4;
			var actualCells = [for (k in cells.keys()) k];
			var pass1 = Assert.assertEquals(expectedCells, actualCells.length, "Number of cells should be " + expectedCells);

			// Check that each cell has at least one dual vertex
			var pass2 = true;
			for (cell in cells) {
				if (cell.length < 1) {
					pass2 = false;
					break;
				}
			}
			var pass = pass1 && pass2;

			SVGGenerate.writePowerDiagram("pd_equal.svg", cells, points2D);

			logResult(testName, pass, pass ? "" : "One or more cells have no dual vertices.");
		} catch (e:String) {
			logResult(testName, false, "Exception occurred: " + e);
		}
	}

	public static function testSquareRandomWeights():Void {
		var random = new Random(Int64.make(123456789, 987654321));
		var testName = "Square with Random Weights";
		try {
			var points2D = [
				WeightedPoint2D.fromPoint2D(new Point2D(-1, -1), random.random() * 3.0 + 0.5),
				WeightedPoint2D.fromPoint2D(new Point2D(1, -1), random.random() * 3.0 + 0.5),
				WeightedPoint2D.fromPoint2D(new Point2D(1, 1), random.random() * 3.0 + 0.5),
				WeightedPoint2D.fromPoint2D(new Point2D(-1, 1), random.random() * 3.0 + 0.5)
			];
			var cells = PowerDiagram.computeCells(points2D, new Point2D(-2.0, -2.0), new Point2D(2.0, 2.0), random);
			var expectedCells = 4;
			var actualCells = [for (k in cells.keys()) k];
			var pass1 = Assert.assertEquals(expectedCells, actualCells.length, "Number of cells should be " + expectedCells);

			// Check that each cell has at least one dual vertex
			var pass2 = true;
			for (cell in cells) {
				if (cell.length < 1) {
					pass2 = false;
					break;
				}
			}
			var pass = pass1 && pass2;

			SVGGenerate.writePowerDiagram("pd_random.svg", cells, points2D);

			logResult(testName, pass, pass ? "" : "One or more cells have no dual vertices.");
		} catch (e:String) {
			logResult(testName, false, "Exception occurred: " + e);
		}
	}

	public static function testFiveEqualWeights():Void {
		var testName = "Five with Equal Weights";
		try {
			var points2D = [
				WeightedPoint2D.fromPoint2D(new Point2D(-1, -1), 1),
				WeightedPoint2D.fromPoint2D(new Point2D(1, -1), 1),
				WeightedPoint2D.fromPoint2D(new Point2D(0, 0), 1),
				WeightedPoint2D.fromPoint2D(new Point2D(1, 1), 1),
				WeightedPoint2D.fromPoint2D(new Point2D(-1, 1), 1)
			];
			var cells = PowerDiagram.computeCells(points2D, new Point2D(-2.0, -2.0), new Point2D(2.0, 2.0), random);
			var expectedCells = points2D.length;
			var actualCells = [for (k in cells.keys()) k];
			var pass1 = Assert.assertEquals(expectedCells, actualCells.length, "Number of cells should be " + expectedCells);

			// Check that each cell has at least one dual vertex
			var pass2 = true;
			for (cell in cells) {
				if (cell.length < 1) {
					pass2 = false;
					break;
				}
			}
			var pass = pass1 && pass2;

			SVGGenerate.writePowerDiagram("five_equal.svg", cells, points2D);

			logResult(testName, pass, pass ? "" : "One or more cells have no dual vertices.");
		} catch (e:String) {
			logResult(testName, false, "Exception occurred: " + e);
		}
	}

	public static function randomEqualWeights():Void {
		var testName = "Random with Equal Weights";
		try {
			var rand = new Random(Int64.make(334343, 124544));

			var count = rand.randomInt(10, 20);

			var points2D = [];
			for (i in 0...count) {
				points2D.push(new WeightedPoint2D(rand.random() * 10 - 5, rand.random() * 10 - 5, 1));
			}

			var cells = PowerDiagram.computeCells(points2D, new Point2D(-10.0, -10.0), new Point2D(10.0, 10.0), random);
			var expectedCells = points2D.length;
			var actualCells = [for (k in cells.keys()) k];
			var pass1 = Assert.assertEquals(expectedCells, actualCells.length, "Number of cells should be " + expectedCells);

			// Check that each cell has at least one dual vertex
			var pass2 = true;
			for (cell in cells) {
				if (cell.length < 1) {
					pass2 = false;
					break;
				}
			}
			var pass = pass1 && pass2;

			SVGGenerate.writePowerDiagram("random_equal.svg", cells, points2D);

			logResult(testName, pass, pass ? "" : "One or more cells have no dual vertices.");
		} catch (e:String) {
			logResult(testName, false, "Exception occurred: " + e);
		}
	}

	// Test 1: Tetrahedron
	private static function testTetrahedron():Void {
		trace("\nTest 1: Tetrahedron");
		var points = [
			new Point3D(0, 0, 0),
			new Point3D(1, 0, 0),
			new Point3D(0, 1, 0),
			new Point3D(0, 0, 1)
		];

		runTest(points, 4);
	}

	// Test 2: Cube
	private static function testCube():Void {
		trace("\nTest 2: Cube");
		var points = [
			new Point3D(0, 0, 0),
			new Point3D(1, 0, 0),
			new Point3D(1, 1, 0),
			new Point3D(0, 1, 0),
			new Point3D(0, 0, 1),
			new Point3D(1, 0, 1),
			new Point3D(1, 1, 1),
			new Point3D(0, 1, 1)
		];

		runTest(points, 12);
	}

	// Test 3: Octahedron
	private static function testOctahedron():Void {
		trace("\nTest 3: Octahedron");
		var points = [
			new Point3D(1, 0, 0),
			new Point3D(-1, 0, 0),
			new Point3D(0, 1, 0),
			new Point3D(0, -1, 0),
			new Point3D(0, 0, 1),
			new Point3D(0, 0, -1)
		];

		runTest(points, 8);
	}

	// Test 4: Coplanar Points
	private static function testCoplanarPoints():Void {
		trace("\nTest 4: Coplanar Points");
		var points = [
			new Point3D(0, 0, 0),
			new Point3D(1, 0, 0),
			new Point3D(1, 1, 0),
			new Point3D(0, 1, 0),
			new Point3D(0.5, 0.5, 0)
		];

		try {
			runTest(points, 0);
		} catch (e:String) {
			trace("Expected Exception: " + e);
		}
	}

	// Test 5: Colinear Points
	private static function testColinearPoints():Void {
		trace("\nTest 5: Colinear Points");
		var points = [
			new Point3D(0, 0, 0),
			new Point3D(1, 1, 1),
			new Point3D(2, 2, 2),
			new Point3D(3, 3, 3)
		];

		try {
			runTest(points, 0);
		} catch (e:String) {
			trace("Expected Exception: " + e);
		}
	}

	// Test 6: Duplicate Points
	private static function testDuplicatePoints():Void {
		trace("\nTest 6: Duplicate Points");
		var points = [
			new Point3D(0, 0, 0),
			new Point3D(1, 0, 0),
			new Point3D(1, 1, 0),
			new Point3D(0, 1, 0),
			new Point3D(0, 0, 0), // Duplicate
			new Point3D(1, 1, 0) // Duplicate
		];

		runTest(points, 4);
	}

	// Test 7: Random Point Cloud
	private static function testRandomPointCloud():Void {
		trace("\nTest 7: Random Point Cloud");
		var points = [];
		var numPoints = 8;
		var rand = new Random(Int64.make(334343, 124544));

		for (i in 0...numPoints) {
			var x = rand.random() * 10 - 5; // Random float between -5 and 5
			var y = rand.random() * 10 - 5;
			var z = rand.random() * 10 - 5;
			points.push(new Point3D(x, y, z));
		}

		runTest(points);
	}

	// Test 8: Large Dataset
	private static function testLargeDataset():Void {
		trace("\nTest 8: Large Dataset");
		var points = [];
		var numPoints = 1000;
		var rand = new Random(Int64.make(12356789, 98764321));

		var pointMap = new Map<String, Bool>();

		for (i in 0...numPoints) {
			var x = rand.random() * 100 - 50;
			var y = rand.random() * 100 - 50;
			var z = rand.random() * 100 - 50;
			var key = x + ',' + y + ',' + z;
			if (pointMap.exists(key)) {
				trace('Duplicate point: ' + key);
				continue;
			}
			pointMap.set(key, true);
			points.push(new Point3D(x, y, z));
		}

		runTest(points);
	}

	// Helper function to run a test
	private static function runTest(points:Array<Point3D>, ?expectedFaceCount:Int = null):Void {
		try {
			var quickHull = new QuickHull3D(points);
			var faceCount = quickHull.faces.length;
			trace('Computed Convex Hull with ' + faceCount + ' faces.');

			if (expectedFaceCount != null) {
				if (faceCount == expectedFaceCount) {
					trace('Test passed: Expected face count matches computed face count.');
				} else {
					trace('Test failed: Expected ' + expectedFaceCount + ' faces, but got ' + faceCount + ' faces.');
				}
			} else {
				trace('Test completed without expected face count.');
			}

			// Optional: Verify convexity and correctness
			verifyConvexity(quickHull.faces, points);
		} catch (e:String) {
			trace('Exception during convex hull computation: ' + e);
		}
	}

	// Optional function to verify convexity (not implemented here)
	private static function verifyConvexity(faces:Array<FaceMesh3DFace>, points:Array<Point3D>):Void {
		// Check that all faces are correctly oriented and that all points lie on or inside the convex hull

		// For each face, verify that:
		// 1. The face is correctly oriented (normals point outward)
		// 2. No point lies outside the convex hull (i.e., in front of any face)

		var hullCentroid = computeCentroid(points);

		for (face in faces) {
			// Check if the face normal points away from the interior point
			if (face.isPointAbove(hullCentroid)) {
				throw('Convexity check failed: Face normal points inward: v ${face.vertices[0]} n ${face.normal} -> c ${hullCentroid}');
			}

			// Now, check that no external point lies outside this face
			for (point in points) {
				// Skip the vertices of the face
				if (face.vertices.indexOf(point) != -1)
					continue;

				if (face.isPointAbove(point)) {
					throw 'Convexity check failed: Point ${point.toString()} lies outside the convex hull by ${face.distanceToPoint(point)} : v ${face.vertices} n ${face.normal} -> ${point}';
				}
			}
		}

		trace('Convexity check passed: All points lie on or inside the convex hull, and all faces are correctly oriented.');
	}

	/**
	 * Test triangulation of a simple convex triangle.
	 */
	static function testConvexTriangle():Void {
		trace("Running EarClipping testConvexTriangle...");
		var polygon = [new Point2D(0, 0), new Point2D(1, 0), new Point2D(0, 1)];

		var triangles = EarClipping.triangulate(polygon);

		// Expecting one triangle
		Assert.assertEquals(1, triangles.length, "Convex Triangle: Incorrect number of triangles");

		// Verify the triangle matches the polygon
		var tri = triangles[0];
		Assert.assertTrue((tri.a == polygon[0] && tri.b == polygon[1] && tri.c == polygon[2])
			|| (tri.a == polygon[1] && tri.b == polygon[2] && tri.c == polygon[0])
			|| (tri.a == polygon[2] && tri.b == polygon[0] && tri.c == polygon[1]),
			"Convex Triangle: Triangle vertices do not match polygon vertices");
	}

	/**
	 * Test triangulation of a convex square.
	 */
	static function testConvexSquare():Void {
		trace("Running EarClipping testConvexSquare...");
		var polygon = [new Point2D(0, 0), new Point2D(2, 0), new Point2D(2, 2), new Point2D(0, 2)];

		var triangles = EarClipping.triangulate(polygon);

		// Expecting two triangles
		Assert.assertEquals(2, triangles.length, "Convex Square: Incorrect number of triangles");

		// Verify total area
		var polygonArea = computePolygonArea(polygon);
		var totalTriArea = 0.0;
		for (tri in triangles) {
			totalTriArea += computeTriangleArea(tri);
		}
		Assert.assertTrue(Math.abs(polygonArea - totalTriArea) < 1e-6, "Convex Square: Total triangle area does not match polygon area");
	}

	/**
	 * Test triangulation of a convex pentagon.
	 */
	static function testConvexPentagon():Void {
		trace("Running EarClipping testConvexPentagon...");
		var polygon = [
			new Point2D(0, 0),
			new Point2D(2, 0),
			new Point2D(3, 1),
			new Point2D(1.5, 3),
			new Point2D(0, 2)
		];

		var triangles = EarClipping.triangulate(polygon);

		// Expecting three triangles
		Assert.assertEquals(3, triangles.length, "Convex Pentagon: Incorrect number of triangles");

		// Verify total area
		var polygonArea = computePolygonArea(polygon);
		var totalTriArea = 0.0;
		for (tri in triangles) {
			totalTriArea += computeTriangleArea(tri);
		}
		Assert.assertTrue(Math.abs(polygonArea - totalTriArea) < 1e-6, "Convex Pentagon: Total triangle area does not match polygon area");
	}

	/**
	 * Test triangulation of a concave arrow-shaped polygon.
	 */
	static function testConcaveArrow():Void {
		trace("Running EarClipping testConcaveArrow...");
		var polygon = [
			new Point2D(0, 0),
			new Point2D(2, 1),
			new Point2D(4, 0),
			new Point2D(3, 2),
			new Point2D(4, 4),
			new Point2D(2, 3),
			new Point2D(0, 4),
			new Point2D(1, 2)
		];

		var triangles = EarClipping.triangulate(polygon);

		// Expecting six triangles for an octagon (8 vertices)
		Assert.assertEquals(6, triangles.length, "Concave Arrow: Incorrect number of triangles");

		// Verify total area
		var polygonArea = computePolygonArea(polygon);
		var totalTriArea = 0.0;
		for (tri in triangles) {
			totalTriArea += computeTriangleArea(tri);
		}
		Assert.assertTrue(Math.abs(polygonArea - totalTriArea) < 1e-4, "Concave Arrow: Total triangle area does not match polygon area");
	}

	/**
	 * Test triangulation of a concave star-shaped polygon.
	 */
	static function testConcaveStar():Void {
		trace("Running EarClipping testConcaveStar...");
		var polygon = [
			new Point2D(0, 3),
			new Point2D(1, 1),
			new Point2D(3, 1),
			new Point2D(1.5, -1),
			new Point2D(2.5, -3),
			new Point2D(0, -2),
			new Point2D(-2.5, -3),
			new Point2D(-1.5, -1),
			new Point2D(-3, 1),
			new Point2D(-1, 1)
		];

		var triangles = EarClipping.triangulate(polygon);

		// Expecting eight triangles for a decagon (10 vertices)
		Assert.assertEquals(8, triangles.length, "Concave Star: Incorrect number of triangles");

		// Verify total area
		var polygonArea = computePolygonArea(polygon);
		var totalTriArea = 0.0;
		for (tri in triangles) {
			totalTriArea += computeTriangleArea(tri);
		}
		Assert.assertTrue(Math.abs(polygonArea - totalTriArea) < 1e-4, "Concave Star: Total triangle area does not match polygon area");
	}

	/**
	 * Test triangulation of a polygon with colinear points.
	 */
	static function testPolygonWithColinearPoints():Void {
		trace("Running EarClipping testPolygonWithColinearPoints...");
		var polygon = [
			new Point2D(0, 0),
			new Point2D(2, 0),
			new Point2D(4, 0), // Colinear point
			new Point2D(4, 2),
			new Point2D(2, 2),
			new Point2D(0, 2)
		];

		var triangles = EarClipping.triangulate(polygon);

		// Expecting four triangles for a hexagon (6 vertices) with one colinear point
		Assert.assertEquals(4, triangles.length, "Polygon with Colinear Points: Incorrect number of triangles");

		// Verify total area
		var polygonArea = computePolygonArea(polygon);
		var totalTriArea = 0.0;
		for (tri in triangles) {
			totalTriArea += computeTriangleArea(tri);
		}
		Assert.assertTrue(Math.abs(polygonArea - totalTriArea) < 1e-4, "Polygon with Colinear Points: Total triangle area does not match polygon area");
	}

	/**
	 * Test triangulation of a polygon with duplicate consecutive points.
	 */
	static function testPolygonWithDuplicatePoints():Void {
		trace("Running EarClipping testPolygonWithDuplicatePoints...");
		var polygon = [
			new Point2D(0, 0),
			new Point2D(2, 0),
			new Point2D(2, 0), // Duplicate point
			new Point2D(2, 2),
			new Point2D(0, 2)
		];

		var triangles = EarClipping.triangulate(polygon);

		// After removing duplicate, it's a pentagon with 5 vertices, expecting 3 triangles
		Assert.assertEquals(2, triangles.length, "Polygon with Duplicate Points: Incorrect number of triangles");

		// Verify total area
		var cleanedPolygon = removeDuplicatePoints(polygon);
		var polygonArea = computePolygonArea(cleanedPolygon);
		var totalTriArea = 0.0;
		for (tri in triangles) {
			totalTriArea += computeTriangleArea(tri);
		}
		Assert.assertTrue(Math.abs(polygonArea - totalTriArea) < 1e-4, "Polygon with Duplicate Points: Total triangle area does not match polygon area");
	}

	/**
	 * Test triangulation of degenerate polygons.
	 */
	static function testDegeneratePolygons():Void {
		trace("Running EarClipping testDegeneratePolygons...");

		// Test with less than 3 points
		var polygon1 = [new Point2D(0, 0), new Point2D(1, 1)];

		var triangles1 = EarClipping.triangulate(polygon1);
		Assert.assertEquals(0, triangles1.length, "Degenerate Polygon (2 points): Should return no triangles");

		// Test with exactly 3 points (triangle)
		var polygon2 = [new Point2D(0, 0), new Point2D(1, 0), new Point2D(0, 1)];

		var triangles2 = EarClipping.triangulate(polygon2);
		Assert.assertEquals(1, triangles2.length, "Degenerate Polygon (3 points): Should return one triangle");

		// Test with duplicate all points
		var polygon3 = [new Point2D(0, 0), new Point2D(0, 0), new Point2D(0, 0)];

		var triangles3 = EarClipping.triangulate(polygon3);
		Assert.assertEquals(0, triangles3.length, "Degenerate Polygon (all duplicate points): Should return no triangles");

		// Test with a polygon that has all colinear points
		var polygon4 = [new Point2D(0, 0), new Point2D(1, 1), new Point2D(2, 2), new Point2D(3, 3)];

		var triangles4 = EarClipping.triangulate(polygon4);
		Assert.assertEquals(0, triangles4.length, "Degenerate Polygon (all colinear points): Should return no triangles");
	}

	/**
	 * Helper function to compute the area of a polygon using the shoelace formula.
	 * @param vertices An array of Point2D representing the polygon vertices in order.
	 * @return The absolute area of the polygon.
	 */
	static function computePolygonArea(vertices:Array<Point2D>):Float {
		var area = 0.0;
		var n = vertices.length;
		for (i in 0...n) {
			var current = vertices[i];
			var next = vertices[(i + 1) % n];
			area += (current.x * next.y) - (next.x * current.y);
		}
		return Math.abs(area) / 2.0;
	}

	/**
	 * Helper function to compute the area of a triangle.
	 * @param tri The Triangle2D object.
	 * @return The absolute area of the triangle.
	 */
	static function computeTriangleArea(tri:Triangle2D):Float {
		return Math.abs(Point2D.orientation(tri.a, tri.b, tri.c)) / 2.0;
	}

	/**
	 * Helper function to remove consecutive duplicate points from a polygon.
	 * @param polygon An array of Point2D.
	 * @return A new array of Point2D without consecutive duplicates.
	 */
	static function removeDuplicatePoints(polygon:Array<Point2D>):Array<Point2D> {
		if (polygon.length == 0)
			return [];
		var cleaned = [polygon[0]];
		for (i in 1...polygon.length) {
			if (!polygon[i].eqval(cleaned[cleaned.length - 1])) {
				cleaned.push(polygon[i]);
			}
		}
		// Check if first and last points are duplicates
		if (cleaned.length > 1 && cleaned[0].eqval(cleaned[cleaned.length - 1])) {
			cleaned.pop();
		}
		return cleaned;
	}

	static function dtcreateTriangle(a:Point2D, b:Point2D, c:Point2D):Triangle2D {
		var tri = new Triangle2D(a, b, c);
		if (!tri.isCounterClockwise()) {
			tri = new Triangle2D(a, c, b);
		}
		return tri;
	}

	static function dttestPointInCircumcircle():Void {
		trace("Running DelaunayTriangulator dttestPointInCircumcircle...");
		var p1 = new Point2D(0, 0);
		var p2 = new Point2D(4, 0);
		var p3 = new Point2D(2, 3);
		var tri = new Triangle2D(p1, p2, p3);

		var insidePoint = new Point2D(2, 1);
		var outsidePoint = new Point2D(2, 4);

		Assert.assertTrue(tri.circumCircleContains(insidePoint), "Point should be inside the circumcircle");
		Assert.assertTrue(!tri.circumCircleContains(outsidePoint), "Point should be outside the circumcircle");
	}

	/**
	 * Test the eqval function for Triangle2D.
	 */
	static function dttestTriangleEquality():Void {
		trace("Running DelaunayTriangulator testTriangleEquality...");

		var p1 = new Point2D(0, 0);
		var p2 = new Point2D(1, 0);
		var p3 = new Point2D(0, 1);
		var p4 = new Point2D(1, 1);

		// Create triangles with consistent CCW orientation
		var tri1 = dtcreateTriangle(p1, p2, p3); // (0,0), (1,0), (0,1)
		var tri2 = dtcreateTriangle(p2, p3, p1); // Cyclic permutation
		var tri3 = dtcreateTriangle(p3, p1, p2); // Cyclic permutation
		var tri4 = dtcreateTriangle(p1, p3, p2); // Should be reordered to CCW

		// Assert equality
		Assert.assertTrue(tri1.eqvalCCW(tri2), "tri1 should equal tri2");
		Assert.assertTrue(tri1.eqvalCCW(tri3), "tri1 should equal tri3");
		Assert.assertTrue(tri1.eqvalCCW(tri4), "tri1 should equal tri4 after orientation correction");

		// Create a different triangle
		var tri5 = dtcreateTriangle(p1, p2, p4); // Different set of vertices
		Assert.assertTrue(!tri1.eqvalCCW(tri5), "tri1 should not equal tri5");
	}

	/**
	 * Test triangulation of a simple triangle.
	 */
	static function dttestSimpleTriangle():Void {
		trace("Running DelaunayTriangulator testSimpleTriangle...");
		var points = [new Point2D(0, 0), new Point2D(1, 0), new Point2D(0, 1)];

		var triangles = DelaunayTriangulator.triangulate(points);
		Assert.assertEquals(1, triangles.length, "Simple Triangle: Incorrect number of triangles");

		var trianglesFast = DelaunayTriangulator.triangulateFast(points);
		// Expecting one triangle

		var tri = triangles[0];
		Assert.assertTrue((tri.a.eqval(points[0]) && tri.b.eqval(points[1]) && tri.c.eqval(points[2]))
			|| (tri.a.eqval(points[1]) && tri.b.eqval(points[2]) && tri.c.eqval(points[0]))
			|| (tri.a.eqval(points[2]) && tri.b.eqval(points[0]) && tri.c.eqval(points[1])),
			"Simple Triangle: Triangle vertices do not match input points");

		Assert.assertEquals(trianglesFast.length, 1, "Simple Triangle: Incorrect number of triangles (fast)");
		// Verify circumcircle does not contain any other points (none in this case)
	}

	/**
	 * Test triangulation of a convex square.
	 */
	static function dttestConvexSquare():Void {
		trace("Running DelaunayTriangulator testConvexSquare...");
		var points = [new Point2D(0, 0), new Point2D(2, 0), new Point2D(2, 2), new Point2D(0, 2)];

		var triangles = DelaunayTriangulator.triangulate(points);

		// Expecting two triangles
		Assert.assertEquals(2, triangles.length, "Convex Square: Incorrect number of triangles");

		var trianglesFast = DelaunayTriangulator.triangulateFast(points);
		// Expecting one triangle

		trace('Fast Delaunay Triangulation (Square): ' + trianglesFast);

		// Verify that each triangle's circumcircle does not contain any other points
		for (tri in triangles) {
			for (p in points) {
				if (tri.containsPoint(p))
					continue;
				Assert.assertTrue(!tri.circumCircleContains(p), "Convex Square: Point " + p.toString() + " lies inside the circumcircle of a triangle");
			}
		}
	}

	/**
	 * Test triangulation of a convex pentagon.
	 */
	static function dttestConvexPentagon():Void {
		trace("Running DelaunayTriangulator testConvexPentagon...");
		var points = [
			new Point2D(0, 0),
			new Point2D(2, 0),
			new Point2D(3, 1),
			new Point2D(1.5, 3),
			new Point2D(0, 2)
		];

		var triangles = DelaunayTriangulator.triangulate(points);

		// Expecting three triangles
		Assert.assertEquals(3, triangles.length, "Convex Pentagon: Incorrect number of triangles");

		// Verify Delaunay condition
		for (tri in triangles) {
			for (p in points) {
				if (tri.containsPoint(p))
					continue;
				Assert.assertTrue(!tri.circumCircleContains(p), "Convex Pentagon: Point " + p.toString() + " lies inside the circumcircle of a triangle");
			}
		}
	}

	/**
	 * Test triangulation of a concave polygon.
	 */
	static function dttestConcavePolygon():Void {
		trace("Running DelaunayTriangulator testConcavePolygon...");
		var points = [
			new Point2D(0, 0),
			new Point2D(2, 1),
			new Point2D(4, 0),
			new Point2D(3, 2),
			new Point2D(4, 4),
			new Point2D(2, 3),
			new Point2D(0, 4),
			new Point2D(1, 2)
		];

		var triangles = DelaunayTriangulator.triangulate(points);

		Assert.assertEquals(10, triangles.length, "Concave Polygon: Incorrect number of triangles");

		// Verify Delaunay condition
		for (tri in triangles) {
			for (p in points) {
				if (tri.containsPoint(p))
					continue;
				Assert.assertTrue(!tri.circumCircleContains(p), "Concave Polygon: Point " + p.toString() + " lies inside the circumcircle of a triangle");
			}
		}
	}

	/**
	 * Test triangulation of a random point cloud.
	 */
	static function dttestRandomPointCloud():Void {
		trace("Running DelaunayTriangulator testRandomPointCloud...");
		var points = new Array<Point2D>();
		var random = new Random();
		var numPoints = 100;
		for (i in 0...numPoints) {
			var x = random.random() * 100;
			var y = random.random() * 100;
			points.push(new Point2D(x, y));
		}

		var triangles = DelaunayTriangulator.triangulate(points);

		// For n points, expect roughly 2n - 5 triangles (Euler's formula for planar graphs)
		var expectedTriangles = 2 * numPoints - 5;
		Assert.assertTrue(triangles.length >= expectedTriangles * 0.9 && triangles.length <= expectedTriangles * 1.1,
			"Random Point Cloud: Number of triangles deviates significantly from expected");

		// Verify Delaunay condition
		for (tri in triangles) {
			for (p in points) {
				if (tri.containsPoint(p))
					continue;
				Assert.assertTrue(!tri.circumCircleContains(p), "Random Point Cloud: Point " + p.toString() + " lies inside the circumcircle of a triangle");
			}
		}
	}

	/**
	 * Test triangulation with colinear points.
	 */
	static function dttestColinearPoints():Void {
		trace("Running DelaunayTriangulator testColinearPoints...");
		var points = [
			new Point2D(0, 0),
			new Point2D(1, 1),
			new Point2D(2, 2),
			new Point2D(3, 3),
			new Point2D(4, 4)
		];

		var triangles = DelaunayTriangulator.triangulate(points);

		// Colinear points do not form a valid triangulation
		Assert.assertEquals(0, triangles.length, "Colinear Points: Should return no triangles");
	}

	/**
	 * Test triangulation with duplicate points.
	 */
	static function dttestDuplicatePoints():Void {
		trace("Running DelaunayTriangulator testDuplicatePoints...");
		var points = [
			new Point2D(0, 0),
			new Point2D(2, 0),
			new Point2D(2, 0), // Duplicate
			new Point2D(2, 2),
			new Point2D(0, 2)
		];

		var uniquePoints = removeDuplicatePoints(points);
		var expectedTriangles = uniquePoints.length >= 3 ? uniquePoints.length - 2 : 0;

		var triangles = DelaunayTriangulator.triangulate(points);

		Assert.assertEquals(expectedTriangles, triangles.length, "Duplicate Points: Incorrect number of triangles");

		// Verify Delaunay condition
		for (tri in triangles) {
			for (p in uniquePoints) {
				if (tri.containsPoint(p))
					continue;
				Assert.assertTrue(!tri.circumCircleContains(p), "Duplicate Points: Point " + p.toString() + " lies inside the circumcircle of a triangle");
			}
		}
	}

	/**
	 * Test triangulation of degenerate cases.
	 */
	static function dttestDegenerateCases():Void {
		trace("Running DelaunayTriangulator testDegenerateCases...");

		// Less than 3 points
		var points1 = [new Point2D(0, 0), new Point2D(1, 1)];
		var triangles1 = DelaunayTriangulator.triangulate(points1);
		Assert.assertEquals(0, triangles1.length, "Degenerate Case (2 points): Should return no triangles");

		// All points duplicate
		var points2 = [new Point2D(0, 0), new Point2D(0, 0), new Point2D(0, 0)];
		var triangles2 = DelaunayTriangulator.triangulate(points2);
		Assert.assertEquals(0, triangles2.length, "Degenerate Case (all duplicates): Should return no triangles");

		// All points colinear
		var points3 = [new Point2D(0, 0), new Point2D(1, 1), new Point2D(2, 2), new Point2D(3, 3)];
		var triangles3 = DelaunayTriangulator.triangulate(points3);
		Assert.assertEquals(0, triangles3.length, "Degenerate Case (colinear points): Should return no triangles");
	}

	/**
	 * Test Case 1: Triangles Completely Inside a Convex Polygon
	 * Expected Outcome: All such triangles are removed.
	 */
	static function tftestTrianglesCompletelyInsidePolygon():Void {
		trace("Running testTrianglesCompletelyInsidePolygon...");

		// Define a convex polygon (square)
		var polygon = [new Point2D(1, 1), new Point2D(5, 1), new Point2D(5, 5), new Point2D(1, 5)];

		// Define triangles
		var tri1 = new Triangle2D(new Point2D(2, 2), new Point2D(3, 2), new Point2D(2.5, 3)); // Inside
		var tri2 = new Triangle2D(new Point2D(1.5, 1.5), new Point2D(4.5, 1.5), new Point2D(3, 4)); // Inside
		var tri3 = new Triangle2D(new Point2D(6, 6), new Point2D(7, 6), new Point2D(6.5, 7)); // Clearly Outside

		var triangles = [tri1, tri2, tri3];
		var polygons = [polygon];

		var filtered = TriangleFilter.filterTriangles(triangles, polygons);

		// Expected: Only tri3 remains
		Assert.assertEquals(1, filtered.length, "Test 1 Failed: Expected 1 triangle after filtering.");
		if (filtered.length > 0)
			Assert.assertTrue(filtered[0].eqvalUnordered(tri3), "Test 1 Failed: Expected tri3 to remain.");
	}

	/**
	 * Test Case 2: Triangles Partially Overlapping a Convex Polygon
	 * Expected Outcome: All such triangles are removed.
	 */
	static function tftestTrianglesPartiallyOverlappingPolygon():Void {
		trace("Running testTrianglesPartiallyOverlappingPolygon...");

		// Define a convex polygon (triangle)
		var polygon = [new Point2D(2, 2), new Point2D(4, 2), new Point2D(3, 4)];

		// Define triangles
		var tri1 = new Triangle2D(new Point2D(3, 3), new Point2D(5, 3), new Point2D(4, 5)); // Partially Overlapping
		var tri2 = new Triangle2D(new Point2D(1, 1), new Point2D(3, 1), new Point2D(2, 3)); // Partially Overlapping
		var tri3 = new Triangle2D(new Point2D(5, 5), new Point2D(6, 6), new Point2D(7, 5)); // Outside

		var triangles = [tri1, tri2, tri3];
		var polygons = [polygon];

		var filtered = TriangleFilter.filterTriangles(triangles, polygons);

		// Expected: Only tri3 remains
		Assert.assertEquals(1, filtered.length, "Test 2 Failed: Expected 1 triangle after filtering.");
		Assert.assertTrue(filtered[0].eqvalUnordered(tri3), "Test 2 Failed: Expected tri3 to remain.");
	}

	/**
	 * Test Case 3: Triangles Completely Outside All Polygons
	 * Expected Outcome: All such triangles remain.
	 */
	static function tftestTrianglesCompletelyOutsidePolygon():Void {
		trace("Running testTrianglesCompletelyOutsidePolygon...");

		// Define a convex polygon (rectangle)
		var polygon = [new Point2D(2, 2), new Point2D(4, 2), new Point2D(4, 4), new Point2D(2, 4)];

		// Define triangles
		var tri1 = new Triangle2D(new Point2D(0, 0), new Point2D(1, 0), new Point2D(0.5, 1)); // Outside
		var tri2 = new Triangle2D(new Point2D(5, 5), new Point2D(6, 5), new Point2D(5.5, 6)); // Outside

		var triangles = [tri1, tri2];
		var polygons = [polygon];

		var filtered = TriangleFilter.filterTriangles(triangles, polygons);

		// Expected: Both triangles remain
		Assert.assertEquals(2, filtered.length, "Test 3 Failed: Expected 2 triangles after filtering.");
		Assert.assertTrue(filtered[0].eqvalUnordered(tri1), "Test 3 Failed: Expected tri1 to remain.");
		Assert.assertTrue(filtered[1].eqvalUnordered(tri2), "Test 3 Failed: Expected tri2 to remain.");
	}

	/**
	 * Test Case 4: Triangles Sharing Edges with a Polygon
	 * Expected Outcome: Depending on implementation, these triangles may be removed.
	 * For this test, we'll assume that sharing an edge counts as overlapping, hence removed.
	 */
	static function tftestTrianglesSharingEdgesWithPolygon():Void {
		trace("Running testTrianglesSharingEdgesWithPolygon...");

		// Define a convex polygon (triangle)
		var polygon = [new Point2D(2, 2), new Point2D(4, 2), new Point2D(3, 4)];

		// Define triangles
		var tri1 = new Triangle2D(new Point2D(2, 2), new Point2D(4, 2), new Point2D(3, 3)); // Shares edge (2,2)-(4,2)
		var tri2 = new Triangle2D(new Point2D(4, 2), new Point2D(3, 4), new Point2D(5, 4)); // Shares edge (4,2)-(3,4)
		var tri3 = new Triangle2D(new Point2D(1, 1), new Point2D(2, 2), new Point2D(3, 1)); // Shares vertex (2,2)
		var tri4 = new Triangle2D(new Point2D(0, 0), new Point2D(1, 0), new Point2D(0.5, 1)); // Outside

		var triangles = [tri1, tri2, tri3, tri4];
		var polygons = [polygon];

		var filtered = TriangleFilter.filterTriangles(triangles, polygons);

		// Expected: Only tri4 remains
		Assert.assertEquals(1, filtered.length, "Test 4 Failed: Expected 1 triangle after filtering.");
		Assert.assertTrue(filtered[0].eqvalUnordered(tri4), "Test 4 Failed: Expected tri4 to remain.");
	}

	/**
	 * Test Case 5: Triangles with Multiple Polygons (Both Convex and Concave)
	 * Expected Outcome: Triangles overlapping with any polygon are removed.
	 */
	static function tftestTrianglesWithMultiplePolygons():Void {
		trace("Running testTrianglesWithMultiplePolygons...");

		// Define two polygons: one convex and one concave
		var convexPolygon = [new Point2D(1, 1), new Point2D(3, 1), new Point2D(3, 3), new Point2D(1, 3)];

		var concavePolygon = [
			new Point2D(4, 1),
			new Point2D(6, 1),
			new Point2D(6, 3),
			new Point2D(5, 2),
			new Point2D(4, 3)
		];

		// Define triangles
		var tri1 = new Triangle2D(new Point2D(2, 2), new Point2D(3, 2), new Point2D(2.5, 2.5)); // Inside convex
		var tri2 = new Triangle2D(new Point2D(5, 2), new Point2D(6, 2), new Point2D(5.5, 2.5)); // Inside concave
		var tri3 = new Triangle2D(new Point2D(0, 0), new Point2D(1, 0), new Point2D(0.5, 1)); // Outside
		var tri4 = new Triangle2D(new Point2D(3, 4), new Point2D(4, 4), new Point2D(3.5, 5)); // Outside
		var tri5 = new Triangle2D(new Point2D(2, 3), new Point2D(3, 3), new Point2D(2.5, 4)); // Partially Overlapping concave

		var triangles = [tri1, tri2, tri3, tri4, tri5];
		var polygons = [convexPolygon, concavePolygon];

		var filtered = TriangleFilter.filterTriangles(triangles, polygons);

		// Expected: Only tri3 and tri4 remain
		Assert.assertEquals(2, filtered.length, "Test 5 Failed: Expected 2 triangles after filtering.");
		Assert.assertTrue(filtered.exists(function(t:Triangle2D) return t.eqvalUnordered(tri3)), "Test 5 Failed: Expected tri3 to remain.");
		Assert.assertTrue(filtered.exists(function(t:Triangle2D) return t.eqvalUnordered(tri4)), "Test 5 Failed: Expected tri4 to remain.");
	}

	/**
	 * Test Case 6: Degenerate Triangles
	 * Expected Outcome: Depending on implementation, degenerate triangles can be removed or ignored.
	 * For this test, we'll assume degenerate triangles are to be removed.
	 */
	static function tftestDegenerateTriangles():Void {
		trace("Running testDegenerateTriangles...");

		// Define polygons
		var polygon = [new Point2D(2, 2), new Point2D(4, 2), new Point2D(4, 4), new Point2D(2, 4)];

		var degeneratePolygon = [new Point2D(0, 0), new Point2D(2, 0), new Point2D(2, 2), new Point2D(0, 2)];

		var polygons = [polygon, degeneratePolygon];

		// Define triangles
		var tri1 = new Triangle2D(new Point2D(1, 1), new Point2D(1, 1), new Point2D(1, 1)); // Completely degenerate
		var tri2 = new Triangle2D(new Point2D(2, 2), new Point2D(3, 3), new Point2D(4, 4)); // Colinear (degenerate)
		var tri3 = new Triangle2D(new Point2D(5, 5), new Point2D(6, 5), new Point2D(5.5, 6)); // Valid
		var tri4 = new Triangle2D(new Point2D(0, 0), new Point2D(1, 0), new Point2D(0.5, 1)); // Valid but inside degeneratePolygon

		var triangles = [tri1, tri2, tri3, tri4];

		var filtered = TriangleFilter.filterTriangles(triangles, polygons);

		// Expected: Only tri3 remains (tri1 and tri2 are degenerate and within polygons, tri4 is valid but inside degeneratePolygon)
		Assert.assertEquals(1, filtered.length, "Test 6 Failed: Expected 1 triangle after filtering.");
		if (filtered.length > 0)
			Assert.assertTrue(filtered[0].eqvalUnordered(tri3), "Test 6 Failed: Expected tri3 to remain.");

		trace("testDegenerateTriangles passed.");
	}

	// Helper function to check if a point is on the edge between two vertices
	public static function isPointOnEdge(p:Point2D, v1:Point2D, v2:Point2D, epsilon:Float = 1e-6):Bool {
		var cross = (p.y - v1.y) * (v2.x - v1.x) - (p.x - v1.x) * (v2.y - v1.y);
		if (Math.abs(cross) > epsilon)
			return false;

		var dot = (p.x - v1.x) * (v2.x - v1.x) + (p.y - v1.y) * (v2.y - v1.y);
		if (dot < 0)
			return false;

		var lenSq = (v2.x - v1.x) * (v2.x - v1.x) + (v2.y - v1.y) * (v2.y - v1.y);
		if (dot > lenSq)
			return false;

		return true;
	}

	public static function pftestGenerateEdgePoints() {
		trace("Testing generateEdgePoints...");

		// Test with a square
		var square:Polygon2D = [new Point2D(0, 0), new Point2D(10, 0), new Point2D(10, 10), new Point2D(0, 10)];
		var spacing = 2.0;
		var edgePoints = square.generateEdgePoints(spacing);

		SVGGenerate.writePointField("pf_square_edges.svg", edgePoints);

		// Expected number of edge points (approximate)
		var perimeter = square.getPerimeter();
		var expectedNumPoints = Math.ceil(perimeter / spacing);
		trace('Expected number of edge points (approx): ' + expectedNumPoints);
		trace('Actual number of edge points: ' + edgePoints.length);

		// Check that all points are on the edges
		for (p in edgePoints) {
			var onEdge = false;
			for (i in 0...square.length) {
				var v1 = square[i];
				var v2 = square[(i + 1) % square.length];
				if (isPointOnEdge(p, v1, v2)) {
					onEdge = true;
					break;
				}
			}
			if (!onEdge) {
				trace('Point not on edge: ' + p);
			}
			Assert.assertTrue(onEdge, 'Edge point should be on an edge');
		}

		trace("generateEdgePoints test passed for square.\n");
	}

	public static function pftestGenerateInteriorPoints() {
		trace("Testing generateInteriorPoints...");

		// Test with a square
		var square:Polygon2D = [
			new Point2D(-20, -20),
			new Point2D(20, -20),
			new Point2D(10, 10),
			new Point2D(0, 10)
		];
		var minDistance = 2.0;
		var interiorPoints = Poisson2D.pointsOnPolygon(square, minDistance);

		SVGGenerate.writePointField("pf_square_interior.svg", interiorPoints);

		trace('Checking inside...');
		// Check that all points are inside the polygon
		for (p in interiorPoints) {
			var inside = square.containsPoint(p);
			if (!inside) {
				trace('Point not inside polygon: ' + p);
			}
			Assert.assertTrue(inside, 'Interior point should be inside the polygon');
		}

		trace('Checking min distance...');
		// Check that points are at least minDistance apart
		for (i in 0...interiorPoints.length) {
			var p1 = interiorPoints[i];
			for (j in i + 1...interiorPoints.length) {
				var p2 = interiorPoints[j];
				var dist = p1.distanceTo(p2);
				if (dist < minDistance - 1e-6) {
					trace('Points too close: ' + p1 + ' and ' + p2 + ', distance: ' + dist);
				}
				Assert.assertTrue(dist >= minDistance - 1e-6, 'Points should be at least minDistance apart');
			}
		}

		trace("generateInteriorPoints test passed for square.\n");
	}

	public static function pftestGeneratePointField() {
		trace("Testing generatePointField...");

		// Test with a square
		var square:Polygon2D = [new Point2D(0, 0), new Point2D(10, 0), new Point2D(10, 10), new Point2D(0, 10)];
		var spacing = 2.0;
		var edgePoints = square.generateEdgePoints(spacing);
		var interiorPoints = Poisson2D.pointsOnPolygon(square, spacing, 0.0, edgePoints);
		var pointField = edgePoints.concat(interiorPoints);

		SVGGenerate.writePointField("pf_square.svg", pointField);

		// Separate edge and interior points for testing
		var edgePoints = new Array<Point2D>();
		var interiorPoints = new Array<Point2D>();
		for (p in pointField) {
			var onEdge = false;
			for (i in 0...square.length) {
				var v1 = square[i];
				var v2 = square[(i + 1) % square.length];
				if (isPointOnEdge(p, v1, v2)) {
					onEdge = true;
					break;
				}
			}
			if (onEdge) {
				edgePoints.push(p);
			} else {
				interiorPoints.push(p);
			}
		}

		// Check edge points
		for (p in edgePoints) {
			var onEdge = false;
			for (i in 0...square.length) {
				var v1 = square[i];
				var v2 = square[(i + 1) % square.length];
				if (isPointOnEdge(p, v1, v2)) {
					onEdge = true;
					break;
				}
			}
			Assert.assertTrue(onEdge, 'Edge point should be on an edge');
		}

		// Check interior points
		var minDistance = spacing;
		for (i in 0...interiorPoints.length) {
			var p1 = interiorPoints[i];
			var inside = square.containsPoint(p1);
			Assert.assertTrue(inside, 'Interior point should be inside the polygon');

			for (j in i + 1...interiorPoints.length) {
				var p2 = interiorPoints[j];
				var dist = p1.distanceTo(p2);
				Assert.assertTrue(dist >= minDistance - 1e-6, 'Interior points should be at least minDistance apart');
			}
		}

		// Check that edge and interior points are at least minDistance apart
		for (p1 in interiorPoints) {
			for (p2 in edgePoints) {
				var dist = p1.distanceTo(p2);
				Assert.assertTrue(dist >= minDistance - 1e-6, 'Points should be at least minDistance apart');
			}
		}

		trace("generatePointField test passed for square.\n");
	}

	public static function pftestMerge() {
		trace("Testing pftestMerge...");

		// Test with a square
		var square:PointField2D = [
			new Point2D(0, 0),
			new Point2D(10, 0),
			new Point2D(10, 10),
			new Point2D(0, 10),
			new Point2D(0, 0),
			new Point2D(10, 0),
			new Point2D(10, 10),
			new Point2D(0, 10)
		];

		var merged = square.mergeAndRemap();

		Assert.assertEquals(4, merged.points.length, "Merged square should have 4 points");
		Assert.assertEquals(8, merged.indices.length, "Merged square should have 8 indices");

		trace("generatePointField test passed for square.\n");
	}

	public static function writeTriangulation(name:String, triangulation:Array<Triangle2D>) {
		var writer = new SVGWriter();
		var bounds = Rect2D.fromTriangles(triangulation);

		writer.bound(bounds, true);

		var attr = new SVGPrimAttributes();

		for (t in triangulation) {
			writer.polygon([t.a, t.b, t.c], attr);
		}

		writer.finishAndWrite(name);
	}

	public static function relaxTriFunadmental() {
		trace("Testing relaxTriFunadmental...");

		// equilateral triangle
		var equilateralTriangle = new Triangle2D(new Point2D(0, 0), new Point2D(1, 0), new Point2D(0.5, Math.sqrt(3) / 2));

		trace('Equilateral triangle: ' + equilateralTriangle);
		Relax.relaxTriangulation([equilateralTriangle], [0.1], 0.1, 100);

		trace('Relaxed triangle: ' + equilateralTriangle);

		// Jeremy's triangle
		var jeremyTriangle = new Triangle2D(new Point2D(0, 0), new Point2D(0, 1), new Point2D(1, 2));
		writeTriangulation('jeremy_start.svg', [jeremyTriangle]);

		trace('Jeremy triangle: ' + jeremyTriangle);
		Relax.relaxTriangulation([jeremyTriangle], [0.1], 0.1, 100);
		writeTriangulation('jeremy_end.svg', [jeremyTriangle]);

		trace('Relaxed triangle: ' + jeremyTriangle);
	}

	public static function heBasic() {
		var mesh = new HalfEdgeMesh2D();

		// Add vertices to the mesh
		var v0 = mesh.addVertex(0, 0);
		var v1 = mesh.addVertex(1, 0);
		var v2 = mesh.addVertex(1, 1);
		var v3 = mesh.addVertex(0, 1);

		// Add a face (quadrilateral) to the mesh
		mesh.addFace([v0, v1, v2, v3]);

		trace('Vertices: ${mesh.vertices}');
		trace('Edges: ${mesh.edges}');
		trace('Faces: ${mesh.faces}');

		trace('Inserting midpoint...');
		var edge = mesh.getEdge(v0, v1);
		mesh.insertMidPoint(edge);

		trace('Vertices: ${mesh.vertices}');
		trace('Edges: ${mesh.edges}');
		trace('Faces: ${mesh.faces}');
		// // Compute the dual mesh
		// var dualMesh = mesh.computeDual();

		// // Output the dual mesh data
		// trace("Dual Mesh Vertices:");
		// for (v in dualMesh.vertices) {
		// 	trace('(' + v.x + ', ' + v.y + ')');
		// }

		// trace("Dual Mesh Faces:");
		// for (f in dualMesh.faces) {
		// 	var edge = f.edge;
		// 	var vertices = [];
		// 	do {
		// 		vertices.push(edge.vertex);
		// 		edge = edge.next;
		// 	} while (edge != f.edge);

		// 	var s = "";
		// 	for (v in vertices) {
		// 		s += '(' + v.x + ', ' + v.y + ') ';
		// 	}
		// 	trace(s);
		// }
	}
	public static function primDisolve() {
		var a = new Point2D(0, 0);
		var b = new Point2D(1, 0);
		var c = new Point2D(0, 1);
		var d = new Point2D(1, 1);
		var triA = new Triangle2D(a, b, c);
		var triB = new Triangle2D(c, b, d);
		var tris : Array<Prim2D> = [triA, triB];
		var triConnectivity = PrimConnectivity2D.fromPrims(tris);

		trace('pre-dissolve: ' + tris);
		var edge = triConnectivity.getEdgeFromPoints(b, c);
		triConnectivity.disolveEdge(edge);
		var newTris = triConnectivity.gatherFaces();
		trace('post-dissolve: ' + newTris);
	}

	public static function primDisolveVert() {
		var center = new Point2D(0.5, 0.5);
		var a = new Point2D(0, 0);
		var b = new Point2D(1, 0);
		var c = new Point2D(1, 1);
		var d = new Point2D(0, 1);
		var triA = new Triangle2D(center, a, b);
		var triB = new Triangle2D(center, b, c);
		var quad = new Quad2D(center, c, d, a);
		var connectivity = PrimConnectivity2D.fromPrims([triA, triB, quad]);

		trace('primDisolveVert : pre-dissolve: ' + connectivity.gatherFaces() + " " + getPrimStats(connectivity));

		connectivity.disolveVertex(center);

		trace('primDisolveVert : post-dissolve: ' + connectivity.gatherFaces() + " " + getPrimStats(connectivity));
	}

	public static function primCollapseEdge() {
		var a = new Point2D(-1, 0.5);
		var b = new Point2D(0, 0);
		var c = new Point2D(0, 1);
		var d = new Point2D(1, 0.5);
		var triA = new Triangle2D(a, b, c);
		var triB = new Triangle2D(c, b, d);
		var tris : Array<Prim2D> = [triA, triB];
		var connectivity = PrimConnectivity2D.fromPrims(tris);

		trace('primCollapseEdge : Pre ' + connectivity.gatherFaces() + ' ' + getPrimStats(connectivity));
		connectivity.collapseEdge(b,c);
		trace('primCollapseEdge: Post ' + connectivity.gatherFaces() + ' ' + getPrimStats(connectivity));

		var e = new Point2D(0.0, 2.0);
		var f = new Point2D(-1, 2.0);
		var q1 = new Quad2D(a, f, e, c);

		var g = new Point2D(0, -1);
		var h = new Point2D(-1, -1);
		var q2 = new Quad2D(a, h, g, b);

		connectivity = PrimConnectivity2D.fromPrims([triA, triB, q1, q2]);

		trace('primCollapseEdge 2 : Pre ' + connectivity.gatherFaces() + ' ' + getPrimStats(connectivity));
		connectivity.collapseEdge(b,c);
		trace('primCollapseEdge 2 : Post ' + connectivity.gatherFaces() + ' ' + getPrimStats(connectivity));

		var i = new Point2D(1, 2);
		var j = new Point2D(1, -1);
		q1 = new Quad2D(a, d, e, c);
		q2 = new Quad2D(a, h, g, b);
		var q3 = new Quad2D(c, b, j, i);

		connectivity = PrimConnectivity2D.fromPrims([triA, q1, q2, q3]);
		trace('primCollapseEdge 3 : Pre ' + connectivity.gatherFaces() + ' ' + getPrimStats(connectivity));
		connectivity.collapseEdge(b,c);
		trace('primCollapseEdge 3 : Post ' + connectivity.gatherFaces() + ' ' + getPrimStats(connectivity));

		throw('done');

	}

	static function getPrimStats(connectivity:PrimConnectivity2D) {
		var vertCount = 0;
		for (v in connectivity.vertIt) {
			vertCount++;
		}

		var edgeCount = 0;
		for (e in connectivity.edgeIt) {
			edgeCount++;
		}
		return { verts: vertCount, edges: edgeCount };
	}
	public static function primRemove() {
		var a = new Point2D(0, 0);
		var b = new Point2D(1, 0);
		var c = new Point2D(1, 1);
		var d = new Point2D(0, 1);
		var q = new Quad2D(a, b, c, d);
		var quads : Array<Prim2D> = [q];
		var quadConnectivity = PrimConnectivity2D.fromPrims(quads);

		trace('primRemove pre-remove: ' + quads + ' ' + getPrimStats(quadConnectivity));
		quadConnectivity.removeFace(q);
		
		trace('primRemove post-remove: ' + quadConnectivity.gatherFaces() + ' ' + getPrimStats(quadConnectivity));

		var e = new Point2D( 2, 0 );
		var f = new Point2D( 2, 1 );

		var quad2 = new Quad2D(c, b, e, f);
		quads.push(quad2);
		quadConnectivity = PrimConnectivity2D.fromPrims(quads);
		trace('primRemove pre-remove2: ' + quadConnectivity.gatherFaces() + ' ' + getPrimStats(quadConnectivity));
		quadConnectivity.removeFace(quad2);
		trace('primRemove post-remove2-1: ' + quadConnectivity.gatherFaces() + ' ' + getPrimStats(quadConnectivity));
		quadConnectivity.removeFace(q);
		trace('primRemove post-remove2-2: ' + quadConnectivity.gatherFaces() + ' ' + getPrimStats(quadConnectivity));
		
	}

	public static function primSubdivide() {
		var a = new Point2D(0, 0);
		var b = new Point2D(1, 0);
		var c = new Point2D(0, 1);
		var d = new Point2D(1, 1);
		var triA = new Triangle2D(a, b, c);
		var triB = new Triangle2D(c, b, d);
		var tris : Array<Prim2D> = [triA, triB];
		var triConnectivity = PrimConnectivity2D.fromPrims([triA]);

		var prims = triConnectivity.getSubdivided();

		trace('subdivided triangle: ' + prims);
	}

	public static function primAngles() {
		var a = new Point2D(0, 0);
		var b = new Point2D(1, 0);
		var c = new Point2D(1, 1);
		var d = new Point2D(0, 1);

		var quad = new Quad2D(a, b, c, d);
		var angles = quad.getInteriorAngles().map(function(a) return a * 180 / Math.PI);
		trace('quad angles: ' + angles);

		var e = new Point2D(0.25, 0.25);
		var quad2 = new Quad2D(a, b, e, d);
		var angles2 = quad2.getInteriorAngles().map(function(a) return a * 180 / Math.PI);
		trace('quad2 angles: ' + angles2);
	}

	public static function primRelax() {
		var a = new Point2D(0, 0);
		var b = new Point2D(1, 0);
		var c = new Point2D(0.25, 0.25);
		var d = new Point2D(0, 1);
		var quad2 = new Quad2D(a, b, c, d);

		var prims : Array<Prim2D> = [quad2];
		var angles = quad2.getInteriorAngles().map(function(a) return a * 180 / Math.PI);
		trace('relaxed quad2 - before: ' + angles);
		Relax.relaxPrims(prims, [0.1, 0.5], 0.1, 10);
		var angles2 = quad2.getInteriorAngles().map(function(a) return a * 180 / Math.PI);
		trace('relaxed quad2 - after: ' + angles2);
	}
}
