package gdoc;

import gdoc.Point3D;

class IndexedTriMesh3DFace {
    public var a:Int;
    public var b:Int;
    public var c:Int;
    public var normal:Point3D;

    public function new(a:Int, b:Int, c:Int) {
        this.a = a;
        this.b = b;
        this.c = c;
    }
}

class IndexedTriMesh3D {
    public function new( points : Array<Point3D>) {
        this._vertices = points;
    }
    var _faces:Array<IndexedTriMesh3DFace>;
    var _vertices:Array<Point3D>;

    public function addFace( a:Int, b:Int, c:Int) : IndexedTriMesh3DFace{
        var face = new IndexedTriMesh3DFace(a, b, c);
        face.normal = computeNormal( _vertices[a], _vertices[b], _vertices[c]);
        _faces.push(face);
        return face;
    }

    public function addVertex( p : Point3D ) {
        _vertices.push(p);
        return _vertices.length -1;
    }

    public inline function getVertex(i : Int) {
        return _vertices[i];
    }

    public inline function getFaceVerts(f : IndexedTriMesh3DFace) {
        return [_vertices[f.a], _vertices[f.b], _vertices[f.c]];
    }

    public inline function getFaceVertA(f : IndexedTriMesh3DFace) {
        return _vertices[f.a];
    }

    public inline function getFaceVertB(f : IndexedTriMesh3DFace) {
        return _vertices[f.b];
    }

    public inline function getFaceVertC(f : IndexedTriMesh3DFace) {
        return _vertices[f.c];
    }

    // public function 
    // function isPointInTetrahedron(point:Point3D, faces:FaceMesh3D):Bool {
    //     for (face in faces) {
    //         if (face.isPointAbove(point)) {
    //             return false;
    //         }
    //     }
    //     return true;
    // }
        
}

