package gdoc;
import seedyrng.Random;

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

	public function getAsEdges():Array<Edge2D> {
		var edges = new Array<Edge2D>();
		var len = this.length;
		if (len < 2)
			return edges;
		for (i in 0...len) {
			var a = this[i];
			var b = this[(i + 1) % len]; // Wrap around to the first point
			edges.push(new Edge2D(a, b));
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


	// Generate Poisson-disc distributed points within the polygon considering edge points
	public function generateInteriorPoints(minDistance:Float, margin: Float = 0.0, avoidPoints:Array<Point2D> = null, avoidanceDistance : Null<Float> = null, rejectionThreshold = 30, random:Random = null):Array<Point2D> {
		if (random == null) {
			random = new Random();
		}
		var bbox = Rect2D.fromPoints(this);
		var cellSize = minDistance / Math.sqrt(2);

        if (avoidanceDistance == null) {
            avoidanceDistance = minDistance;
        }
		// Initialize grid
		var gridWidth = Math.ceil((bbox.xmax - bbox.xmin) / cellSize);
		var gridHeight = Math.ceil((bbox.ymax - bbox.ymin) / cellSize);
		var grid:Array<Array<WeightedPoint2D>> = [];

        grid.resize(gridWidth * gridHeight);

        // Function to get grid index
		function getGridIndex(p:Point2D):Int {
			var gx = Math.floor((p.x - bbox.xmin) / cellSize);
			var gy = Math.floor((p.y - bbox.ymin) / cellSize);
			return gy * gridWidth + gx;
		}

        function addPointToGrid(p:Point2D, d : Float) {
            var index = getGridIndex(p);
            if (grid[index] == null) {
                grid[index] = new Array<WeightedPoint2D>();
            }
            grid[index].push(new WeightedPoint2D(p.x, p.y, d* d));
        }

		
		var points = new Array<Point2D>();
		var activeList = new Array<Point2D>();

        function isWithinMargin(p:Point2D):Bool {
            if (margin == 0.0) {
                return false;
            }
            for (i in 0...this.length) {
                var a = this[i];
                var b = this[(i + 1) % this.length];
                var distance = Line2D.segmentDistanceToPoint(a, b, p);
                if (distance < margin) {
                    return true;
                }
            }
            return false;
        }
		// Function to check if point is valid
		function isValidPoint(p:Point2D):Bool {
			if (!containsPoint(p))
				return false;

            if (isWithinMargin(p)) {
                return false;
            }
			var gx = Math.floor((p.x - bbox.xmin) / cellSize);
			var gy = Math.floor((p.y - bbox.ymin) / cellSize);

			var minGX = Std.int(Math.max(gx - 2, 0));
			var maxGX = Std.int(Math.min(gx + 2, gridWidth - 1));
			var minGY = Std.int(Math.max(gy - 2, 0));
			var maxGY = Std.int(Math.min(gy + 2, gridHeight - 1));

			for (ix in minGX...maxGX + 1) {
				for (iy in minGY...maxGY + 1) {
					var index = iy * gridWidth + ix;
					var neighbors = grid[index];
					if (neighbors != null) {
						for (neighbor in neighbors) {
							if (p.withinSquaredXY(neighbor.x, neighbor.y, neighbor.weight)) {
								return false;
							}
						}
					}
				}
			}
			return true;
		}

		if (avoidPoints != null) {
			// Add edge points to the grid
			for (ep in avoidPoints) {
                addPointToGrid(ep, avoidanceDistance);
			}
		}

		// Generate initial point
		var initialPoint:Point2D;
		var attempts = 0;
		do {
			var x = random.random() * (bbox.xmax - bbox.xmin) + bbox.xmin;
			var y = random.random() * (bbox.ymax - bbox.ymin) + bbox.ymin;
			initialPoint = new Point2D(x, y);
			attempts++;
			if (attempts > 2000) {
				throw 'Unable to find initial point inside polygon';
			}
		} while (!isValidPoint(initialPoint));

		points.push(initialPoint);
		activeList.push(initialPoint);
        addPointToGrid(initialPoint, minDistance);

		while (activeList.length > 0) {
			var randomIndex = Std.int(random.random() * activeList.length);
			var point = activeList[randomIndex];
			var found = false;
			for (_ in 0...rejectionThreshold) {
				var radius = minDistance + minDistance * random.random();
				var angle = random.random() * Math.PI * 2;
				var newX = point.x + radius * Math.cos(angle);
				var newY = point.y + radius * Math.sin(angle);
				var newPoint = new Point2D(newX, newY);
				if (isValidPoint(newPoint)) {
					points.push(newPoint);
					activeList.push(newPoint);
                    addPointToGrid(newPoint, minDistance);
					found = true;
					break;
				}
			}
			if (!found) {
                for (i in randomIndex...activeList.length - 1) {
                    activeList[i] = activeList[i + 1];
                }
				activeList.resize(activeList.length - 1);
			}
		}
		return points;
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
}
