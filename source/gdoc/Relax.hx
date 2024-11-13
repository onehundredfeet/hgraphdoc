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
		var angularStiffness = stiffness.length >= 2 ? stiffness[1] : 0.0;

		
		var verts = [for (v in connectivity.vertIt) v];
		var edges = [for (e in connectivity.edgeIt) e];
		
		trace('relaxing ${verts.length} verts and ${edges.length} edges from ${triangles.length} triangles');

		var edgeLengths = [for (e in edges) {
			var dx = e.b.x - e.a.x;
			var dy = e.b.y - e.a.y;
			Math.sqrt(dx * dx + dy * dy);
		}];

		var triangleAreas = [for (t in triangles) t.area()];

		var avergeEdgeLength = edgeLengths.fold((l, sum) -> sum + l, 0.0) / edgeLengths.length;
		var avergeTriangleArea = triangleAreas.fold((a, sum) -> sum + a, 0.0) / triangleAreas.length;
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

		trace('average length: $avergeEdgeLength with error ${calculateError()} and average area $avergeTriangleArea');

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

			for (j in 0...triangles.length) {
				triangleAreas[j] = triangles[j].area();
				var angleDelta = (triangleAreas[j] - avergeTriangleArea);
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
			//trace('iteration $i error ${calculateError()}');
		}


	}

	public static function relaxPrims( prims : Array<Prim2D>, stiffness: Array<Float>, iterationStrength:Float, iterations: Int, connectivity:PrimConnectivity2D = null) {
		if (connectivity == null) {
			connectivity = PrimConnectivity2D.fromPrims(prims);
		}

		var stiffness1 = stiffness[0];
		var angularStiffness = stiffness.length >= 2 ? stiffness[1] : 0.0;

		var verts = [for (v in connectivity.vertIt) v];
		var edges = [for (e in connectivity.edgeIt) e];
		
		trace('relaxing ${verts.length} verts and ${edges.length} edges from ${prims.length} prims');

		var edgeLengths = [for (e in edges) {
			var dx = e.b.x - e.a.x;
			var dy = e.b.y - e.a.y;
			Math.sqrt(dx * dx + dy * dy);
		}];


		var avergeEdgeLength = edgeLengths.fold((l, sum) -> sum + l, 0.0) / edgeLengths.length;
		var averageEdgeLengthRoot2 = avergeEdgeLength * Math.sqrt(2.0);

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

		trace('average length: $avergeEdgeLength with error ${calculateError()} ');

		final RELAX_EPISLON = 1e-7;

		inline function applyForce(p : Point2D, fx : Float, fy : Float) {
			var accuma = forceAccum[connectivity.getPointID(p)];
			if (accuma == null) {
				throw('no accumulator for $p');
			}
			accuma.x += fx;
			accuma.y += fy;
		}

		inline function applyForcePair(a : Point2D, b : Point2D, fx : Float, fy : Float) {
			applyForce(a, fx, fy);
			applyForce(b, -fx, -fy);
		}

		

		function computeAndApplyForce( a : Point2D, b : Point2D, targetLength : Float, scale:Float, squareScale = 0.0) {
			var dx = b.x - a.x;
			var dy = b.y - a.y;
			var currentLength = Math.sqrt(dx * dx + dy * dy);

			if (currentLength > 0.0) {
				// if currentLength is > avergeEdgeLength, then the force is attractive, i.e. move a and b closer together
				// if currentLength is < avergeEdgeLength, then the force is repulsive
				var delta = (currentLength - targetLength);
				var sign = delta >= 0.0 ? 1.0 : -1.0;
				var mag = delta * sign;
				if (mag < RELAX_EPISLON) {
					return;
				}
				var forceStrength = mag * stiffness1 * sign * scale + mag * mag * stiffness1 * sign * squareScale;
				// normalize the vector to get the direction from a to b
				// if the force is attractive, i.e. positive, then a should move towards b and vice versa
				dx /= currentLength; 
				dy /= currentLength;

				// scale the direction by the strength of the force
				var fdx = dx * forceStrength;
				var fdy = dy * forceStrength;
				
				applyForcePair(a, b, fdx, fdy);
			}
		}

		function computeAndApplyAngularForce(p: Point2D, a : Point2D, b:Point2D, targetAngle : Float, strenth:Float) {
			var angle = Point2D.angleBetweenCCPoints(p, a, b);

			var delta = angle - targetAngle;
			var sign = delta >= 0.0 ? 1.0 : -1.0;
			var mag = delta * sign;

			if (mag < RELAX_EPISLON) {
				return;
			}
			var forceStrength = mag * angularStiffness * sign * strenth;

			// the force we want is perpendicular to the line from a to b
			var dx1 = a.x - p.x;
			var dy1 = a.y - p.y;
			var dx2 = b.x - p.x;
			var dy2 = b.y - p.y;

			// normalize the vectors
			var len1 = Math.sqrt(dx1 * dx1 + dy1 * dy1);
			var len2 = Math.sqrt(dx2 * dx2 + dy2 * dy2);

			dx1 /= len1;
			dy1 /= len1;
			dx2 /= len2;
			dy2 /= len2;

			// the force is perpendicular to the line from p to a and p to b in the direct towards the center to close, or away from the center to open
			// if sign is positive, the angle is too large and we want to close it
			// if sign is negative, the angle is too small and we want to open it
			var fdx1 = dy1;
			var fdy1 = -dx1;

			// opposite direction
			var fdx2 = -dy2;
			var fdy2 = dx2;

			applyForce(a, fdx1 * forceStrength, fdy1 * forceStrength);
			applyForce(b, fdx2 * forceStrength, fdy2 * forceStrength);
		}
		final PI_3 = Math.PI / 5;
		final LOCAL_QUAD_EDGE_STRENGTH = 0.25 * 3;
		final LOCAL_TRI_EDGE_STRENGTH = (1.0 / 3.0) * 3;
		for (i in 0...iterations) {
			for (e in edges) {
				computeAndApplyForce(e.a, e.b, avergeEdgeLength, 0.75);
			}

			for (p in prims) {
				// compute average edge length for each face
				

				if (p.d != null) {
					var ab = Point2D.pointDistanceToXY(p.a.x, p.a.y, p.b.x, p.b.y);
					var bc = Point2D.pointDistanceToXY(p.b.x, p.b.y, p.c.x, p.c.y);
					var cd = Point2D.pointDistanceToXY(p.c.x, p.c.y, p.d.x, p.d.y);
					var da = Point2D.pointDistanceToXY(p.d.x, p.d.y, p.a.x, p.a.y);

					var averageLocalLength = (ab + bc + cd + da) * 0.25;

					computeAndApplyForce(p.a, p.b, averageLocalLength, LOCAL_QUAD_EDGE_STRENGTH, LOCAL_QUAD_EDGE_STRENGTH);
					computeAndApplyForce(p.b, p.c, averageLocalLength, LOCAL_QUAD_EDGE_STRENGTH, LOCAL_QUAD_EDGE_STRENGTH);
					computeAndApplyForce(p.c, p.d, averageLocalLength, LOCAL_QUAD_EDGE_STRENGTH, LOCAL_QUAD_EDGE_STRENGTH);
					computeAndApplyForce(p.d, p.a, averageLocalLength, LOCAL_QUAD_EDGE_STRENGTH, LOCAL_QUAD_EDGE_STRENGTH);

					computeAndApplyForce(p.a, p.c, averageEdgeLengthRoot2, 0.5);
					computeAndApplyForce(p.b, p.d, averageEdgeLengthRoot2, 0.5);

					computeAndApplyAngularForce( p.a, p.d, p.b,Math.PI * 0.5, 1.0);
					computeAndApplyAngularForce( p.b, p.a, p.c,Math.PI * 0.5, 1.0);
					computeAndApplyAngularForce( p.c, p.b, p.d,Math.PI * 0.5, 1.0);
					computeAndApplyAngularForce( p.d, p.c, p.a,Math.PI * 0.5, 1.0);
				} else {
					var ab = Point2D.pointDistanceToXY(p.a.x, p.a.y, p.b.x, p.b.y);
					var bc = Point2D.pointDistanceToXY(p.b.x, p.b.y, p.c.x, p.c.y);
					var ca = Point2D.pointDistanceToXY(p.c.x, p.c.y, p.a.x, p.a.y);

					final OO3 = 1.0 / 3.0;

					var averageLocalLength = (ab + bc + ca) * OO3;

					computeAndApplyForce(p.a, p.b, averageLocalLength, LOCAL_TRI_EDGE_STRENGTH);
					computeAndApplyForce(p.b, p.c, averageLocalLength,  LOCAL_TRI_EDGE_STRENGTH);
					computeAndApplyForce(p.c, p.a, averageLocalLength,  LOCAL_TRI_EDGE_STRENGTH);

					computeAndApplyAngularForce( p.a, p.c, p.b,PI_3, 2.0);
					computeAndApplyAngularForce( p.b, p.a, p.c,PI_3, 2.0);
					computeAndApplyAngularForce( p.c, p.b, p.a,PI_3, 2.0);
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
			//trace('iteration $i error ${calculateError()}');
		}


	}
}
