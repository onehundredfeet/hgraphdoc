package gdoc;

class Prim2D {
    public var a:Point2D;
	public var b:Point2D;
	public var c:Point2D;
    public var d:Point2D;

    public inline function toPrim() : Prim2D{
        return this;
    }

    public function getVertCount() : Int {
        return 3;
    }
    public inline function getPoint(idx:Int) : Point2D {
        return switch(idx) {
            case 0: a;
            case 1: b;
            case 2: c;
            case 3: d;
            default: throw "Invalid index";
        }
    }

    public function getEdgeIndexFromVerts(oa : Point2D, ob : Point2D) : Int {
        var l = getVertCount();

        for (i in 0...l) {
            if (getPoint(i) == oa) {
                final next = (i+1)%l;
                if (getPoint(next) == ob) return i;
                final prev = (i-1+l)%l;
                if (getPoint(prev) == ob) return prev;
                break;
            }
        }
        return -1;
    }
    
    public function getSharedEdgeLocalIndex(foreignPrim : Prim2D, foreignEdge:Int) : Int {
        var fa = foreignPrim.getPoint(foreignEdge);
        var fb = foreignPrim.getPoint((foreignEdge + 1) % foreignPrim.getVertCount());

        return getEdgeIndexFromVerts(fa, fb);
    }
}