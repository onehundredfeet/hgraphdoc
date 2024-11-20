package grph;

import haxe.rtti.Meta;
import grph.Point2D;
import grph.Rect2D;
import Math;

class Poisson2D {
	// Bridson's Algorithm - Spatially accelerated
	public static function pointsOnDiskFast(bounds:Rect2D, radius:Float, numSamples:Int, random:Random):Array<Point2D> {
		var gridSize = radius / Math.sqrt(2);
		var grid:Array<Array<Point2D>> = [];
		var points:Array<Point2D> = [];
		var activeList:Array<Point2D> = [];

		var cols = Math.ceil(bounds.width / gridSize);
		var rows = Math.ceil(bounds.height / gridSize);
		for (i in 0...cols) {
			grid.push([]);
			for (j in 0...rows) {
				grid[i].push(null);
			}
		}

		var initialPoint = new Point2D(random.random() * bounds.width + bounds.xmin, random.random() * bounds.height + bounds.ymin);
		points.push(initialPoint);
		activeList.push(initialPoint);
        var gx = Math.floor(initialPoint.x / gridSize);
        var gy = Math.floor(initialPoint.y / gridSize);
		grid[gx][gy] = initialPoint;

        function isValidDiscPoint(point:Point2D):Bool {
            if (point.x < bounds.xmin || point.x >= bounds.xmax || point.y < bounds.ymin || point.y >= bounds.ymax) {
                return false;
            }
    
            var gridX = Math.floor(point.x / gridSize);
            var gridY = Math.floor(point.y / gridSize);
            var searchRadius = 2;
    
            var mini = Std.int(Math.max(0, gridX - searchRadius));
            var maxi = Std.int(Math.min(grid.length, gridX + searchRadius + 1));
            for (i in mini...maxi) {
                var minj = Std.int(Math.max(0, gridY - searchRadius));
                var maxj = Std.int(Math.min(grid[i].length, gridY + searchRadius + 1));
                for (j in minj...maxj) {
                    var neighbor = grid[i][j];
                    if (neighbor != null && neighbor.distanceTo(point) < radius) {
                        return false;
                    }
                }
            }
    
            return true;
        }

		while (activeList.length > 0) {
			var idx = Math.floor(random.random() * activeList.length);
			var point = activeList[idx];
			var found = false;

			for (n in 0...numSamples) {
				var angle = random.random() * Math.PI * 2;
				var r = radius + random.random() * radius;
				var newPoint = new Point2D(point.x + r * Math.cos(angle), point.y + r * Math.sin(angle));

				if (isValidDiscPoint(newPoint)) {
					points.push(newPoint);
					activeList.push(newPoint);
					grid[Math.floor(newPoint.x / gridSize)][Math.floor(newPoint.y / gridSize)] = newPoint;
					found = true;
					break;
				}
			}

			if (!found) {
				activeList.splice(idx, 1);
			}
		}

		return points;
	}

	// Bridson's Algorithm with Rectangle
	public static function pointsOnRectangleFast(bounds:Rect2D, radius:Float, numSamples:Int, random:Random):Array<Point2D> {
		final gridSize = radius / Math.sqrt(2);
		var grid:Array<Array<Point2D>> = [];
		var points:Array<Point2D> = [];
		var activeList:Array<Point2D> = [];

		var cols = Math.ceil(bounds.width / gridSize);
		var rows = Math.ceil(bounds.height / gridSize);
		for (i in 0...cols) {
			grid.push([]);
			for (j in 0...rows) {
				grid[i].push(null);
			}
		}

		// Start with an initial random point inside the rectangle
		var initialPoint = new Point2D(random.random() * bounds.width + bounds.xmin, random.random() * bounds.height + bounds.ymin);
		points.push(initialPoint);
		activeList.push(initialPoint);
		grid[Math.floor(initialPoint.x / gridSize)][Math.floor(initialPoint.y / gridSize)] = initialPoint;

        function isValidPointInRectangle(point:Point2D):Bool {
            if (point.x < bounds.xmin || point.x >= bounds.xmax || point.y < bounds.ymin || point.y >= bounds.ymax) {
                return false;
            }
    
            final gridX = Math.floor(point.x / gridSize);
            final gridY = Math.floor(point.y / gridSize);
            final searchRadius = 2; // Check neighboring grid cells within 2x2 radius
    
            final min = Std.int(Math.max(0, gridX - searchRadius));
            final max = Std.int(Math.min(grid.length, gridX + searchRadius + 1));
    
            for (i in min...max) {
                final jmin = Std.int(Math.max(0, gridY - searchRadius));
                final jmax = Std.int(Math.min(grid[i].length, gridY + searchRadius + 1));
                for (j in jmin...jmax) {
                    var neighbor = grid[i][j];
                    if (neighbor != null && neighbor.distanceTo(point) < radius) {
                        return false;
                    }
                }
            }
    
            return true;
        }

		while (activeList.length > 0) {
			var idx = Math.floor(random.random() * activeList.length);
			var point = activeList[idx];
			var found = false;

			for (n in 0...numSamples) {
				// Generate a new candidate point within a ring around the current point
				var angle = random.random() * Math.PI * 2;
				var r = radius + random.random() * radius;
				var newPoint = new Point2D(point.x + r * Math.cos(angle), point.y + r * Math.sin(angle));

				// Check if the point is within the rectangular bounds
				if (isValidPointInRectangle(newPoint)) {
					points.push(newPoint);
					activeList.push(newPoint);
					grid[Math.floor(newPoint.x / gridSize)][Math.floor(newPoint.y / gridSize)] = newPoint;
					found = true;
					break;
				}
			}

			if (!found) {
				activeList.splice(idx, 1);
			}
		}

		return points;
	}

    // Generate Poisson-disc distributed points within the polygon considering edge points
	public static function pointsOnPolygon(polygon:Polygon2D, minDistance:Float, margin: Float = 0.0, avoidPoints:Array<Point2D> = null, avoidanceDistance : Null<Float> = null, rejectionThreshold = 30, random:Random = null):Array<Point2D> {
		if (random == null) {
			random = new Random();
		}
		var bbox = Rect2D.fromPoints(polygon);
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
            for (i in 0...polygon.length) {
                var a = polygon[i];
                var b = polygon[(i + 1) % polygon.length];
                var distance = Line2D.segmentDistanceToPoint(a, b, p);
                if (distance < margin) {
                    return true;
                }
            }
            return false;
        }
		// Function to check if point is valid
		function isValidPoint(p:Point2D):Bool {
			if (!polygon.containsPoint(p))
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

}

