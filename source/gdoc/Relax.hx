package gdoc;

import gdoc.NodeGraph;

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
}
