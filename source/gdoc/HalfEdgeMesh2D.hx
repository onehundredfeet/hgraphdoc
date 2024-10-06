package gdoc;

class HalfEdge2DVertex2D extends Point2D{
    public var edge:HalfEdge2D; // An outgoing half-edge from this vertex
    public var index:Int;     // Unique identifier for the vertex

    public function new(x:Float, y:Float, index:Int) {
        super(x, y);
        this.edge = null;
        this.index = index;
    }
}

class HalfEdge2D {
    public var vertex:HalfEdge2DVertex2D;     // Vertex at the start of this half-edge
    public var face:HalfEdgeFace2D;         // Face this half-edge borders
    public var next:HalfEdge2D;     // Next half-edge around the face
    public var prev:HalfEdge2D;     // Previous half-edge around the face (added)
    public var opposite:HalfEdge2D; // Opposite half-edge (twin)

    public function new() {
        this.vertex = null;
        this.face = null;
        this.next = null;
        this.prev = null; // Initialize prev to null
        this.opposite = null;
    }
}

class HalfEdgeFace2D {
    public var edge:HalfEdge2D; // One of the half-edges bordering this face

    public function new() {
        this.edge = null;
    }
}

class HalfEdgeGeometryConstructor {
    public function new(vertex : (x : Float, y : Float, id : Int) -> HalfEdge2DVertex2D, edge : () -> HalfEdge2D, face : () -> HalfEdgeFace2D) {
        this.vertex = vertex;
        this.edge = edge;
        this.face = face;
    }
    public var vertex : (x : Float, y : Float, id : Int) -> HalfEdge2DVertex2D;
    public var edge : () -> HalfEdge2D;
    public var face : () -> HalfEdgeFace2D;
}

class HalfEdgeRemapCB {
    public var vertex : (Point2D, HalfEdge2DVertex2D) -> Void;
    public var triangle : (Triangle2D, HalfEdgeFace2D) -> Void;
    public var polygon : (Array<Point2D>, HalfEdgeFace2D) -> Void;
}

class HalfEdgeMesh2D {
    public var vertices:Array<HalfEdge2DVertex2D>;
    public var edges:Array<HalfEdge2D>;
    public var faces:Array<HalfEdgeFace2D>;

    var _constructor: HalfEdgeGeometryConstructor;

    static var _defaultConstructor = new HalfEdgeGeometryConstructor(
        function(x:Float, y:Float, id:Int) {
            return new HalfEdge2DVertex2D(x, y, id);
        },
        function() {
            return new HalfEdge2D();
        },
        function() {
            return new HalfEdgeFace2D();
        }
    );

    public function new(constructor : HalfEdgeGeometryConstructor = null) {
        vertices = new Array<HalfEdge2DVertex2D>();
        edges = new Array<HalfEdge2D>();
        faces = new Array<HalfEdgeFace2D>();
        _constructor = constructor == null ? _defaultConstructor : constructor;
    }

    private var _nextID:Int = 0; // For assigning unique indices to vertices
    // Map to find matching half-edges using integer keys
    // Ensure that vertex indices are within 16-bit limits (0 to 65535)
    private var _edgeMap = new Map<Int, HalfEdge2D>();

    // Adds a vertex to the mesh and returns its index
    public function addVertex(x:Float, y:Float):HalfEdge2DVertex2D {
        var vertex = _constructor.vertex(x, y, _nextID++);
        vertices.push(vertex);
        return vertex;
    }

