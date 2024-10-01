package gdoc;

import gdoc.FaceMesh3D;
import gdoc.Point3D;

class QuickHull3D {
	var hull:FaceMesh3D;
	var vertexMap:VertexIndexMap;
	var hullPoints = new Map<Point3D, Bool>();
    var hullPointsCount = 0;
    var hullCentroid:Point3D;

	public var faces(get, never):Array<FaceMesh3DFace>;

    private function updateHullPoints() {
        hullPoints = new Map<Point3D, Bool>();
        hullPointsCount = 0;
        var sum = new Point3D(0, 0, 0);

        for (f in hull.faces) {
            for (v in f.vertices) {
                if (hullPoints.exists(v)) continue;
                hullPoints.set(v, true);
                hullPointsCount++;
                sum.x += v.x;
                sum.y += v.y;
                sum.z += v.z;
            }
        }
        
        sum.x /= hullPointsCount;
        sum.y /= hullPointsCount;
        sum.z /= hullPointsCount;

        hullCentroid = sum;
    }
    private function calculateInteriorPoint():Point3D {
        // Compute the centroid of the current hull's vertices
        var sum = new Point3D(0, 0, 0);
        
        for (v in hullPoints.keys()) {
            sum.x += v.x;
            sum.y += v.y;
            sum.z += v.z;
        }
        sum.x /= hullPointsCount;
        sum.y /= hullPointsCount;
        sum.z /= hullPointsCount;

        hullCentroid = sum;

        return sum;
    }

	function get_faces() {
		return hull.faces;
	}
	// points are assumed to be unique
	public function new(points:Array<Point3D>) {
        
		hull = new FaceMesh3D(points);
		vertexMap = hull.makeVertexIndexMap();

		computeConvexHull();
	}

	function computeConvexHull() {
		if (hull.vertices.length < 4) {
			throw 'At least four points are required to compute a 3D convex hull.';
		}
		findInitialTetrahedron();

		var facePointMap = new Map<FaceMesh3DFace, Array<Point3D>>();
		var remainingPoints = [];

		for (point in hull.vertices) {
			if (!hull.isPointInside(point)) {
                if (hullPoints.exists(point)) {
                    throw 'Point ${point} is already in the hull, but outside hull ${hull.faces}?';
                }
				remainingPoints.push(point);
			}
		}

		// For each remaining point
		for (point in remainingPoints) {
			var maxFace:FaceMesh3DFace = null;
			var maxDistance = -1.0;

			for (face in hull.faces) {
				if (face.isPointAbove(point)) {
					var distance = face.distanceToPoint(point);
					if (distance > maxDistance) {
						maxDistance = distance;
						maxFace = face;
					}
				}
			}

			if (maxFace != null) {
				if (!facePointMap.exists(maxFace)) {
					facePointMap.set(maxFace, []);
				}
				facePointMap.get(maxFace).push(point);
			} else {
                throw ('Point ${point} is not above any face.');
            }
		}

		// Recurse over faces with assigned points
		var processedFaces = new Map<FaceMesh3DFace, Bool>();

        var iterator = facePointMap.keys();
		while (iterator.hasNext()) {
            var face = iterator.next();
			if (!processedFaces.exists(face)) {
				addPointsToHull(face, facePointMap, processedFaces);
                iterator = facePointMap.keys();
			}
		}
	}

