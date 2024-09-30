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
                    throw 'Point ${point} is already in the hull';
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

                //trace('Next? ${iterator.hasNext()}');
			}
		}
	}

	private function findInitialTetrahedron() {
		var points = hull.vertices;
		// Find extreme points
		var minX = points[0];
		var maxX = points[0];
		var minY = points[0];
		var maxY = points[0];
		var minZ = points[0];
		var maxZ = points[0];

		for (p in points) {
			if (p.x < minX.x)
				minX = p;
			if (p.x > maxX.x)
				maxX = p;
			if (p.y < minY.y)
				minY = p;
			if (p.y > maxY.y)
				maxY = p;
			if (p.z < minZ.z)
				minZ = p;
			if (p.z > maxZ.z)
				maxZ = p;
		}

		// Create initial simplex
		var simplex = [minX, maxX, minY, maxY, minZ, maxZ];
		var vertices:Array<Point3D> = [];
		var found = false;

		for (i in 0...simplex.length) {
			for (j in i + 1...simplex.length) {
				for (k in j + 1...simplex.length) {
					for (l in k + 1...simplex.length) {
						vertices = [simplex[i], simplex[j], simplex[k], simplex[l]];
						if (!areCoplanar(vertices[0], vertices[1], vertices[2], vertices[3])) {
							found = true;
							break;
						}
					}
					if (found)
						break;
				}
				if (found)
					break;
			}
			if (found)
				break;
		}

		if (!found) {
			throw 'Cannot find initial tetrahedron: all points may be coplanar.';
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

		// trace('Adding face ${face} - testing against point ${testPoint}');
		if (face.isPointAbove(hullCentroid)) {
			//  trace('\tFlipping face');
			face.flip();
		}

		// trace('Checking non-manifold geometry');
		// test for non-manifold geometry
		hull.makeEdgeMap(vertexMap);

		return face;
	}

	private function addPointsToHull(face:FaceMesh3DFace, facePointMap:Map<FaceMesh3DFace, Array<Point3D>>, processedFaces:Map<FaceMesh3DFace, Bool>):Void {
		var points = facePointMap.get(face);

		// Remove points that are already in the hull
		points = points.filter(function(p) return !hullPoints.exists(p));

		// trace('Adding points to hull for face ${face} : ${points}');
		if (points == null || points.length == 0) {
//            trace('No points to add to hull for face ${face}');
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
}