    public static function fromTrianglesRemap(triangles:Array<Triangle2D>, constructor: HalfEdgeGeometryConstructor = null, remap : HalfEdgeRemapCB = null) {
        var mesh = new HalfEdgeMesh2D(constructor);
        var vertexMap = new Map<Point2D, HalfEdge2DVertex2D>();

        for (t in triangles) {
            var a = t.a;
            var b = t.b;
            var c = t.c;

            var va = vertexMap.get(a);
            if (va == null) {
                va = mesh.addVertex(a.x, a.y);
                if (remap != null && remap.vertex != null) {
                    remap.vertex(a, va);
                }
                vertexMap.set(a, va);
            }

            var vb = vertexMap.get(b);
            if (vb == null) {
                vb = mesh.addVertex(b.x, b.y);
                if (remap != null && remap.vertex != null) {
                    remap.vertex(b, vb);
                }
                vertexMap.set(b, vb);
            }

            var vc = vertexMap.get(c);
            if (vc == null) {
                vc = mesh.addVertex(c.x, c.y);
                if (remap != null && remap.vertex != null) {
                    remap.vertex(c, vc);
                }
                vertexMap.set(c, vc);
            }

            var face = mesh.addFace([va, vb, vc]);
            if (remap != null && remap.triangle != null) {
                remap.triangle(t, face);
            }
        }

        return mesh;
    }
    public function addFace(vertexes:Array<HalfEdge2DVertex2D>) {
        var face = _constructor.face();
        faces.push(face);
    
        var numVertices = vertexes.length;
        var faceEdges:Array<HalfEdge2D> = [];
    
        // Create half-edges for the face
        for (i in 0...numVertices) {
            var he = _constructor.edge();
            edges.push(he);
            faceEdges.push(he);
            he.face = face;
        }
    
        // Link the half-edges and assign vertices
        for (i in 0...numVertices) {
            var currentEdge = faceEdges[i];
            var nextEdge = faceEdges[(i + 1) % numVertices];
            var prevEdge = faceEdges[(i - 1 + numVertices) % numVertices]; // Handle negative indices
    
            currentEdge.next = nextEdge;
            currentEdge.prev = prevEdge;
    
            var originVertex = vertexes[i];               // Origin of the half-edge
            var destinationVertex = vertexes[(i + 1) % numVertices]; // Destination vertex
    
            currentEdge.vertex = originVertex;
    
            // Assign an outgoing edge to the origin vertex if not already assigned
            if (originVertex.edge == null) {
                originVertex.edge = currentEdge;
            }
    
            // Create unique keys for the edge and its opposite
            var key:Int = (destinationVertex.index << 16) | originVertex.index;
            var oppositeKey:Int = (originVertex.index << 16) | destinationVertex.index;
    
            // Store the current edge in the global edge map
            _edgeMap.set(key, currentEdge);
    
            // Check if the opposite edge exists in the global edge map
            if (_edgeMap.exists(oppositeKey)) {
                var oppositeEdge = _edgeMap.get(oppositeKey);
                currentEdge.opposite = oppositeEdge;
                oppositeEdge.opposite = currentEdge;
            }
        }
    
        face.edge = faceEdges[0];

        return face;
    }
    


    // Computes the dual of the mesh
    public function computeDual(constructor : HalfEdgeGeometryConstructor = null):HalfEdgeMesh2D {
        var dualMesh = new HalfEdgeMesh2D(constructor);

        // Maps to keep track of associations between original and dual elements
        var faceToDualVertex = new Map<HalfEdgeFace2D, HalfEdge2DVertex2D>();
        var vertexToDualFace = new Map<HalfEdge2DVertex2D, HalfEdgeFace2D>();
        var halfEdgeToDualHalfEdge2D = new Map<HalfEdge2D, HalfEdge2D>();

        // Create dual vertices for each face
        for (f in faces) {
            var centroidX:Float = 0;
            var centroidY:Float = 0;
            var count:Int = 0;

            var edge = f.edge;
            do {
                centroidX += edge.vertex.x;
                centroidY += edge.vertex.y;
                count++;
                edge = edge.next;
            } while (edge != f.edge);

            centroidX /= count;
            centroidY /= count;

            var dualVertex = dualMesh.addVertex(centroidX, centroidY);
            faceToDualVertex.set(f, dualVertex);
        }

        // Create dual faces for each vertex
        for (v in vertices) {
            var dualFace = dualMesh._constructor.face();
            dualMesh.faces.push(dualFace);
            vertexToDualFace.set(v, dualFace);
        }

        // Create dual half-edges
        for (he in edges) {
            var dualHe = dualMesh._constructor.edge();
            dualMesh.edges.push(dualHe);
            halfEdgeToDualHalfEdge2D.set(he, dualHe);
        }

        // Set up dual half-edges
        for (he in edges) {
            var dualHe = halfEdgeToDualHalfEdge2D.get(he);

            // The dual half-edge's vertex corresponds to the face of the original half-edge
            dualHe.vertex = faceToDualVertex.get(he.face);

            // The dual half-edge's face corresponds to the vertex at the end of the original half-edge
            dualHe.face = vertexToDualFace.get(he.vertex);

            // Set the opposite half-edge
            if (he.opposite != null) {
                dualHe.opposite = halfEdgeToDualHalfEdge2D.get(he.opposite);
            }

            // Set the next half-edge (reverse traversal)
            var prevOpposite = he.prev.opposite;
            if (prevOpposite != null) {
                dualHe.next = halfEdgeToDualHalfEdge2D.get(prevOpposite);
            }

            // Set the prev half-edge
            var nextOpposite = he.next.opposite;
            if (nextOpposite != null) {
                dualHe.prev = halfEdgeToDualHalfEdge2D.get(nextOpposite);
            }
        }

        //  Assign half-edges to dual faces
        for (v in vertices) {
            var dualFace = vertexToDualFace.get(v);
            var startHe = v.edge;
            var edge = startHe;
            var firstDualHe:HalfEdge2D = null;

            do {
                var he = edge;
                var dualHe = halfEdgeToDualHalfEdge2D.get(he);

                if (firstDualHe == null) {
                    dualFace.edge = dualHe;
                    firstDualHe = dualHe;
                }

                dualHe.face = dualFace;

                // Move to the next half-edge around the original vertex
                edge = he.prev.opposite;
            } while (edge != null && edge != startHe);
        }

        // Assign half-edges to dual vertices
        for (f in faces) {
            var dualVertex = faceToDualVertex.get(f);
            dualVertex.edge = halfEdgeToDualHalfEdge2D.get(f.edge);
        }

        return dualMesh;
    }

