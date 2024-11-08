package gdoc;
import gdoc.Point3D;

@:forward
@:forward.new
abstract Polygon2D(Array<Point2D>) from Array<Point2D> to Array<Point2D> {
	public static function isConvex(prev:Point2D, curr:Point2D, next:Point2D):Bool {
		return Point2D.orientation(prev, curr, next) > 0;
	}

	public function copy():Polygon2D {
		return this.copy();
	}

    public inline function asArray():Array<Point2D> {
        return this;
    }

	//  shoelace formula
	public function isCounterClockwise():Bool {
		var sum = 0.0;
		for (i in 0...this.length) {
			var current = this[i];
			var next = this[(i + 1) % this.length];
			sum += (current.x * next.y) - (next.x * current.y);
		}
		return sum > 0;
	}

	public function getAsEdgesUndirected():Array<Edge2D> {
		var edges = new Array<Edge2D>();
		var len = this.length;
		if (len < 2)
			return edges;
		for (i in 0...len) {
			var a = this[i];
			var b = this[(i + 1) % len]; // Wrap around to the first point
			edges.push(Edge2D.fromPointsUndirected(a, b));
		}
		return edges;
	}

	public function getAsEdgesDirected():Array<Edge2D> {
		var edges = new Array<Edge2D>();
		var len = this.length;
		if (len < 2)
			return edges;
		for (i in 0...len) {
			var a = this[i];
			var b = this[(i + 1) % len]; // Wrap around to the first point
			edges.push(Edge2D.fromPointsDirected(a, b));
		}
		return edges;
	}

	public function containsPoint(point:Point2D):Bool {
		var count = 0;
		var len = this.length;
		for (i in 0...len) {
			var a = this[i];
			var b = this[(i + 1) % len];

			// Check if the point is on the same y-range as the edge
			if ((a.y > point.y) != (b.y > point.y)) {
				// Calculate the x coordinate of the intersection point of the edge with the horizontal line y = point.y
				var slope = (b.x - a.x) / (b.y - a.y);
				var xIntersect = a.x + slope * (point.y - a.y);
				if (xIntersect == point.x) {
					// The point is exactly on the edge
					return true;
				}
				if (xIntersect > point.x) {
					count++;
				}
			}
		}
		return (count % 2) == 1; // Inside if odd number of intersections
	}

	// Generate evenly spaced points along the edges
	public function generateEdgePoints(spacing:Float):PointField2D {
		var n = this.length;
		var edgePoints = new PointField2D();
		for (i in 0...n) {
			var pi = this[i];
			var pj = this[(i + 1) % n];
			edgePoints.push(pi); // Include the vertex
			var dx = pj.x - pi.x;
			var dy = pj.y - pi.y;
			var length = Math.sqrt(dx * dx + dy * dy);
			var numSegments = Math.ceil(length / spacing);
			for (j in 1...numSegments) {
				var t = j / numSegments;
				var x = pi.x + t * dx;
				var y = pi.y + t * dy;
				edgePoints.push(new Point2D(x, y));
			}
		}
		return edgePoints;
	}


	
	/*
		// Check if a point is inside the polygon using the ray casting algorithm
		public static function isPointInPolygon(p:Point2D, vertices:Array<Point2D>):Bool {
			var n = vertices.length;
			var inside = false;
			var j = n - 1;
			for (i in 0...n) {
				var pi = vertices[i];
				var pj = vertices[j];
				if (((pi.y > p.y) != (pj.y > p.y))) {
					var xIntersect = (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y + 1e-12) + pi.x;
					if (p.x < xIntersect) {
						inside = !inside;
					}
				}
				j = i;
			}
			return inside;
		}
	 */
	public function getPerimeter():Float {
		var n = this.length;
		var perimeter = 0.0;
		for (i in 0...n) {
			var pi = this[i];
			var pj = this[(i + 1) % n];
			perimeter += pi.distanceTo(pj);
		}
		return perimeter;
	}

    public function computeConvexArea():Float {
        var n = this.length;
        if (n < 3) {
            throw ("A polygon must have at least three vertices.");
        }

        // shoelace formula
        var sum:Float = 0;
        for (i in 0...n) {
            var current = this[i];
            var next = this[(i + 1) % n]; // Wrap around to the first point
            sum += (current.x * next.y) - (next.x * current.y);
        }

        return 0.5 * Math.abs(sum);
    }

	public function scale(s : Float) {
		var center = Point2D.computeCentroid2D(this);

		for (p in this) {
			p.x = center.x + s * (p.x - center.x);
			p.y = center.y + s * (p.y - center.y);
		}
	}
}
