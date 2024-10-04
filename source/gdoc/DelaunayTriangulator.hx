package gdoc;

class DelaunayTriangulator {
	public static function triangulate(points:Array<Point2D>):Array<Triangle2D> {
		var triangles = new Array<Triangle2D>();

		if (points.length < 3) {
			return triangles;
		}

		var superTri = createSuperTriangle(points);
        if (superTri == null) {
            return [];
        }
		triangles.push(superTri);

		// Insert each point into the triangulation
		for (point in points) {
			var badTriangles = new Array<Triangle2D>();

			// Find all triangles that are no longer valid due to the insertion
			for (tri in triangles) {
				if (tri.circumCircleContains(point)) {
					badTriangles.push(tri);
				}
			}

			// Find the boundary of the polygonal hole
			var polygon = new Array<Edge2D>();
			for (tri in badTriangles) {
				var edges = tri.getEdges();
				for (edge in edges) {
					var isShared = false;
					for (other in badTriangles) {
						if (tri == other)
							continue;
						var otherEdges = other.getEdges();
						for (otherEdge in otherEdges) {
							if (edge.eqval(otherEdge)) {
								isShared = true;
								break;
							}
						}
						if (isShared)
							break;
					}
					if (!isShared) {
						polygon.push(edge);
					}
				}
			}

			// Remove bad triangles from the triangulation
			triangles = triangles.filter(function(t:Triangle2D):Bool {
				return !badTriangles.contains(t);
			});

			// Retriangulate the polygonal hole with new triangles
			for (edge in polygon) {
				// Inside the triangulate function, when creating a new triangle
				var newTri = new Triangle2D(edge.a, edge.b, point);

				// Ensure the new triangle is counter-clockwise
				if (Point2D.orientation(edge.a, edge.b, point) < 0) {
					newTri = new Triangle2D(edge.a, point, edge.b);
				}

				triangles.push(newTri);
			}
		}

		// Remove any triangles that share a vertex with the super triangle
		triangles = triangles.filter(function(t:Triangle2D):Bool {
			return !t.hasPointRef(superTri.a) && !t.hasPointRef(superTri.b) && !t.hasPointRef(superTri.c);
		});

		return triangles;
	}

	private static function createSuperTriangle(points:Array<Point2D>):Triangle2D {
		// Find the bounding box of the points
		var minX = points[0].x;
		var minY = points[0].y;
		var maxX = points[0].x;
		var maxY = points[0].y;

		for (p in points) {
			if (p.x < minX)
				minX = p.x;
			if (p.y < minY)
				minY = p.y;
			if (p.x > maxX)
				maxX = p.x;
			if (p.y > maxY)
				maxY = p.y;
		}

		var dx = maxX - minX;
		var dy = maxY - minY;
		var deltaMax = dx > dy ? dx : dy;
		var midx = (minX + maxX) / 2;
		var midy = (minY + maxY) / 2;

		// Create a super triangle
		var p1 = new Point2D(midx - 20 * deltaMax, midy - deltaMax);
		var p2 = new Point2D(midx, midy + 20 * deltaMax);
		var p3 = new Point2D(midx + 20 * deltaMax, midy - deltaMax);

		var tri = new Triangle2D(p1, p2, p3);

		// Ensure the super triangle is counter-clockwise
		if (Point2D.orientation(p1, p2, p3) < 0) {
			tri = new Triangle2D(p1, p3, p2);
		}

        if (tri.isDegenerate()) {
            return null;
        }
		for (p in points) {
			if (!tri.containsPoint(p)) {
				throw('Super triangle does not contain all points ${tri} -> ${p}');
			}
		}

		return tri;
	}
}
