package gdoc;

import haxe.Int64;
import gdoc.Point3D;
import gdoc.Point2D;
import gdoc.WeightedPoint2D;
import gdoc.Line2D;
import gdoc.Clipping2D;

@:forward
@:forward.new
abstract PowerCell(Array<Point2D>) from Array<Point2D> to Array<Point2D> {
    public inline function asArray():Array<Point2D> {
        return this;
    }
}

@:forward
@:forward.new
abstract PowerPolygon(Array<Point2D>) from Array<Point2D> to Array<Point2D> {}

class PowerDiagram {
	private static function getBoundingBox(min:Point2D, max:Point2D):PowerPolygon {
		return [
			new Point2D(min.x, min.y),
			new Point2D(max.x, min.y),
			new Point2D(max.x, max.y),
			new Point2D(min.x, max.y)
		];
	}



	private static function createBoundaryPoints(min:Point2D, max:Point2D):Array<WeightedPoint2D> {
		return [
			WeightedPoint2D.fromPoint2D(new Point2D(min.x, min.y), 0), // Bottom-left
			WeightedPoint2D.fromPoint2D(new Point2D(max.x, min.y), 0), // Bottom-right
			WeightedPoint2D.fromPoint2D(new Point2D(max.x, max.y), 0), // Top-right
			WeightedPoint2D.fromPoint2D(new Point2D(min.x, max.y), 0) // Top-left
		];
	}

	static final PRECISION = 1e-5;

	private static function removeDuplicates(cell:Array<Point2D>):Array<Point2D> {
		var uniqueCell:Array<Point2D> = [];
		var visited = new Map<String, Bool>();

		for (v in cell) {
			var rx = Math.round(v.x / PRECISION) * PRECISION;
			var ry = Math.round(v.y / PRECISION) * PRECISION;
			var key = rx + ',' + ry;

			if (!visited.exists(key)) {
				visited.set(key, true);
				uniqueCell.push(new Point2D(rx, ry));
			}
		}

		return uniqueCell;
	}

	private static function sortInPlace(points:Array<Point2D>, origin:Point2D) {
		points.sort(function(a:Point2D, b:Point2D):Int {
			var angleA = Math.atan2(a.y - origin.y, a.x - origin.x);
			var angleB = Math.atan2(b.y - origin.y, b.x - origin.x);
			if (angleA < angleB)
				return -1;
			else if (angleA > angleB)
				return 1;
			else
				return 0;
		});
	}