	private function findInitialTetrahedron() {
		var points = hull.vertices;
        var vertices:Array<Point3D> ;

        if (points.length > 4) {
			final MIN_X = 0;
			final MIN_Y = 1;
			final MIN_Z = 2;
			final MAX_X = 3;
			final MAX_Y = 4;
			final MAX_Z = 5;
			var extremePoints = [for (i in 0...6) new Array<Point3D>()];
			var extremeValues = [];
            vertices = [];

            // Find extreme points
			
            extremeValues[MIN_X] = Math.POSITIVE_INFINITY;
            extremeValues[MIN_Y] = Math.POSITIVE_INFINITY;
            extremeValues[MIN_Z] = Math.POSITIVE_INFINITY;
			extremeValues[MAX_X] = Math.NEGATIVE_INFINITY;
			extremeValues[MAX_Y] = Math.NEGATIVE_INFINITY;
			extremeValues[MAX_Z] = Math.NEGATIVE_INFINITY;

            for (p in points) {
				var values = [p.x, p.y, p.z, p.x, p.y, p.z];

				for (i in 0...3) {
					if (values[i] < extremeValues[i]) {
						extremeValues[i] = values[i];
						extremePoints[i] = [p];
					} else {
						if (values[i] == extremeValues[i]) {
							extremePoints[i].push(p);
						}
					}
				}
				for (i in 3...6) {
					if (values[i] > extremeValues[i]) {
						extremeValues[i] = values[i];
						extremePoints[i] = [p];
					} else {
						if (values[i] == extremeValues[i]) {
							extremePoints[i].push(p);
						}
					}
				}
            }

            // Create initial simplex
            var simplexCandidates = [];
			for (i in 0...6) {
				for (p in extremePoints[i]) {
					simplexCandidates.push(p);
				}
			}

            var simplex = [];
            for (c in simplexCandidates) {
                if (!simplex.contains(c)) {
                    simplex.push(c);
                }
            }
            if (simplex.length < 4) {
                throw 'Not enough distinct exterme points ${simplex}.';
            }

            var found = false;

			var maxDistance = EPSILON;
			var maxSet = [];

            for (i in 0...simplex.length) {
                for (j in i + 1...simplex.length) {
                    for (k in j + 1...simplex.length) {
                        for (l in k + 1...simplex.length) {
                            var testVerts = [simplex[i], simplex[j], simplex[k], simplex[l]];

							var dist = Math.abs(pointToPlaneDistance(computeNormal(testVerts[0], testVerts[1], testVerts[2]), testVerts[0], testVerts[3]));
							if (dist > maxDistance) {
								maxDistance = dist;
								maxSet = testVerts;
								found = true;
							}
                            
                        }
                    }
                }
            }

			vertices = maxSet;

            if (!found) {
                throw 'Cannot find initial tetrahedron: all points may be coplanar. ${points}';
            }
        } else {
            vertices = points;
            if (areCoplanar(vertices[0], vertices[1], vertices[2], vertices[3])) {
                throw 'Cannot find initial tetrahedron: all points may be coplanar.';
            }
        }

		// Create faces of the tetrahedron
		hull.addFace(vertices[0], vertices[1], vertices[2]);
		hull.addFace(vertices[0], vertices[1], vertices[3]);
		hull.addFace(vertices[0], vertices[2], vertices[3]);
		hull.addFace(vertices[1], vertices[2], vertices[3]);

		var interior = computeCentroid(vertices);

		// Ensure faces are correctly oriented
		for (face in hull.faces) {
			if (face.isPointAbove(interior)) {
				face.flip();
			}
		}

		for (v in vertices) {
			hullPoints.set(v, true);
            hullPointsCount++;
		}

        calculateInteriorPoint();
	}

	private function constructFace(a:Point3D, b:Point3D, c:Point3D):FaceMesh3DFace {
		if (areColinear(a, b, c)) {
			throw 'Degenerate face: Colinear vertices detected.';
		}
		var face = hull.addFace(a, b, c);

		if (face.isPointAbove(hullCentroid)) {
			face.flip();
		}

		// test for non-manifold geometry
		hull.makeEdgeMap(vertexMap);

		return face;
	}