    // Static function to generate a Voronoi diagram
        public static function generateVoronoi(points:Array<{x:Float, y:Float}>, bounds:{minX:Float, maxX:Float, minY:Float, maxY:Float}):HalfEdgeMesh2D {
            var delaunayMesh = new HalfEdgeMesh2D();
    
            // Create a super-triangle that contains all the points
            var dx = bounds.maxX - bounds.minX;
            var dy = bounds.maxY - bounds.minY;
            var deltaMax = Math.max(dx, dy) * 10;
    
            var midX = (bounds.minX + bounds.maxX) / 2;
            var midY = (bounds.minY + bounds.maxY) / 2;
    
            var v0 = delaunayMesh.addVertex(midX - deltaMax, midY - deltaMax);
            var v1 = delaunayMesh.addVertex(midX, midY + deltaMax);
            var v2 = delaunayMesh.addVertex(midX + deltaMax, midY - deltaMax);
    
            // Create the super-triangle face
            delaunayMesh.addFace([v0, v1, v2]);
    
            // Map to store point to vertex index
            var pointToVertex = new Map<{x:Float, y:Float}, HalfEdge2DVertex2D>();
    
            // Insert each point into the triangulation
            for (p in points) {
                // Add the point as a vertex
                var vi = delaunayMesh.addVertex(p.x, p.y);
                pointToVertex.set(p, vi);
    
                // Find all triangles whose circumcircle contains the point
                var badFaces = [];
                for (face in delaunayMesh.faces) {
                    if (circumcircleContains(face, vi)) {
                        badFaces.push(face);
                    }
                }
    
                // Find the boundary of the polygonal hole
                var polygon = [];
                for (face in badFaces) {
                    var edges = [face.edge, face.edge.next, face.edge.prev];
                    for (he in edges) {
                        var oppositeFace = he.opposite != null ? he.opposite.face : null;
                        if (oppositeFace == null || !badFaces.contains(oppositeFace)) {
                            polygon.push({start: he.prev.vertex, end: he.vertex});
                        }
                    }
                }
    
                // Remove the bad faces from the mesh
                for (face in badFaces) {
                    delaunayMesh.removeFace(face);
                }
    
                // Re-triangulate the hole
                for (edge in polygon) {
                    delaunayMesh.addFace([edge.start, edge.end, vi]);
                }
            }
    
            // Remove triangles that include vertices from the super-triangle
            var verticesToRemove = [v0, v1, v2];
            delaunayMesh.removeFacesUsingVertices(verticesToRemove);
    
            // Compute the Voronoi diagram as the dual of the Delaunay triangulation
            var voronoiMesh = delaunayMesh.computeDual();
    
            // Clip the Voronoi diagram to the bounding box (not implemented)
            // You may implement clipping logic here if needed
    
            return voronoiMesh;
        }
    
