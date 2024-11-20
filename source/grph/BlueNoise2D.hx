package grph;

// Two different methods for generating blue noise in 2D
class BlueNoise2D {
    // Lloyd's algorithm
    public static function generatePointsCVT(bbox:Rect2D, numPoints:Int, gridSizeX:Int, gridSizeY:Int, numIterations:Int, random:Random = null):Array<Point2D> {
        var xMin = bbox.xmin;
        var xMax = bbox.xmax;
        var yMin = bbox.ymin;
        var yMax = bbox.ymax;

        if (random == null) {
            random = new Random();
        }
        // Initialize random points
        var points = bbox.uniformRandomPoints(numPoints, random);

        var dx = (xMax - xMin) / gridSizeX;
        var dy = (yMax - yMin) / gridSizeY;

        for (iteration in 0...numIterations) {
            // Assign pixels to the nearest point
            var assignments = new Map<Int, Array<Point2D>>();
            for (i in 0...gridSizeX) {
                for (j in 0...gridSizeY) {
                    var x = xMin + (i + 0.5) * dx;
                    var y = yMin + (j + 0.5) * dy;
                    var pixel = new Point2D(x, y);
                    // Find the nearest point
                    var minDistSq:Null<Float> = null;
                    var nearestPointIndex:Int = -1;
                    for (k in 0...numPoints) {
                        var point = points[k];
                        var distSq = (point.x - x) * (point.x - x) + (point.y - y) * (point.y - y);
                        if (minDistSq == null || distSq < minDistSq) {
                            minDistSq = distSq;
                            nearestPointIndex = k;
                        }
                    }
                    // Assign the pixel to the nearest point
                    if (!assignments.exists(nearestPointIndex)) {
                        assignments.set(nearestPointIndex, new Array<Point2D>());
                    }
                    assignments.get(nearestPointIndex).push(pixel);
                }
            }
            // Update the positions of the points
            for (k in 0...numPoints) {
                if (assignments.exists(k)) {
                    var pixels = assignments.get(k);
                    // Compute centroid
                    var sumX = 0.0;
                    var sumY = 0.0;
                    var numPixels = pixels.length;
                    for (p in pixels) {
                        sumX += p.x;
                        sumY += p.y;
                    }
                    var centroidX = sumX / numPixels;
                    var centroidY = sumY / numPixels;
                    // Update point position
                    points[k].x = centroidX;
                    points[k].y = centroidY;
                } else {
                    // If no pixels assigned, re-initialize the point randomly
                    points[k].x = random.random() * (xMax - xMin) + xMin;
                    points[k].y = random.random() * (yMax - yMin) + yMin;
                }
            }
            // Optionally, print progress
            trace("Iteration " + (iteration + 1) + "/" + numIterations + " completed.");
        }

        return points;
    }

    //Blue Noise through Optimal Transport
    public static function generatePointsBNOTApprox(bbox:Rect2D, numPoints:Int, gridSizeX:Int, gridSizeY:Int, numIterations:Int, random:Random = null):Array<Point2D> {
        var xMin = bbox.xmin;
        var xMax = bbox.xmax;
        var yMin = bbox.ymin;
        var yMax = bbox.ymax;

        var xRange = xMax - xMin;
        var yRange = yMax - yMin;

        if (random == null) {
            random = new Random();
        }
        var points = bbox.uniformRandomPoints(numPoints, random);

        // Define the density function (uniform in this case)
        var totalMass = xRange * yRange;
        var massPerCell = totalMass / (gridSizeX * gridSizeY);

        // Initialize potentials (weights) for each point
        var potentials = new Array<Float>();
        for (_ in 0...numPoints) {
            potentials.push(0.0);
        }

        var dx = xRange / gridSizeX;
        var dy = yRange / gridSizeY;

        for (iteration in 0...numIterations) {
            // Compute power diagram cells (approximated)
            var cells = new Map<Int, Array<Point2D>>();
            for (i in 0...gridSizeX) {
                for (j in 0...gridSizeY) {
                    var x = xMin + (i + 0.5) * dx;
                    var y = yMin + (j + 0.5) * dy;
                    var pixel = new Point2D(x, y);

                    // Compute power distance to each point
                    var minPowerDist:Null<Float> = null;
                    var nearestPointIndex:Int = -1;
                    for (k in 0...numPoints) {
                        var point = points[k];
                        var distSq = (point.x - x) * (point.x - x) + (point.y - y) * (point.y - y);
                        var powerDist = distSq - potentials[k]; // Subtract potential
                        if (minPowerDist == null || powerDist < minPowerDist) {
                            minPowerDist = powerDist;
                            nearestPointIndex = k;
                        }
                    }
                    // Assign the pixel to the nearest point in power distance
                    if (!cells.exists(nearestPointIndex)) {
                        cells.set(nearestPointIndex, new Array<Point2D>());
                    }
                    cells.get(nearestPointIndex).push(pixel);
                }
            }

            // Update potentials and point positions
            for (k in 0...numPoints) {
                if (cells.exists(k)) {
                    var cell = cells.get(k);
                    var cellMass = cell.length * massPerCell;
                    var desiredMass = totalMass / numPoints;
                    var massDifference = cellMass - desiredMass;

                    // Update potential (gradient descent step)
                    var learningRate = 0.1; // Adjust as needed
                    potentials[k] += learningRate * massDifference;

                    // Compute centroid of the cell
                    var sumX = 0.0;
                    var sumY = 0.0;
                    for (p in cell) {
                        sumX += p.x;
                        sumY += p.y;
                    }
                    var centroidX = sumX / cell.length;
                    var centroidY = sumY / cell.length;

                    // Update point position towards centroid
                    points[k].x = centroidX;
                    points[k].y = centroidY;
                } else {
                    // If no cell assigned, re-initialize the point
                    points[k].x = random.random() * xRange + xMin;
                    points[k].y = random.random() * yRange + yMin;
                    potentials[k] = 0.0;
                }
            }

            // Optionally, print progress
            trace("Iteration " + (iteration + 1) + "/" + numIterations + " completed.");
        }

        return points;
    }

