package grph;

import hl.types.Int64Map;
import haxe.Int64;

using Lambda;

@:forward
abstract PrimGridCellKey( Int64 ) from Int64 to Int64 {
    public function new( v : Int64 ) {
        this = v;
    }
    public static function make( x : Int, y : Int ) : PrimGridCellKey{
        return Int64.make( x, y );
    }
    @:keep
    public function toString() {
        return '${this.high}:${this.low}';
    }
}

@:forward
@:forward.new
abstract PrimGridCell(Array<Prim2D>) to Array<Prim2D>{
}


abstract PrimCellMap( Int64Map ) {
    public inline function new() {
        this = new Int64Map();
    }
    public inline function get( key : PrimGridCellKey ) : PrimGridCell {
        return this.get( key );
    }
    public inline function set( key : PrimGridCellKey, value : PrimGridCell ) {
        return this.set( key, value );
    }

    public function toString() {
        var keys = this.keysArray();
        var keyStrings = [];
        for (k in keys) {
            keyStrings.push( '${k.high}:${k.low}' );
        }        
        return 'PrimCellMap(${keyStrings.length} cells: ${keyStrings})';
    }
}
class PrimGrid2D {
    public function new (cellWidth:Float, cellHeight:Float) {
        this.cellWidth = cellWidth;
        this.cellHeight = cellHeight;
    }
    public final cellWidth:Float;
    public final cellHeight:Float;
    public final cells = new PrimCellMap();
    
    public inline function getCellX(x:Float):Int {
        return Std.int(x / cellWidth);
    }
    public inline function getCellY(y:Float):Int {
        return Std.int(y / cellHeight);
    }
    public inline function getPointCellKeyXY( x : Float, y : Float ) : PrimGridCellKey{
        return new PrimGridCellKey( Int64.make( Std.int(x / cellWidth), Std.int(y / cellHeight) ) );
    }
    public inline function getPointCellKey( p : Point2D ) : PrimGridCellKey{
        return getPointCellKeyXY( p.x, p.y );
    }

    public inline function getCellFromPoint( p : Point2D ) : PrimGridCell {
        return cells.get( getPointCellKey( p ) );
    }
    public inline function getCellFromXY( x : Float, y : Float ) : PrimGridCell {
        return cells.get( getPointCellKeyXY( x, y ) );
    }
    public inline function getCellFromKey( key : PrimGridCellKey ) : PrimGridCell {
        return cells.get( key );
    }
    public inline function getOrCreateCellFromKey( key : PrimGridCellKey ) : PrimGridCell {
        var x = cells.get( key );
        if (x == null) {
            x = new PrimGridCell();
            cells.set( key, x );
        }
        return x;
    }
    public inline function getOrCreateCellFromPoint( p : Point2D ) : PrimGridCell {
        return getOrCreateCellFromKey(getPointCellKey( p ) );
    }
    public inline function walkCellsNear( p : Point2D, r : Float, fn : (PrimGridCell) -> Bool) {
        return walkCellsNearXY( p.x, p.y, r, fn );
    }

    public function walkCellsNearXY( x : Float, y : Float, r : Float, fn : (PrimGridCell) -> Bool) {
        var minX = getCellX(x - r);
        var minY = getCellY(y - r);
        var maxX = getCellX(x + r) + 1;
        var maxY = getCellY(y + r) + 1;

        for (x in minX...maxX) {
            for (y in minY...maxY) {
                var c = cells.get( new PrimGridCellKey( (x << 32) | y ) );
                if (c != null) {
                    if (!fn(c)) return;
                }
            }
        }
    }

    // may produce dupe prims
    public function walkPrimsNear( p : Point2D, r : Float, fn : (Prim2D) -> Bool) {
        walkCellsNear( p, r, function(c) {
            for (prim in c) {
                if (!fn(prim)) return false;
            }
            return true;
        });
    }
    public function getPrimAtXY( x : Float, y : Float ) : Prim2D {
        var c = getCellFromXY( x, y );
//        trace('getPrimAtXY ${x}, ${y}, [${getPointCellKeyXY(x,y)}] ${c}');
        if (c == null) return null;
        for (prim in c) {
            if (prim.containsXY(x, y)) return prim;
        }
        return null;
    }
    public function getPrimNearestXY( x : Float, y : Float, r : Float ) : Prim2D {
        var exact = getPrimAtXY( x, y );
        if (exact != null) return exact;

        var bestDist2 = r * r;
        var bestPrim = null;
        walkCellsNearXY( x, y, r, function(primCell) {
            for (p in primCell) {
                var d2 = p.distanceSquaredToNearestVertXY(x, y);
                if (d2 < bestDist2) {
                    bestDist2 = d2;
                    bestPrim = p;
                }
            }
            return true;
        });
        return bestPrim;
    }

    public function getPrimAt( p : Point2D ) : Prim2D {
        var c = getCellFromPoint( p );
        if (c == null) return null;
        for (prim in c) {
            if (prim.containsPoint(p)) return prim;
        }
        return null;
    }

    public function addPrims( prims : Array<Prim2D> ) {
        var bounds = Rect2D.infiniteEmpty();
        for (prim in prims) {
            bounds.reset();
            bounds.expandToIncludePrim( prim );
            var minX = getCellX(bounds.xmin);
            var maxX = getCellX(bounds.xmax) + 1;
            var minY = getCellY(bounds.ymin);
            var maxY = getCellY(bounds.ymax) + 1;

            for (x in minX...maxX) {
                for (y in minY...maxY) {
                    var key = PrimGridCellKey.make( x, y );
                    var c = cells.get( key );
                    if (c == null) {
                        c = new PrimGridCell();
                        cells.set( key, c );
                    } 
                    c.push( prim );
                }
            }
        }
    }

    public static function fromPrims( prims : Array<Prim2D>, cellWidth : Float, cellHeight : Float ) : PrimGrid2D {
        var grid = new PrimGrid2D( cellWidth, cellHeight );
        grid.addPrims( prims );
        return grid;
    }

    @:keep
    public function toString() {
        return 'PrimGrid2D(${cellWidth}, ${cellHeight}: ${cells} )';
    }
}