        // Helper function to check if a point is inside the circumcircle of a face
        private static function circumcircleContains(face:HalfEdgeFace2D, point:HalfEdge2DVertex2D):Bool {
            var a = face.edge.vertex;
            var b = face.edge.next.vertex;
            var c = face.edge.next.next.vertex;
        
            var matrix = [
                [a.x - point.x, a.y - point.y, (a.x - point.x) * (a.x - point.x) + (a.y - point.y) * (a.y - point.y)],
                [b.x - point.x, b.y - point.y, (b.x - point.x) * (b.x - point.x) + (b.y - point.y) * (b.y - point.y)],
                [c.x - point.x, c.y - point.y, (c.x - point.x) * (c.x - point.x) + (c.y - point.y) * (c.y - point.y)]
            ];
        
            var det = matrix[0][0] * (matrix[1][1] * matrix[2][2] - matrix[2][1] * matrix[1][2]) -
                        matrix[0][1] * (matrix[1][0] * matrix[2][2] - matrix[2][0] * matrix[1][2]) +
                        matrix[0][2] * (matrix[1][0] * matrix[2][1] - matrix[2][0] * matrix[1][1]);
        
            return det > 0; // Adjust sign based on coordinate system
        }
            
    
        // Removes a face from the mesh
        function removeFace(face:HalfEdgeFace2D):Void {
            faces.remove(face);
        
            // Collect all half-edges associated with the face
            var edgesToRemove:Array<HalfEdge2D> = [];
            var startEdge = face.edge;
            var edge = startEdge;
            do {
                edgesToRemove.push(edge);
                edge = edge.next;
            } while (edge != startEdge);
        
            // Remove each half-edge associated with the face
            for (he in edgesToRemove) {
                // Remove he from its vertex's edge list if necessary
                if (he.vertex.edge == he) {
                    // Assign another outgoing edge if available
                    var outgoingEdge = he.next.opposite;
                    if (outgoingEdge != null && outgoingEdge.vertex == he.vertex) {
                        he.vertex.edge = outgoingEdge;
                    } else {
                        he.vertex.edge = null;
                    }
                }
        
                // Remove the edge from the global edge map
                var originIndex = he.vertex.index;
                var destinationIndex = he.next.vertex.index;
                var key:Int = (destinationIndex << 16) | originIndex;
                _edgeMap.remove(key);
        
                // Update he.opposite
                if (he.opposite != null) {
                    he.opposite.opposite = null;
                }
        
                // Update next and prev of adjacent half-edges
                if (he.next != null) {
                    he.next.prev = he.prev;
                }
                if (he.prev != null) {
                    he.prev.next = he.next;
                }
        
                edges.remove(he);
            }
        }
        
        function removeFaceAndVerts(face:HalfEdgeFace2D):Void {

            // Keep track of vertices that may become isolated
            var verticesToCheck:Array<HalfEdge2DVertex2D> = new Array<HalfEdge2DVertex2D>();
            var startEdge = face.edge;
            var edge = startEdge;
            do {
                verticesToCheck.push(edge.vertex);
                edge = edge.next;
            } while (edge != startEdge);

            removeFace(face);
            
            // Remove isolated vertices
            for (vertex in verticesToCheck) {
                if (vertex.edge == null) {
                    // The vertex is not connected to any edges, so remove it
                    vertices.remove(vertex);
                }
            }
        }
    
        // Removes faces that use any of the specified vertices
        private function removeFacesUsingVertices(verticesToRemove:Array<HalfEdge2DVertex2D>):Void {
            var facesToRemove = [];
            for (face in faces) {
                var usesVertex = false;
                var edge = face.edge;
                do {
                    if (verticesToRemove.indexOf(edge.vertex) != -1) {
                        usesVertex = true;
                        break;
                    }
                    edge = edge.next;
                } while (edge != face.edge);
    
                if (usesVertex) {
                    facesToRemove.push(face);
                }
            }
    
            for (face in facesToRemove) {
                removeFace(face);
            }
        }
    
}