    /**
     * Generates a blue noise point distribution within a 2D bounding box using the
     * Blue Noise through Optimal Transport (BNOT) algorithm with the provided PowerDiagram class.
     *
     * @param bbox A Rect2D object defining the bounding box.
     * @param numPoints The number of points to generate.
     * @param numIterations The number of iterations to run the algorithm.
     * @return An array of Point2D coordinates of the generated points.
     */
    public static function generatePointsBNOT(bbox:Rect2D, numPoints:Int, numIterations:Int, random:Random):Array<Point2D> {
        var xMin = bbox.xmin;
        var xMax = bbox.xmax;
        var yMin = bbox.ymin;
        var yMax = bbox.ymax;

        // Initialize points randomly within the bounding box
        var points = new Array<Point2D>();
        var weightedPoints = new Array<WeightedPoint2D>();
        for (i in 0...numPoints) {
            var x = random.random() * (xMax - xMin) + xMin;
            var y = random.random() * (yMax - yMin) + yMin;
            var point = new Point2D(x, y);
            points.push(point);
            weightedPoints.push(WeightedPoint2D.fromPoint2D(point, 0.0));
        }

        // Define the density function (uniform in this case)
        var totalArea = (xMax - xMin) * (yMax - yMin);
        var desiredMass = totalArea / numPoints; // Each point should cover an equal area

        // Initialize potentials (weights) for each point
        for (wp in weightedPoints) {
            wp.weight = 0.0;
        }

        for (iteration in 0...numIterations) {
            // Compute power diagram cells using the provided PowerDiagram class
            var cells = PowerDiagram.computeCells(weightedPoints, bbox.getMin(), bbox.getMax(), random);

            // Update potentials and point positions
            for (k in 0...numPoints) {
                var wp = weightedPoints[k];

                // Get the cell associated with this point
                var cell = cells.get(k);
                if (cell != null && cell != null && cell.length > 0) {
                    // Compute the area (mass) of the cell
                    var cellArea = computePolygonArea(cell);

                    // Compute the mass difference
                    var massDifference = cellArea - desiredMass;

                    // Update potential (using gradient descent)
                    var learningRate = 0.1; // Adjust as needed
                    wp.weight += learningRate * massDifference;

                    // Compute centroid of the cell
                    var centroid = computeCentroid(cell);

                    // Update point position towards centroid
                    wp.x = centroid.x;
                    wp.y = centroid.y;
                } else {
                    // If cell is null or empty, re-initialize the point
                    wp.x = random.random() * (xMax - xMin) + xMin;
                    wp.y = random.random() * (yMax - yMin) + yMin;
                    wp.weight = 0.0;
                }
            }

            // Optionally, print progress
            trace("Iteration " + (iteration + 1) + "/" + numIterations + " completed.");
        }

        // Extract final point positions
        var finalPoints = new Array<Point2D>();
        for (wp in weightedPoints) {
            finalPoints.push(new Point2D(wp.x, wp.y));
        }

        return finalPoints;
    }

    /**
     * Computes the area of a polygon given its vertices.
     *
     * @param polygon An array of Point2D representing the polygon vertices.
     * @return The area of the polygon.
     */
    private static function computePolygonArea(polygon:Array<Point2D>):Float {
        var area = 0.0;
        var n = polygon.length;
        for (i in 0...n) {
            var p1 = polygon[i];
            var p2 = polygon[(i + 1) % n];
            area += (p1.x * p2.y) - (p2.x * p1.y);
        }
        return Math.abs(area) / 2.0;
    }

    /**
     * Computes the centroid of a polygon given its vertices.
     *
     * @param polygon An array of Point2D representing the polygon vertices.
     * @return The centroid as a Point2D.
     */
    private static function computeCentroid(polygon:Array<Point2D>):Point2D {
        var area = computePolygonArea(polygon);
        var centroidX = 0.0;
        var centroidY = 0.0;
        var n = polygon.length;

        for (i in 0...n) {
            var p1 = polygon[i];
            var p2 = polygon[(i + 1) % n];
            var cross = (p1.x * p2.y) - (p2.x * p1.y);
            centroidX += (p1.x + p2.x) * cross;
            centroidY += (p1.y + p2.y) * cross;
        }

        var factor = 1.0 / (6.0 * area);
        centroidX *= factor;
        centroidY *= factor;

        return new Point2D(centroidX, centroidY);
    }


}
