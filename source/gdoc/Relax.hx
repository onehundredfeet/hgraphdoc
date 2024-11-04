package gdoc;

import gdoc.NodeGraph;
import gdoc.TriangleConnectivity2D;

using Lambda;

import gdoc.Point2D;

class RelaxNodeInfo {
	public var x:Float;
	public var y:Float;
	public var count:Int;

	public function new(x:Float, y:Float) {
		this.x = x;
		this.y = y;
		this.count = 0;
	}
}


class Relax {
	// Unrolled version, could collapse to common version
	static function closestPointVector(x1:Float, y1:Float, x2:Float, y2:Float, px:Float, py:Float):Point2D {
		var dx = x2 - x1;
		var dy = y2 - y1;

		// Calculate the vector from A to P
		var aPx = px - x1;
		var aPy = py - y1;

		// Compute the square of the length of AB
		var magnitudeAB2 = dx * dx + dy * dy;

		if (magnitudeAB2 == 0) {
			return new Point2D(x1 - px, y1 - py);
		}

		// Project vector AP onto AB, normalized by the length squared of AB
		var t = (aPx * dx + aPy * dy) / magnitudeAB2;

		t = Math.max(0, Math.min(1, t));

		// Compute the closest point coordinates on the line segment AB
		var closestX = x1 + dx * t;
		var closestY = y1 + dy * t;

		return new Point2D(closestX - px, closestY - py);
	}

	public static function relaxGraph(graph:NodeGraph, edgeLengths:Array<Float>, iterationStrength:Float) {
		var maxId = graph.nodes.fold((n, max) -> n.id > max ? n.id : max, 0);

		var accumulators = [for (_ in 0...(maxId + 1)) new RelaxNodeInfo(0.0, 0.0)];

		var squaredError = 0.0;
		for (e in graph.edges) {
			var n0 = e.source;
			var n1 = e.target;

			var dx = n1.x - n0.x;
			var dy = n1.y - n0.y;
			var distance = Math.sqrt(dx * dx + dy * dy);
			var forceStrength = (distance - edgeLengths[e.id]);
			squaredError += forceStrength * forceStrength;
			if (distance > 0.0) {
				dx /= distance;
				dy /= distance;
				accumulators[n0.id].x += dx * forceStrength;
				accumulators[n0.id].y += dy * forceStrength;
				accumulators[n0.id].count += 1;
				accumulators[n1.id].x -= dx * forceStrength;
				accumulators[n1.id].y -= dy * forceStrength;
				accumulators[n1.id].count += 1;
			}
		}

		squaredError /= graph.edges.length;

		for (n in graph.nodes) {
			var acc = accumulators[n.id];
			if (acc.count > 0) {
				n.x += (acc.x / acc.count) * iterationStrength;
				n.y += (acc.y / acc.count) * iterationStrength;
			}
			acc.x = 0.0;
			acc.y = 0.0;
			acc.count = 0;
		}

		final INVERSE_GRAVITY = 2000.0;

		for (a in graph.nodes) {
			var acc_x = 0.0;
			var acc_y = 0.0;

			for (b in graph.nodes) {
				if (a == b)
					continue;

				var dx = a.x - b.x;
				var dy = a.y - b.y;

				var distance = Math.sqrt(dx * dx + dy * dy);
				var forceStrength = INVERSE_GRAVITY / (distance * distance);

				acc_x += (dx / distance) * forceStrength * iterationStrength;
				acc_y += (dy / distance) * forceStrength * iterationStrength;
			}

			a.x += acc_x / (graph.nodes.length - 1);
			a.y += acc_y / (graph.nodes.length - 1);

			acc_x = 0.0;
			acc_y = 0.0;
			var count = 0;

			for (e in graph.edges) {
				if (e.source == a || e.target == a) {
					continue;
				}

				var n0 = e.source;
				var n1 = e.target;
				var closestVector = closestPointVector(n0.x, n0.y, n1.x, n1.y, a.x, a.y);

				var distance = Math.sqrt(closestVector.x * closestVector.x + closestVector.y * closestVector.y);
				final INVERSE_EDGE_GRAVITY = 1000.0;
				var forceStrength = INVERSE_EDGE_GRAVITY / (distance * distance);
				acc_x -= (closestVector.x / distance) * forceStrength * iterationStrength;
				acc_y -= (closestVector.y / distance) * forceStrength * iterationStrength;
				count++;
			}

			if (count > 0) {
				a.x += acc_x / count;
				a.y += acc_y / count;
			}
		}

		return squaredError;
	}

