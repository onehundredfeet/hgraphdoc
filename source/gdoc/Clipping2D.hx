package gdoc;

class Clipping2D {
	public static function clipPolygon(subjectPolygon:Array<Point2D>, clipPolygon:Array<Point2D>):Array<Point2D> {
		var outputList = subjectPolygon;
		for (i in 0...clipPolygon.length) {
			var clipEdgeStart = clipPolygon[i];
			var clipEdgeEnd = clipPolygon[(i + 1) % clipPolygon.length];
			var inputList = outputList;
			outputList = [];
			var S = inputList[inputList.length - 1];
			for (v in inputList) {
				var E = v;
				if (isInside(E, clipEdgeStart, clipEdgeEnd)) {
					if (!isInside(S, clipEdgeStart, clipEdgeEnd)) {
						outputList.push(computeIntersection(S, E, clipEdgeStart, clipEdgeEnd));
					}
					outputList.push(E);
				} else if (isInside(S, clipEdgeStart, clipEdgeEnd)) {
					outputList.push(computeIntersection(S, E, clipEdgeStart, clipEdgeEnd));
				}
				S = E;
			}
		}
		return outputList;
	}

	private static function isInside(p:Point2D, edgeStart:Point2D, edgeEnd:Point2D):Bool {
		// Compute the cross product to determine if point p is to the left of the edge
		var cross = (edgeEnd.x - edgeStart.x) * (p.y - edgeStart.y) - (edgeEnd.y - edgeStart.y) * (p.x - edgeStart.x);
		return cross >= 0;
	}

	private static function computeIntersection(S:Point2D, E:Point2D, edgeStart:Point2D, edgeEnd:Point2D):Point2D {
		var dx1 = E.x - S.x;
		var dy1 = E.y - S.y;
		var dx2 = edgeEnd.x - edgeStart.x;
		var dy2 = edgeEnd.y - edgeStart.y;

		var denominator = dx1 * dy2 - dy1 * dx2;
		if (Math.abs(denominator) < 1e-10) {
			// Lines are parallel; return midpoint as a fallback
			return new Point2D((S.x + E.x) / 2, (S.y + E.y) / 2);
		}

		var t = ((edgeStart.x - S.x) * dy2 - (edgeStart.y - S.y) * dx2) / denominator;
		return new Point2D(S.x + t * dx1, S.y + t * dy1);
	}
}
