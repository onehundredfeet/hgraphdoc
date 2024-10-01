package gdoc;

import gdoc.Point3D;

class FaceMesh3DFace {
    public var vertices:Array<Point3D>;
    public var normal:Point3D;

    public function new(a:Point3D, b:Point3D, c:Point3D) {
        vertices = [a, b, c];
        normal = computeNormal(a, b, c);
        if (Math.isNaN(normal.x) || Math.isNaN(normal.y) || Math.isNaN(normal.z)) {
            throw 'Degenerate face: ${a}, ${b}, ${c}';
        }
    }

    public inline function isPointAbove(point:Point3D):Bool {
        return isPointAbovePlane(normal, vertices[0], point);
    }
    public inline function distanceToPoint(point:Point3D):Float {
        return pointToPlaneDistance(normal, vertices[0], point);
    }
    public inline function isNormalAligned(normal:Point3D):Bool {
        return this.normal.x * normal.x + this.normal.y * normal.y + this.normal.z * normal.z >= 0;
    }
    public function flip() {
        var temp = vertices[1];
        vertices[1] = vertices[2];
        vertices[2] = temp;
        normal = computeNormal(vertices[0], vertices[1], vertices[2]);
        if (Math.isNaN(normal.x) || Math.isNaN(normal.y) || Math.isNaN(normal.z)) {
            throw 'Degenerate face after flip: ${vertices[0]}, ${vertices[1]}, ${vertices[2]}';
        }
    }

    public function toString():String {
        return 'Face(${vertices}, ${normal})';
    }

    public inline function centroid() {
        return computeCentroid(vertices);
    }
}

class FaceMesh3DEdge {
    public var va:Point3D;
    public var vb:Point3D;
    public var fa: FaceMesh3DFace;
    public var fb: FaceMesh3DFace;

    public inline function new(va:Point3D, vb:Point3D) {
        this.va = va;
        this.vb = vb;
    }

    public inline function getOtherFace(f:FaceMesh3DFace):FaceMesh3DFace {
        if (f == fa) {
            return fb;
        }
        if (f != fb) {
            throw 'Edge does not contain face ${f}';
        }
        return fa;
    }
}

@:forward.new
@:forward
abstract VertexIndexMap(Map<Point3D, Int>) {

    // only supports indicies up to 65535
    public function makeEdgeKey(a:Point3D, b:Point3D):Int {
        var aIndex = this.get(a);
        var bIndex = this.get(b);
        if (aIndex < bIndex) {
            return (aIndex << 16) | bIndex;
        } else {
            return (bIndex << 16) | aIndex;
        }
    }
}

// only supports up to 65535 vertices
class FaceMesh3D{
    public var faces(default,null) = new Array<FaceMesh3DFace>();
    public var vertices(default,null):Array<Point3D>;
    
    public function new (vertices:Array<Point3D> = null){
        this.vertices = vertices != null ? vertices : [];
    }

    public function addFace(a:Point3D, b:Point3D, c:Point3D):FaceMesh3DFace {
        var face = new FaceMesh3DFace(a, b, c);
        faces.push(face);
        return face;
    }
    public function addFaceByIndex(a:Int, b:Int, c:Int): FaceMesh3DFace {
        var face = new FaceMesh3DFace(vertices[a], vertices[b], vertices[c]);
        faces.push(face);
        return face;
    }

    public function makeVertexIndexMap() : VertexIndexMap {
        var map = new VertexIndexMap();
        for (i in 0...vertices.length) {
            map.set(vertices[i], i);
        }
        return map;
    }

    public function centroidFromFaces() : Point3D {
        var visited = new Map<Point3D, Bool>();

        var accum = new Point3D(0.0, 0.0, 0.0);

        var count = 0;
        for (f in faces) {
            for (v in f.vertices) {
                if (!visited.exists(v)) {
                    accum.x += v.x;
                    accum.y += v.y;
                    accum.z += v.z;
                    count ++;
                    visited.set(v, true);
                }
            }
        }

        accum.x /= count;
        accum.y /= count;
        accum.z /= count;
        return accum;
    }

    public function makeEdgeMap(vertexMap : VertexIndexMap ) : Map<Int, FaceMesh3DEdge> {
        var map = new Map<Int, FaceMesh3DEdge>();

        function addEdge( a: Point3D, b:Point3D, f:FaceMesh3DFace) {
            var ab = vertexMap.makeEdgeKey(a,b);
            if (!map.exists(ab)) {
                var edge = new FaceMesh3DEdge(a, b);
                edge.fa = f;
                map.set(ab,edge );
                return edge;
            }
            var edge = map.get(ab);
            if (edge.fb != null) {
                throw 'Non-manifold geometry\n\t${edge.fa}\n\t${edge.fb}\n\t${f}';
            }
            edge.fb = f;
            return edge;
        }
        for (face in faces) {
            var ab = addEdge(face.vertices[0], face.vertices[1], face);
            var bc = addEdge(face.vertices[1], face.vertices[2], face);
            var ca = addEdge(face.vertices[2], face.vertices[0], face);            
        }
        return map;
    }
    public function isPointInside(point:Point3D):Bool {
        for (face in faces) {
            if (face.vertices[0] == point || face.vertices[1] == point || face.vertices[2] == point) {
               //trace('Point is on face...');
                return true;
            }
            if (isPointAbovePlane(face.normal, face.vertices[0], point)) {
                //trace('Failed by ${face.distanceToPoint(point)}');
                return false;
            }
        }
        return true;
    }

    
}