	public static function relaxTriangulation( triangles : Array<Triangle2D>, stiffness: Array<Float>, iterationStrength:Float, iterations: Int, connectivity:TriangleConnectivity2D = null) {
		if (connectivity == null) {
			connectivity = TriangleConnectivity2D.fromTriangles(triangles);
		}

		var stiffness1 = stiffness[0];
		var stiffness2 = stiffness.length >= 2 ? stiffness[1] : 0.0;

		
		var verts = [for (v in connectivity.vertIt) v];
		var edges = [for (e in connectivity.edgeIt) e];
		
		trace('relaxing ${verts.length} verts and ${edges.length} edges from ${triangles.length} triangles');

		var edgeLengths = [for (e in edges) {
			var dx = e.b.x - e.a.x;
			var dy = e.b.y - e.a.y;
			Math.sqrt(dx * dx + dy * dy);
		}];

		var avergeEdgeLength = edgeLengths.fold((l, sum) -> sum + l, 0.0) / edgeLengths.length;

		//avergeEdgeLength *= 0.5;
		var forceAccum = [for (_ in 0...verts.length) new Point2D(0.0, 0.0)];

		
		function calculateError() {
			var squaredError = 0.0;
			for (e in edges) {
				var a = e.a;
				var b = e.b;

				var dx = b.x - a.x;
				var dy = b.y - a.y;
				var distance = Math.sqrt(dx * dx + dy * dy);
				var delta = (distance - avergeEdgeLength);
				squaredError += delta * delta;
			}
			return squaredError / edges.length;
		}

		trace('average length: $avergeEdgeLength with error ${calculateError()}');

		final RELAX_EPISLON = 1e-7;
		for (i in 0...iterations) {
			for (e in edges) {
				var a = e.a;
				var b = e.b;

				var dx = b.x - a.x;
				var dy = b.y - a.y;
				var currentLength = Math.sqrt(dx * dx + dy * dy);

				if (currentLength > 0.0) {
					// if currentLength is > avergeEdgeLength, then the force is attractive, i.e. move a and b closer together
					// if currentLength is < avergeEdgeLength, then the force is repulsive
					var delta = (currentLength - avergeEdgeLength);
					var sign = delta >= 0.0 ? 1.0 : -1.0;
					var mag = delta * sign;
					if (mag < RELAX_EPISLON) {
						continue;
					}
					// + mag * mag * stiffness2
					var forceStrength = mag * stiffness1 * sign;

					// normalize the vector to get the direction from a to b
					// if the force is attractive, i.e. positive, then a should move towards b and vice versa
					dx /= currentLength; 
					dy /= currentLength;

					// scale the direction by the strength of the force
					var fdx = dx * forceStrength;
					var fdy = dy * forceStrength;

					var accuma = forceAccum[connectivity.getPointID(a)];
					var accumb = forceAccum[connectivity.getPointID(b)];

					// if force strength is positive it will move a and b closer together
					accuma.x += fdx;
					accuma.y += fdy;
					accumb.x -= fdx;
					accumb.y -= fdy;
				} 
			}
		
			// average edge length for each face
			
			for (j in 0...verts.length) {
				var v = verts[j];
				var vid = connectivity.getPointID(v);
				var acc = forceAccum[vid];
				v.x += acc.x * iterationStrength;
				v.y += acc.y * iterationStrength;
				acc.x = 0.0;
				acc.y = 0.0;
			}
			trace('iteration $i error ${calculateError()}');
		}


	}
}