	public static function computeCells(originalPoints:Array<WeightedPoint2D>, min:Point2D, max:Point2D):Map<Int, PowerCell> {
		var bb = getBoundingBox(min, max);
		var random = new seedyrng.Random(Int64.make(8743112, 9182834));

		var points = originalPoints.concat(createBoundaryPoints(min, max));

		if (points.length < 4) {
			throw 'At least four points are required to compute a Power Diagram.';
		}

        var range = max.x - min.x;

        static final INSIGNIFICANT_PERTURBATION =  1e-6;

		inline function liftAndPerturb(p:WeightedPoint2D, i:Int):Point3D {
			var lifted = p.lift();
			lifted.z += INSIGNIFICANT_PERTURBATION * random.random() * range; // Minimal perturbation
			return lifted;
		}

		var liftedPoints = [for (i in 0...points.length) liftAndPerturb(points[i], i)];

		var quickHull = new QuickHull3D(liftedPoints);
		var faces = quickHull.faces.copy().filter((x) -> x.normal.z < 0);
		var faceIndices = quickHull.asTriangleIndices(faces); // Flat array, 3 per triangle

		var cells = new Map<Int, PowerCell>();
		for (i in 0...points.length) {
			cells.set(i, new PowerCell());
		}

		var faceCount = Std.int(faceIndices.length / 3);

		// Deduplication map with precision control
		var cellVerts = new Map<String, Point2D>();
		final precision = 1e-6; // Adjust precision as needed

		// Get convex hull point indices
		var convexHullIndices = quickHull.getUsedVerticesByIndex();

		for (i in 0...faceCount) {
			var index = i * 3;

			var fi0 = faceIndices[index + 0];
			var fi1 = faceIndices[index + 1];
			var fi2 = faceIndices[index + 2];

			var v0 = points[fi0];
			var v1 = points[fi1];
			var v2 = points[fi2];

			if (v0 == null || v1 == null || v2 == null) {
				throw 'Invalid face indices detected. ${fi0}, ${fi1}, ${fi2}';
			}
			var dualPoint = computePowerCenter(v0, v1, v2);
			if (dualPoint != null) {
				// Round coordinates to mitigate floating-point precision issues
				var roundedX = Math.round(dualPoint.x / precision) * precision;
				var roundedY = Math.round(dualPoint.y / precision) * precision;
				var key = roundedX + "," + roundedY;

				if (!cellVerts.exists(key)) {
					cellVerts.set(key, dualPoint);
				}
				var p = cellVerts.get(key);

				// Assign dual vertex to the corresponding cells
				for (j in 0...3) {
					var cellIndex = faceIndices[index + j];
					var cell = cells.get(cellIndex);
					if (cell != null) {
						cell.push(p);
					}
				}
			}
		}

		// Identify indices of boundary points
		var boundaryStartIndex = originalPoints.length;
		var boundaryEndIndex = liftedPoints.length - 1;
		var boundaryIndices = [];
		for (i in boundaryStartIndex...liftedPoints.length) {
			boundaryIndices.push(i);
		}

		// Handle unbounded cells by extending their edges to the bounding box
		var convexHull = new haxe.ds.Map<Int, Bool>();
		for (index in convexHullIndices) {
			convexHull.set(index, true);
		}

		for (i in boundaryStartIndex...liftedPoints.length) {
			cells.remove(i);
		}

		for (pair in cells.keyValueIterator()) {
			var pointIndex = pair.key;
			var cell = pair.value;
			var origin = points[pointIndex]; // Ensure this conversion exists

			// Remove duplicates based on proximity
			var uniqueCell = removeDuplicates(cell);

			// Sort unique vertices by angle around the origin
			sortInPlace(uniqueCell, new Point2D(origin.x, origin.y));

			var isUnbounded = convexHull.exists(pointIndex);

			if (isUnbounded) {
				// Perform polygon clipping to the bounding box
				uniqueCell = Clipping2D.clipPolygon(uniqueCell, bb);
				sortInPlace(uniqueCell, new Point2D(origin.x, origin.y));
				cells.set(pointIndex, uniqueCell);
			} 
		}

		// Remove boundary points from cells
		for (i in boundaryStartIndex...liftedPoints.length) {
			cells.remove(i);
		}
		return cells;
	}

	private static function computePowerCenter(p1:WeightedPoint2D, p2:WeightedPoint2D, p3:WeightedPoint2D):Point2D {
		// Compute coefficients for the linear equations derived from power distance
		var A1 = 2 * (p2.x - p1.x);
		var B1 = 2 * (p2.y - p1.y);
		var C1 = (p2.x * p2.x - p1.x * p1.x) + (p2.y * p2.y - p1.y * p1.y) + (p1.weight - p2.weight);

		var A2 = 2 * (p3.x - p2.x);
		var B2 = 2 * (p3.y - p2.y);
		var C2 = (p3.x * p3.x - p2.x * p2.x) + (p3.y * p3.y - p2.y * p2.y) + (p2.weight - p3.weight);

		var determinant = A1 * B2 - A2 * B1;
		if (Math.abs(determinant) < 1e-10) {
			// Degenerate case, cannot compute power center
			trace('Degenerate face encountered: cannot compute power center.');
			return null;
		}

		var x = (B2 * C1 - B1 * C2) / determinant;
		var y = (A1 * C2 - A2 * C1) / determinant;

		return new Point2D(x, y);
	}

}
