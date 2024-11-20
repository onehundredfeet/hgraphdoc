package grph;

import grph.Point2D;



@:forward.new
@:forward
private abstract Site(Point2D) from Point2D to Point2D{

}


private class Event {
    public var point:Point2D;
    public var y:Float;
    public var arc:Arc;
    public var valid:Bool;

    public function new(point:Point2D, y:Float, arc:Arc) {
        this.point = point;
        this.y = y;
        this.arc = arc;
        this.valid = true;
    }
}


private class Arc {
    public var site:Site;
    public var prev:Arc;
    public var next:Arc;
    public var event:Event;
    public var edge:Edge2D;

    public function new(site:Site) {
        this.site = site;
        this.prev = null;
        this.next = null;
        this.event = null;
        this.edge = null;
    }
}


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

		var edges = [new Edge2D(), new Edge2D(), new Edge2D()];

		// Insert each point into the triangulation
		var badTriangles = new Array<Triangle2D>();
		//var badTriangles = new Map<Triangle2D, Bool>();
		for (point in points) {
			badTriangles.resize(0);

			// Find all triangles that are no longer valid due to the insertion
			for (tri in triangles) {
				if (tri.circumCircleContains(point)) {
					badTriangles.push(tri);
				}
			}

			// Find the boundary of the polygonal hole
			var polygon = new Array<Edge2D>();
			for (tri in badTriangles) {
				edges[0].setFromPointsDirected(tri.a, tri.b);
				edges[1].setFromPointsDirected(tri.b, tri.c);
				edges[2].setFromPointsDirected(tri.c, tri.a);
				for (edge in edges) {
					var isShared = false;
					for (other in badTriangles) {
						if (tri == other)
							continue;
						var otherEdges = other.getEdgesDirected();
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
						polygon.push(edge.clone());
					}
				}
			}

			// Remove bad triangles from the triangulation
			triangles = triangles.filter(function(t:Triangle2D):Bool {
				return !badTriangles.contains(t);
			});

			// Retriangulate the polygonal hole with new triangles
			for (edge in polygon) {
				var newTri = null;

				// Ensure the new triangle is counter-clockwise
				if (Point2D.orientation(edge.a, edge.b, point) < 0) {
					newTri = new Triangle2D(edge.a, point, edge.b);
				} else {
					newTri = new Triangle2D(edge.a, edge.b, point);
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


	// Sweeping line algorithm
    public static function triangulateFast(points:Array<Point2D>, bounds:Rect2D = null) : Array<Triangle2D> {
		var triangles = new Array<Triangle2D>();
		var edges:Array<Edge2D> = [];
		var beachline:Arc = null;
		var events:Array<Event> = [];

		if (bounds == null) {
			bounds = Rect2D.fromPoints(points);
		}

		var x0:Float = bounds.xmin;
		var x1:Float = bounds.xmax;
		var y0:Float = bounds.ymin;
		var y1:Float = bounds.ymax;

		function computeBreakPoint(p1:Point2D, p2:Point2D, directrix:Float):Float {
			// Parabola breakpoint calculation
			var dp1 = 2.0 * (p1.y - directrix);
			var dp2 = 2.0 * (p2.y - directrix);
	
			if (dp1 == dp2) {
				return (p1.x + p2.x) / 2.0;
			}
	
			var a1 = 1.0 / dp1;
			var b1 = -2.0 * p1.x / dp1;
			var c1 = (p1.x * p1.x + p1.y * p1.y - directrix * directrix) / dp1;
	
			var a2 = 1.0 / dp2;
			var b2 = -2.0 * p2.x / dp2;
			var c2 = (p2.x * p2.x + p2.y * p2.y - directrix * directrix) / dp2;
	
			var A = a1 - a2;
			var B = b1 - b2;
			var C = c1 - c2;
	
			var discriminant = B * B - 4 * A * C;
			if (discriminant < 0) {
				return (p1.x + p2.x) / 2.0;
			}
	
			var x1 = (-B + Math.sqrt(discriminant)) / (2 * A);
			var x2 = (-B - Math.sqrt(discriminant)) / (2 * A);
	
			return p1.y > p2.y ? Math.max(x1, x2) : Math.min(x1, x2);
		}

		function leftBreakPoint(arc:Arc, directrix:Float):Float {
			if (arc.prev == null) {
				return x0;
			}
			return computeBreakPoint(arc.prev.site, arc.site, directrix);
		}
	
		function rightBreakPoint(arc:Arc, directrix:Float):Float {
			if (arc.next == null) {
				return x1;
			}
			return computeBreakPoint(arc.site, arc.next.site, directrix);
		}

		function getArcAbove(x:Float, y:Float):Arc {
			var arc = beachline;
			var last:Arc = null;
	
			while (arc != null) {
				var dxl = leftBreakPoint(arc, y) - x;
				if (dxl > 0) {
					if (arc.prev != null) {
						arc = arc.prev;
					} else {
						break;
					}
				} else {
					var dxr = x - rightBreakPoint(arc, y);
					if (dxr > 0) {
						if (arc.next == null) {
							last = arc;
							break;
						}
						arc = arc.next;
					} else {
						return arc;
					}
				}
				last = arc;
			}
			return last;
		}
	
		function getY(point:Point2D, x:Float):Float {
			// Compute the y-coordinate of the parabola at x
			var dp = 2.0 * (point.y - point.y);
			if (dp == 0) {
				return point.y;
			}
			var a = 1.0 / dp;
			var b = -2.0 * point.x / dp;
			var c = (point.x * point.x + point.y * point.y - point.y * point.y) / dp;
	
			return a * x * x + b * x + c;
		}
		
		function ccw(a:Point2D, b:Point2D, c:Point2D):Bool {
			return ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) >= 0;
		}

		function circleCenter(a:Point2D, b:Point2D, c:Point2D):Point2D {
			// Compute the center of the circle passing through a, b, c
			var d = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y));
			if (d == 0) {
				return null;
			}
			var x = ((a.x * a.x + a.y * a.y) * (b.y - c.y) +
					 (b.x * b.x + b.y * b.y) * (c.y - a.y) +
					 (c.x * c.x + c.y * c.y) * (a.y - b.y)) / d;
			var y = ((a.x * a.x + a.y * a.y) * (c.x - b.x) +
					 (b.x * b.x + b.y * b.y) * (a.x - c.x) +
					 (c.x * c.x + c.y * c.y) * (b.x - a.x)) / d;
			return new Point2D(x, y);
		}
		function checkCircleEvent(arc:Arc) {
			trace('Check circle event');
			if (arc.event != null && arc.event.y != y0) {
				arc.event.valid = false;
			}
			arc.event = null;
	
			if (arc.prev == null || arc.next == null) {
				trace('No neighbors');
				return;
			}
	
			var a = arc.prev.site;
			var b = arc.site;
			var c = arc.next.site;
	
			if (!ccw(a, b, c)) {
				trace('Not counterclockwise ${a} ${b} ${c}');
				return;
			}
	
			var circle = circleCenter(a, b, c);
			if (circle == null) {
				trace('Circle center is null');
				return;
			}
	
			var y = circle.y + Point2D.pointDistanceToXY(circle.x, circle.y, b.x, b.y);
	
			if (y < y0) {
				trace('Circle center is below the sweep line');
				return;
			}
	
			trace('Circle event: ${circle} ${y}');
			var event = new Event(new Point2D(circle.x, y), y, arc);
			arc.event = event;
			//events.push(event);

			// max y heap 
			var i = 0;
			for (i in 0...events.length) {
				if ( y < events[i].y) {
					events.insert(i, event);
					break;
				}
			}
			if (events.length == 0 || i == events.length) {
				events.push(event);
			}
			//trace('Evens: ${events.map(function(e:Event):Float { return e.y; })}');
			// events.sort(function(e1:Event, e2:Event) {
			// 	return e2.y - e1.y > 0 ? 1 : -1; // Max-heap
			// });
		}
	
		
		function handleSite(site:Site) {
			if (beachline == null) {
				beachline = new Arc(site);
				return;
			}
		
			var arc = getArcAbove(site.x, site.y);
			if (arc.event != null) {
				arc.event.valid = false;
			}
		
			// Create new edges without setting both points to start
			var start = new Point2D(site.x, getY(arc.site, site.x));
			var edgeLeft = new Edge2D();
			edgeLeft.setFromPointsDirected(start, null); // Set one point; the other will be set later
			var edgeRight = new Edge2D();
			edgeRight.setFromPointsDirected(null, start); // Set one point; the other will be set later
		
			arc.edge = edgeLeft;
			var newArc = new Arc(site);
			newArc.edge = edgeRight;
		
			// Re-link the beachline
			newArc.prev = arc;
			newArc.next = arc.next;
			if (arc.next != null) {
				arc.next.prev = newArc;
			}
			arc.next = newArc;
		
			// Add edges to the list
			edges.push(edgeLeft);
			edges.push(edgeRight);
		
			// Check for circle events
			checkCircleEvent(arc);
			checkCircleEvent(newArc);
		}
		
	
		function handleCircle(event:Event) {
			var arc = event.arc;
	
			// Create a vertex at the circle event location
			var vertex = event.point;
	
			// Set the endpoints of the edges
			if (arc.prev != null) {
				arc.prev.edge.b = vertex;
			}
			if (arc.next != null) {
				arc.next.edge.a = vertex;
			}
	
			// Collect Delaunay edges (connections between sites)
			if (arc.prev != null && arc.next != null) {
				var a = arc.prev.site;
				var b = arc.site;
				var c = arc.next.site;
	
				var triangle = new Triangle2D(a, b, c);
				if (!triangle.isDegenerate()) {
					triangles.push(triangle);
				}
			}
	
			// Remove the arc from the beachline
			if (arc.prev != null) {
				arc.prev.next = arc.next;
				// arc.prev.edge = new Edge2D();
				// arc.prev.edge.setFromPointsDirected(vertex, vertex); // this is a degenerate edge?!? ERROR
				// edges.push(arc.prev.edge);
			}
			if (arc.next != null) {
				arc.next.prev = arc.prev;
			}
	
			// Invalidate any circle events involving the disappearing arc
			if (arc.prev != null) {
				checkCircleEvent(arc.prev);
			}
			if (arc.next != null) {
				checkCircleEvent(arc.next);
			}
		}
	
		function finalizeEdges() {
			// Finish all edges by extending them to the bounding box
			var l = beachline;
	
			while (l != null) {
				if (l.edge != null) {
					var start = l.edge.a;
					var end = l.edge.b;
	
					// Extend edges to the bounding box
					if (start != null && end == null) {
						// Extend edge to the bounding box
						if (l.prev == null) {
							end = new Point2D(x0, start.y);
						} else {
							end = new Point2D(x1, start.y);
						}
						l.edge.b = end;
					}
				}
				l = l.next;
			}
		}


		var sites = points.copy();
        sites.sort(function(a:Site, b:Site) {
			if (a.y == b.y) return 0;
            return b.y - a.y > 0 ? -1 : 1; // sort by decreasing y
        });

		trace('sorted: ${sites}');
        // Main loop
        while (sites.length > 0 || events.length > 0) {
            var event:Event;
            // Handle site events
            if (events.length == 0 || (sites.length > 0 && sites[sites.length - 1].y > events[events.length - 1].y)) {
				trace('Handel site ${events.length} ${sites.length}');
                var site = sites.pop();
                handleSite(site);
            } else {
				trace('handle event  ${events.length} ${sites.length}');
                // Handle circle events
                event = events.pop();
                if (event.valid) {
                    handleCircle(event);
                }
            }
        }

        // Finish edges
        finalizeEdges();
		
		return triangles;
    }

}


