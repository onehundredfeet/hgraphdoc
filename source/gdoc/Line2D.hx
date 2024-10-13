package gdoc;

@:forward
abstract Line2D(Point3D) from Point3D {
    public inline static function fromPoints(p1:Point2D, p2:Point2D):Line2D {
        var a = p2.y - p1.y;
        var b = p1.x - p2.x;
        var c = a * p1.x + b * p1.y;
        return new Point3D(a, b, c);
    }

    public inline static function fromCoefficients(a:Float, b:Float, c:Float):Line2D {
        return new Point3D(a, b, c);
    }

    public inline function isPointOn( point:Point2D, epsilon:Float = 1e-12):Bool {
        var lhs:Float = this.x * point.x + this.y * point.y + this.z;
        return Math.abs(lhs) < epsilon;
    }
    public function computeIntersection(line2:Line2D, epsilon:Float = 1e-12):Point2D {
        var a1:Float = this.x;
        var b1:Float = this.y;
        var c1:Float = this.z;

        var a2:Float = line2.x;
        var b2:Float = line2.y;
        var c2:Float = line2.z;

        var determinant:Float = a1 * b2 - a2 * b1;
        if (Math.abs(determinant) < epsilon) {
            // Lines are parallel
            return null;
        }

        var x:Float = (b2 * (-c1) - b1 * (-c2)) / determinant;
        var y:Float = (a1 * (-c2) - a2 * (-c1)) / determinant;
        return new Point2D(x, y);
    }

    // By cross product
    public static function segmentsIntersect(p1:Point2D, q1:Point2D, p2:Point2D, q2:Point2D):Bool {
        // Compute vectors
        var d1 = q1.subtract(p1);
        var d2 = q2.subtract(p2);
        
        // Compute vectors between points
        var r = p2.subtract(p1);
        var s = q2.subtract(p2);
        
        // Compute cross products
        var cross_r_s = d1.crossProduct(d2);
        var cross_r_r = d1.crossProduct(r);
        var cross_s_r = s.crossProduct(r);
        
        // Check if segments are parallel
        if (Math.abs(cross_r_s) < EPSILON) {
            if (Math.abs(cross_r_r) < EPSILON) {
                // Colinear segments - check for overlap
                // Project onto x and y axes and check for overlapping intervals
                var t0 = (p2.x - p1.x) / (d1.x != 0 ? d1.x : EPSILON);
                var t1 = (q2.x - p1.x) / (d1.x != 0 ? d1.x : EPSILON);
                
                if (d1.x == 0) { // Vertical lines, use y-axis
                    t0 = (p2.y - p1.y) / d1.y;
                    t1 = (q2.y - p1.y) / d1.y;
                }
                
                var t_min = Math.min(t0, t1);
                var t_max = Math.max(t0, t1);
                
                if (t_min > 1 + EPSILON || t_max < -EPSILON) {
                    return false; // No overlap
                }
                return true; // Overlapping
            }
            return false; // Parallel and non-colinear
        }
        
        // Compute parameters t and u
        var t = r.crossProduct(d2) / cross_r_s;
        var u = r.crossProduct(d1) / cross_r_s;
        
        // Check if t and u are within the segment ranges
        if (t >= -EPSILON && t <= 1 + EPSILON && u >= -EPSILON && u <= 1 + EPSILON) {
            return true; // Intersection occurs within the segments
        }
        
        return false; // No intersection within the segments
    }

    static inline final EPSILON = 1e-12;

    public static function segmentIntersectsCircle(p1:Point2D, p2:Point2D, center_x:Float, center_y: Float, radius:Float):Bool {
        var dx = p2.x - p1.x;
        var dy = p2.y - p1.y;
        var fx = p1.x - center_x;
        var fy = p1.y - center_y;
        
        var a = dx * dx + dy * dy;
        var b = 2 * (fx * dx + fy * dy);
        var c = (fx * fx + fy * fy) - radius * radius;
        
        var discriminant = b * b - 4 * a * c;
        if (discriminant < -EPSILON) {
            return false; 
        }
        
        discriminant = Math.sqrt(Math.max(discriminant, 0)); // Clamp to zero if very small negative due to precision
        
        var t1 = (-b - discriminant) / (2 * a);
        var t2 = (-b + discriminant) / (2 * a);
        
        if ((t1 >= -EPSILON && t1 <= 1 + EPSILON) || (t2 >= -EPSILON && t2 <= 1 + EPSILON)) {
            return true; // Intersection occurs within the segment
        }
        
        return false; 
    }

    public static function segmentOverlapsCircle(p1:Point2D, p2:Point2D, center_x : Float, center_y : Float, radius:Float) {
        final r2 = radius * radius;
        var point1Inside = Point2D.withinSquaredXYXY(center_x, center_y, p1.x, p1.y, r2);
        var point2Inside = Point2D.withinSquaredXYXY(center_x, center_y, p2.x, p2.y, r2);
        if (point1Inside || point2Inside) return true;

        return segmentIntersectsCircle(p1, p2, center_x, center_y, radius);
    }

    public static function segmentDistanceToPoint(a:Point2D, b:Point2D, p:Point2D):Float {
        var dx = b.x - a.x;
        var dy = b.y - a.y;
        
        if (Math.abs(dx) < EPSILON && Math.abs(dy) < EPSILON) {
            // a and b are the same point
            return p.distanceTo( a);
        }
        
        // Calculate the projection parameter t of point p onto the line segment
        var t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / (dx * dx + dy * dy);
        
        if (t < 0) {
            // Beyond point a
            var d = p.distanceTo( a);
            return d;
        } else if (t > 1) {
            // Beyond point b
            return p.distanceTo( b);
        } else {
            // Projection falls on the segment
            var projection = new Point2D(a.x + t * dx, a.y + t * dy);
            return p.distanceTo( projection);
        }
    }

    public static function segmentDistanceToPointXY(ax : Float, ay: Float, bx : Float, by:Float, px : Float, py:Float):Float {
        var dx = bx - ax;
        var dy = by - ay;
        
        if (Math.abs(dx) < EPSILON && Math.abs(dy) < EPSILON) {
            // a and b are the same point
            return Point2D.distanceToXY(px, py, ax, ay);
        }
        
        // Calculate the projection parameter t of point p onto the line segment
        var t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
        
        if (t < 0) {
            // Beyond point a
            var d = Point2D.distanceToXY(px, py, ax, ay);
            return d;
        } else if (t > 1) {
            // Beyond point b
            return Point2D.distanceToXY(px, py, bx, by);
        } else {
            // Projection falls on the segment
            var projx = ax + t * dx;
            var projy = ay + t * dy;
            return Point2D.distanceToXY(px, py, projx, projy);
        }
    }

    public static function segmentDistanceToSegment(a1:Point2D, a2:Point2D, b1:Point2D, b2:Point2D):Float {
        // If segments intersect, the distance is zero
        if (segmentsIntersect(a1, a2, b1, b2)) {
            return 0.0;
        }
        
        // Otherwise, the distance is the minimum of the distances from the endpoints to the opposite segments
        var d1 = segmentDistanceToPoint(a1, b1, b2);
        var d2 = segmentDistanceToPoint(a2, b1, b2);
        var d3 = segmentDistanceToPoint(b1, a1, a2);
        var d4 = segmentDistanceToPoint(b2, a1, a2);
        
        return Math.min(Math.min(d1, d2), Math.min(d3, d4));
    }

    public static function segmentIntersectionXY(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float) : Point2D {
		var s1x = x2 - x1;
		var s1y = y2 - y1;
		var s2x = x4 - x3;
		var s2y = y4 - y3;

		var denominator = (-s2x * s1y + s1x * s2y);

		if (denominator == 0) {
			// Lines are parallel or colinear
			return null;
		}

		var s = (-s1y * (x1 - x3) + s1x * (y1 - y3)) / denominator;
		var t = (s2x * (y1 - y3) - s2y * (x1 - x3)) / denominator;

		if (s >= 0 && s <= 1 && t >= 0 && t <= 1) {
			// Intersection detected
			var ix = x1 + (t * s1x);
			var iy = y1 + (t * s1y);
			return new Point2D(ix, iy);
		}

		// No intersection
		return null;
	}
}