	private function addPointsToHull(face:FaceMesh3DFace, facePointMap:Map<FaceMesh3DFace, Array<Point3D>>, processedFaces:Map<FaceMesh3DFace, Bool>):Void {
		var points = facePointMap.get(face);

		// Remove points that are already in the hull
		points = points.filter(function(p) return !hullPoints.exists(p));

		if (points == null || points.length == 0) {
			processedFaces.set(face, true);
			return;
		}

		// Find the furthest point from the face
		var furthestPoint = points[0];
		var maxDistance = face.distanceToPoint(furthestPoint);

		for (p in points) {
			var distance = face.distanceToPoint(p);
			if (distance > maxDistance) {
				maxDistance = distance;
				furthestPoint = p;
			}
		}

		// Find all faces visible from the furthest point
		var visibleFaces = [];
		findVisibleFaces(furthestPoint, face, visibleFaces);

        // Remove visible faces from convex hull
		for (visibleFace in visibleFaces) {
			hull.faces.remove(visibleFace);
			processedFaces.set(visibleFace, true);
		}

        updateHullPoints();
		// Find the horizon edges
		var horizonEdges = [];
		var edgeMap = hull.makeEdgeMap(vertexMap); // optimization later, don't need to recreate this every time

		for (visibleFace in visibleFaces) {
			for (i in 0...3) {
				var edge = edgeMap.get(vertexMap.makeEdgeKey(visibleFace.vertices[i], visibleFace.vertices[(i + 1) % 3]));
				if (edge != null) {
                    if (edge.fb != null) {
                        throw 'Non-manifold geometry';
                    }
					var adjacentFace = edge.fa;
					if (adjacentFace != null && !visibleFaces.contains(adjacentFace)) {
						horizonEdges.push([visibleFace.vertices[i], visibleFace.vertices[(i + 1) % 3]]);
					}
				}
			}
		}

		// Create new faces from horizon edges to the furthest point
		var newFaces = [];
		for (edge in horizonEdges) {
			// Check if furthestPoint is not the same as any of the horizon edge vertices
			if (edge[0] == furthestPoint || edge[1] == furthestPoint) {
				throw('Edge with duplicate vertices ${edge[0] == furthestPoint} ${edge[1] == furthestPoint}');
			}

			var vertices = [edge[0], edge[1], furthestPoint];
			// find an edge that is still connected
			var otherFace = null;
			for (i in 0...3) {
				var edgeKey = vertexMap.makeEdgeKey(vertices[i], vertices[(i + 1) % 3]);
				if (edgeMap.exists(edgeKey)) {
					var edge = edgeMap.get(edgeKey);
					if (edge.fb != null) {
						throw 'Can not make nonmanifold mesh ${edge.fa} ${edge.fb}';
					}
					otherFace = edge.fa;
					break;
				}
			}
			if (otherFace == null) {
				throw 'Cannot find connected edge for new face.';
			}

			var newFace = constructFace(edge[0], edge[1], furthestPoint);
			newFaces.push(newFace);
			facePointMap.set(newFace, []);
		}

		// Add furthest point to hullPoints
		hullPoints.set(furthestPoint, true);
        hullPointsCount++;

		// Remove furthest point from all facePointMap entries
		for (faceKey in facePointMap.keys()) {
			var pointList = facePointMap.get(faceKey);
			pointList = pointList.filter(function(p) return p != furthestPoint);
			facePointMap.set(faceKey, pointList);
		}

        var allPointsNotInHull = hull.vertices.filter(function(p) return !(hullPoints.exists(p) || p == furthestPoint));
        
		// Reassign points to the new faces
          for (p in allPointsNotInHull) {
            var maxFace:FaceMesh3DFace = null;
            var maxDistance = -1.0;
            for (newFace in newFaces) {
                if (newFace.isPointAbove(p)) {
                    var distance = newFace.distanceToPoint(p);
                    if (distance > maxDistance) {
                        maxDistance = distance;
                        maxFace = newFace;
                    }
                }
            }
            if (maxFace != null) {
                facePointMap.get(maxFace).push(p);
            }
        }

		// Recurse for new faces
		for (newFace in newFaces) {
			if (!processedFaces.exists(newFace)) {
				addPointsToHull(newFace, facePointMap, processedFaces);
			}
		}
	}

	private function findVisibleFaces(point:Point3D, face:FaceMesh3DFace, visibleFaces:Array<FaceMesh3DFace>):Void {
		var stack = [face];
		var visited = new Map<FaceMesh3DFace, Bool>();

		var edgeMap = hull.makeEdgeMap(vertexMap);

		while (stack.length > 0) {
			var currentFace = stack.pop();
			if (!visited.exists(currentFace)) {
				visited.set(currentFace, true);
				if (currentFace.isPointAbove(point)) {
					visibleFaces.push(currentFace);
					// Add adjacent faces
					for (i in 0...3) {
						var a = currentFace.vertices[i];
						var b = currentFace.vertices[(i + 1) % 3];
						var edgeKey = vertexMap.makeEdgeKey(a, b);
						var edge = edgeMap.get(edgeKey);

						var adjacentFace = edge.getOtherFace(currentFace);
						if (adjacentFace != null && !visited.exists(adjacentFace)) {
							stack.push(adjacentFace);
						}
					}
				}
			}
		}
	}

    public function asTriangleIndices(transFaces: Array<FaceMesh3DFace>):Array<Int> {

        if (transFaces == null) transFaces = hull.faces;
        var indices : Array<Int> = [];

        for (face in transFaces) {
            if (face.vertices.length != 3) {
                throw 'Face ${face} is not a triangle';
            }
            indices.push(vertexMap.get(face.vertices[0]));
            indices.push(vertexMap.get(face.vertices[1]));
            indices.push(vertexMap.get(face.vertices[2]));
        }
        return indices;
    }

    public function getUsedVerticesByIndex():Array<Int> {
        var indices : Array<Int> = [];
        var visted = new Map<Point3D, Bool>();
        
        function visit(v:Point3D) {
            if (!visted.exists(v)) {
                visted.set(v, true);
                indices.push(vertexMap.get(v));
            }
        }
        for (face in hull.faces) {
            for (v in face.vertices) {
                visit(v);
            }   
        }
        return indices;
    }
}
